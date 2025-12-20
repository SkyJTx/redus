/// Reactivity utility functions.
library;

import '../core/computed.dart';
import '../core/ref.dart';
import '../core/readonly.dart';
import '../advanced/shallow.dart';

/// Check if a value is a [Ref].
///
/// Example:
/// ```dart
/// final count = ref(0);
/// isRef(count);  // true
/// isRef(5);      // false
/// ```
bool isRef(Object? value) => value is Ref;

/// Unwrap a Ref to get its value, or return the value as-is if not a Ref.
///
/// Example:
/// ```dart
/// final r = ref(42);
/// unref(r);   // 42
/// unref(100); // 100
/// ```
T unref<T>(Object? maybeRef) {
  if (maybeRef is Ref<T>) {
    return maybeRef.value;
  }
  return maybeRef as T;
}

/// Normalizes values/refs/getters to values.
///
/// - If argument is a ref, returns its value
/// - If argument is a getter function, invokes it and returns the result
/// - Otherwise returns the value as-is
///
/// Example:
/// ```dart
/// toValue(1);           // 1
/// toValue(ref(1));      // 1
/// toValue(() => 1);     // 1
/// ```
T toValue<T>(Object source) {
  if (source is Ref<T>) {
    return source.value;
  }
  if (source is T Function()) {
    return source();
  }
  return source as T;
}

/// Normalizes value/ref/getter to a Ref.
///
/// - Returns existing refs as-is
/// - Creates a readonly computed ref for getter functions
/// - Creates a normal ref for plain values
///
/// Example:
/// ```dart
/// toRef(existingRef);    // returns existingRef
/// toRef(() => foo.bar);  // creates computed ref
/// toRef(1);              // creates ref(1)
/// ```
Ref<T> toRef<T>(Object source) {
  if (source is Ref<T>) {
    return source;
  }
  if (source is T Function()) {
    // Create a computed ref for getter functions
    return _GetterRef<T>(source);
  }
  return ref<T>(source as T);
}

/// Internal ref that wraps a getter function.
class _GetterRef<T> extends Ref<T> {
  final T Function() _getter;

  _GetterRef(this._getter) : super(_getter());

  @override
  T get value => _getter();

  @override
  set value(T newValue) {
    throw UnsupportedError('Cannot set value on a getter-based ref');
  }
}

/// Converts a Map to a Map of Refs.
///
/// Each property of the resulting map is a ref pointing to the
/// corresponding property of the original map.
///
/// Example:
/// ```dart
/// final state = {'foo': 1, 'bar': 2};
/// final refs = toRefs(state);
/// refs['foo']!.value; // 1
/// ```
Map<String, Ref<T>> toRefs<T>(Map<String, T> source) {
  return source.map((key, value) => MapEntry(key, ref(value)));
}

/// Check if a value is a reactive proxy (Ref, Computed, Readonly, ShallowRef).
///
/// Example:
/// ```dart
/// isProxy(ref(1));      // true
/// isProxy(computed(...)); // true
/// isProxy(5);           // false
/// ```
bool isProxy(Object? value) {
  return value is Ref ||
      value is Computed ||
      value is Readonly ||
      value is ShallowRef;
}

/// Check if a value is reactive (Ref, Computed, or ShallowRef).
///
/// Example:
/// ```dart
/// isReactive(ref(1));      // true
/// isReactive(computed(...)); // true
/// isReactive(readonly(...)); // false (readonly is not reactive itself)
/// ```
bool isReactive(Object? value) {
  return value is Ref || value is Computed || value is ShallowRef;
}

/// Check if a value is readonly (Readonly or read-only Computed).
///
/// Example:
/// ```dart
/// isReadonly(readonly(ref(1))); // true
/// isReadonly(computed(...));    // true (computed is readonly)
/// isReadonly(ref(1));           // false
/// ```
bool isReadonly(Object? value) {
  if (value is Readonly) return true;
  if (value is Computed && value is! WritableComputed) return true;
  return false;
}
