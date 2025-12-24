import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

import '../helpers/test_widgets.dart';

void main() {
  group('ReactiveWidget', () {
    testWidgets('should call setup once', (tester) async {
      var setupCount = 0;

      final component = TestReactiveWidget(
        onSetupCallback: () => setupCount++,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      expect(setupCount, equals(1));

      await tester.pump();
      expect(setupCount, equals(1)); // Still 1 after rebuild
    });

    testWidgets('should call onMounted after first build', (tester) async {
      var mountedCalled = false;

      final component = TestReactiveWidget(
        onSetupCallback: () {},
        onMountedCallback: () => mountedCalled = true,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      await tester.pump(); // Process post-frame callback
      expect(mountedCalled, isTrue);
    });

    testWidgets('should call onDispose on dispose', (tester) async {
      var disposeCalled = false;

      final component = TestReactiveWidget(
        onSetupCallback: () {},
        onDisposeCallback: () => disposeCalled = true,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      await tester.pump();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(disposeCalled, isTrue);
    });

    testWidgets('bind() should persist state across parent rebuilds',
        (tester) async {
      final parentTrigger = ref(0);
      late CounterStore capturedStore;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          // Watch parent trigger to force parent rebuilds
          parentTrigger.watch(context);
          return BindStoreTestWidget(
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

      // Trigger parent rebuild (creates new widget instance)
      parentTrigger.value++;
      await tester.pump();

      // State should persist!
      expect(find.text('Count: 1'), findsOneWidget);

      // Can still increment
      capturedStore.increment();
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('should call render with context', (tester) async {
      var renderCalled = false;

      final component = TestReactiveWidget(
        onSetupCallback: () {},
        builder: (context) {
          renderCalled = true;
          return const Text('Hello');
        },
      );

      await tester.pumpWidget(MaterialApp(home: component));
      expect(renderCalled, isTrue);
    });

    testWidgets('should update when props change', (tester) async {
      final value = ref(0);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          final v = value.watch(context);
          return PropTestWidget(propValue: v);
        }),
      ));

      // Initial
      expect(find.text('Prop: 0'), findsOneWidget);

      // Change prop
      value.value = 42;
      await tester.pump();

      // Should show updated prop
      expect(find.text('Prop: 42'), findsOneWidget);
    });
  });

  group('Store pattern with bind()', () {
    testWidgets('store is created once per element', (tester) async {
      var storeCreationCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: StoreCreationCountWidget(
          onCreation: () => storeCreationCount++,
        ),
      ));

      expect(storeCreationCount, 1);

      // Trigger rebuilds
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Store should still only be created once
      expect(storeCreationCount, 1);
    });

    testWidgets('multiple binds work correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiBindTestWidget(),
      ));

      expect(find.text('A: 0, B: 100'), findsOneWidget);
    });
  });
}
