import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

/// Example demonstrating Redus Flutter widgets.
///
/// Run with: `flutter run example/example.dart`
void main() {
  runApp(const MaterialApp(home: ExampleApp()));
}

/// A store that encapsulates counter state and logic.
class CounterStore {
  final count = ref(0);

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;
}

/// Example app showing all reactive widgets.
class ExampleApp extends ReactiveWidget {
  const ExampleApp({super.key});

  @override
  ReactiveState<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends ReactiveState<ExampleApp> {
  late final store = CounterStore();

  @override
  void setup() {
    onInitState(() => debugPrint('ExampleApp initialized!'));
    onMounted(() => debugPrint('ExampleApp first frame rendered!'));
    onDispose(() => debugPrint('ExampleApp disposing...'));
  }

  @override
  Widget render(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redus Flutter Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: ReactiveWidget with bind()
          _Section(
            title: 'ReactiveWidget with bind()',
            child: Text(
              'Count: ${store.count.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          // Section: Observe widget
          _Section(
            title: 'Observe<T> widget',
            child: Observe<int>(
              source: store.count.call,
              builder: (context, value) => Text(
                'Observed: $value',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // Section: Observe with derived value
          _Section(
            title: 'Observe with derived value',
            child: Observe<int>(
              source: () => store.count.value * 2,
              builder: (context, doubled) => Text(
                'Doubled: $doubled',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // Section: ObserveEffect widget
          _Section(
            title: 'ObserveEffect (auto-track)',
            child: ObserveEffect(
              builder: (context) => Text(
                'Auto-tracked: ${store.count.value}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: store.decrement,
                child: const Icon(Icons.remove),
              ),
              ElevatedButton(
                onPressed: store.reset,
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: store.increment,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
