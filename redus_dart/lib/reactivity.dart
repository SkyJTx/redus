/// Fine-grained reactivity system inspired by Vue's Composition API.
///
/// This library provides three modules:
///
/// **Core** - Reactive primitives and effects:
/// - [ref] / [Ref] - Mutable reactive reference
/// - [computed] / [Computed] - Derived reactive value
/// - [readonly] / [Readonly] - Read-only wrapper
/// - [watchEffect] / [watch] - Effect tracking
///
/// **Utilities** - Helper functions:
/// - [isRef] / [unref] / [toRef] / [toValue] / [toRefs]
/// - [isProxy] / [isReactive] / [isReadonly]
///
/// **Advanced** - Advanced features:
/// - [shallowRef] / [triggerRef] / [shallowReadonly]
/// - [customRef] - Custom ref with track/trigger control
/// - [toRaw] / [markRaw] - Raw value utilities
/// - [effectScope] / [getCurrentScope] / [onScopeDispose]
library reactivity;

// Core exports
export 'src/reactivity/core/core.dart';

// Utilities exports
export 'src/reactivity/utilities/utilities.dart';

// Advanced exports
export 'src/reactivity/advanced/advanced.dart';
