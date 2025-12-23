import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('BindWidget', () {
    testWidgets('bind() persists state across parent rebuilds', (tester) async {
      final parentCounter = ref(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ObserveEffect(
            builder: (context) {
              // Access parentCounter to trigger rebuilds
              final _ = parentCounter.value;
              return _TestBindWidget(key: ValueKey('test'));
            },
          ),
        ),
      );

      // Initial value
      expect(find.text('Count: 0'), findsOneWidget);

      // Increment via button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Trigger parent rebuild
      parentCounter.value++;
      await tester.pump();

      // State should persist
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('lifecycle hooks fire correctly', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _LifecycleTestWidget(logs: logs),
        ),
      );
      await tester.pumpAndSettle();

      expect(logs, contains('setup'));
      expect(logs, contains('beforeMount'));
      expect(logs, contains('mounted'));

      // Unmount
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(logs, contains('beforeUnmount'));
      expect(logs, contains('unmounted'));
    });

    testWidgets('setup() is called once', (tester) async {
      int setupCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _SetupCountWidget(onSetup: () => setupCount++),
        ),
      );
      await tester.pump();

      expect(setupCount, 1);

      // Trigger rebuild
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // setup should not be called again
      expect(setupCount, 1);
    });

    testWidgets('multiple bind() calls work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MultipleBind(),
        ),
      );

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

    testWidgets('works with Observe widget for reactivity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _BindWithObserve(),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Value: 1'), findsOneWidget);
    });

    testWidgets('bind() with store pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _StorePatternWidget(),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('BindMixin', () {
    testWidgets('BindMixin can be used with custom widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _CustomBindMixinWidget(),
        ),
      );

      expect(find.text('Custom: 42'), findsOneWidget);
    });
  });
}

// Test Widgets

class _TestBindWidget extends BindWidget {
  _TestBindWidget({super.key});

  late final count = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    return Observe<int>(
      source: count.call,
      builder: (_, value) => Column(
        children: [
          Text('Count: $value'),
          ElevatedButton(
            onPressed: () => count.value++,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class _LifecycleTestWidget extends BindWidget {
  final List<String> logs;

  _LifecycleTestWidget({required this.logs});

  @override
  void setup() {
    logs.add('setup');
    onBeforeMount((_) => logs.add('beforeMount'));
    onMounted((_) => logs.add('mounted'));
    onBeforeUpdate((_) => logs.add('beforeUpdate'));
    onUpdated((_) => logs.add('updated'));
    onBeforeUnmount((_) => logs.add('beforeUnmount'));
    onUnmounted((_) => logs.add('unmounted'));
  }

  @override
  Widget build(BuildContext context) {
    return const Text('Lifecycle Test');
  }
}

class _SetupCountWidget extends BindWidget {
  final VoidCallback onSetup;

  _SetupCountWidget({required this.onSetup});

  late final counter = bind(() => ref(0));

  @override
  void setup() {
    onSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Observe<int>(
      source: counter.call,
      builder: (_, value) => ElevatedButton(
        onPressed: () => counter.value++,
        child: Text('$value'),
      ),
    );
  }
}

class _MultipleBind extends BindWidget {
  _MultipleBind();

  late final countA = bind(() => ref(0));
  late final countB = bind(() => ref(10));

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    return ObserveEffect(
      builder: (_) => Column(
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
      ),
    );
  }
}

class _BindWithObserve extends BindWidget {
  _BindWithObserve();

  late final value = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Observe<int>(
          source: value.call,
          builder: (_, v) => Text('Value: $v'),
        ),
        ElevatedButton(
          onPressed: () => value.value++,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

class _StorePatternWidget extends BindWidget {
  _StorePatternWidget();

  late final store = bind(() => _CounterStore());

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Observe<int>(
          source: store.count.call,
          builder: (_, value) => Text('Count: $value'),
        ),
        ElevatedButton(
          onPressed: store.increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

// Custom widget using BindMixin directly
class _CustomBindMixinWidget extends StatelessWidget {
  const _CustomBindMixinWidget();

  @override
  Widget build(BuildContext context) {
    return _InnerCustomWidget();
  }
}

class _InnerCustomWidget extends BindWidget {
  _InnerCustomWidget();

  late final value = bind(() => 42);

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    return Text('Custom: $value');
  }
}
