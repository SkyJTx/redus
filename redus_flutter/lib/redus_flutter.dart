/// Vue-like Component system for Flutter with reactive state and lifecycle hooks.
///
/// This library provides:
/// - [ReactiveWidget] - Vue-like reactive component base class with `bind()` API
/// - [BindWidget] - Lightweight widget with bind() and lifecycle (no auto-reactivity)
/// - [Observe] - Widget that watches a reactive source and rebuilds when it changes
/// - [ObserveEffect] - Widget that auto-tracks reactive dependencies
/// - [BindMixin] - Mixin for adding bind() to custom widgets
/// - [LifecycleHooksStateMixin] and [ReactiveProviderStateMixin] for State classes
/// - Lifecycle hooks with Flutter semantics (onInitState, onDispose, etc.)
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
///     onInitState(() => print('Initialized!'));
///     onDispose(() => print('Disposing...'));
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

// Extensions
export 'src/extensions/extensions.dart';

// Mixins
export 'src/mixins/mixins.dart';

// Widgets
export 'src/widgets/widgets.dart';
