/// Component base class for Vue-like reactive widgets.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle.dart';

export 'lifecycle.dart';

/// Current component state for accessing rebuild function.
_ComponentState? _currentComponentState;

/// A Vue-like component with reactive state and lifecycle hooks.
///
/// Components provide:
/// - [setup] method for defining reactive state and registering lifecycle hooks
/// - [build] method for building the UI
/// - Automatic effect scope for cleanup
/// - Lifecycle hooks (onMounted, onUpdated, onUnmounted, etc.)
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
///
///     // Set up reactive rebuilding
///     watchEffect((_) {
///       count.value; // Track dependency
///       rebuild(); // Trigger rebuild when value changes
///     });
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
  /// - Set up watchers with [watchEffect], [watch], etc.
  void setup();

  /// Override to build the component's UI.
  ///
  /// This is called whenever the component needs to rebuild.
  /// Access reactive values here to create the widget tree.
  Widget render(BuildContext context);

  /// Trigger a rebuild of this component.
  ///
  /// Call this in a watchEffect to rebuild when dependencies change.
  /// Note: This uses the current component state context set during setup.
  void rebuild() {
    _currentComponentState?.triggerRebuild();
  }

  @override
  State<Component> createState() => _ComponentState();
}

class _ComponentState extends State<Component> with RouteAware {
  late EffectScope _scope;
  bool _isFirstBuild = true;
  Object? _error;

  /// Trigger a rebuild of this component.
  void triggerRebuild() {
    if (mounted && !_isFirstBuild) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _scope = effectScope();

    // Set current state context for rebuild access
    _currentComponentState = this;

    _scope.run(() {
      widget.setup();
    });

    // Clear context after setup (will be set again during build)
    _currentComponentState = null;

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
    _currentComponentState = null;
    _scope.stop();
    widget.runUnmounted();
    super.dispose();
  }
}
