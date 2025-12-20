# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.3] - 2025-12-20

### Fixed

- Code formatting issues across library and test files

## [0.4.2] - 2025-12-20

### Fixed

- Code formatting issues across library and test files

## [0.4.1] - 2025-12-19

### Fixed

- Updated README to reflect redus as dev utility package (not just reactivity)
- Added complete DI module documentation to CHANGELOG and README

## [0.4.0] - 2025-12-19

### Added

- **Dependency Injection Module** (`package:redus/di.dart`)
  - `register<T>(instance, {key})` - Register singleton with optional key
  - `registerFactory<T>(factory, {key})` - Register factory with optional key
  - `get<T>({key})` - Get registered instance by type and optional key
  - `isRegistered<T>({key})` - Check if type/key is registered
  - `unregister<T>({key})` - Remove registration
  - `resetLocator()` - Clear all registrations

- **Key-based Lookup** - Register multiple instances of same type with different keys

  ```dart
  register<Logger>(ConsoleLogger(), key: #console);
  register<Logger>(FileLogger(), key: #file);
  final log = get<Logger>(key: #console);
  ```

### Changed

- **Package Scope Expanded** - Redus is now a dev utility package with multiple modules:
  - `package:redus/reactivity.dart` - Fine-grained reactivity system
  - `package:redus/di.dart` - Dependency injection
  - `package:redus/redus.dart` - All modules combined

## [0.3.0] - 2025-12-19

### Added

- **Callable Ref and Computed** - Both `Ref<T>` and `Computed<T>` now have a `call()` method
  - `count()` is equivalent to `count.value`
  - Allows `Ref<T>` and `Computed<T>` to be used as `T Function()`
  - Enables **perfect type inference** in `watch()` and other APIs

### Changed

- **Strongly typed `watch()` API** - Source is now `T Function()` instead of `Object`
  - Type inference works automatically: `watch(count, (val, old, _) => ...)` infers `T` as `int`
  - No more need for explicit `watch<int>(...)` calls
  - Both `Ref` and `Computed` work directly as sources (since they're callable)
  - Getter functions `() => x.value` also work with full inference

- **Strongly typed `watchMultiple()` API** - Sources are now `List<T Function()>`

## [0.2.0] - 2025-12-19

### Added

- **Flutter Integration Support**
  - Exported `ReactiveEffect` class for custom effect creation
  - Exported `activeEffect` and `effectStack` for render tracking
  - Enables automatic UI reactivity in redus_flutter without manual watchEffect

### Changed

- Removed `@internal` annotations from `activeEffect` and `effectStack`

## [0.1.0] - 2025-12-18

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
