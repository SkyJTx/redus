/// Lifecycle hooks for Components.
///
/// These functions register callbacks for various lifecycle events.
/// They must be called during [Component.setup].
library;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// Callback type for lifecycle hooks.
///
/// Receives the [BuildContext] to allow access to InheritedWidgets
/// like MediaQuery, Theme, Navigator, etc.
typedef LifecycleCallback = void Function(BuildContext context);

/// Callback type for error handling.
typedef ErrorCallback = bool? Function(Object error, StackTrace stack);

/// Debug event for render tracking.
class RenderDebugEvent {
  /// The type of operation that triggered the event.
  final String type;

  /// The target that was tracked/triggered.
  final Object? target;

  /// Creates a render debug event.
  const RenderDebugEvent({required this.type, this.target});
}

/// Callback type for render debugging.
typedef RenderDebugCallback = void Function(RenderDebugEvent event);

/// Mixin that provides lifecycle hook registration.
mixin LifecycleHooks {
  final List<LifecycleCallback> _onBeforeMountCallbacks = [];
  final List<LifecycleCallback> _onMountedCallbacks = [];
  final List<LifecycleCallback> _onBeforeUpdateCallbacks = [];
  final List<LifecycleCallback> _onUpdatedCallbacks = [];
  final List<LifecycleCallback> _onBeforeUnmountCallbacks = [];
  final List<LifecycleCallback> _onUnmountedCallbacks = [];
  final List<ErrorCallback> _onErrorCapturedCallbacks = [];
  final List<RenderDebugCallback> _onRenderTrackedCallbacks = [];
  final List<RenderDebugCallback> _onRenderTriggeredCallbacks = [];
  final List<LifecycleCallback> _onActivatedCallbacks = [];
  final List<LifecycleCallback> _onDeactivatedCallbacks = [];
  final List<LifecycleCallback> _onDependenciesChangedCallbacks = [];
  final List<LifecycleCallback> _onAfterDependenciesChangedCallbacks = [];

  /// Register a callback to be called before the component mounts.
  ///
  /// Called before the first build, after setup() completes.
  void onBeforeMount(LifecycleCallback callback) {
    _onBeforeMountCallbacks.add(callback);
  }

  /// Register a callback to be called after the component mounts.
  ///
  /// Called after the first build completes.
  void onMounted(LifecycleCallback callback) {
    _onMountedCallbacks.add(callback);
  }

  /// Register a callback to be called before the component updates.
  ///
  /// Called before each rebuild (except the first).
  void onBeforeUpdate(LifecycleCallback callback) {
    _onBeforeUpdateCallbacks.add(callback);
  }

  /// Register a callback to be called after the component updates.
  ///
  /// Called after each rebuild (except the first).
  void onUpdated(LifecycleCallback callback) {
    _onUpdatedCallbacks.add(callback);
  }

  /// Register a callback to be called before the component unmounts.
  ///
  /// Called at the start of dispose.
  void onBeforeUnmount(LifecycleCallback callback) {
    _onBeforeUnmountCallbacks.add(callback);
  }

  /// Register a callback to be called after the component unmounts.
  ///
  /// Called at the end of dispose.
  void onUnmounted(LifecycleCallback callback) {
    _onUnmountedCallbacks.add(callback);
  }

  /// Register a callback to capture errors from descendants.
  ///
  /// Return true to prevent the error from propagating.
  void onErrorCaptured(ErrorCallback callback) {
    _onErrorCapturedCallbacks.add(callback);
  }

  /// Register a debug callback called when a dependency is tracked.
  ///
  /// Development mode only.
  void onRenderTracked(RenderDebugCallback callback) {
    _onRenderTrackedCallbacks.add(callback);
  }

  /// Register a debug callback called when a re-render is triggered.
  ///
  /// Development mode only.
  void onRenderTriggered(RenderDebugCallback callback) {
    _onRenderTriggeredCallbacks.add(callback);
  }

  /// Register a callback called when the component is activated.
  ///
  /// Called when route becomes visible or component is restored.
  void onActivated(LifecycleCallback callback) {
    _onActivatedCallbacks.add(callback);
  }

  /// Register a callback called when the component is deactivated.
  ///
  /// Called when route becomes hidden or component is cached.
  void onDeactivated(LifecycleCallback callback) {
    _onDeactivatedCallbacks.add(callback);
  }

  /// Register a callback called when InheritedWidget dependencies change.
  ///
  /// Called when MediaQuery, Theme, Locale, or other InheritedWidgets change.
  /// This is triggered before processing the change.
  ///
  /// Note: NOT called on initial mount. Use [onMounted] for initial setup.
  void onDependenciesChanged(LifecycleCallback callback) {
    _onDependenciesChangedCallbacks.add(callback);
  }

  /// Register a callback called after InheritedWidget dependencies change.
  ///
  /// Called after processing the change from MediaQuery, Theme, Locale, etc.
  ///
  /// Note: NOT called on initial mount. Use [onMounted] for initial setup.
  void onAfterDependenciesChanged(LifecycleCallback callback) {
    _onAfterDependenciesChangedCallbacks.add(callback);
  }

  // Internal: Execute callbacks - @internal prevents public use while allowing package access
  @internal
  void runBeforeMount(BuildContext context) {
    for (final cb in _onBeforeMountCallbacks) {
      cb(context);
    }
  }

  @internal
  void runMounted(BuildContext context) {
    for (final cb in _onMountedCallbacks) {
      cb(context);
    }
  }

  @internal
  void runBeforeUpdate(BuildContext context) {
    for (final cb in _onBeforeUpdateCallbacks) {
      cb(context);
    }
  }

  @internal
  void runUpdated(BuildContext context) {
    for (final cb in _onUpdatedCallbacks) {
      cb(context);
    }
  }

  @internal
  void runBeforeUnmount(BuildContext context) {
    for (final cb in _onBeforeUnmountCallbacks) {
      cb(context);
    }
  }

  @internal
  void runUnmounted(BuildContext context) {
    for (final cb in _onUnmountedCallbacks) {
      cb(context);
    }
  }

  @internal
  bool runErrorCaptured(Object error, StackTrace stack) {
    for (final cb in _onErrorCapturedCallbacks) {
      if (cb(error, stack) == true) {
        return true; // Error handled
      }
    }
    return false;
  }

  @internal
  void runRenderTracked(RenderDebugEvent event) {
    for (final cb in _onRenderTrackedCallbacks) {
      cb(event);
    }
  }

  @internal
  void runRenderTriggered(RenderDebugEvent event) {
    for (final cb in _onRenderTriggeredCallbacks) {
      cb(event);
    }
  }

  @internal
  void runActivated(BuildContext context) {
    for (final cb in _onActivatedCallbacks) {
      cb(context);
    }
  }

  @internal
  void runDeactivated(BuildContext context) {
    for (final cb in _onDeactivatedCallbacks) {
      cb(context);
    }
  }

  @internal
  void runDependenciesChanged(BuildContext context) {
    for (final cb in _onDependenciesChangedCallbacks) {
      cb(context);
    }
  }

  @internal
  void runAfterDependenciesChanged(BuildContext context) {
    for (final cb in _onAfterDependenciesChangedCallbacks) {
      cb(context);
    }
  }

  /// Clear all lifecycle callbacks.
  ///
  /// Called when element unmounts to prevent callback accumulation
  /// when widget instance is reused.
  @internal
  void clearLifecycleCallbacks() {
    _onBeforeMountCallbacks.clear();
    _onMountedCallbacks.clear();
    _onBeforeUpdateCallbacks.clear();
    _onUpdatedCallbacks.clear();
    _onBeforeUnmountCallbacks.clear();
    _onUnmountedCallbacks.clear();
    _onErrorCapturedCallbacks.clear();
    _onRenderTrackedCallbacks.clear();
    _onRenderTriggeredCallbacks.clear();
    _onActivatedCallbacks.clear();
    _onDeactivatedCallbacks.clear();
    _onDependenciesChangedCallbacks.clear();
    _onAfterDependenciesChangedCallbacks.clear();
  }
}
