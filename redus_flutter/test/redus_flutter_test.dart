import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ReactiveWidget', () {
    testWidgets('should call setup once', (tester) async {
      var setupCount = 0;

      final component = _TestComponent(
        onSetup: () => setupCount++,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      expect(setupCount, equals(1));

      await tester.pump();
      expect(setupCount, equals(1)); // Still 1 after rebuild
    });

    testWidgets('should call onMounted after first build', (tester) async {
      var mountedCalled = false;

      final component = _TestComponent(
        onSetup: () {},
        onMountedCallback: (context) => mountedCalled = true,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      await tester.pump(); // Process post-frame callback
      expect(mountedCalled, isTrue);
    });

    testWidgets('should call onUnmounted on dispose', (tester) async {
      var unmountedCalled = false;

      final component = _TestComponent(
        onSetup: () {},
        onUnmountedCallback: (context) => unmountedCalled = true,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      await tester.pump();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(unmountedCalled, isTrue);
    });

    testWidgets('bind() should persist state across parent rebuilds',
        (tester) async {
      final parentTrigger = ref(0);
      late _CounterStore capturedStore;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          // Watch parent trigger to force parent rebuilds
          parentTrigger.watch(context);
          return _BindTestComponent(
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

      final component = _TestComponent(
        onSetup: () {},
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
          return _PropTestWidget(propValue: v);
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

  group('Observe widget', () {
    testWidgets('rebuilds when source changes', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: count.call,
          builder: (context, value) {
            buildCount++;
            return Text('Count: $value');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('works with computed source', (tester) async {
      final count = ref(1);
      final doubled = computed(() => count.value * 2);

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: doubled.call,
          builder: (context, value) => Text('Doubled: $value'),
        ),
      ));

      expect(find.text('Doubled: 2'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(find.text('Doubled: 10'), findsOneWidget);
    });

    testWidgets('works with getter function source', (tester) async {
      final a = ref(10);
      final b = ref(20);

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: () => a.value + b.value,
          builder: (context, sum) => Text('Sum: $sum'),
        ),
      ));

      expect(find.text('Sum: 30'), findsOneWidget);

      a.value = 15;
      await tester.pump();

      expect(find.text('Sum: 35'), findsOneWidget);
    });

    testWidgets('only Observe rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var observeBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentBuilds++;
          return Column(
            children: [
              const Text('Static parent'),
              Observe<int>(
                source: count.call,
                builder: (context, value) {
                  observeBuilds++;
                  return Text('Count: $value');
                },
              ),
            ],
          );
        }),
      ));

      expect(parentBuilds, 1);
      expect(observeBuilds, 1);

      // Update ref - only Observe should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(observeBuilds, 2); // Observe rebuilt
    });
  });

  group('ObserveMultiple widget', () {
    testWidgets('rebuilds when any source changes', (tester) async {
      final firstName = ref('John');
      final lastName = ref('Doe');

      await tester.pumpWidget(MaterialApp(
        home: ObserveMultiple<String>(
          sources: [firstName.call, lastName.call],
          builder: (context, values) => Text('${values[0]} ${values[1]}'),
        ),
      ));

      expect(find.text('John Doe'), findsOneWidget);

      firstName.value = 'Jane';
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);

      lastName.value = 'Smith';
      await tester.pumpAndSettle();

      expect(find.text('Jane Smith'), findsOneWidget);
    });
  });

  group('ObserveEffect widget', () {
    testWidgets('auto-tracks dependencies and rebuilds', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: ObserveEffect(
          builder: (context) {
            buildCount++;
            return Text('Count: ${count.value}');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value - should trigger rebuild
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('tracks multiple dependencies', (tester) async {
      final a = ref(1);
      final b = ref(2);

      await tester.pumpWidget(MaterialApp(
        home: ObserveEffect(
          builder: (context) => Text('Sum: ${a.value + b.value}'),
        ),
      ));

      expect(find.text('Sum: 3'), findsOneWidget);

      a.value = 10;
      await tester.pump();
      expect(find.text('Sum: 12'), findsOneWidget);

      b.value = 20;
      await tester.pump();
      expect(find.text('Sum: 30'), findsOneWidget);
    });

    testWidgets('only ObserveEffect rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var effectBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentBuilds++;
          return Column(
            children: [
              const Text('Static parent'),
              ObserveEffect(
                builder: (context) {
                  effectBuilds++;
                  return Text('Count: ${count.value}');
                },
              ),
            ],
          );
        }),
      ));

      expect(parentBuilds, 1);
      expect(effectBuilds, 1);

      // Update ref - only ObserveEffect should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(effectBuilds, 2); // ObserveEffect rebuilt
    });
  });

  group('.watch(context) fine-grained reactivity', () {
    testWidgets('Ref.watch rebuilds widget when value changes', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildCount++;
          return Text('Count: ${count.watch(context)}');
        }),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('Computed.watch rebuilds widget when value changes',
        (tester) async {
      final count = ref(1);
      final doubled = computed(() => count.value * 2);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildCount++;
          return Text('Doubled: ${doubled.watch(context)}');
        }),
      ));

      expect(buildCount, 1);
      expect(find.text('Doubled: 2'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Doubled: 10'), findsOneWidget);
    });

    testWidgets('only watching widget rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var childBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            parentBuilds++;
            return Column(
              children: [
                const Text('Static parent'),
                Builder(builder: (ctx) {
                  childBuilds++;
                  return Text('Count: ${count.watch(ctx)}');
                }),
              ],
            );
          },
        ),
      ));

      expect(parentBuilds, 1);
      expect(childBuilds, 1);

      // Update ref - only child should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(childBuilds, 2); // Child rebuilt
    });

    testWidgets('multiple watches on same value work correctly',
        (tester) async {
      final name = ref('Alice');
      var build1 = 0;
      var build2 = 0;

      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            Builder(builder: (ctx) {
              build1++;
              return Text('Hello ${name.watch(ctx)}');
            }),
            Builder(builder: (ctx) {
              build2++;
              return Text('Goodbye ${name.watch(ctx)}');
            }),
          ],
        ),
      ));

      expect(build1, 1);
      expect(build2, 1);

      name.value = 'Bob';
      await tester.pump();

      expect(build1, 2);
      expect(build2, 2);
      expect(find.text('Hello Bob'), findsOneWidget);
      expect(find.text('Goodbye Bob'), findsOneWidget);
    });

    testWidgets('watch works in StatelessWidget', (tester) async {
      final count = ref(10);

      await tester.pumpWidget(MaterialApp(
        home: _WatchingStatelessWidget(count: count),
      ));

      expect(find.text('Value: 10'), findsOneWidget);

      count.value = 20;
      await tester.pump();

      expect(find.text('Value: 20'), findsOneWidget);
    });
  });

  group('Store pattern with bind()', () {
    testWidgets('store is created once per element', (tester) async {
      var storeCreationCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _StoreCreationCountComponent(
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
        home: _MultiBindComponent(),
      ));

      expect(find.text('A: 0, B: 100'), findsOneWidget);
    });
  });
}

