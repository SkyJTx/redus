/// Watch API implementations.
library;

import 'computed.dart';
import 'effect.dart';
import 'ref.dart';
import 'types.dart';

// Re-export for internal use
export 'effect.dart' show activeEffect, effectStack, onWatcherCleanup;

/// Handle to control a watcher.
///
/// Provides methods to stop, pause, and resume a watcher.
class WatchHandle {
  final ReactiveEffect _effect;

  WatchHandle._(this._effect);

  /// Stop the watcher permanently.
  ///
  /// After stopping, the watcher will not run again.
  void stop() => _effect.stop();

  /// Pause the watcher temporarily.
  ///
  /// While paused, changes to dependencies will not trigger the watcher.
  /// Call [resume] to start watching again.
  void pause() => _effect.pause();

  /// Resume a paused watcher.
  ///
  /// If dependencies changed while paused, the watcher will run.
  void resume() => _effect.resume();

  /// Callable - same as [stop].
  void call() => stop();
}

/// Runs an effect immediately and re-runs it when dependencies change.
///
/// The effect function is called immediately upon creation, and will be
/// re-called whenever any reactive values it reads change.
///
/// Example:
/// ```dart
/// final count = ref(0);
///
/// watchEffect((onCleanup) {
///   print('Count is: ${count.value}');
///
///   // Optional cleanup
///   onCleanup(() => print('Cleaning up...'));
/// });
/// // Prints: "Count is: 0"
///
/// count.value = 1;
/// // Prints: "Cleaning up..."
/// // Prints: "Count is: 1"
/// ```
WatchHandle watchEffect(
  EffectFn effect, {
  WatchOptions options = WatchOptions.defaults,
}) {
  late final ReactiveEffect reactiveEffect;

  reactiveEffect = ReactiveEffect(
    () {
      effect((cleanup) => reactiveEffect.onCleanup(cleanup));
    },
    flush: options.flush,
  );

  // Run immediately
  reactiveEffect.run();

  return WatchHandle._(reactiveEffect);
}

/// Alias for [watchEffect] with `flush: FlushMode.post`.
///
/// The effect will run after all pre-flush effects have completed.
WatchHandle watchPostEffect(EffectFn effect) {
  return watchEffect(
    effect,
    options: const WatchOptions(flush: FlushMode.post),
  );
}

/// Alias for [watchEffect] with `flush: FlushMode.sync`.
///
/// The effect will run synchronously when dependencies change.
/// Use with caution as this can cause performance issues.
WatchHandle watchSyncEffect(EffectFn effect) {
  return watchEffect(
    effect,
    options: const WatchOptions(flush: FlushMode.sync),
  );
}

/// Watch type for determining source type.
sealed class _WatchSource<T> {
  T getValue();
}

class _RefSource<T> implements _WatchSource<T> {
  final Ref<T> ref;
  _RefSource(this.ref);

  @override
  T getValue() => ref.value;
}

class _ComputedSource<T> implements _WatchSource<T> {
  final Computed<T> computed;
  _ComputedSource(this.computed);

  @override
  T getValue() => computed.value;
}

class _GetterSource<T> implements _WatchSource<T> {
  final WatchGetter<T> getter;
  _GetterSource(this.getter);

  @override
  T getValue() => getter();
}

/// Watches one or more reactive sources and invokes a callback when they change.
///
/// Unlike [watchEffect], [watch] is lazy by default - the callback is only
/// called when the watched source has changed, not immediately on creation.
///
/// The source can be:
/// - A [Ref]
/// - A [Computed]
/// - A getter function that returns a value
/// - A [List] of the above
///
/// Example:
/// ```dart
/// final count = ref(0);
///
/// watch(
///   count,
///   (value, oldValue, onCleanup) {
///     print('Count changed from $oldValue to $value');
///   },
/// );
///
/// count.value = 1;
/// // Prints: "Count changed from 0 to 1"
/// ```
WatchHandle watch<T>(
  Object source,
  WatchCallback<T> callback, {
  WatchOptions options = WatchOptions.defaults,
}) {
  final watchSource = _resolveSource<T>(source);
  T? oldValue;
  var isFirst = true;

  late final ReactiveEffect effect;

  effect = ReactiveEffect(
    () {
      final newValue = watchSource.getValue();

      if (isFirst) {
        oldValue = newValue;
        isFirst = false;

        if (options.immediate) {
          callback(newValue, null, (cleanup) => effect.onCleanup(cleanup));
        }
        return;
      }

      // Only call callback if value actually changed
      if (!identical(newValue, oldValue) && newValue != oldValue) {
        final prev = oldValue;
        oldValue = newValue;
        callback(newValue, prev, (cleanup) => effect.onCleanup(cleanup));

        // Handle once option
        if (options.once) {
          effect.stop();
        }
      }
    },
    flush: options.flush,
  );

  // Initial run to set up tracking
  effect.run();

  return WatchHandle._(effect);
}

_WatchSource<T> _resolveSource<T>(Object source) {
  if (source is Ref<T>) {
    return _RefSource<T>(source);
  }
  if (source is Computed<T>) {
    return _ComputedSource<T>(source);
  }
  if (source is WatchGetter<T>) {
    return _GetterSource<T>(source);
  }
  throw ArgumentError(
    'Watch source must be a Ref<$T>, Computed<$T>, or getter function. '
    'Got: ${source.runtimeType}',
  );
}

/// Watches multiple sources and invokes callback when any of them change.
///
/// Example:
/// ```dart
/// final firstName = ref('John');
/// final lastName = ref('Doe');
///
/// watchMultiple(
///   [firstName, lastName],
///   (values, oldValues, onCleanup) {
///     print('Name changed to: ${values[0]} ${values[1]}');
///   },
/// );
/// ```
WatchHandle watchMultiple<T>(
  List<Object> sources,
  void Function(List<T> values, List<T?> oldValues, OnCleanup onCleanup) callback, {
  WatchOptions options = WatchOptions.defaults,
}) {
  final watchSources = sources.map(_resolveSource<T>).toList();
  List<T>? oldValues;
  var isFirst = true;

  late final ReactiveEffect effect;

  effect = ReactiveEffect(
    () {
      final newValues = watchSources.map((s) => s.getValue()).toList();

      if (isFirst) {
        oldValues = List<T>.from(newValues);
        isFirst = false;

        if (options.immediate) {
          callback(
            newValues,
            List<T?>.filled(sources.length, null),
            (cleanup) => effect.onCleanup(cleanup),
          );
        }
        return;
      }

      // Check if any value changed
      var hasChanged = false;
      for (var i = 0; i < newValues.length; i++) {
        if (!identical(newValues[i], oldValues![i]) && newValues[i] != oldValues![i]) {
          hasChanged = true;
          break;
        }
      }

      if (hasChanged) {
        final prev = oldValues;
        oldValues = List<T>.from(newValues);
        callback(newValues, prev!, (cleanup) => effect.onCleanup(cleanup));

        if (options.once) {
          effect.stop();
        }
      }
    },
    flush: options.flush,
  );

  // Initial run to set up tracking
  effect.run();

  return WatchHandle._(effect);
}
