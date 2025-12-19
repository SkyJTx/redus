# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-19

### Changed

- **Automatic Reactivity** - `render()` now automatically tracks reactive dependencies
  - No more manual `watchEffect` + `rebuild()` needed in `setup()`
  - Accessing `Ref.value` or `Computed.value` in `render()` auto-triggers rebuilds when they change
  - Similar to Vue's template reactivity

- **Removed `rebuild()` method** - No longer needed with automatic tracking

### Dependencies

- Updated to `redus: ^0.3.0` with callable `Ref` and `Computed`
  - `count()` is now equivalent to `count.value`
  - Strongly typed `watch()` API with proper type inference

## [0.1.0] - 2024-12-18

### Added

- **Component Base Class** (`src/component/`)
  - Vue-like `Component` extending `StatefulWidget`
  - `setup()` method for reactive state initialization
  - `render()` method replacing `build()`
  - `rebuild()` method to trigger component update

- **Lifecycle Hooks** (`src/component/lifecycle.dart`)
  - `onBeforeMount` - Before first build
  - `onMounted` - After first build
  - `onBeforeUpdate` - Before rebuild
  - `onUpdated` - After rebuild
  - `onBeforeUnmount` - Before dispose
  - `onUnmounted` - After dispose
  - `onErrorCaptured` - Error boundary
  - `onActivated` / `onDeactivated` - Route visibility
  - `onRenderTracked` / `onRenderTriggered` - Debug hooks

- **Dependency Injection** (`src/di/service_locator.dart`)
  - `register<T>()` - Register singleton
  - `registerFactory<T>()` - Register factory
  - `get<T>()` - Get instance
  - `isRegistered<T>()` - Check registration
  - `unregister<T>()` - Remove registration
  - `resetServiceLocator()` - Clear all

### Dependencies

- Built on `redus` reactivity system
- Re-exports all `redus` APIs for convenience
