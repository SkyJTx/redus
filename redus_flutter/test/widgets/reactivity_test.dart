import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ReactiveWidget auto-tracking', () {
    testWidgets('should auto-track ref in render() and rebuild on change',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: _RefAutoTrackWidget()));

      expect(find.text('Count: 0'), findsOneWidget);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('should auto-track computed in render()', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _ComputedAutoTrackWidget()));

      expect(find.text('Doubled: 0'), findsOneWidget);

      // Tap to increment base value
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Doubled: 2'), findsOneWidget);
    });

    testWidgets('should auto-track multiple refs in render()', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _MultiRefAutoTrackWidget()));

      expect(find.text('A: 0, B: 10'), findsOneWidget);

      // Increment A
      await tester.tap(find.text('Inc A'));
      await tester.pump();
      expect(find.text('A: 1, B: 10'), findsOneWidget);

      // Increment B
      await tester.tap(find.text('Inc B'));
      await tester.pump();
      expect(find.text('A: 1, B: 11'), findsOneWidget);
    });
  });

  group('ReactiveWidget watch()', () {
    testWidgets('watch() should fire callback when source changes',
        (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _WatchTestWidget(logs: logs),
      ));
      await tester.pump();

      // Initial - watch doesn't fire on first value
      expect(logs, isEmpty);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(logs, ['Changed from 0 to 1']);
    });

    testWidgets('watch() should receive old and new values', (tester) async {
      final changes = <(int, int)>[];

      await tester.pumpWidget(MaterialApp(
        home: _WatchValuesTestWidget(onChange: (n, o) => changes.add((o, n))),
      ));
      await tester.pump();

      // Increment 3 times
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(changes, [(0, 1), (1, 2), (2, 3)]);
    });
  });

  group('ReactiveWidget watchEffect()', () {
    testWidgets('watchEffect() should run immediately', (tester) async {
      var runCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectTestWidget(onRun: () => runCount++),
      ));
      await tester.pump();

      expect(runCount, 1);
    });

    testWidgets('watchEffect() should re-run when tracked values change',
        (tester) async {
      var runCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectTestWidget(onRun: () => runCount++),
      ));
      await tester.pump();

      expect(runCount, 1);

      // Increment triggers re-run
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(runCount, 2);
    });

    testWidgets('watchEffect() cleanup should be called before re-run',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectCleanupWidget(
          onRun: () => events.add('run'),
          onCleanup: () => events.add('cleanup'),
        ),
      ));
      await tester.pump();

      expect(events, ['run']);

      // Increment triggers cleanup then re-run
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(events, ['run', 'cleanup', 'run']);
    });

    testWidgets('watchEffect() should stop on dispose', (tester) async {
      var runCount = 0;
      final trigger = ref(0);

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectExternalRefWidget(
          trigger: trigger,
          onRun: () => runCount++,
        ),
      ));
      await tester.pump();

      expect(runCount, 1);

      // Unmount
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Trigger should not cause effect to run
      runCount = 0;
      trigger.value++;
      await tester.pump();

      expect(runCount, 0);
    });
  });

  group('ReactiveWidget bind()', () {
    testWidgets('bind() should persist state across parent rebuilds',
        (tester) async {
      final parentTrigger = ref(0);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentTrigger.watch(context);
          return _BindPersistenceWidget();
        }),
      ));

      expect(find.text('Count: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Trigger parent rebuild
      parentTrigger.value++;
      await tester.pump();

      // State should persist
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('bind() with computed should work correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _BindComputedWidget()));

      expect(find.text('Count: 0, Doubled: 0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1, Doubled: 2'), findsOneWidget);
    });
  });

  group('ReactiveWidget combined reactivity', () {
    testWidgets('should handle ref + computed + watch together',
        (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _CombinedReactivityWidget(logs: logs),
      ));
      await tester.pump();

      expect(find.text('Base: 0, Doubled: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Base: 1, Doubled: 2'), findsOneWidget);
      expect(logs, contains('Doubled changed to 2'));
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _RefAutoTrackWidget extends ReactiveWidget {
  _RefAutoTrackWidget();

  late final count = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _ComputedAutoTrackWidget extends ReactiveWidget {
  _ComputedAutoTrackWidget();

  late final base = bind(() => ref(0));
  late final doubled = bind(() => computed(() => base.value * 2));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('Doubled: ${doubled.value}'),
        ElevatedButton(
          onPressed: () => base.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _MultiRefAutoTrackWidget extends ReactiveWidget {
  _MultiRefAutoTrackWidget();

  late final countA = bind(() => ref(0));
  late final countB = bind(() => ref(10));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('A: ${countA.value}, B: ${countB.value}'),
        ElevatedButton(
          onPressed: () => countA.value++,
          child: const Text('Inc A'),
        ),
        ElevatedButton(
          onPressed: () => countB.value++,
          child: const Text('Inc B'),
        ),
      ],
    );
  }
}

class _WatchTestWidget extends ReactiveWidget {
  final List<String> logs;

  _WatchTestWidget({required this.logs});

  late final count = bind(() => ref(0));

  @override
  void setup() {
    watch(() => count.value, (newVal, oldVal, onCleanup) {
      logs.add('Changed from $oldVal to $newVal');
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _WatchValuesTestWidget extends ReactiveWidget {
  final void Function(int newVal, int oldVal) onChange;

  _WatchValuesTestWidget({required this.onChange});

  late final count = bind(() => ref(0));

  @override
  void setup() {
    watch(() => count.value, (newVal, oldVal, onCleanup) {
      onChange(newVal, oldVal!);
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _WatchEffectTestWidget extends ReactiveWidget {
  final VoidCallback onRun;

  _WatchEffectTestWidget({required this.onRun});

  late final count = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((onCleanup) {
      // Track count
      final _ = count.value;
      onRun();
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _WatchEffectCleanupWidget extends ReactiveWidget {
  final VoidCallback onRun;
  final VoidCallback onCleanup;

  _WatchEffectCleanupWidget({required this.onRun, required this.onCleanup});

  late final count = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((cleanup) {
      final _ = count.value;
      onRun();
      cleanup(onCleanup);
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _WatchEffectExternalRefWidget extends ReactiveWidget {
  final Ref<int> trigger;
  final VoidCallback onRun;

  const _WatchEffectExternalRefWidget(
      {required this.trigger, required this.onRun});

  @override
  void setup() {
    watchEffect((onCleanup) {
      final _ = trigger.value;
      onRun();
    });
  }

  @override
  Widget render(BuildContext context) {
    return Text('Trigger: ${trigger.value}');
  }
}

class _BindPersistenceWidget extends ReactiveWidget {
  _BindPersistenceWidget();

  late final count = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _BindComputedWidget extends ReactiveWidget {
  _BindComputedWidget();

  late final count = bind(() => ref(0));
  late final doubled = bind(() => computed(() => count.value * 2));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${count.value}, Doubled: ${doubled.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _CombinedReactivityWidget extends ReactiveWidget {
  final List<String> logs;

  _CombinedReactivityWidget({required this.logs});

  late final base = bind(() => ref(0));
  late final doubled = bind(() => computed(() => base.value * 2));

  @override
  void setup() {
    watch(() => doubled.value, (newVal, oldVal, onCleanup) {
      logs.add('Doubled changed to $newVal');
    });
  }

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        Text('Base: ${base.value}, Doubled: ${doubled.value}'),
        ElevatedButton(
          onPressed: () => base.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
