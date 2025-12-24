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

    testWidgets('onBeforeUnmount and onUnmounted fire on dispose',
        (tester) async {
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

      expect(logs, contains('beforeUnmount'));
      expect(logs, contains('unmounted'));
    });

    testWidgets('onActivated and onDeactivated fire correctly', (tester) async {
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

    testWidgets('onDependenciesChanged fires on dependency changes',
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

      expect(logs, contains('dependenciesChanged'));
      expect(logs, contains('afterDependenciesChanged'));
    });
  });

  group('ReactiveProviderStateMixin', () {
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

      expect(logs, contains('beforeUnmount'));
      expect(logs, contains('unmounted'));
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
    with LifecycleHooksStateMixin {
  @override
  void initState() {
    super.initState();
    onMounted((_) => widget.logs.add('mounted'));
    onBeforeUnmount((_) => widget.logs.add('beforeUnmount'));
    onUnmounted((_) => widget.logs.add('unmounted'));
    onActivated((_) => widget.logs.add('activated'));
    onDeactivated((_) => widget.logs.add('deactivated'));
  }

  @override
  Widget build(BuildContext context) {
    scheduleLifecycleCallbacks();
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
    with LifecycleHooksStateMixin {
  @override
  void initState() {
    super.initState();
    onDependenciesChanged((_) => widget.logs.add('dependenciesChanged'));
    onAfterDependenciesChanged(
        (_) => widget.logs.add('afterDependenciesChanged'));
  }

  @override
  Widget build(BuildContext context) {
    scheduleLifecycleCallbacks();
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
    with ReactiveProviderStateMixin {
  late final count = ref(0);

  @override
  void setup() {
    widget.onSetup();
  }

  @override
  Widget build(BuildContext context) {
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
    with ReactiveProviderStateMixin {
  late final trigger = ref(0);

  @override
  void setup() {
    watchEffect((onCleanup) {
      // Track the trigger
      trigger.value;
      onCleanup(widget.onCleanup);
    });
  }

  @override
  Widget build(BuildContext context) {
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
    with ReactiveProviderStateMixin {
  late final count = ref(0);

  @override
  void setup() {
    watchEffect((onCleanup) {
      widget.logs.add(count.value);
    });
  }

  @override
  Widget build(BuildContext context) {
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
    with LifecycleHooksStateMixin, ReactiveProviderStateMixin {
  late final count = ref(0);

  @override
  void setup() {
    widget.logs.add('setup');

    onMounted((_) => widget.logs.add('mounted'));
    onBeforeUnmount((_) => widget.logs.add('beforeUnmount'));
    onUnmounted((_) => widget.logs.add('unmounted'));

    watchEffect((onCleanup) {
      widget.watchLogs.add(count.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    scheduleLifecycleCallbacks();
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}
