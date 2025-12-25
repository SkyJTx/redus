/// ReactiveStatefulWidget - A customizable reactive widget supporting Flutter mixins.
///
/// Unlike [ReactiveWidget] which has a fixed State class, this widget allows
/// you to create custom State classes that can include Flutter's built-in
/// mixins like [SingleTickerProviderStateMixin] or [AutomaticKeepAliveClientMixin].
library;

import 'package:flutter/widgets.dart';

import '../mixins/lifecycle_mixin.dart';
import '../mixins/state_mixin.dart';

/// A StatefulWidget with reactive State that supports custom Flutter mixins.
///
/// Unlike [ReactiveWidget], this allows you to create a custom State class
/// where you can add Flutter's built-in mixins like [SingleTickerProviderStateMixin].
///
/// **Example with animation:**
/// ```dart
/// class AnimatedCounter extends ReactiveStatefulWidget {
///   const AnimatedCounter({super.key});
///
///   @override
///   ReactiveWidgetState<AnimatedCounter> createState() => _AnimatedCounterState();
/// }
///
/// class _AnimatedCounterState extends ReactiveWidgetState<AnimatedCounter>
///     with SingleTickerProviderStateMixin {
///   late final controller = AnimationController(
///     vsync: this,
///     duration: const Duration(milliseconds: 300),
///   );
///   late final count = bind(() => ref(0));
///
///   @override
///   void setup() {
///     onMounted(() => controller.forward());
///     onDispose(() => controller.dispose());
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     return FadeTransition(
///       opacity: controller,
///       child: Text('Count: ${count.value}'),
///     );
///   }
/// }
/// ```
///
/// **Example with keep alive:**
/// ```dart
/// class KeepAliveCounter extends ReactiveStatefulWidget {
///   const KeepAliveCounter({super.key});
///
///   @override
///   ReactiveWidgetState<KeepAliveCounter> createState() => _KeepAliveCounterState();
/// }
///
/// class _KeepAliveCounterState extends ReactiveWidgetState<KeepAliveCounter>
///     with AutomaticKeepAliveClientMixin {
///   late final count = bind(() => ref(0));
///
///   @override
///   bool get wantKeepAlive => true;
///
///   @override
///   void setup() {}
///
///   @override
///   Widget build(BuildContext context) {
///     super.build(context); // Required for AutomaticKeepAliveClientMixin
///     return reactiveBuild(context); // Use reactiveBuild() instead of duplicating logic
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     return Text('Count: ${count.value}');
///   }
/// }
/// ```
abstract class ReactiveStatefulWidget extends StatefulWidget {
  /// Creates a reactive stateful widget.
  const ReactiveStatefulWidget({super.key});

  /// Override this to create your custom [ReactiveWidgetState] subclass.
  ///
  /// Your State class can include additional Flutter mixins:
  /// ```dart
  /// @override
  /// ReactiveWidgetState<MyWidget> createState() => _MyWidgetState();
  /// ```
  @override
  ReactiveWidgetState createState();
}

/// Base State class for [ReactiveStatefulWidget].
///
/// Provides all reactive features including:
/// - `bind()` - State persistence across parent rebuilds
/// - Lifecycle hooks - onMounted, onDispose, etc.
/// - Reactive tracking - Auto-rebuilds when reactive values change
/// - Effect scope - Automatic cleanup of watchers
///
/// Extend this class and add Flutter mixins as needed:
/// ```dart
/// class _MyWidgetState extends ReactiveWidgetState<MyWidget>
///     with SingleTickerProviderStateMixin {
///   // Now you have AnimationController support!
/// }
/// ```
///
/// ## Using with Mixins that Override build()
///
/// Some Flutter mixins like [AutomaticKeepAliveClientMixin] require you to
/// override `build()` and call `super.build(context)`. In these cases, use
/// [reactiveBuild] to get the full reactive functionality:
///
/// ```dart
/// class _MyState extends ReactiveWidgetState<MyWidget>
///     with AutomaticKeepAliveClientMixin {
///   @override
///   Widget build(BuildContext context) {
///     super.build(context); // Required for the mixin
///     return reactiveBuild(context); // Use reactiveBuild() for full functionality
///   }
/// }
/// ```
abstract class ReactiveWidgetState<T extends ReactiveStatefulWidget>
    extends State<T>
    with
        LifecycleCallbacks,
        LifecycleHooksStateMixin<T>,
        BindStateMixin<T>,
        ReactiveStateMixin<T> {
  Object? _error;

  /// Called once when the State is first created.
  ///
  /// Use this to register lifecycle hooks, set up watchers, and initialize
  /// resources. This is called within an effect scope, so `watchEffect()`
  /// and `watch()` will be automatically cleaned up on dispose.
  ///
  /// ```dart
  /// @override
  /// void setup() {
  ///   onMounted(() => print('Widget mounted!'));
  ///   onDispose(() => controller.dispose());
  ///
  ///   watchEffect((onCleanup) {
  ///     print('Count changed: ${count.value}');
  ///   });
  /// }
  /// ```
  void setup();

  /// Build the widget UI.
  ///
  /// Reactive values accessed here are automatically tracked, and the
  /// widget rebuilds when they change.
  ///
  /// ```dart
  /// @override
  /// Widget render(BuildContext context) {
  ///   return Text('Count: ${count.value}'); // Auto-tracked!
  /// }
  /// ```
  Widget render(BuildContext context);

  @override
  @mustCallSuper
  void initState() {
    runInScope(() {
      try {
        setup();
      } catch (e, stack) {
        if (runErrorCapturedCallbacks(e, stack)) {
          _error = e;
        } else {
          rethrow;
        }
      }
    });

    super.initState();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget, oldWidget)) {
      resetBindIndex();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    stopReactivity();
    super.dispose();
  }

  /// Performs the reactive build with full functionality.
  ///
  /// This method handles:
  /// - Error state checking
  /// - Reactive dependency tracking via [buildReactive]
  /// - Error catching and [onErrorCaptured] callback invocation
  /// - Scheduling [onMounted] callbacks
  ///
  /// Use this method when you need to override [build] for compatibility
  /// with Flutter mixins like [AutomaticKeepAliveClientMixin]:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   super.build(context); // Required for AutomaticKeepAliveClientMixin
  ///   return reactiveBuild(context);
  /// }
  /// ```
  @protected
  @mustCallSuper
  Widget reactiveBuild(BuildContext context) {
    if (_error != null) {
      return ErrorWidget.withDetails(message: _error.toString());
    }

    final result = buildReactive(context, () {
      try {
        return render(context);
      } catch (e, stack) {
        if (runErrorCapturedCallbacks(e, stack)) {
          _error = e;
          return ErrorWidget.withDetails(message: _error.toString());
        } else {
          rethrow;
        }
      }
    });

    scheduleMountedCallbackIfNeeded();
    return result;
  }

  @override
  Widget build(BuildContext context) => reactiveBuild(context);
}
