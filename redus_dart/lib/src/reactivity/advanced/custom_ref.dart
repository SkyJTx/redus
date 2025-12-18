/// Custom ref implementation.
library;

import '../core/dep.dart';
import '../core/ref.dart';

/// Factory function for creating a custom ref.
///
/// Receives track and trigger functions, returns get and set methods.
typedef CustomRefFactory<T> = ({T Function() get, void Function(T) set}) Function(
  void Function() track,
  void Function() trigger,
);

/// Creates a customized ref with explicit control over dependency tracking.
///
/// The factory function receives `track` and `trigger` functions:
/// - Call `track()` in `get` to track dependencies
/// - Call `trigger()` in `set` to trigger updates
///
/// Example - Debounced Ref:
/// ```dart
/// Ref<T> useDebouncedRef<T>(T initialValue, {Duration delay = Duration(milliseconds: 200)}) {
///   var value = initialValue;
///   Timer? timeout;
///
///   return customRef((track, trigger) => (
///     get: () {
///       track();
///       return value;
///     },
///     set: (newValue) {
///       timeout?.cancel();
///       timeout = Timer(delay, () {
///         value = newValue;
///         trigger();
///       });
///     },
///   ));
/// }
/// ```
Ref<T> customRef<T>(CustomRefFactory<T> factory) {
  return _CustomRef<T>(factory);
}

/// Internal custom ref implementation.
class _CustomRef<T> implements Ref<T> {
  final Dep _customDep = Dep();
  late final T Function() _actualGetter;
  late final void Function(T) _actualSetter;

  _CustomRef(CustomRefFactory<T> factory) {
    final methods = factory(
      () => _customDep.track(),
      () => _customDep.trigger(),
    );
    _actualGetter = methods.get;
    _actualSetter = methods.set;
  }

  @override
  T get value => _actualGetter();

  @override
  set value(T newValue) => _actualSetter(newValue);

  @override
  T get raw => _actualGetter();

  @override
  void update(T Function(T current) updater) {
    value = updater(value);
  }

  @override
  void trigger() {
    _customDep.trigger();
  }

  @override
  String toString() => 'CustomRef($value)';
}
