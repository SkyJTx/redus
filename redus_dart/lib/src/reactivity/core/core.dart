/// Core reactivity exports.
///
/// This barrel file exports all core reactivity primitives:
/// - [ref] / [Ref] - Mutable reactive reference
/// - [computed] / [Computed] - Derived reactive value
/// - [readonly] / [Readonly] - Read-only wrapper
/// - Watch APIs: [watchEffect], [watch], etc.
library;

export 'types.dart';
export 'ref.dart';
export 'computed.dart';
export 'readonly.dart';
export 'effect.dart'
    show onWatcherCleanup, Scheduler, ReactiveEffect, activeEffect, effectStack;
export 'watch.dart' hide activeEffect, effectStack;
