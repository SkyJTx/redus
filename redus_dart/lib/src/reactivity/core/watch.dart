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

/// Watches a reactive source and invokes a callback when it changes.
///
/// Unlike [watchEffect], [watch] is lazy by default - the callback is only
/// called when the watched source has changed, not immediately on creation.
///
/// The source is a `T Function()` - this can be:
/// - A [Ref] (e.g., `count`) - since Ref is callable
/// - A [Computed] (e.g., `doubled`) - since Computed is callable
/// - A getter function (e.g., `() => x.value + y.value`)
///
/// Example:
/// ```dart
/// final count = ref(0);
///
/// // Pass Ref directly - type is inferred!
/// watch(count, (value, oldValue, onCleanup) {
///   print('Count changed from $oldValue to $value');
/// });
///
/// // Or use a getter for derived values:
/// watch(() => count.value * 2, (doubled, old, _) {
///   print('Doubled: $doubled');
/// });
///
/// count.value = 1;
/// // Prints: "Count changed from 0 to 1"
/// // Prints: "Doubled: 2"
/// ```
WatchHandle watch<T>(
  T Function() source,
  WatchCallback<T> callback, {
  WatchOptions options = WatchOptions.defaults,
}) {
  T? oldValue;
  var isFirst = true;

  late final ReactiveEffect effect;

  effect = ReactiveEffect(
    () {
      final newValue = source();

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

/// Watches multiple sources and invokes callback when any of them change.
///
/// Each source is a `T Function()` - this can be:
/// - A [Ref] (e.g., `firstName`) - since Ref is callable
/// - A [Computed] - since Computed is callable
/// - A getter function
///
/// Example:
/// ```dart
/// final firstName = ref('John');
/// final lastName = ref('Doe');
///
/// watchMultiple<String>(
///   [firstName, lastName],
///   (values, oldValues, onCleanup) {
///     print('Name changed to: ${values[0]} ${values[1]}');
///   },
/// );
/// ```
WatchHandle watchMultiple<T>(
  List<T Function()> sources,
  void Function(List<T> values, List<T?> oldValues, OnCleanup onCleanup) callback, {
  WatchOptions options = WatchOptions.defaults,
}) {
  List<T>? oldValues;
  var isFirst = true;

  late final ReactiveEffect effect;

  effect = ReactiveEffect(
    () {
      final newValues = sources.map((s) => s()).toList();

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

