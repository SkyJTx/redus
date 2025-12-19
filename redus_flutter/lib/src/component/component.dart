/// Component base class for Vue-like reactive widgets.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle.dart';

export 'lifecycle.dart';

/// A Vue-like component with reactive state and lifecycle hooks.
///
/// Components provide:
/// - [setup] method for defining reactive state and registering lifecycle hooks
/// - [render] method for building the UI with automatic reactivity tracking
/// - Automatic effect scope for cleanup
/// - Lifecycle hooks (onMounted, onUpdated, onUnmounted, etc.)
///
/// **Automatic Reactivity**: Any reactive value (Ref, Computed) accessed in
/// [render] is automatically tracked. When these values change, the component
/// rebuilds automatically - no manual `watchEffect` or `rebuild()` needed!
///
/// Example:
/// ```dart
/// class CounterComponent extends Component {
///   late final Ref<int> count;
///
///   @override
///   void setup() {
///     count = ref(0);
///
///     onMounted(() => print('Counter mounted!'));
///     onUnmounted(() => print('Counter unmounted!'));
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     // Accessing count.value automatically tracks it!
///     // Component rebuilds when count changes.
///     return GestureDetector(
///       onTap: () => count.value++,
///       child: Text('Count: ${count.value}'),
///     );
///   }
/// }
///
/// // Usage:
/// CounterComponent()
/// ```
abstract class Component extends StatefulWidget with LifecycleHooks {
  /// Creates a component.
  Component({super.key});

  /// Override to define reactive state and register lifecycle hooks.
  ///
  /// This is called once when the component is first created.
  /// Use this to:
  /// - Initialize reactive state with [ref], [computed], etc.
  /// - Register lifecycle hooks with [onMounted], [onUnmounted], etc.
  /// - Set up watchers with [watchEffect], [watch], etc. for side effects
  void setup();

  /// Override to build the component's UI.
  ///
  /// This is called whenever the component needs to rebuild.
  /// **Automatic tracking**: Any reactive values (Ref, Computed) accessed
  /// here are automatically tracked. The component rebuilds when they change.
  Widget render(BuildContext context);

  @override
  State<Component> createState() => _ComponentState();
}

class _ComponentState extends State<Component> with RouteAware {
  late EffectScope _scope;
  late ReactiveEffect _renderEffect;
  bool _isFirstBuild = true;
  bool _isRendering = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scope = effectScope();

    // Create a render effect that triggers rebuilds when dependencies change
    _renderEffect = ReactiveEffect(
      () {
        // Only trigger rebuild if we're not currently rendering
        // and this is not the first build
        if (mounted && !_isFirstBuild && !_isRendering) {
          setState(() {});
        }
      },
      flush: FlushMode.sync, // Sync flush for immediate UI updates
    );

    _scope.run(() {
      widget.setup();
    });

    widget.runBeforeMount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Component oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFirstBuild) {
      widget.runBeforeUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle error state
    if (_error != null) {
      return _buildError();
    }

    Widget? result;

    // Set render effect as active to track dependencies
    _isRendering = true;
    effectStack.add(_renderEffect);
    final previousEffect = activeEffect;
    activeEffect = _renderEffect;

    try {
      _scope.run(() {
        try {
          result = widget.render(context);
        } catch (e, stack) {
          if (widget.runErrorCaptured(e, stack)) {
            _error = e;
            result = _buildError();
          } else {
            rethrow;
          }
        }
      });
    } finally {
      // Restore previous effect state
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
      _isRendering = false;
    }

    // Schedule post-build callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isFirstBuild) {
        _isFirstBuild = false;
        widget.runMounted();
      } else {
        widget.runUpdated();
      }
    });

    return result ?? const SizedBox.shrink();
  }

  Widget _buildError() {
    return ErrorWidget.withDetails(
      message: _error.toString(),
      error: _error is FlutterError ? _error as FlutterError : null,
    );
  }

  @override
  void deactivate() {
    widget.runDeactivated();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    widget.runActivated();
  }

  @override
  void dispose() {
    widget.runBeforeUnmount();
    _renderEffect.stop();
    _scope.stop();
    widget.runUnmounted();
    super.dispose();
  }
}
