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
      expect(logs, isNot(contains('dependenciesChanged')));
      expect(logs, isNot(contains('afterDependenciesChanged')));
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

  _DependencyTestWidget({required this.logs});

  @override
  void setup() {
    onMounted((_) => logs.add('mounted'));
    onDependenciesChanged((_) => logs.add('dependenciesChanged'));
    onAfterDependenciesChanged((_) => logs.add('afterDependenciesChanged'));
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

  _SimpleHookTestWidget({
    required this.logs,
    required this.onCallbackRegistered,
  });

  @override
  void setup() {
    onMounted((_) => logs.add('mounted'));
    onDependenciesChanged((_) => logs.add('dependenciesChanged'));
    onAfterDependenciesChanged((_) => logs.add('afterDependenciesChanged'));
    onCallbackRegistered();
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Simple Test');
  }
}
