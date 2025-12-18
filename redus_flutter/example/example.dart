import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

/// Example demonstrating Redus Flutter Component system.
///
/// Run with: `flutter run example/example.dart`
void main() {
  runApp(MaterialApp(home: CounterComponent()));
}

/// A simple counter component demonstrating:
/// - Reactive state with `ref`
/// - Lifecycle hooks
/// - Component rebuilding
class CounterComponent extends Component {
  CounterComponent({super.key});

  late final Ref<int> count;

  @override
  void setup() {
    // Create reactive state
    count = ref(0);

    // Register lifecycle hooks
    onMounted(() {
      debugPrint('CounterComponent mounted!');
    });

    onUpdated(() {
      debugPrint('CounterComponent updated! Count: ${count.value}');
    });

    onUnmounted(() {
      debugPrint('CounterComponent unmounted!');
    });

    // Watch for changes and rebuild
    watchEffect((_) {
      count.value; // Track dependency
      rebuild();
    });
  }

  @override
  Widget render(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redus Flutter Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${count.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
