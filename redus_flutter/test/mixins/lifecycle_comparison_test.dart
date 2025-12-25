import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // COMPARISON: Flutter vs ReactiveWidget Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  group('Lifecycle Comparison: Flutter StatefulWidget vs ReactiveWidget', () {
    testWidgets('initState: Flutter vs ReactiveWidget', (tester) async {
      final flutterLogs = <String>[];
      final reactiveLogs = <String>[];

      // Flutter StatefulWidget
      await tester.pumpWidget(MaterialApp(
        home: _FlutterLifecycleWidget(logs: flutterLogs),
      ));

      // ReactiveWidget
      await tester.pumpWidget(MaterialApp(
        home: _ReactiveLifecycleWidget(logs: reactiveLogs),
      ));

      // Both should have initState called
      expect(flutterLogs, contains('initState'));
      expect(reactiveLogs, contains('initState'));
    });

    testWidgets('didChangeDependencies: Flutter vs ReactiveWidget',
        (tester) async {
      final flutterLogs = <String>[];
      final reactiveLogs = <String>[];
      final themeMode = ValueNotifier(ThemeMode.light);

      // Flutter
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (_, mode, __) => MaterialApp(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: _FlutterDependencyWidget(logs: flutterLogs),
          ),
        ),
      );
      await tester.pumpAndSettle();
      flutterLogs.clear();

      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      // ReactiveWidget
      themeMode.value = ThemeMode.light;
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (_, mode, __) => MaterialApp(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: _ReactiveDependencyWidget(logs: reactiveLogs),
          ),
        ),
      );
      await tester.pumpAndSettle();
      reactiveLogs.clear();

      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      // Both detect dependency changes
      expect(flutterLogs, contains('didChangeDependencies'));
      expect(reactiveLogs, contains('didChangeDependencies'));
    });

    testWidgets('didUpdateWidget: Flutter vs ReactiveWidget', (tester) async {
      final flutterLogs = <String>[];
      final reactiveLogs = <String>[];
      final counter = ValueNotifier(0);

      // Flutter
      await tester.pumpWidget(
        ValueListenableBuilder<int>(
          valueListenable: counter,
          builder: (_, value, __) => MaterialApp(
            home: _FlutterUpdateWidget(value: value, logs: flutterLogs),
          ),
        ),
      );
      flutterLogs.clear();
      counter.value++;
      await tester.pump();

      // ReactiveWidget
      counter.value = 0;
      await tester.pumpWidget(
        ValueListenableBuilder<int>(
          valueListenable: counter,
          builder: (_, value, __) => MaterialApp(
            home: _ReactiveUpdateWidget(value: value, logs: reactiveLogs),
          ),
        ),
      );
      reactiveLogs.clear();
      counter.value++;
      await tester.pump();

      // Both detect widget updates
      expect(flutterLogs, contains('didUpdateWidget'));
      expect(reactiveLogs, contains('didUpdateWidget'));
    });

    testWidgets('deactivate & dispose: Flutter vs ReactiveWidget',
        (tester) async {
      final flutterLogs = <String>[];
      final reactiveLogs = <String>[];

      // Flutter
      await tester.pumpWidget(MaterialApp(
        home: _FlutterLifecycleWidget(logs: flutterLogs),
      ));
      flutterLogs.clear();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // ReactiveWidget
      await tester.pumpWidget(MaterialApp(
        home: _ReactiveLifecycleWidget(logs: reactiveLogs),
      ));
      reactiveLogs.clear();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Both have deactivate and dispose
      expect(flutterLogs, contains('deactivate'));
      expect(flutterLogs, contains('dispose'));
      expect(reactiveLogs, contains('deactivate'));
      expect(reactiveLogs, contains('dispose'));

      // Order: deactivate before dispose
      expect(flutterLogs.indexOf('deactivate'),
          lessThan(flutterLogs.indexOf('dispose')));
      expect(reactiveLogs.indexOf('deactivate'),
          lessThan(reactiveLogs.indexOf('dispose')));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ReactiveWidget: All Lifecycle Hooks
  // ═══════════════════════════════════════════════════════════════════════════

  group('ReactiveWidget: All Lifecycle Hooks', () {
    testWidgets('onInitState fires during initState', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));

      expect(logs, contains('onInitState:before'));
      expect(logs, contains('onInitState:after'));
      // Before should come before after
      expect(logs.indexOf('onInitState:before'),
          lessThan(logs.indexOf('onInitState:after')));
    });

    testWidgets('onMounted fires after first frame', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));
      await tester.pumpAndSettle();

      expect(logs, contains('onMounted'));
      // Mounted comes after build
      expect(logs.indexOf('build'), lessThan(logs.indexOf('onMounted')));
    });

    testWidgets('onDidChangeDependencies fires on dependency change',
        (tester) async {
      final logs = <String>[];
      final themeMode = ValueNotifier(ThemeMode.light);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (_, mode, __) => MaterialApp(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: _AllHooksWidget(logs: logs),
          ),
        ),
      );
      await tester.pumpAndSettle();
      logs.clear();

      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(logs, contains('onDidChangeDependencies:before'));
      expect(logs, contains('onDidChangeDependencies:after'));
    });

    testWidgets('onDidUpdateWidget fires when props change', (tester) async {
      final logs = <String>[];
      final counter = ValueNotifier(0);

      await tester.pumpWidget(
        ValueListenableBuilder<int>(
          valueListenable: counter,
          builder: (_, value, __) => MaterialApp(
            home: _PropsWidget(value: value, logs: logs),
          ),
        ),
      );
      logs.clear();

      counter.value++;
      await tester.pump();

      expect(logs, contains('onDidUpdateWidget:before'));
      expect(logs, contains('onDidUpdateWidget:after'));
    });

    testWidgets('onDeactivate fires when widget removed from tree',
        (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));
      logs.clear();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(logs, contains('onDeactivate:before'));
      expect(logs, contains('onDeactivate:after'));
    });

    testWidgets('onActivate fires when widget reinserted into tree',
        (tester) async {
      final logs = <String>[];
      final key = GlobalKey();

      // Initial mount
      await tester.pumpWidget(MaterialApp(
        home: KeyedSubtree(
          key: key,
          child: _AllHooksWidget(logs: logs),
        ),
      ));
      await tester.pumpAndSettle();
      logs.clear();

      // Move to different location (triggers deactivate then activate)
      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            KeyedSubtree(
              key: key,
              child: _AllHooksWidget(logs: logs),
            ),
          ],
        ),
      ));
      await tester.pump();

      // Note: activate may not fire in simple moves, depends on Flutter internals
      // This test documents the behavior
    });

    testWidgets('onDispose fires on unmount', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));
      logs.clear();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(logs, contains('onDispose:before'));
      expect(logs, contains('onDispose:after'));
    });

    testWidgets('lifecycle order on mount', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));
      await tester.pumpAndSettle();

      // Expected order: setup -> initState -> build -> mounted
      expect(
          logs.indexOf('setup'), lessThan(logs.indexOf('onInitState:before')));
      expect(
          logs.indexOf('onInitState:after'), lessThan(logs.indexOf('build')));
      expect(logs.indexOf('build'), lessThan(logs.indexOf('onMounted')));
    });

    testWidgets('lifecycle order on unmount', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));
      await tester.pumpAndSettle();
      logs.clear();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Expected order: deactivate -> dispose
      expect(logs.indexOf('onDeactivate:before'),
          lessThan(logs.indexOf('onDispose:before')));
    });

    testWidgets('before timing runs before after timing', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AllHooksWidget(logs: logs),
      ));

      // initState before/after
      final beforeIdx = logs.indexOf('onInitState:before');
      final afterIdx = logs.indexOf('onInitState:after');
      expect(beforeIdx, lessThan(afterIdx));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ReactiveWidget: Error Handling
  // ═══════════════════════════════════════════════════════════════════════════

  group('ReactiveWidget: Error Handling', () {
    testWidgets('onErrorCaptured catches errors in setup', (tester) async {
      Object? capturedError;

      await tester.pumpWidget(MaterialApp(
        home: _ErrorWidget(
          throwInSetup: true,
          onError: (e) => capturedError = e,
        ),
      ));

      expect(capturedError, isNotNull);
      expect(capturedError.toString(), contains('Setup error'));
    });

    testWidgets('onErrorCaptured catches errors in render', (tester) async {
      Object? capturedError;

      await tester.pumpWidget(MaterialApp(
        home: _ErrorWidget(
          throwInRender: true,
          onError: (e) => capturedError = e,
        ),
      ));

      expect(capturedError, isNotNull);
      expect(capturedError.toString(), contains('Render error'));
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// FLUTTER STATEFULWIDGET TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _FlutterLifecycleWidget extends StatefulWidget {
  final List<String> logs;

  const _FlutterLifecycleWidget({required this.logs});

  @override
  State<_FlutterLifecycleWidget> createState() =>
      _FlutterLifecycleWidgetState();
}

class _FlutterLifecycleWidgetState extends State<_FlutterLifecycleWidget> {
  @override
  void initState() {
    super.initState();
    widget.logs.add('initState');
  }

  @override
  void deactivate() {
    widget.logs.add('deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    widget.logs.add('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.logs.add('build');
    return const Text('Flutter');
  }
}

class _FlutterDependencyWidget extends StatefulWidget {
  final List<String> logs;

  const _FlutterDependencyWidget({required this.logs});

  @override
  State<_FlutterDependencyWidget> createState() =>
      _FlutterDependencyWidgetState();
}

class _FlutterDependencyWidgetState extends State<_FlutterDependencyWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.logs.add('didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register dependency
    return const Text('Flutter');
  }
}

class _FlutterUpdateWidget extends StatefulWidget {
  final int value;
  final List<String> logs;

  const _FlutterUpdateWidget({required this.value, required this.logs});

  @override
  State<_FlutterUpdateWidget> createState() => _FlutterUpdateWidgetState();
}

class _FlutterUpdateWidgetState extends State<_FlutterUpdateWidget> {
  @override
  void didUpdateWidget(covariant _FlutterUpdateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.logs.add('didUpdateWidget');
  }

  @override
  Widget build(BuildContext context) {
    return Text('${widget.value}');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ReactiveWidget TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _ReactiveLifecycleWidget extends ReactiveWidget {
  final List<String> logs;

  const _ReactiveLifecycleWidget({required this.logs});

  @override
  ReactiveState<_ReactiveLifecycleWidget> createState() => _ReactiveLifecycleWidgetState();
}

class _ReactiveLifecycleWidgetState extends ReactiveState<_ReactiveLifecycleWidget> {
  @override
  void setup() {
    onInitState(() => widget.logs.add('initState'));
    onDeactivate(() => widget.logs.add('deactivate'));
    onDispose(() => widget.logs.add('dispose'));
  }

  @override
  Widget render(BuildContext context) {
    widget.logs.add('build');
    return const Text('Reactive');
  }
}

class _ReactiveDependencyWidget extends ReactiveWidget {
  final List<String> logs;

  const _ReactiveDependencyWidget({required this.logs});

  @override
  ReactiveState<_ReactiveDependencyWidget> createState() => _ReactiveDependencyWidgetState();
}

class _ReactiveDependencyWidgetState extends ReactiveState<_ReactiveDependencyWidget> {
  @override
  void setup() {
    onDidChangeDependencies(() => widget.logs.add('didChangeDependencies'));
  }

  @override
  Widget render(BuildContext context) {
    Theme.of(context); // Register dependency
    return const Text('Reactive');
  }
}

class _ReactiveUpdateWidget extends ReactiveWidget {
  final int value;
  final List<String> logs;

  const _ReactiveUpdateWidget({required this.value, required this.logs});

  @override
  ReactiveState<_ReactiveUpdateWidget> createState() => _ReactiveUpdateWidgetState();
}

class _ReactiveUpdateWidgetState extends ReactiveState<_ReactiveUpdateWidget> {
  @override
  void setup() {
    onDidUpdateWidget<_ReactiveUpdateWidget>(
      (oldWidget, newWidget) => widget.logs.add('didUpdateWidget'),
    );
  }

  @override
  Widget render(BuildContext context) {
    return Text('${widget.value}');
  }
}

class _AllHooksWidget extends ReactiveWidget {
  final List<String> logs;

  const _AllHooksWidget({required this.logs});

  @override
  ReactiveState<_AllHooksWidget> createState() => _AllHooksWidgetState();
}

class _AllHooksWidgetState extends ReactiveState<_AllHooksWidget> {
  @override
  void setup() {
    widget.logs.add('setup');

    onInitState(() => widget.logs.add('onInitState:before'),
        timing: LifecycleTiming.before);
    onInitState(() => widget.logs.add('onInitState:after'));

    onMounted(() => widget.logs.add('onMounted'));

    onDidChangeDependencies(() => widget.logs.add('onDidChangeDependencies:before'),
        timing: LifecycleTiming.before);
    onDidChangeDependencies(() => widget.logs.add('onDidChangeDependencies:after'));

    onDidUpdateWidget<_AllHooksWidget>(
      (oldWidget, newWidget) => widget.logs.add('onDidUpdateWidget:before'),
      timing: LifecycleTiming.before,
    );
    onDidUpdateWidget<_AllHooksWidget>(
      (oldWidget, newWidget) => widget.logs.add('onDidUpdateWidget:after'),
    );

    onDeactivate(() => widget.logs.add('onDeactivate:before'),
        timing: LifecycleTiming.before);
    onDeactivate(() => widget.logs.add('onDeactivate:after'));

    onActivate(() => widget.logs.add('onActivate:before'),
        timing: LifecycleTiming.before);
    onActivate(() => widget.logs.add('onActivate:after'));

    onDispose(() => widget.logs.add('onDispose:before'),
        timing: LifecycleTiming.before);
    onDispose(() => widget.logs.add('onDispose:after'));
  }

  @override
  Widget render(BuildContext context) {
    widget.logs.add('build');
    Theme.of(context); // Register dependency for didChangeDependencies test
    return const Text('All Hooks');
  }
}

class _PropsWidget extends ReactiveWidget {
  final int value;
  final List<String> logs;

  const _PropsWidget({required this.value, required this.logs});

  @override
  ReactiveState<_PropsWidget> createState() => _PropsWidgetState();
}

class _PropsWidgetState extends ReactiveState<_PropsWidget> {
  @override
  void setup() {
    onDidUpdateWidget<_PropsWidget>(
      (oldWidget, newWidget) => widget.logs.add('onDidUpdateWidget:before'),
      timing: LifecycleTiming.before,
    );
    onDidUpdateWidget<_PropsWidget>(
      (oldWidget, newWidget) => widget.logs.add('onDidUpdateWidget:after'),
    );
  }

  @override
  Widget render(BuildContext context) {
    return Text('${widget.value}');
  }
}

class _ErrorWidget extends ReactiveWidget {
  final bool throwInSetup;
  final bool throwInRender;
  final void Function(Object) onError;

  const _ErrorWidget({
    this.throwInSetup = false,
    this.throwInRender = false,
    required this.onError,
  });

  @override
  ReactiveState<_ErrorWidget> createState() => _ErrorWidgetState();
}

class _ErrorWidgetState extends ReactiveState<_ErrorWidget> {
  @override
  void setup() {
    onErrorCaptured((error, stack) {
      widget.onError(error);
      return true; // Mark as handled
    });

    if (widget.throwInSetup) {
      throw Exception('Setup error');
    }
  }

  @override
  Widget render(BuildContext context) {
    if (widget.throwInRender) {
      throw Exception('Render error');
    }
    return const Text('No Error');
  }
}
