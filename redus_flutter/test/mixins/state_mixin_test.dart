import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('LifecycleHooksStateMixin', () {
    testWidgets('onMounted fires after first build', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _LifecycleTestWidget(logs: logs),
        ),
      );
      await tester.pumpAndSettle();

      expect(logs, contains('mounted'));
    });

    testWidgets('onDispose fires on dispose', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _LifecycleTestWidget(logs: logs),
        ),
      );
      await tester.pumpAndSettle();

      logs.clear();

      // Unmount
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(logs, contains('beforeDispose'));
      expect(logs, contains('disposed'));
    });

    testWidgets('onActivate and onDeactivate fire correctly', (tester) async {
      final logs = <String>[];
      final showWidget = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showWidget,
            builder: (context, show, _) {
              return show
                  ? _LifecycleTestWidget(logs: logs)
                  : const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      logs.clear();

      // Deactivate by hiding
      showWidget.value = false;
      await tester.pumpAndSettle();

      expect(logs, contains('deactivated'));
    });

    testWidgets('onDidChangeDependencies fires on dependency changes',
        (tester) async {
      final logs = <String>[];
      final themeMode = ValueNotifier(ThemeMode.light);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) {
            return MaterialApp(
              themeMode: mode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: _DependencyTestWidget(logs: logs),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      logs.clear();

      // Change theme
      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(logs, contains('beforeDependenciesChanged'));
      expect(logs, contains('dependenciesChanged'));
    });
  });

  group('ReactiveStateMixin', () {
    testWidgets('setup is called once during initState', (tester) async {
      int setupCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _ReactiveTestWidget(onSetup: () => setupCount++),
        ),
      );
      await tester.pumpAndSettle();

      expect(setupCount, 1);

      // Trigger rebuild
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // setup should not be called again
      expect(setupCount, 1);
    });

    testWidgets('EffectScope is stopped on dispose', (tester) async {
      bool effectStopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: _EffectCleanupWidget(
            onCleanup: () => effectStopped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(effectStopped, false);

      // Unmount to trigger dispose
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(effectStopped, true);
    });

    testWidgets('watchEffect works within setup', (tester) async {
      final watchLogs = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _WatchEffectTestWidget(logs: watchLogs),
        ),
      );
      await tester.pump();

      // Initial value tracked
      expect(watchLogs, [0]);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(watchLogs, [0, 1]);
    });
  });

  group('Mixins Combined', () {
    testWidgets('both mixins work together', (tester) async {
      final logs = <String>[];
      final watchLogs = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _CombinedMixinWidget(logs: logs, watchLogs: watchLogs),
        ),
      );
      await tester.pumpAndSettle();

      expect(logs, contains('setup'));
      expect(logs, contains('mounted'));
      expect(watchLogs, [0]);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(watchLogs, [0, 1]);

      // Unmount
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(logs, contains('beforeDispose'));
      expect(logs, contains('disposed'));
    });
  });
}

// Test Widgets

class _LifecycleTestWidget extends StatefulWidget {
  final List<String> logs;

  const _LifecycleTestWidget({required this.logs});

  @override
  State<_LifecycleTestWidget> createState() => _LifecycleTestWidgetState();
}

class _LifecycleTestWidgetState extends State<_LifecycleTestWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin {
  @override
  void initState() {
    super.initState();
    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => widget.logs.add('beforeDispose'),
        timing: LifecycleTiming.before);
    onDispose(() => widget.logs.add('disposed'));
    onActivate(() => widget.logs.add('activated'));
    onDeactivate(() => widget.logs.add('deactivated'));
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return const Text('Lifecycle Test');
  }
}

class _DependencyTestWidget extends StatefulWidget {
  final List<String> logs;

  const _DependencyTestWidget({required this.logs});

  @override
  State<_DependencyTestWidget> createState() => _DependencyTestWidgetState();
}

class _DependencyTestWidgetState extends State<_DependencyTestWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin {
  @override
  void initState() {
    super.initState();
    onDidChangeDependencies(
      () => widget.logs.add('beforeDependenciesChanged'),
      timing: LifecycleTiming.before,
    );
    onDidChangeDependencies(() => widget.logs.add('dependenciesChanged'));
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    // Access theme to register dependency
    Theme.of(context);
    return const Text('Dependency Test');
  }
}

class _ReactiveTestWidget extends StatefulWidget {
  final VoidCallback onSetup;

  const _ReactiveTestWidget({required this.onSetup});

  @override
  State<_ReactiveTestWidget> createState() => _ReactiveTestWidgetState();
}

class _ReactiveTestWidgetState extends State<_ReactiveTestWidget>
    with
        LifecycleCallbacks,
        LifecycleHooksStateMixin,
        BindStateMixin,
        ReactiveStateMixin {
  late final count = ref(0);

  @override
  void initState() {
    super.initState();
    widget.onSetup();
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return ElevatedButton(
      onPressed: () => setState(() => count.value++),
      child: Text('Count: ${count.value}'),
    );
  }
}

class _EffectCleanupWidget extends StatefulWidget {
  final VoidCallback onCleanup;

  const _EffectCleanupWidget({required this.onCleanup});

  @override
  State<_EffectCleanupWidget> createState() => _EffectCleanupWidgetState();
}

class _EffectCleanupWidgetState extends State<_EffectCleanupWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin, ReactiveStateMixin {
  late final trigger = ref(0);

  @override
  void initState() {
    super.initState();
    runInScope(() {
      watchEffect((onCleanup) {
        // Track the trigger
        trigger.value;
        onCleanup(widget.onCleanup);
      });
    });
  }

  @override
  void dispose() {
    stopReactivity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return const Text('Effect Cleanup Test');
  }
}

class _WatchEffectTestWidget extends StatefulWidget {
  final List<int> logs;

  const _WatchEffectTestWidget({required this.logs});

  @override
  State<_WatchEffectTestWidget> createState() => _WatchEffectTestWidgetState();
}

class _WatchEffectTestWidgetState extends State<_WatchEffectTestWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin, ReactiveStateMixin {
  late final count = ref(0);

  @override
  void initState() {
    super.initState();
    runInScope(() {
      watchEffect((onCleanup) {
        widget.logs.add(count.value);
      });
    });
  }

  @override
  void dispose() {
    stopReactivity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _CombinedMixinWidget extends StatefulWidget {
  final List<String> logs;
  final List<int> watchLogs;

  const _CombinedMixinWidget({required this.logs, required this.watchLogs});

  @override
  State<_CombinedMixinWidget> createState() => _CombinedMixinWidgetState();
}

class _CombinedMixinWidgetState extends State<_CombinedMixinWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin, ReactiveStateMixin {
  late final count = ref(0);

  @override
  void initState() {
    super.initState();
    widget.logs.add('setup');

    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => widget.logs.add('beforeDispose'),
        timing: LifecycleTiming.before);
    onDispose(() => widget.logs.add('disposed'));

    runInScope(() {
      watchEffect((onCleanup) {
        widget.watchLogs.add(count.value);
      });
    });
  }

  @override
  void dispose() {
    stopReactivity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}
