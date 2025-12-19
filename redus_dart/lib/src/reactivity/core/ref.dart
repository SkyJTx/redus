/// Reactive reference implementation.
library;

import 'dep.dart';

/// Creates a reactive reference to a value.
///
/// The returned [Ref] object is mutable and reactive:
/// - Reading [Ref.value] tracks the current effect as a dependency
/// - Writing [Ref.value] triggers all dependent effects to re-run
///
/// Example:
/// ```dart
/// final count = ref(0);
/// print(count.value); // 0
///
/// count.value = 1;
/// print(count.value); // 1
/// ```
Ref<T> ref<T>(T value) => Ref<T>(value);

/// A reactive reference container.
///
/// Wraps a value and makes it reactive. Any read of [value] will track
/// the current effect, and any write will trigger dependent effects.
class Ref<T> {
  T _value;
  final Dep _dep = Dep();

  /// Creates a new reactive reference with the given initial value.
  Ref(this._value);

  /// The reactive value.
  ///
  /// Reading this property tracks the current effect as a dependency.
  /// Writing this property triggers all dependent effects to re-run.
  T get value {
    _dep.track();
    return _value;
  }

  set value(T newValue) {
    if (!identical(_value, newValue) && _value != newValue) {
      _value = newValue;
      _dep.trigger();
    }
  }

  /// The raw value without triggering reactivity.
  ///
  /// Use this when you need to read the value without tracking.
  T get raw => _value;

  /// Update the value using a function.
  ///
  /// This is useful when you need to update based on the current value.
  /// ```dart
  /// count.update((v) => v + 1);
  /// ```
  void update(T Function(T current) updater) {
    value = updater(_value);
  }

  /// Force trigger all dependents even if value hasn't changed.
  void trigger() {
    _dep.trigger();
  }

  /// Makes Ref callable, returning the reactive value.
  ///
  /// This allows Ref to be used as a `T Function()` for strong typing
  /// in watch() and other APIs. Same as accessing [value].
  ///
  /// Example:
  /// ```dart
  /// final count = ref(0);
  /// print(count()); // 0 - same as count.value
  ///
  /// // Use in watch with type inference:
  /// watch(count, (val, old, _) => print(val));
  /// ```
  T call() => value;

  @override
  String toString() => 'Ref($_value)';
}
