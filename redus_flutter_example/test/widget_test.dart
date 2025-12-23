import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';
import 'package:redus_flutter_example/main.dart';
import 'package:redus_flutter_example/stores/dashboard_store.dart';

void main() {
  setUp(() {
    // Register dependencies for testing
    register<DashboardStore>(DashboardStore());
  });

  testWidgets('Showcase app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RedusShowcaseApp());
    await tester.pumpAndSettle();

    // Verify home screen is displayed
    expect(find.text('Vue-like Reactivity\nfor Flutter'), findsOneWidget);
    expect(find.text('Core Features'), findsOneWidget);

    // Verify feature cards are present
    expect(find.text('Fine-Grained Reactivity'), findsOneWidget);
    expect(find.text('Lifecycle Hooks'), findsOneWidget);
    expect(find.text('Dependency Injection'), findsOneWidget);
    expect(find.text('Reactive Widgets'), findsOneWidget);

    // Verify navigation rail is present
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('Navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RedusShowcaseApp());
    await tester.pumpAndSettle();

    // Navigate to Reactivity screen
    await tester.tap(find.byIcon(Icons.bolt_outlined));
    await tester.pumpAndSettle();

    // Verify Reactivity screen content
    expect(find.text('⚡ Reactivity System'), findsOneWidget);
    expect(find.text('ref()'), findsOneWidget);
    expect(find.text('computed()'), findsOneWidget);
    expect(find.text('watch()'), findsOneWidget);

    // Navigate to Lifecycle screen
    await tester.tap(find.byIcon(Icons.loop_outlined));
    await tester.pumpAndSettle();

    // Verify Lifecycle screen content
    expect(find.text('🔄 Lifecycle Hooks'), findsOneWidget);
    expect(find.text('Lifecycle Order'), findsOneWidget);

    // Navigate to DI screen
    await tester.tap(find.byIcon(Icons.integration_instructions_outlined));
    await tester.pumpAndSettle();

    // Verify DI screen content
    expect(find.text('💉 Dependency Injection'), findsOneWidget);
    expect(find.text('register() / get()'), findsOneWidget);

    // Navigate to Dashboard screen
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();

    // Verify Dashboard screen content
    expect(find.text('🚀 Real-time Dashboard'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Active Users'), findsOneWidget);
  });
}
