/// Shallow reactive implementations.
library;

import '../core/computed.dart';
import '../core/dep.dart';
import '../core/ref.dart';

/// Creates a shallow ref - only .value access is reactive.
///
/// Unlike [ref], the inner value is stored and exposed as-is,
/// and will not be made deeply reactive.
///
/// Example:
/// ```dart
/// final state = shallowRef({'count': 1});
///
/// // Does NOT trigger effects (shallow)
/// state.value['count'] = 2;
///
/// // DOES trigger effects (value replacement)
/// state.value = {'count': 2};
/// ```
ShallowRef<T> shallowRef<T>(T value) => ShallowRef<T>(value);

/// A shallow reactive reference.
///
/// Only the `.value` access is reactive. Nested properties are not tracked.
class ShallowRef<T> {
  T _value;
  final Dep _dep = Dep();

  /// Creates a new shallow ref with the given initial value.
  ShallowRef(this._value);

  /// The reactive value.
  ///
  /// Reading tracks the current effect.
  /// Writing triggers effects only if the reference changes.
  T get value {
    _dep.track();
    return _value;
  }

  set value(T newValue) {
    // For shallow refs, always trigger on reference change
    if (!identical(_value, newValue)) {
      _value = newValue;
      _dep.trigger();
    }
  }

  /// The raw value without triggering reactivity.
  T get raw => _value;

  /// Force trigger all dependents.
  void trigger() {
    _dep.trigger();
  }

  @override
  String toString() => 'ShallowRef($_value)';
}

/// Force trigger effects that depend on a shallow ref.
///
/// Typically used after making deep mutations to the inner value.
///
/// Example:
/// ```dart
/// final shallow = shallowRef({'greet': 'Hello'});
///
/// // This won't trigger effects
/// shallow.value['greet'] = 'Hi';
///
/// // Force trigger
/// triggerRef(shallow);
/// ```
void triggerRef(ShallowRef<dynamic> ref) {
  ref.trigger();
}

/// Creates a shallow readonly wrapper.
///
/// Only root-level access is readonly. Nested properties can still be mutated.
///
/// Example:
/// ```dart
/// final state = shallowReadonly(ref({'foo': 1, 'nested': {'bar': 2}}));
///
/// // Reading works
/// state.value; // {'foo': 1, 'nested': {'bar': 2}}
///
/// // Nested mutation still works
/// state.value['nested']['bar'] = 3;
/// ```
ShallowReadonly<T> shallowReadonly<T>(Object source) =>
    ShallowReadonly<T>(source);

/// A shallow readonly wrapper.
///
/// Only root-level is readonly. Nested properties are not protected.
class ShallowReadonly<T> {
  final Object _source;

  /// Creates a shallow readonly wrapper around the given source.
  ShallowReadonly(this._source) {
    if (_source is! Ref<T> &&
        _source is! Computed<T> &&
        _source is! ShallowRef<T>) {
      throw ArgumentError(
        'ShallowReadonly source must be a Ref<$T>, Computed<$T>, or ShallowRef<$T>, '
        'got ${_source.runtimeType}',
      );
    }
  }

  /// The readonly value.
  T get value {
    if (_source is Ref<T>) {
      return (_source as Ref<T>).value;
    }
    if (_source is Computed<T>) {
      return (_source as Computed<T>).value;
    }
    if (_source is ShallowRef<T>) {
      return (_source as ShallowRef<T>).value;
    }
    throw StateError('Invalid shallow readonly source');
  }

  /// Get the underlying source.
  Object get source => _source;

  @override
  String toString() => 'ShallowReadonly($value)';
}
