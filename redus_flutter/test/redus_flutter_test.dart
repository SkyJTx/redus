import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ServiceLocator', () {
    setUp(() {
      resetLocator();
    });

    test('register should store singleton instance', () {
      register<String>('test-value');
      expect(get<String>(), equals('test-value'));
    });

    test('register should return same instance', () {
      final list = <int>[1, 2, 3];
      register<List<int>>(list);
      expect(identical(get<List<int>>(), list), isTrue);
    });

    test('registerFactory should create new instance each time', () {
      var counter = 0;
      registerFactory<int>(() => ++counter);

      expect(get<int>(), equals(1));
      expect(get<int>(), equals(2));
      expect(get<int>(), equals(3));
    });

    test('get should throw if not registered', () {
      expect(
        () => get<String>(),
        throwsA(isA<StateError>()),
      );
    });

    test('isRegistered should return true for registered types', () {
      register<String>('test');
      expect(isRegistered<String>(), isTrue);
      expect(isRegistered<int>(), isFalse);
    });

    test('unregister should remove registration', () {
      register<String>('test');
      unregister<String>();
      expect(isRegistered<String>(), isFalse);
    });
  });

  group('Component', () {
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
        onMountedCallback: () => mountedCalled = true,
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
        onUnmountedCallback: () => unmountedCalled = true,
        builder: (_) => const Text('Hello'),
      );

      await tester.pumpWidget(MaterialApp(home: component));
      await tester.pump();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(unmountedCalled, isTrue);
    });

    // TODO: Reactive rebuilding requires deeper integration.
    // For now, users should wrap reactive reads in a builder or use
    // watchEffect with setState manually.
    testWidgets('should call render with context', (tester) async {
      late Ref<int> count;
      var renderCalled = false;

      final component = _TestComponent(
        onSetup: () => count = ref(0),
        builder: (context) {
          renderCalled = true;
          return Text('Count: ${count.value}');
        },
      );

      await tester.pumpWidget(MaterialApp(home: component));
      expect(renderCalled, isTrue);
      expect(find.text('Count: 0'), findsOneWidget);
    });
  });
}

/// Test component for unit testing
class _TestComponent extends Component {
  final void Function() onSetup;
  final void Function()? onMountedCallback;
  final void Function()? onUnmountedCallback;
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
