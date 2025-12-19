/// Reactive effect management and scheduling.
library;

import 'dart:async';

import 'dep.dart';
import 'types.dart';

/// The currently active effect being executed.
///
/// This is used during dependency tracking to know which effect
/// is currently reading reactive values. Also used by redus_flutter
/// for automatic component rendering.
ReactiveEffect? activeEffect;

/// Stack of active effects for nested effect handling.
final List<ReactiveEffect> effectStack = [];

/// The current effect for cleanup registration.
ReactiveEffect? _currentCleanupEffect;

/// Represents a reactive side effect that re-runs when dependencies change.
class ReactiveEffect {
  /// The effect function to run.
  final void Function() _fn;

  /// When to flush this effect.
  final FlushMode flush;

  /// Dependencies that this effect tracks.
  final Set<Dep> _deps = {};

  /// Whether this effect is active (not stopped).
  bool _active = true;

  /// Whether this effect is paused.
  bool _paused = false;

  /// Cleanup function to run before next execution.
  CleanupFn? _cleanup;

  /// List of cleanup functions registered via onWatcherCleanup.
  final List<CleanupFn> _cleanups = [];

  /// Creates a new reactive effect.
  ReactiveEffect(this._fn, {this.flush = FlushMode.pre});

  /// Whether this effect is active.
  bool get isActive => _active;

  /// Whether this effect is paused.
  bool get isPaused => _paused;

  /// Register a cleanup function.
  void onCleanup(CleanupFn cleanup) {
    _cleanup = cleanup;
  }

  /// Register a cleanup via onWatcherCleanup.
  void addCleanup(CleanupFn cleanup) {
    _cleanups.add(cleanup);
  }

  /// Add a dependency to this effect.
  void addDep(Dep dep) {
    _deps.add(dep);
  }

  /// Run the effect function and track dependencies.
  void run() {
    if (!_active) return;
    if (_paused) return;

    // Run cleanup before re-running
    _runCleanups();

    // Push this effect onto the stack
    effectStack.add(this);
    final previousEffect = activeEffect;
    activeEffect = this;
    _currentCleanupEffect = this;

    try {
      _fn();
    } finally {
      // Pop from stack
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      _currentCleanupEffect = null;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
    }
  }

  void _runCleanups() {
    // Run the single cleanup
    _cleanup?.call();
    _cleanup = null;

    // Run all registered cleanups
    for (final cleanup in _cleanups) {
      cleanup();
    }
    _cleanups.clear();
  }

  /// Stop this effect from running.
  void stop() {
    if (!_active) return;

    _runCleanups();

    // Unsubscribe from all deps
    for (final dep in _deps) {
      dep.unsubscribe(this);
    }
    _deps.clear();
    _active = false;
  }

  /// Pause this effect temporarily.
  void pause() {
    _paused = true;
  }

  /// Resume a paused effect.
  void resume() {
    if (_paused) {
      _paused = false;
      // Re-run if we were triggered while paused
      Scheduler.queueEffect(this);
    }
  }
}

/// Scheduler for batching and flushing effects.
class Scheduler {
  static final List<ReactiveEffect> _preQueue = [];
  static final List<ReactiveEffect> _postQueue = [];
  static final Set<ReactiveEffect> _preQueued = {};
  static final Set<ReactiveEffect> _postQueued = {};
  static bool _isFlushing = false;
  static bool _isFlushPending = false;

  /// Queue an effect for execution based on its flush mode.
  static void queueEffect(ReactiveEffect effect) {
    if (!effect.isActive || effect.isPaused) return;

    switch (effect.flush) {
      case FlushMode.sync:
        // Run immediately
        effect.run();
        break;
      case FlushMode.pre:
        if (!_preQueued.contains(effect)) {
          _preQueue.add(effect);
          _preQueued.add(effect);
          _scheduleFlush();
        }
        break;
      case FlushMode.post:
        if (!_postQueued.contains(effect)) {
          _postQueue.add(effect);
          _postQueued.add(effect);
          _scheduleFlush();
        }
        break;
    }
  }

  static void _scheduleFlush() {
    if (!_isFlushPending) {
      _isFlushPending = true;
      scheduleMicrotask(_flush);
    }
  }

  static void _flush() {
    _isFlushPending = false;
    _isFlushing = true;

    try {
      // Flush pre-queue first
      while (_preQueue.isNotEmpty) {
        final effect = _preQueue.removeAt(0);
        _preQueued.remove(effect);
        effect.run();
      }

      // Then flush post-queue
      while (_postQueue.isNotEmpty) {
        final effect = _postQueue.removeAt(0);
        _postQueued.remove(effect);
        effect.run();
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Force flush all pending effects (useful for testing).
  static void flushSync() {
    _flush();
  }

  /// Check if scheduler is currently flushing.
  static bool get isFlushing => _isFlushing;
}

/// Register a cleanup function for the current watcher.
///
/// Can only be called during the synchronous execution of a
/// watchEffect or watch callback function.
///
/// Example:
/// ```dart
/// watchEffect((_) {
///   final subscription = stream.listen(handler);
///   onWatcherCleanup(() => subscription.cancel());
/// });
/// ```
void onWatcherCleanup(CleanupFn cleanup, {bool failSilently = false}) {
  if (_currentCleanupEffect != null) {
    _currentCleanupEffect!.addCleanup(cleanup);
  } else if (!failSilently) {
    throw StateError(
      'onWatcherCleanup can only be called during the synchronous '
      'execution of a watchEffect or watch callback.',
    );
  }
}
