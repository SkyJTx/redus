/// State Mixins - Lifecycle hooks and state binding for `State<T>` classes.
///
/// Provides mixins for standard Flutter StatefulWidget:
/// - [LifecycleHooksStateMixin] - Lifecycle hooks with Flutter semantics
/// - [BindStateMixin] - State persistence via bind()
/// - [ReactiveStateMixin] - EffectScope and reactivity
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle_mixin.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BIND STATE MIXIN
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin providing bind() for state persistence in State classes.
///
/// Use bind() to create state that persists across parent rebuilds:
///
/// ```dart
/// class _MyState extends State<MyWidget> with BindStateMixin {
///   late final count = bind(() => ref(0));
///   late final store = bind(() => MyStore());
/// }
/// ```
mixin BindStateMixin<T extends StatefulWidget> on State<T> {
  final Map<int, dynamic> _bindStorage = {};
  int _bindIndex = 0;

  /// Create or retrieve state that persists across parent rebuilds.
  S bind<S>(S Function() create) {
    if (!_bindStorage.containsKey(_bindIndex)) {
      _bindStorage[_bindIndex] = create();
    }
    return _bindStorage[_bindIndex++] as S;
  }

  /// Reset bind index. Call when widget instance changes.
  void resetBindIndex() {
    _bindIndex = 0;
  }
}

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
  void initState() {
    runInitStateCallbacks(LifecycleTiming.before);
    super.initState();
    runInitStateCallbacks(LifecycleTiming.after);
  }

  @override
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
  void didUpdateWidget(covariant T oldWidget) {
    runDidUpdateWidgetCallbacks(LifecycleTiming.before, oldWidget, widget);
    super.didUpdateWidget(oldWidget);
    runDidUpdateWidgetCallbacks(LifecycleTiming.after, oldWidget, widget);
  }

  @override
  void deactivate() {
    runDeactivateCallbacks(LifecycleTiming.before);
    super.deactivate();
    runDeactivateCallbacks(LifecycleTiming.after);
  }

  @override
  void activate() {
    runActivateCallbacks(LifecycleTiming.before);
    super.activate();
    runActivateCallbacks(LifecycleTiming.after);
  }

  @override
  void reassemble() {
    runReassembleCallbacks(LifecycleTiming.before);
    super.reassemble();
    runReassembleCallbacks(LifecycleTiming.after);
  }

  @override
  void dispose() {
    runDisposeCallbacks(LifecycleTiming.before);
    runDisposeCallbacks(LifecycleTiming.after);
    super.dispose();
  }

  /// Schedule mounted callback after first build.
  /// Call this at end of build() method.
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
