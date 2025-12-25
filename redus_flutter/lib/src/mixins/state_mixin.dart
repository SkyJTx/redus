/// State Mixins - Lifecycle hooks and reactivity for `State<T>` classes.
///
/// Provides mixins for standard Flutter StatefulWidget:
/// - [LifecycleHooksStateMixin] - Lifecycle hooks with Flutter semantics
/// - [ReactiveStateMixin] - EffectScope and reactivity
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle_mixin.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LIFECYCLE HOOKS STATE MIXIN
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// LIFECYCLE HOOKS STATE MIXIN
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin providing lifecycle hooks for State classes.
///
/// Extends [LifecycleCallbacks] with Flutter lifecycle method overrides
/// that automatically run registered callbacks at the correct times.
///
/// ```dart
/// class _MyState extends State<MyWidget>
///     with LifecycleCallbacks, LifecycleHooksStateMixin {
///   @override
///   void initState() {
///     super.initState();
///     onMounted(() => print('Mounted!'));
///     onDispose(() => print('Disposing...'));
///   }
/// }
/// ```
mixin LifecycleHooksStateMixin<T extends StatefulWidget>
    on State<T>, LifecycleCallbacks {
  bool _isFirstBuild = true;
  bool _dependenciesInitialized = false;

  @override
  @mustCallSuper
  void initState() {
    runInitStateCallbacks(LifecycleTiming.before);
    super.initState();
    runInitStateCallbacks(LifecycleTiming.after);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (!_dependenciesInitialized) {
      _dependenciesInitialized = true;
      super.didChangeDependencies();
      return;
    }
    runDidChangeDependenciesCallbacks(LifecycleTiming.before);
    super.didChangeDependencies();
    runDidChangeDependenciesCallbacks(LifecycleTiming.after);
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    runDidUpdateWidgetCallbacks(LifecycleTiming.before, oldWidget, widget);
    super.didUpdateWidget(oldWidget);
    runDidUpdateWidgetCallbacks(LifecycleTiming.after, oldWidget, widget);
  }

  @override
  @mustCallSuper
  void deactivate() {
    runDeactivateCallbacks(LifecycleTiming.before);
    super.deactivate();
    runDeactivateCallbacks(LifecycleTiming.after);
  }

  @override
  @mustCallSuper
  void activate() {
    runActivateCallbacks(LifecycleTiming.before);
    super.activate();
    runActivateCallbacks(LifecycleTiming.after);
  }

  @override
  @mustCallSuper
  void reassemble() {
    runReassembleCallbacks(LifecycleTiming.before);
    super.reassemble();
    runReassembleCallbacks(LifecycleTiming.after);
  }

  @override
  @mustCallSuper
  void dispose() {
    runDisposeCallbacks(LifecycleTiming.before);
    runDisposeCallbacks(LifecycleTiming.after);
    super.dispose();
  }

  /// Schedule mounted callback after first build.
  /// Call this at end of build() method.
  @protected
  void scheduleMountedCallbackIfNeeded() {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) runMountedCallbacks();
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REACTIVE STATE MIXIN
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin providing automatic reactivity for State classes.
///
/// Tracks reactive dependencies during build() and automatically
/// triggers setState when they change.
///
/// ```dart
/// class _MyState extends State<MyWidget>
///     with LifecycleCallbacks, LifecycleHooksStateMixin, ReactiveStateMixin {
///   late final count = ref(0);
///
///   @override
///   Widget build(BuildContext context) {
///     return buildReactive(context, () {
///       return Text('${count.value}'); // Auto-tracked!
///     });
///   }
/// }
/// ```
mixin ReactiveStateMixin<T extends StatefulWidget> on State<T> {
  late final EffectScope _scope = effectScope();
  late final ReactiveEffect _renderEffect = ReactiveEffect(
    () {
      if (mounted && !_isRendering) {
        setState(() {});
      }
    },
    flush: FlushMode.sync,
  );
  bool _isRendering = false;

  /// Build with reactive tracking.
  Widget buildReactive(BuildContext context, Widget Function() builder) {
    Widget? result;
    _isRendering = true;

    effectStack.add(_renderEffect);
    final previousEffect = activeEffect;
    activeEffect = _renderEffect;

    try {
      _scope.run(() {
        result = builder();
      });
    } finally {
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
      _isRendering = false;
    }

    return result ?? const SizedBox.shrink();
  }

  /// Run code within the effect scope.
  void runInScope(void Function() fn) {
    _scope.run(fn);
  }

  /// Stop reactivity. Call in dispose().
  void stopReactivity() {
    _renderEffect.stop();
    _scope.stop();
  }
}
