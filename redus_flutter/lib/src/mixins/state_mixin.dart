/// State Mixins - Lifecycle hooks and reactivity for `State<T>` classes.
///
/// Provides mixins that can be used with standard Flutter StatefulWidget:
/// - [LifecycleHooksStateMixin] for Vue-like lifecycle hooks
/// - [ReactiveProviderStateMixin] for EffectScope and reactivity utilities
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle_mixin.dart';

/// Mixin that provides Vue-like lifecycle hooks for State classes.
///
/// Use this mixin to register callbacks for various lifecycle events
/// on a standard [StatefulWidget].
///
/// **Available Hooks:**
/// - [onMounted] - Called after the first build completes
/// - [onBeforeUnmount] - Called at the start of dispose
/// - [onUnmounted] - Called at the end of dispose
/// - [onActivated] - Called when widget is re-activated
/// - [onDeactivated] - Called when widget is deactivated
/// - [onDependenciesChanged] - Called before processing InheritedWidget changes
/// - [onAfterDependenciesChanged] - Called after processing InheritedWidget changes
///
/// **Example:**
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with LifecycleHooksStateMixin {
///   @override
///   void initState() {
///     super.initState();
///     onMounted((context) => print('Widget mounted!'));
///     onUnmounted((context) => print('Widget unmounted!'));
///   }
///
///   @override
///   Widget build(BuildContext context) => Text('Hello');
/// }
/// ```
mixin LifecycleHooksStateMixin<T extends StatefulWidget> on State<T> {
  final List<LifecycleCallback> _onMountedCallbacks = [];
  final List<LifecycleCallback> _onBeforeUnmountCallbacks = [];
  final List<LifecycleCallback> _onUnmountedCallbacks = [];
  final List<LifecycleCallback> _onActivatedCallbacks = [];
  final List<LifecycleCallback> _onDeactivatedCallbacks = [];
  final List<LifecycleCallback> _onDependenciesChangedCallbacks = [];
  final List<LifecycleCallback> _onAfterDependenciesChangedCallbacks = [];
  final List<ErrorCallback> _onErrorCapturedCallbacks = [];

  bool _isFirstBuild = true;
  bool _dependenciesInitialized = false;

  /// Register a callback to be called after the component mounts.
  ///
  /// Called after the first build completes.
  void onMounted(LifecycleCallback callback) {
    _onMountedCallbacks.add(callback);
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
  /// Note: NOT called on initial mount.
  void onDependenciesChanged(LifecycleCallback callback) {
    _onDependenciesChangedCallbacks.add(callback);
  }

  /// Register a callback called after InheritedWidget dependencies change.
  ///
  /// Called after processing the change from MediaQuery, Theme, Locale, etc.
  ///
  /// Note: NOT called on initial mount.
  void onAfterDependenciesChanged(LifecycleCallback callback) {
    _onAfterDependenciesChangedCallbacks.add(callback);
  }

  /// Register a callback to capture errors.
  ///
  /// Return true to mark the error as handled.
  void onErrorCaptured(ErrorCallback callback) {
    _onErrorCapturedCallbacks.add(callback);
  }

  /// Runs the error captured callbacks.
  /// Returns true if any callback handled the error.
  bool runErrorCaptured(Object error, StackTrace stack) {
    for (final cb in _onErrorCapturedCallbacks) {
      if (cb(error, stack) == true) {
        return true;
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    // Skip first call (during mount) - use onMounted for initial setup
    if (!_dependenciesInitialized) {
      _dependenciesInitialized = true;
      super.didChangeDependencies();
      return;
    }

    // Run before hook
    for (final cb in _onDependenciesChangedCallbacks) {
      cb(context);
    }

    super.didChangeDependencies();

    // Run after hook
    for (final cb in _onAfterDependenciesChangedCallbacks) {
      cb(context);
    }
  }

  @override
  void activate() {
    super.activate();
    for (final cb in _onActivatedCallbacks) {
      cb(context);
    }
  }

  @override
  void deactivate() {
    for (final cb in _onDeactivatedCallbacks) {
      cb(context);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    // Before unmount
    for (final cb in _onBeforeUnmountCallbacks) {
      cb(context);
    }

    // After unmount
    for (final cb in _onUnmountedCallbacks) {
      cb(context);
    }

    // Clear callbacks
    _onMountedCallbacks.clear();
    _onBeforeUnmountCallbacks.clear();
    _onUnmountedCallbacks.clear();
    _onActivatedCallbacks.clear();
    _onDeactivatedCallbacks.clear();
    _onDependenciesChangedCallbacks.clear();
    _onAfterDependenciesChangedCallbacks.clear();
    _onErrorCapturedCallbacks.clear();

    super.dispose();
  }

  /// Called during build to schedule mounted callback on first build.
  ///
  /// Call this at the start of your build method:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   scheduleLifecycleCallbacks();
  ///   return Text('Hello');
  /// }
  /// ```
  void scheduleLifecycleCallbacks() {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          for (final cb in _onMountedCallbacks) {
            cb(context);
          }
        }
      });
    }
  }
}

/// Mixin that provides EffectScope and reactivity utilities for State classes.
///
/// Use this mixin to integrate redus reactivity with standard [StatefulWidget].
/// It provides an [EffectScope] that is automatically cleaned up on dispose.
///
/// **Features:**
/// - Creates an [EffectScope] for automatic cleanup
/// - Provides [setup] method for initialization
/// - All reactive effects created in setup are automatically stopped on dispose
///
/// **Example:**
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with LifecycleHooksStateMixin, ReactiveProviderStateMixin {
///
///   late final count = ref(0);
///
///   @override
///   void setup() {
///     onMounted((context) => print('Mounted!'));
///
///     // This watchEffect is automatically stopped on dispose
///     watchEffect((onCleanup) {
///       print('Count changed: ${count.value}');
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     scheduleLifecycleCallbacks();
///     return Text('Count: ${count.value}');
///   }
/// }
/// ```
mixin ReactiveProviderStateMixin<T extends StatefulWidget> on State<T> {
  late final EffectScope _scope;

  /// Called once during initState to set up reactive effects.
  ///
  /// Override this method to:
  /// - Register lifecycle hooks (if using [LifecycleHooksStateMixin])
  /// - Set up watchers with [watchEffect], [watch], etc.
  ///
  /// All effects created here are automatically cleaned up on dispose.
  void setup();

  @override
  void initState() {
    super.initState();

    // Create effect scope for cleanup
    _scope = effectScope();

    // Run setup within scope
    _scope.run(() {
      setup();
    });
  }

  @override
  void dispose() {
    _scope.stop();
    super.dispose();
  }
}
