/// Readonly reactive wrapper implementation.
library;

import 'computed.dart';
import 'ref.dart';

/// Creates a readonly proxy of a reactive value.
///
/// The readonly wrapper still tracks dependencies when read,
/// but prevents mutations.
///
/// Example:
/// ```dart
/// final original = ref(0);
/// final copy = readonly(original);
///
/// print(copy.value); // 0, and tracks dependency
///
/// // This will throw:
/// // copy.value = 1; // Error!
///
/// // But updating original still works:
/// original.value = 1;
/// print(copy.value); // 1
/// ```
Readonly<T> readonly<T>(Object source) => Readonly<T>(source);

/// A readonly wrapper around a reactive value.
///
/// Provides read-only access to a [Ref] or [Computed] while still
/// participating in dependency tracking.
class Readonly<T> {
  final Object _source;

  /// Creates a readonly wrapper around the given source.
  ///
  /// The source must be a [Ref<T>] or [Computed<T>].
  Readonly(this._source) {
    if (_source is! Ref<T> && _source is! Computed<T>) {
      throw ArgumentError(
        'Readonly source must be a Ref<$T> or Computed<$T>, '
        'got ${_source.runtimeType}',
      );
    }
  }

  /// The readonly value.
  ///
  /// Reading this property tracks the current effect as a dependency.
  /// The value cannot be set through this wrapper.
  T get value {
    if (_source is Ref<T>) {
      return (_source as Ref<T>).value;
    }
    if (_source is Computed<T>) {
      return (_source as Computed<T>).value;
    }
    throw StateError('Invalid readonly source');
  }

  /// Get the underlying source (for internal use).
  Object get source => _source;

  @override
  String toString() => 'Readonly($value)';
}

/// Extension to create readonly from Ref.
extension ReadonlyRef<T> on Ref<T> {
  /// Create a readonly view of this ref.
  Readonly<T> asReadonly() => Readonly<T>(this);
}

/// Extension to create readonly from Computed.
extension ReadonlyComputed<T> on Computed<T> {
  /// Create a readonly view of this computed.
  Readonly<T> asReadonly() => Readonly<T>(this);
}
