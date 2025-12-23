# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.1] - 2025-12-23

### Fixed

- **Documentation** - Updated all docstring examples in source files to use the new `(context)` parameter signature for lifecycle hooks.

## [0.7.0] - 2025-12-23

### Changed (BREAKING)

- **Lifecycle hooks now receive `BuildContext`** - All lifecycle callbacks (`onMounted`, `onUpdated`, `onUnmounted`, etc.) now receive `BuildContext` as a parameter, enabling access to InheritedWidgets like `Theme`, `MediaQuery`, and `Navigator`.

  **Migration:**

  ```dart
  // Before
  onMounted(() => print('Mounted!'));
  
  // After
  onMounted((context) => print('Mounted!'));
  // Or if context not needed:
  onMounted((_) => print('Mounted!'));
  ```

### Added

- **Context access in lifecycle hooks** - Developers can now access Flutter's InheritedWidget system directly:

  ```dart
  onMounted((context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
  });
  
  onDependenciesChanged((context) {
    // React to theme/locale/media changes
    final brightness = Theme.of(context).brightness;
  });
  ```

---

## [0.6.0] - 2025-12-23

### Added

- **`BindMixin`** - Decoupled `bind()` into a composable mixin
  - Can be used with custom widgets for flexible state persistence
  - Similar pattern to `LifecycleHooks` mixin
  
- **`BindableElementMixin`** - State storage mixin for custom elements
  - Provides index-based state storage
  - Handles bind index reset on widget recreation
  
- **`BindableElement`** - Base element class for bind-supporting widgets
  - `ReactiveElement` now extends `BindableElement`
  
- **`BindWidget`** - Lightweight alternative to `ReactiveWidget`
  - Provides `bind()` and lifecycle hooks
  - No automatic reactivity in `build()` (use `Observe`/`ObserveEffect`)
  - Simpler mental model with explicit reactivity control

- **`onDependenciesChanged`** - Lifecycle hook for InheritedWidget changes
  - Called when MediaQuery, Theme, Locale, etc. change
  - Triggered before processing the change
  
- **`onAfterDependenciesChanged`** - Lifecycle hook after dependency processing
  - Called after processing InheritedWidget changes

### Changed

- **`ReactiveWidget` refactored** - Now composed of:
  - `BindMixin` - for `bind()` API
  - `LifecycleHooks` - for lifecycle callbacks
  - Automatic reactivity in `render()`
  
- **Architecture** - Modular, composable architecture allows:
  - `ReactiveWidget` = BindMixin + LifecycleHooks + auto-reactivity
  - `BindWidget` = BindMixin + LifecycleHooks (no auto-reactivity)
  - Custom widgets can use mixins directly

## [0.5.2] - 2025-12-23

### Fixed

- **Lifecycle callback accumulation** - Fixed issue where `onMounted` and other lifecycle callbacks would accumulate when the same widget instance was reused across navigations. Callbacks are now cleared on unmount.
- **Updated to redus ^0.4.4** - Includes fix for effects not being stopped when scope stops, preventing timer accumulation.

## [0.5.1] - 2025-12-23

### Fixed

- **bind() type mismatch bug** - Fixed `TypeError` when using `bind()` with multiple `Ref` types and `watch()` in `setup()`. The issue occurred when fields were accessed in different phases (setup vs render), causing incorrect index assignment. Now correctly tracks widget instances to reset indices only on widget recreation.

## [0.5.0] - 2025-12-20

### Added

- **`Observe<T>` widget** - Watches a reactive source and rebuilds when it changes
  - Takes a `source` function (Ref, Computed, or getter)
  - Similar to `watch()` but as a widget
  - Only rebuilds when source value changes

- **`ObserveMultiple<T>` widget** - Watches multiple sources
  - Takes list of `sources`
  - Rebuilds when any source changes

- **`ObserveEffect` widget** - Auto-tracks reactive dependencies
  - Similar to `watchEffect()` but as a widget
  - Tracks any `.value` access in builder
  - Most fine-grained reactivity option

### Changed

- **Folder restructure**: Renamed `component/` to `widget/`
- **File split**: Split into individual files:
  - `reactive_widget.dart` - ReactiveWidget + ReactiveElement
  - `observe.dart` - Observe + ObserveMultiple widgets
  - `observe_effect.dart` - ObserveEffect widget
  - `lifecycle.dart` - Lifecycle hooks mixin

## [0.4.0] - 2025-12-20

### Added

- **`bind<T>()` API** - New simpler way to bind state to Element
  - `late final store = bind(() => MyStore())` - Bind stores or any value
  - Index-based storage - no Symbol keys needed
  - State persists across parent widget rebuilds
  - Supports store pattern for encapsulated business logic

### Removed

- **`state()` and `getState()` methods** - Replaced by `bind()`

## [0.3.1] - 2025-12-19

### Fixed

- Updated README with new `ReactiveWidget` API and `.watch(context)` documentation

## [0.3.0] - 2025-12-19

### Added

- **ReactiveWidget** - New single-class component design
- **.watch(context) Extension** - Fine-grained reactivity for any widget
- **DI Moved to redus_dart** - Dependency injection from `package:redus/di.dart`

## [0.2.0] - 2025-12-19

### Changed

- **Automatic Reactivity** - `render()` now automatically tracks reactive dependencies

## [0.1.0] - 2025-12-18

### Added

- Initial release with Component, Lifecycle Hooks, and DI
