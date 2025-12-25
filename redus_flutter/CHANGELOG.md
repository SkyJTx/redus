# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.0] - 2025-12-25

### Breaking Changes

- **Renamed `ReactiveStatefulWidget` to `ReactiveWidget`** - The widget that supports Flutter mixins is now the primary reactive widget.

- **Renamed `ReactiveWidgetState` to `ReactiveState`** - The State class is now named `ReactiveState`.

- **Removed old `ReactiveWidget`** - The old single-class `ReactiveWidget` has been removed. Use the new `ReactiveWidget` with `ReactiveState`.

- **Removed `bind()` functionality** - The `bind()` method and `BindStateMixin` have been removed. Initialize your stores and refs in `setup()` instead.

  **Migration:**

  ```dart
  // Before (old ReactiveWidget with bind)
  class Counter extends OldReactiveWidget {
    late final count = bind(() => ref(0));
    late final store = bind(() => MyStore());
    
    @override
    Widget render(BuildContext context) => Text('${count.value}');
  }

  // After (new ReactiveWidget without bind)
  class Counter extends ReactiveWidget {
    const Counter({super.key});

    @override
    ReactiveState<Counter> createState() => _CounterState();
  }

  class _CounterState extends ReactiveState<Counter> {
    late final Ref<int> count;
    late final MyStore store;

    @override
    void setup() {
      count = ref(0);
      store = MyStore();
    }

    @override
    Widget render(BuildContext context) => Text('${count.value}');
  }
  ```

---

## [0.10.2] - 2025-12-25

### Added

- **`@mustCallSuper` annotations** - Properly annotated on all overridable lifecycle methods in `ReactiveState` and `ReactiveWidgetState`:
  - `initState()` - Ensures setup and scope initialization
  - `didUpdateWidget()` - Ensures bind index reset on widget recreation
  - `activate()` - Ensures state expando is updated (ReactiveState only)
  - `dispose()` - Ensures reactivity cleanup and scope disposal
  - `build()` / `reactiveBuild()` - Ensures reactive tracking and mounted callbacks

  This ensures subclasses correctly call `super` to maintain proper lifecycle behavior.

---

## [0.10.1] - 2025-12-24

### Added

- **`reactiveBuild(BuildContext context)`** - New helper method in `ReactiveWidgetState` that encapsulates all reactive build logic. Makes it easier to override `build()` for compatibility with Flutter mixins:

  ```dart
  class _KeepAliveState extends ReactiveWidgetState<KeepAliveWidget>
      with AutomaticKeepAliveClientMixin {
    
    @override
    bool get wantKeepAlive => true;

    @override
    Widget build(BuildContext context) {
      super.build(context); // Required for the mixin
      return reactiveBuild(context); // Full reactive functionality!
    }

    @override
    Widget render(BuildContext context) {
      return Text('Count: ${count.value}');
    }
  }
  ```

  The method handles:
  - Error state checking
  - Reactive dependency tracking via `buildReactive`
  - Error catching and `onErrorCaptured` callback invocation
  - Scheduling `onMounted` callbacks

---

## [0.10.0] - 2025-12-24

### Added

- **`ReactiveStatefulWidget` and `ReactiveWidgetState<T>`** - New widget and state base class that supports Flutter's built-in State mixins:

  ```dart
  class AnimatedCounter extends ReactiveStatefulWidget {
    @override
    ReactiveWidgetState<AnimatedCounter> createState() => _AnimatedCounterState();
  }

  class _AnimatedCounterState extends ReactiveWidgetState<AnimatedCounter>
      with SingleTickerProviderStateMixin {  // ✅ Flutter mixin works!
    late final controller = AnimationController(vsync: this);
    late final count = bind(() => ref(0));

    @override
    void setup() {
      onMounted(() => controller.forward());
      onDispose(() => controller.dispose());
    }

    @override
    Widget render(BuildContext context) {
      return Text('Count: ${count.value}');
    }
  }
  ```

  Supported Flutter mixins include:
  - `SingleTickerProviderStateMixin` - For single animations
  - `TickerProviderStateMixin` - For multiple animations
  - `AutomaticKeepAliveClientMixin` - For keeping widget alive in lists
  - `RestorationMixin` - For state restoration
  - `WidgetsBindingObserver` - For app lifecycle events

---

## [0.9.0] - 2025-12-24

### Changed (BREAKING)

- **Lifecycle hooks simplified** - Removed `(context)` parameter from lifecycle callbacks for cleaner API:

  ```dart
  // Before
  onMounted((context) => print('Mounted!'));
  
  // After
  onMounted(() => print('Mounted!'));
  ```

- **Lifecycle hook names changed** to match Flutter semantics:

  | Old Name | New Name |
  |----------|----------|
  | `onBeforeMount` | `onInitState` with `timing: before` |
  | `onBeforeUpdate` | `onDidUpdateWidget` with `timing: before` |
  | `onUpdated` | `onDidUpdateWidget` with `timing: after` |
  | `onBeforeUnmount` | `onDispose` with `timing: before` |
  | `onUnmounted` | `onDispose` with `timing: after` |
  | `onActivated` | `onActivate` |
  | `onDeactivated` | `onDeactivate` |
  | `onDependenciesChanged` | `onDidChangeDependencies` |

- **`ReactiveWidget` now uses `StatefulWidget`** internally:
  - State and lifecycle managed by `State` class internally
  - Developer API unchanged: `setup()`, `render(BuildContext)`, `bind()`, lifecycle hooks
  - More robust lifecycle handling, especially across parent rebuilds

### Removed

- **`BindWidget` removed** - Use `ReactiveWidget` with `Observe`/`ObserveEffect` for explicit reactivity control

### Added

- **Timing control for lifecycle hooks** - All hooks support `timing` parameter:

  ```dart
  onInitState(() => print('before'), timing: LifecycleTiming.before);
  onInitState(() => print('after')); // default: after
  ```

- **`onDidUpdateWidget` receives old and new widget**:

  ```dart
  onDidUpdateWidget<MyWidget>((oldWidget, newWidget) {
    if (oldWidget.value != newWidget.value) {
      // Handle prop change
    }
  });
  ```

- **Consolidated mixins architecture**:
  - `LifecycleCallbacks` - Callback storage and registration
  - `LifecycleHooksStateMixin` - Flutter lifecycle method overrides
  - `BindStateMixin` - State persistence via `bind()`
  - `ReactiveStateMixin` - Reactivity and effect scope

---

## [0.8.0] - 2025-12-24

### Added

- **`LifecycleHooksStateMixin`** - Vue-like lifecycle hooks for standard `State<T>` classes
  - `onMounted`, `onBeforeUnmount`, `onUnmounted`
  - `onActivated`, `onDeactivated`
  - `onDependenciesChanged`, `onAfterDependenciesChanged`
  - Works with regular `StatefulWidget`

- **`ReactiveProviderStateMixin`** - EffectScope and reactivity for `State<T>` classes
  - Provides `setup()` method for initialization
  - Creates `EffectScope` for automatic cleanup
  - Works with `watchEffect()`, `watch()`, `computed()`

### Changed

- **Code restructured** into semantic folders:
  - `src/extensions/` - Extension methods (`.watch()`)
  - `src/mixins/` - Mixin classes (`BindMixin`, `LifecycleHooks`, `*StateMixin`)
  - `src/widgets/` - Widget classes (`ReactiveWidget`, `BindWidget`, `Observe`, `ObserveEffect`)
  
- **Barrel file imports** - All modules now have barrel files for cleaner imports

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
