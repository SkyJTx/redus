/// Raw value utilities.
library;

import '../core/computed.dart';
import '../core/ref.dart';
import '../core/readonly.dart';
import 'shallow.dart';

/// Expando to track objects marked as raw.
final Expando<bool> _rawMarker = Expando<bool>('rawMarker');

/// Returns the raw, original value from a reactive wrapper.
///
/// Works with Ref, ShallowRef, Computed, and Readonly.
/// For non-reactive values, returns the value as-is.
///
/// Example:
/// ```dart
/// final count = ref(42);
/// toRaw(count); // 42
///
/// final obj = ref({'a': 1});
/// toRaw(obj); // {'a': 1}
/// ```
T toRaw<T>(Object? value) {
  if (value is Ref<T>) {
    return value.raw;
  }
  if (value is ShallowRef<T>) {
    return value.raw;
  }
  if (value is Computed<T>) {
    return value.value;
  }
  if (value is Readonly<T>) {
    return toRaw<T>(value.source);
  }
  return value as T;
}

/// Marks an object so that it will never be converted to a reactive proxy.
///
/// Returns the object itself.
///
/// Example:
/// ```dart
/// final rawObj = markRaw({'count': 0});
/// final r = ref(rawObj);
/// // rawObj is still the same object, not wrapped
/// ```
T markRaw<T extends Object>(T value) {
  _rawMarker[value] = true;
  return value;
}

/// Check if an object is marked as raw.
///
/// Example:
/// ```dart
/// final obj = {'a': 1};
/// isMarkedRaw(obj); // false
///
/// markRaw(obj);
/// isMarkedRaw(obj); // true
/// ```
bool isMarkedRaw(Object? value) {
  if (value == null) return false;
  return _rawMarker[value] == true;
}
