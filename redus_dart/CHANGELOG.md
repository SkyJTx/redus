# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-19

### Added

- **Flutter Integration Support**
  - Exported `ReactiveEffect` class for custom effect creation
  - Exported `activeEffect` and `effectStack` for render tracking
  - Enables automatic UI reactivity in redus_flutter without manual watchEffect

### Changed

- Removed `@internal` annotations from `activeEffect` and `effectStack`

## [0.1.0] - 2024-12-18

### Added

- **Core Reactivity** (`src/reactivity/core/`)
  - `ref<T>()` - Mutable reactive reference with `.value` accessor
  - `computed<T>()` - Lazily evaluated, cached computed values
  - `writableComputed<T>()` - Computed values with custom setters
  - `readonly<T>()` - Read-only wrapper preserving reactivity
  - `watchEffect()` - Immediate effect with dependency tracking
  - `watchPostEffect()` / `watchSyncEffect()` - Flush timing variants
  - `watch()` / `watchMultiple()` - Explicit source watching
  - `onWatcherCleanup()` - Register cleanup in effects
  - `WatchHandle` with `stop()`, `pause()`, `resume()`
  - `Scheduler` for batching with pre/post/sync flush modes

- **Utilities** (`src/reactivity/utilities/`)
  - `isRef()` - Check if value is Ref
  - `unref<T>()` - Unwrap ref or return value
  - `toRef<T>()` - Normalize value/getter to ref
  - `toValue<T>()` - Normalize ref/getter to value
  - `toRefs<T>()` - Convert map to refs
  - `isProxy()` / `isReactive()` / `isReadonly()` - Type checking

- **Advanced** (`src/reactivity/advanced/`)
  - `shallowRef<T>()` - Shallow reactive ref (no deep tracking)
  - `triggerRef()` - Force trigger shallow ref
  - `shallowReadonly<T>()` - Shallow readonly wrapper
  - `customRef<T>()` - Custom ref with track/trigger control
  - `toRaw<T>()` - Get underlying value from reactive
  - `markRaw<T>()` / `isMarkedRaw()` - Prevent reactivity
  - `effectScope()` - Group effects for disposal
  - `getCurrentScope()` - Get active effect scope
  - `onScopeDispose()` - Register scope cleanup

### Package Structure

Reorganized into three modules:

- `core/` - Core reactive primitives and effects
- `utilities/` - Helper functions
- `advanced/` - Advanced features
