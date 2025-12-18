/// Vue-like Component system for Flutter with reactive state and lifecycle hooks.
///
/// This library provides:
/// - [Component] - Vue-like reactive component base class
/// - Lifecycle hooks (onMounted, onUpdated, onUnmounted, etc.)
/// - Dependency injection (register, registerFactory, get)
///
/// Example:
/// ```dart
/// import 'package:redus_flutter/redus_flutter.dart';
///
/// class CounterComponent extends Component {
///   late final Ref<int> count;
///
///   @override
///   void setup() {
///     count = ref(0);
///     onMounted(() => print('Mounted!'));
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     return GestureDetector(
///       onTap: () => count.value++,
///       child: Text('Count: ${count.value}'),
///     );
///   }
/// }
/// ```
library redus_flutter;

// Re-export redus reactivity
export 'package:redus/reactivity.dart';

// Component
export 'src/component/component.dart';
export 'src/component/lifecycle.dart';

// Dependency Injection
export 'src/di/service_locator.dart';
