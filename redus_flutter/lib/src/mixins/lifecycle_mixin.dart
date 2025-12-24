/// Lifecycle Mixin - Lifecycle hooks with Flutter State semantics.
///
/// Provides:
/// - [LifecycleCallbacks] - Base mixin for callback storage and registration
/// - [LifecycleTiming] - Timing enum for before/after hooks
/// - Typedefs for callback functions
library;

/// Timing for lifecycle hooks - before or after the lifecycle method.
enum LifecycleTiming {
  /// Run callback before the lifecycle method executes.
  before,

  /// Run callback after the lifecycle method executes (default).
  after,
}

/// Callback type for lifecycle hooks.
typedef LifecycleCallback = void Function();

/// Callback type for didUpdateWidget - receives oldWidget and current widget.
typedef DidUpdateWidgetCallback<T> = void Function(T oldWidget, T widget);

/// Callback type for error handling.
typedef ErrorCallback = bool? Function(Object error, StackTrace stack);

/// Base mixin providing lifecycle callback storage and registration.
///
/// This mixin stores callbacks for all lifecycle events but does NOT
/// automatically call them. Use [LifecycleHooksStateMixin] for State classes
/// that automatically runs these callbacks at the correct times.
///
/// **Available Hooks:**
/// - [onInitState] - Around initialization
/// - [onMounted] - After first frame
/// - [onDidChangeDependencies] - When inherited widgets change
/// - [onDidUpdateWidget] - When widget configuration changes
/// - [onDeactivate] / [onActivate] - Visibility changes
/// - [onDispose] - Around disposal
/// - [onReassemble] - Hot reload
/// - [onErrorCaptured] - Error boundary
mixin LifecycleCallbacks {
  // ─────────────────────────────────────────────────────────────────────────
  // Callback storage
  // ─────────────────────────────────────────────────────────────────────────

  final List<LifecycleCallback> _beforeInitState = [];
  final List<LifecycleCallback> _afterInitState = [];
  final List<LifecycleCallback> _mounted = [];
  final List<dynamic> _beforeDidUpdateWidget = [];
  final List<dynamic> _afterDidUpdateWidget = [];
  final List<LifecycleCallback> _beforeDidChangeDependencies = [];
  final List<LifecycleCallback> _afterDidChangeDependencies = [];
  final List<LifecycleCallback> _beforeDeactivate = [];
  final List<LifecycleCallback> _afterDeactivate = [];
  final List<LifecycleCallback> _beforeActivate = [];
  final List<LifecycleCallback> _afterActivate = [];
  final List<LifecycleCallback> _beforeDispose = [];
  final List<LifecycleCallback> _afterDispose = [];
  final List<LifecycleCallback> _beforeReassemble = [];
  final List<LifecycleCallback> _afterReassemble = [];
  final List<ErrorCallback> _errorCaptured = [];

  // ─────────────────────────────────────────────────────────────────────────
  // Registration methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Register a callback for initState lifecycle.
  void onInitState(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before ? _beforeInitState : _afterInitState)
        .add(callback);
  }

  /// Register a callback after the first frame renders.
  void onMounted(LifecycleCallback callback) {
    _mounted.add(callback);
  }

  /// Register a callback for didChangeDependencies lifecycle.
  void onDidChangeDependencies(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before
            ? _beforeDidChangeDependencies
            : _afterDidChangeDependencies)
        .add(callback);
  }

  /// Register a callback for didUpdateWidget lifecycle.
  void onDidUpdateWidget<T>(DidUpdateWidgetCallback<T> callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before
            ? _beforeDidUpdateWidget
            : _afterDidUpdateWidget)
        .add(callback);
  }

  /// Register a callback for deactivate lifecycle.
  void onDeactivate(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before ? _beforeDeactivate : _afterDeactivate)
        .add(callback);
  }

  /// Register a callback for activate lifecycle.
  void onActivate(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before ? _beforeActivate : _afterActivate)
        .add(callback);
  }

  /// Register a callback for dispose lifecycle.
  void onDispose(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.before}) {
    (timing == LifecycleTiming.before ? _beforeDispose : _afterDispose)
        .add(callback);
  }

  /// Register a callback for reassemble lifecycle (hot reload).
  void onReassemble(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    (timing == LifecycleTiming.before ? _beforeReassemble : _afterReassemble)
        .add(callback);
  }

  /// Register an error handler.
  void onErrorCaptured(ErrorCallback callback) {
    _errorCaptured.add(callback);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal: Run callbacks (for State mixins to call)
  // ─────────────────────────────────────────────────────────────────────────

  /// Run initState callbacks.
  void runInitStateCallbacks(LifecycleTiming timing) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeInitState
        : _afterInitState) {
      cb();
    }
  }

  /// Run mounted callbacks.
  void runMountedCallbacks() {
    for (final cb in _mounted) {
      cb();
    }
  }

  /// Run didChangeDependencies callbacks.
  void runDidChangeDependenciesCallbacks(LifecycleTiming timing) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeDidChangeDependencies
        : _afterDidChangeDependencies) {
      cb();
    }
  }

  /// Run didUpdateWidget callbacks.
  void runDidUpdateWidgetCallbacks<T>(
      LifecycleTiming timing, T oldWidget, T widget) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeDidUpdateWidget
        : _afterDidUpdateWidget) {
      (cb as Function)(oldWidget, widget);
    }
  }

  /// Run deactivate callbacks.
  void runDeactivateCallbacks(LifecycleTiming timing) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeDeactivate
        : _afterDeactivate) {
      cb();
    }
  }

  /// Run activate callbacks.
  void runActivateCallbacks(LifecycleTiming timing) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeActivate
        : _afterActivate) {
      cb();
    }
  }

  /// Run dispose callbacks.
  void runDisposeCallbacks(LifecycleTiming timing) {
    for (final cb
        in timing == LifecycleTiming.before ? _beforeDispose : _afterDispose) {
      cb();
    }
  }

  /// Run reassemble callbacks.
  void runReassembleCallbacks(LifecycleTiming timing) {
    for (final cb in timing == LifecycleTiming.before
        ? _beforeReassemble
        : _afterReassemble) {
      cb();
    }
  }

  /// Run error callbacks.
  bool runErrorCapturedCallbacks(Object error, StackTrace stack) {
    for (final cb in _errorCaptured) {
      if (cb(error, stack) == true) return true;
    }
    return false;
  }
}