/// Simple store for testing bind()
class _CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

/// Test component using bind() with store
class _BindTestComponent extends ReactiveWidget {
  final void Function(_CounterStore)? onStoreCreated;

  _BindTestComponent({this.onStoreCreated});

  late final store = bind(() {
    final s = _CounterStore();
    onStoreCreated?.call(s);
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component for unit testing using new ReactiveWidget API
class _TestComponent extends ReactiveWidget {
  final void Function() onSetup;
  final void Function(BuildContext)? onMountedCallback;
  final void Function(BuildContext)? onUnmountedCallback;
  final Widget Function(BuildContext) builder;

  _TestComponent({
    required this.onSetup,
    required this.builder,
    this.onMountedCallback,
    this.onUnmountedCallback,
  });

  @override
  void setup() {
    onSetup();
    if (onMountedCallback != null) {
      onMounted(onMountedCallback!);
    }
    if (onUnmountedCallback != null) {
      onUnmounted(onUnmountedCallback!);
    }
  }

  @override
  Widget render(BuildContext context) {
    return builder(context);
  }
}

/// Test StatelessWidget for testing .watch(context)
class _WatchingStatelessWidget extends StatelessWidget {
  final Ref<int> count;

  const _WatchingStatelessWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    return Text('Value: ${count.watch(context)}');
  }
}

/// Test component to verify store is only created once
class _StoreCreationCountComponent extends ReactiveWidget {
  final void Function() onCreation;

  _StoreCreationCountComponent({required this.onCreation});

  late final store = bind(() {
    onCreation();
    return _CounterStore();
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component with multiple binds
class _MultiBindComponent extends ReactiveWidget {
  _MultiBindComponent();

  late final storeA = bind(() => _CounterStore());
  late final storeB = bind(() {
    final s = _CounterStore();
    s.count.value = 100;
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('A: ${storeA.count.value}, B: ${storeB.count.value}');
  }
}

/// Test widget for prop update testing
class _PropTestWidget extends ReactiveWidget {
  final int propValue;

  _PropTestWidget({required this.propValue});

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Prop: $propValue');
  }
}
