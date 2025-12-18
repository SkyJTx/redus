/// Advanced reactivity exports.
///
/// This barrel file exports advanced reactivity features:
/// - [shallowRef] / [ShallowRef] - Shallow reactive reference
/// - [triggerRef] - Force trigger shallow ref
/// - [shallowReadonly] - Shallow readonly wrapper
/// - [customRef] - Custom ref with track/trigger control
/// - [toRaw] / [markRaw] - Raw value utilities
/// - [effectScope] / [getCurrentScope] / [onScopeDispose] - Effect scoping
library;

export 'shallow.dart';
export 'custom_ref.dart';
export 'raw.dart';
export 'scope.dart';
