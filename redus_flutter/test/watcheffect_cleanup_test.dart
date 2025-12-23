// Test for watchEffect scope cleanup on unmount
//
// This test verifies that watchEffect effects are properly stopped
// when the ReactiveWidget unmounts, preventing timer/effect accumulation.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('watchEffect scope cleanup', () {
    testWidgets('should stop watchEffect when widget unmounts', (tester) async {
      var effectRunCount = 0;
      var cleanupCallCount = 0;
      final trigger = ref(0);

      // Create a widget that uses watchEffect
      Widget createTestWidget() {
        return MaterialApp(
          home: _WatchEffectTestWidget(
            trigger: trigger,
            onEffectRun: () => effectRunCount++,
            onCleanup: () => cleanupCallCount++,
          ),
        );
      }

      // Mount the widget
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Effect should have run once
      expect(effectRunCount, equals(1));
      expect(cleanupCallCount, equals(0));

      // Trigger the effect
      trigger.value++;
      await tester.pump();
      expect(effectRunCount, equals(2));
      expect(cleanupCallCount, equals(1)); // Cleanup before re-run

      // Unmount by replacing with a different widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Cleanup should have been called
      expect(cleanupCallCount, equals(2));

      // Trigger should no longer cause effect to run
      final effectCountAfterUnmount = effectRunCount;
      trigger.value++;
      await tester.pump();

      // Effect should NOT have run after unmount
      expect(effectRunCount, equals(effectCountAfterUnmount));
    });

    testWidgets('should not accumulate effects on remount', (tester) async {
      var effectRunCount = 0;
      final trigger = ref(0);

      Widget createTestWidget(bool visible) {
        return MaterialApp(
          home: visible
              ? _EffectCounterWidget(
                  trigger: trigger,
                  onEffectRun: () => effectRunCount++,
                )
              : const SizedBox(),
        );
      }

      // Initial mount
      await tester.pumpWidget(createTestWidget(true));
      await tester.pump();
      expect(effectRunCount, equals(1));

      // Unmount
      await tester.pumpWidget(createTestWidget(false));
      await tester.pump();

      // Remount
      effectRunCount = 0;
      await tester.pumpWidget(createTestWidget(true));
      await tester.pump();
      expect(effectRunCount, equals(1)); // Should be 1, not 2

      // Unmount and remount again
      await tester.pumpWidget(createTestWidget(false));
      await tester.pump();

      effectRunCount = 0;
      await tester.pumpWidget(createTestWidget(true));
      await tester.pump();
      expect(effectRunCount, equals(1)); // Should still be 1, not 3

      // Trigger and verify only one effect runs
      effectRunCount = 0;
      trigger.value++;
      await tester.pump();
      expect(effectRunCount, equals(1)); // Should be exactly 1
    });

    testWidgets('timers in watchEffect should be cancelled on unmount',
        (tester) async {
      var timerFireCount = 0;
      final isLive = ref(true);

      await tester.pumpWidget(MaterialApp(
        home: _TimerEffectWidget(
          isLive: isLive,
          onTimerFire: () => timerFireCount++,
        ),
      ));
      await tester.pump();

      // Wait for timer to fire once
      await tester.pump(const Duration(milliseconds: 100));
      final countAfterFirstFire = timerFireCount;
      expect(countAfterFirstFire, greaterThan(0));

      // Unmount
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Timer should be cancelled, no more fires
      timerFireCount = 0;
      await tester.pump(const Duration(milliseconds: 200));
      expect(timerFireCount, equals(0));
    });
  });
}

class _WatchEffectTestWidget extends ReactiveWidget {
  final Ref<int> trigger;
  final VoidCallback onEffectRun;
  final VoidCallback onCleanup;

  _WatchEffectTestWidget({
    required this.trigger,
    required this.onEffectRun,
    required this.onCleanup,
  });

  @override
  void setup() {
    watchEffect((onCleanup) {
      // Access reactive value to track dependency
      final _ = trigger.value;
      onEffectRun();
      onCleanup(() {
        this.onCleanup();
      });
    });
  }

  @override
  Widget render(BuildContext context) {
    return Text('Value: ${trigger.value}');
  }
}

class _EffectCounterWidget extends ReactiveWidget {
  final Ref<int> trigger;
  final VoidCallback onEffectRun;

  _EffectCounterWidget({
    required this.trigger,
    required this.onEffectRun,
  });

  @override
  void setup() {
    watchEffect((onCleanup) {
      final _ = trigger.value;
      onEffectRun();
    });
  }

  @override
  Widget render(BuildContext context) {
    return Text('Value: ${trigger.value}');
  }
}

class _TimerEffectWidget extends ReactiveWidget {
  final Ref<bool> isLive;
  final VoidCallback onTimerFire;

  _TimerEffectWidget({
    required this.isLive,
    required this.onTimerFire,
  });

  @override
  void setup() {
    watchEffect((onCleanup) {
      if (isLive.value) {
        final timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          onTimerFire();
        });
        onCleanup(() => timer.cancel());
      }
    });
  }

  @override
  Widget render(BuildContext context) {
    return Text('Live: ${isLive.value}');
  }
}
