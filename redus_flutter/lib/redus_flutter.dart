/// Vue-like Component system for Flutter with reactive state and lifecycle hooks.
///
/// This library provides:
/// - [ReactiveWidget] - Vue-like reactive component base class with `bind()` API
/// - [Observe] - Widget that watches a reactive source and rebuilds when it changes
/// - [ObserveEffect] - Widget that auto-tracks reactive dependencies
/// - Lifecycle hooks (onMounted, onUpdated, onUnmounted, etc.)
/// - Fine-grained reactivity with `.watch(context)` extension
/// - Dependency injection (register, registerFactory, get) from redus package
///
/// Example:
/// ```dart
/// import 'package:redus_flutter/redus_flutter.dart';
///
/// class CounterStore {
///   final count = ref(0);
///   void increment() => count.value++;
/// }
///
/// class Counter extends ReactiveWidget {
///   late final store = bind(() => CounterStore());
///
///   @override
///   void setup() {
///     onMounted(() => print('Mounted!'));
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     return GestureDetector(
///       onTap: store.increment,
///       child: Text('Count: ${store.count.value}'),
///     );
///   }
/// }
/// ```
library;

// Re-export redus reactivity and DI
export 'package:redus/reactivity.dart';
export 'package:redus/di.dart';

// Widget components
export 'src/widget/reactive_widget.dart';
export 'src/widget/lifecycle.dart';
export 'src/widget/observe.dart';
export 'src/widget/observe_effect.dart';

// Fine-grained reactivity extensions
export 'src/reactive/extensions.dart';
export 'src/reactive/reactive_context.dart';
