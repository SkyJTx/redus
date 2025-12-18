/// Core type definitions for the reactivity system.
library;

/// Flush timing for effects.
///
/// - [pre]: Default. Effect runs before the next microtask.
/// - [post]: Effect runs after the current flush cycle completes.
/// - [sync]: Effect runs synchronously when dependencies change.
enum FlushMode {
  /// Effect runs before the next microtask (default).
  pre,

  /// Effect runs after the current flush cycle completes.
  post,

  /// Effect runs synchronously when dependencies change.
  sync,
}

/// Effect cleanup function type.
typedef CleanupFn = void Function();

/// Callback for registering cleanup in effects.
typedef OnCleanup = void Function(CleanupFn cleanup);

/// Watch callback signature with new value, old value, and cleanup registration.
typedef WatchCallback<T> = void Function(
  T value,
  T? oldValue,
  OnCleanup onCleanup,
);

/// Watch effect function signature.
typedef EffectFn = void Function(OnCleanup onCleanup);

/// Getter function for watch sources.
typedef WatchGetter<T> = T Function();

/// Options for configuring watch behavior.
class WatchOptions {
  /// When to flush the effect.
  final FlushMode flush;

  /// If true, run the callback immediately on creation.
  final bool immediate;

  /// If true, deep watch nested properties.
  final bool deep;

  /// If true, stop the watcher after first callback run.
  final bool once;

  /// Creates watch options with the specified configuration.
  const WatchOptions({
    this.flush = FlushMode.pre,
    this.immediate = false,
    this.deep = false,
    this.once = false,
  });

  /// Default options: pre flush, not immediate, not deep, not once.
  static const WatchOptions defaults = WatchOptions();
}
