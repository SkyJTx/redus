import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ReactiveStatefulWidget', () {
    testWidgets('should call setup once', (tester) async {
      var setupCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _SetupTestWidget(onSetup: () => setupCount++),
      ));

      expect(setupCount, 1);

      // Trigger rebuild
      await tester.pump();
      expect(setupCount, 1); // Still 1 after rebuild
    });

    testWidgets('should call onMounted after first build', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleTestWidget(logs: logs),
      ));
      await tester.pump(); // Process post-frame callback

      expect(logs, contains('mounted'));
    });

    testWidgets('should call onDispose on dispose', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleTestWidget(logs: logs),
      ));
      await tester.pump();

      logs.clear();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(logs, contains('disposed'));
    });

    testWidgets('bind() should persist state across parent rebuilds',
        (tester) async {
      final parentTrigger = ref(0);
      late _CounterStore capturedStore;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentTrigger.watch(context);
          return _BindTestWidget(
            onStoreCreated: (store) => capturedStore = store,
          );
        }),
      ));

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Increment via store
      capturedStore.increment();
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Trigger parent rebuild
      parentTrigger.value++;
      await tester.pump();

      // State should persist!
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('reactive tracking triggers rebuilds', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ReactiveTestWidget(),
      ));

      expect(find.text('Count: 0'), findsOneWidget);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('ReactiveStatefulWidget with Flutter mixins', () {
    testWidgets('works with SingleTickerProviderStateMixin', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AnimatedTestWidget(logs: logs),
      ));
      await tester.pump();

      expect(logs, contains('controller_created'));
      expect(logs, contains('mounted'));
    });

    testWidgets('AnimationController vsync works correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _AnimatedCounterWidget(),
      ));
      await tester.pump();

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Animation controller should work
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('works with TickerProviderStateMixin for multiple animations',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _MultiAnimationWidget(),
      ));
      await tester.pump();

      // Should render without errors
      expect(find.byType(_MultiAnimationWidget), findsOneWidget);
    });
  });

  group('Effect scope cleanup', () {
    testWidgets('watchEffect is cleaned up on dispose', (tester) async {
      bool effectStopped = false;

      await tester.pumpWidget(MaterialApp(
        home: _EffectCleanupWidget(onCleanup: () => effectStopped = true),
      ));
      await tester.pump();

      expect(effectStopped, false);

      // Unmount to trigger dispose
      await tester.pumpWidget(Container());
      await tester.pump();

      expect(effectStopped, true);
    });

    testWidgets('watchEffect works within setup', (tester) async {
      final watchLogs = <int>[];

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectTestWidget(logs: watchLogs),
      ));
      await tester.pump();

      // Initial value tracked
      expect(watchLogs, [0]);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(watchLogs, [0, 1]);
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

class _SetupTestWidget extends ReactiveStatefulWidget {
  final VoidCallback onSetup;

  const _SetupTestWidget({required this.onSetup});

  @override
  ReactiveWidgetState<_SetupTestWidget> createState() =>
      _SetupTestWidgetState();
}

class _SetupTestWidgetState extends ReactiveWidgetState<_SetupTestWidget> {
  @override
  void setup() {
    widget.onSetup();
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Setup Test');
  }
}

class _LifecycleTestWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _LifecycleTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_LifecycleTestWidget> createState() =>
      _LifecycleTestWidgetState();
}

class _LifecycleTestWidgetState
    extends ReactiveWidgetState<_LifecycleTestWidget> {
  @override
  void setup() {
    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => widget.logs.add('disposed'));
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Lifecycle Test');
  }
}

class _BindTestWidget extends ReactiveStatefulWidget {
  final void Function(_CounterStore) onStoreCreated;

  const _BindTestWidget({required this.onStoreCreated});

  @override
  ReactiveWidgetState<_BindTestWidget> createState() => _BindTestWidgetState();
}

class _BindTestWidgetState extends ReactiveWidgetState<_BindTestWidget> {
  late final store = bind(() {
    final s = _CounterStore();
    widget.onStoreCreated(s);
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

class _ReactiveTestWidget extends ReactiveStatefulWidget {
  const _ReactiveTestWidget();

  @override
  ReactiveWidgetState<_ReactiveTestWidget> createState() =>
      _ReactiveTestWidgetState();
}

class _ReactiveTestWidgetState
    extends ReactiveWidgetState<_ReactiveTestWidget> {
  late final count = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLUTTER MIXIN TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedTestWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _AnimatedTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_AnimatedTestWidget> createState() =>
      _AnimatedTestWidgetState();
}

class _AnimatedTestWidgetState extends ReactiveWidgetState<_AnimatedTestWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.logs.add('controller_created');

    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => controller.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Animated Widget');
  }
}

class _AnimatedCounterWidget extends ReactiveStatefulWidget {
  const _AnimatedCounterWidget();

  @override
  ReactiveWidgetState<_AnimatedCounterWidget> createState() =>
      _AnimatedCounterWidgetState();
}

class _AnimatedCounterWidgetState
    extends ReactiveWidgetState<_AnimatedCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final count = bind(() => ref(0));

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    onDispose(() => controller.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _MultiAnimationWidget extends ReactiveStatefulWidget {
  const _MultiAnimationWidget();

  @override
  ReactiveWidgetState<_MultiAnimationWidget> createState() =>
      _MultiAnimationWidgetState();
}

class _MultiAnimationWidgetState
    extends ReactiveWidgetState<_MultiAnimationWidget>
    with TickerProviderStateMixin {
  late final AnimationController controller1;
  late final AnimationController controller2;

  @override
  void setup() {
    controller1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    onDispose(() {
      controller1.dispose();
      controller2.dispose();
    });
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Multi Animation Widget');
  }
}

class _EffectCleanupWidget extends ReactiveStatefulWidget {
  final VoidCallback onCleanup;

  const _EffectCleanupWidget({required this.onCleanup});

  @override
  ReactiveWidgetState<_EffectCleanupWidget> createState() =>
      _EffectCleanupWidgetState();
}

class _EffectCleanupWidgetState
    extends ReactiveWidgetState<_EffectCleanupWidget> {
  late final trigger = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((onCleanup) {
      trigger.value;
      onCleanup(widget.onCleanup);
    });
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Effect Cleanup Test');
  }
}

class _WatchEffectTestWidget extends ReactiveStatefulWidget {
  final List<int> logs;

  const _WatchEffectTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_WatchEffectTestWidget> createState() =>
      _WatchEffectTestWidgetState();
}

class _WatchEffectTestWidgetState
    extends ReactiveWidgetState<_WatchEffectTestWidget> {
  late final count = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((onCleanup) {
      widget.logs.add(count.value);
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
