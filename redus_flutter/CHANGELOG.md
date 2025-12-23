# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
