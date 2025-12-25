import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ReactiveWidget auto-tracking', () {
    testWidgets('should auto-track ref in render() and rebuild on change',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _RefAutoTrackWidget()));

      expect(find.text('Count: 0'), findsOneWidget);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('should auto-track computed in render()', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _ComputedAutoTrackWidget()));

      expect(find.text('Doubled: 0'), findsOneWidget);

      // Tap to increment base value
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Doubled: 2'), findsOneWidget);
    });

    testWidgets('should auto-track multiple refs in render()', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _MultiRefAutoTrackWidget()));

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
          return const _BindPersistenceWidget();
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
      await tester.pumpWidget(const MaterialApp(home: _BindComputedWidget()));

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
  const _RefAutoTrackWidget();

  @override
  ReactiveState<_RefAutoTrackWidget> createState() => _RefAutoTrackWidgetState();
}

class _RefAutoTrackWidgetState extends ReactiveState<_RefAutoTrackWidget> {
  late final count = ref(0);

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
  const _ComputedAutoTrackWidget();

  @override
  ReactiveState<_ComputedAutoTrackWidget> createState() => _ComputedAutoTrackWidgetState();
}

class _ComputedAutoTrackWidgetState extends ReactiveState<_ComputedAutoTrackWidget> {
  late final base = ref(0);
  late final doubled = computed(() => base.value * 2);

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
  const _MultiRefAutoTrackWidget();

  @override
  ReactiveState<_MultiRefAutoTrackWidget> createState() => _MultiRefAutoTrackWidgetState();
}

class _MultiRefAutoTrackWidgetState extends ReactiveState<_MultiRefAutoTrackWidget> {
  late final countA = ref(0);
  late final countB = ref(10);

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

  const _WatchTestWidget({required this.logs});

  @override
  ReactiveState<_WatchTestWidget> createState() => _WatchTestWidgetState();
}

class _WatchTestWidgetState extends ReactiveState<_WatchTestWidget> {
  late final count = ref(0);

  @override
  void setup() {
    watch(() => count.value, (newVal, oldVal, onCleanup) {
      widget.logs.add('Changed from $oldVal to $newVal');
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

  const _WatchValuesTestWidget({required this.onChange});

  @override
  ReactiveState<_WatchValuesTestWidget> createState() => _WatchValuesTestWidgetState();
}

class _WatchValuesTestWidgetState extends ReactiveState<_WatchValuesTestWidget> {
  late final count = ref(0);

  @override
  void setup() {
    watch(() => count.value, (newVal, oldVal, onCleanup) {
      widget.onChange(newVal, oldVal!);
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

  const _WatchEffectTestWidget({required this.onRun});

  @override
  ReactiveState<_WatchEffectTestWidget> createState() => _WatchEffectTestWidgetState();
}

class _WatchEffectTestWidgetState extends ReactiveState<_WatchEffectTestWidget> {
  late final count = ref(0);

  @override
  void setup() {
    watchEffect((onCleanup) {
      // Track count
      final _ = count.value;
      widget.onRun();
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

  const _WatchEffectCleanupWidget({required this.onRun, required this.onCleanup});

  @override
  ReactiveState<_WatchEffectCleanupWidget> createState() => _WatchEffectCleanupWidgetState();
}

class _WatchEffectCleanupWidgetState extends ReactiveState<_WatchEffectCleanupWidget> {
  late final count = ref(0);

  @override
  void setup() {
    watchEffect((cleanup) {
      final _ = count.value;
      widget.onRun();
      cleanup(widget.onCleanup);
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
  ReactiveState<_WatchEffectExternalRefWidget> createState() =>
      _WatchEffectExternalRefWidgetState();
}

class _WatchEffectExternalRefWidgetState
    extends ReactiveState<_WatchEffectExternalRefWidget> {
  @override
  void setup() {
    watchEffect((onCleanup) {
      final _ = widget.trigger.value;
      widget.onRun();
    });
  }

  @override
  Widget render(BuildContext context) {
    return Text('Trigger: ${widget.trigger.value}');
  }
}

class _BindPersistenceWidget extends ReactiveWidget {
  const _BindPersistenceWidget();

  @override
  ReactiveState<_BindPersistenceWidget> createState() => _BindPersistenceWidgetState();
}

class _BindPersistenceWidgetState extends ReactiveState<_BindPersistenceWidget> {
  late final count = ref(0);

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
  const _BindComputedWidget();

  @override
  ReactiveState<_BindComputedWidget> createState() => _BindComputedWidgetState();
}

class _BindComputedWidgetState extends ReactiveState<_BindComputedWidget> {
  late final count = ref(0);
  late final doubled = computed(() => count.value * 2);

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

  const _CombinedReactivityWidget({required this.logs});

  @override
  ReactiveState<_CombinedReactivityWidget> createState() => _CombinedReactivityWidgetState();
}

class _CombinedReactivityWidgetState extends ReactiveState<_CombinedReactivityWidget> {
  late final base = ref(0);
  late final doubled = computed(() => base.value * 2);

  @override
  void setup() {
    watch(() => doubled.value, (newVal, oldVal, onCleanup) {
      widget.logs.add('Doubled changed to $newVal');
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
