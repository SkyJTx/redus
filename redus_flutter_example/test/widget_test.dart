import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';
import 'package:redus_flutter_example/main.dart';
import 'package:redus_flutter_example/services/todo_store.dart';

void main() {
  setUp(() {
    // Reset services before each test
    // Assuming ServiceLocator has a reset method or we just re-register
    // Since we don't expose reset publicly in main interface, we might need to handle it differently
    // Actually, looking at service_locator definition, there is no top-level reset,
    // but the singleton is global. We should be careful.
    // However, since we are inside tests, we can re-register.
    try {
      get<TodoStore>();
      // Already registered, maybe from previous test?
    } catch (_) {
      // Not registered
    }
    // Simplest way for test isolation is to register a fresh store
    // Since register throws or overwrites? Let's check impl.
    // The implementation uses _singletons[T] = instance, so it overwrites.
    register<TodoStore>(TodoStore());
  });

  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TodoApp());

    // Wait for the simulated loading (1 second)
    // We need to pump frames for async operations
    await tester.pump(); // Initial
    await tester.pump(const Duration(seconds: 1)); // Wait for delay
    await tester.pump(); // Update UI

    // Verify that we have loaded items
    expect(find.text('Learn Flutter'), findsOneWidget);
    expect(find.text('Try Redus Package'), findsOneWidget);

    // Tap the add button without text - nothing should happen
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Enter text
    await tester.enterText(find.byType(TextField), 'New Task');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify new task
    expect(find.text('New Task'), findsOneWidget);

    // Filter to Active
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    // Verify filter works (completed items should be gone)
    // 'Learn Flutter' is completed in mock data
    expect(find.text('Learn Flutter'), findsNothing);
    expect(find.text('New Task'), findsOneWidget);
  });
}
