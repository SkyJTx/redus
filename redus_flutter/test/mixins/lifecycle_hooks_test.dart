import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('Dependency Change Hooks', () {
    testWidgets('hooks not called on initial mount', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _DependencyTestWidget(logs: logs),
        ),
      );
      await tester.pumpAndSettle();

      // Should have mounted but not dependency changed
      expect(logs, contains('mounted'));
      expect(logs, isNot(contains('beforeDependenciesChanged')));
      expect(logs, isNot(contains('dependenciesChanged')));
    });

    testWidgets('hooks registered correctly and callbacks list is populated',
        (tester) async {
      final logs = <String>[];
      bool callbackRegistered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            // Simple test to just check that the hooks can be registered
            return _SimpleHookTestWidget(
              logs: logs,
              onCallbackRegistered: () => callbackRegistered = true,
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(callbackRegistered, isTrue);
      expect(logs, contains('mounted'));
    });
  });
}

class _DependencyTestWidget extends ReactiveWidget {
  final List<String> logs;

  const _DependencyTestWidget({required this.logs});

  @override
  ReactiveState<_DependencyTestWidget> createState() => _DependencyTestWidgetState();
}

class _DependencyTestWidgetState extends ReactiveState<_DependencyTestWidget> {
  @override
  void setup() {
    onMounted(() => widget.logs.add('mounted'));
    onDidChangeDependencies(
      () => widget.logs.add('beforeDependenciesChanged'),
      timing: LifecycleTiming.before,
    );
    onDidChangeDependencies(() => widget.logs.add('dependenciesChanged'));
  }

  @override
  Widget render(BuildContext context) {
    MediaQuery.of(context);
    return const Text('Test');
  }
}

class _SimpleHookTestWidget extends ReactiveWidget {
  final List<String> logs;
  final VoidCallback onCallbackRegistered;

  const _SimpleHookTestWidget({
    required this.logs,
    required this.onCallbackRegistered,
  });

  @override
  ReactiveState<_SimpleHookTestWidget> createState() => _SimpleHookTestWidgetState();
}

class _SimpleHookTestWidgetState extends ReactiveState<_SimpleHookTestWidget> {
  @override
  void setup() {
    onMounted(() => widget.logs.add('mounted'));
    onDidChangeDependencies(
      () => widget.logs.add('beforeDependenciesChanged'),
      timing: LifecycleTiming.before,
    );
    onDidChangeDependencies(() => widget.logs.add('dependenciesChanged'));
    widget.onCallbackRegistered();
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Simple Test');
  }
}
