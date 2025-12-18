/// Computed reactive value implementation.
library;

import 'dep.dart';
import 'effect.dart';
import 'types.dart';

/// Creates a readonly computed value.
///
/// The computed value is lazily evaluated and cached. It only recomputes
/// when its dependencies change.
///
/// Example:
/// ```dart
/// final count = ref(1);
/// final double = computed(() => count.value * 2);
///
/// print(double.value); // 2
/// count.value = 2;
/// print(double.value); // 4
/// ```
Computed<T> computed<T>(T Function() getter) => Computed<T>(getter);

/// Creates a writable computed value.
///
/// Allows both getting and setting the computed value.
///
/// Example:
/// ```dart
/// final count = ref(1);
/// final plusOne = writableComputed(
///   get: () => count.value + 1,
///   set: (val) => count.value = val - 1,
/// );
///
/// plusOne.value = 5;
/// print(count.value); // 4
/// ```
WritableComputed<T> writableComputed<T>({
  required T Function() get,
  required void Function(T value) set,
}) =>
    WritableComputed<T>(get, set);

/// A computed reactive value.
///
/// Computed values are:
/// - Lazy: Only computed when accessed
/// - Cached: Reuses the last value if dependencies haven't changed
/// - Reactive: Tracks its own dependents and notifies them when it changes
class Computed<T> {
  final T Function() _getter;
  final Dep _dep = Dep();

  T? _value;
  bool _dirty = true;
  late final ReactiveEffect _effect;

  /// Creates a new computed value with the given getter function.
  Computed(this._getter) {
    // Create an effect that marks this computed as dirty when deps change
    _effect = ReactiveEffect(
      () {
        // When dependencies change, mark as dirty and notify our dependents
        if (!_dirty) {
          _dirty = true;
          _dep.trigger();
        }
      },
      flush: FlushMode.sync, // Computed effects should be sync
    );
  }

  /// The computed value.
  ///
  /// Reading this property:
  /// 1. Recomputes the value if dirty (dependencies changed)
  /// 2. Tracks the current effect as a dependent
  T get value {
    // Track that something is reading this computed
    _dep.track();

    if (_dirty) {
      // Run the getter while tracking its dependencies
      effectStack.add(_effect);
      final previousEffect = activeEffect;
      activeEffect = _effect;

      try {
        _value = _getter();
        _dirty = false;
      } finally {
        effectStack.removeLast();
        activeEffect = effectStack.isEmpty ? null : effectStack.last;
        if (previousEffect != null && effectStack.contains(previousEffect)) {
          activeEffect = previousEffect;
        }
      }
    }

    return _value as T;
  }

  /// Whether the computed value needs to be recalculated.
  bool get isDirty => _dirty;

  /// Force the computed to recalculate on next access.
  void invalidate() {
    _dirty = true;
  }

  @override
  String toString() => 'Computed(${_dirty ? "dirty" : _value})';
}

/// A writable computed value.
///
/// Extends [Computed] with a setter that can update the source values.
class WritableComputed<T> extends Computed<T> {
  final void Function(T value) _setter;

  /// Creates a new writable computed value.
  WritableComputed(super.getter, this._setter);

  /// Set the computed value.
  ///
  /// This calls the setter function provided during creation,
  /// which should update the source reactive values.
  set value(T newValue) {
    _setter(newValue);
  }
}
