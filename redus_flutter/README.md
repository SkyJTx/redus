# Redus Flutter

Vue-like **ReactiveWidget** for Flutter with fine-grained reactivity, lifecycle hooks, and dependency injection.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/redus_flutter.svg)](https://pub.dev/packages/redus_flutter)

## Features

- 🎯 **ReactiveWidget** - Single-class component with state on Element and auto-reactivity
- 🔗 **BindWidget** - Lightweight widget with bind() and lifecycle (no auto-reactivity)
- 👁️ **Observe** - Widget that watches a source and rebuilds
- ⚡ **ObserveEffect** - Widget that auto-tracks dependencies
- 🔄 **Lifecycle Hooks** - onMounted, onUpdated, onUnmounted, etc.
- 🧩 **Composable Mixins** - BindMixin, LifecycleHooks for custom widgets
- 🔧 **State Mixins** - LifecycleHooksStateMixin, ReactiveProviderStateMixin for StatefulWidget
- 💉 **Dependency Injection** - Type + key-based lookup (from `redus`)
- 🧹 **Auto Cleanup** - Effect scopes tied to widget lifecycle

## Installation

```yaml
dependencies:
  redus_flutter: ^0.8.0
```

## Quick Start

### ReactiveWidget with `bind()`

Full reactivity with automatic dependency tracking in `render()`:

```dart
import 'package:redus_flutter/redus_flutter.dart';

class CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

class Counter extends ReactiveWidget {
  late final store = bind(() => CounterStore());

  @override
  void setup() {
    onMounted((context) => print('Count: ${store.count.value}'));
  }

  @override
  Widget render(BuildContext context) {
    // Auto-tracks store.count.value - rebuilds automatically
    return ElevatedButton(
      onPressed: store.increment,
      child: Text('Count: ${store.count.value}'),
    );
  }
}
```

### BindWidget (Explicit Reactivity)

Lightweight widget with `bind()` and lifecycle, but **no auto-reactivity**. Use `Observe`/`ObserveEffect` for reactive parts:

```dart
class Counter extends BindWidget {
  late final count = bind(() => ref(0));

  @override
  void setup() {
    onMounted((_) => print('Mounted!'));
  }

  @override
  Widget build(BuildContext context) {
    // Use Observe for reactive parts
    return Observe<int>(
      source: count.call,
      builder: (_, value) => ElevatedButton(
        onPressed: () => count.value++,
        child: Text('Count: $value'),
      ),
    );
  }
}
```

### Observe Widget

`Observe` watches a reactive source (like `watch()`) and rebuilds when it changes:

```dart
final count = ref(0);

// Watch a Ref directly
Observe<int>(
  source: count,
  builder: (context, value) => Text('Count: $value'),
)

// Watch a derived value
Observe<int>(
  source: () => count.value * 2,
  builder: (context, doubled) => Text('Doubled: $doubled'),
)

// Watch multiple sources
ObserveMultiple<String>(
  sources: [firstName, lastName],
  builder: (context, values) => Text('${values[0]} ${values[1]}'),
)
```

### ObserveEffect Widget

`ObserveEffect` auto-tracks any reactive values (like `watchEffect()`):

```dart
final count = ref(0);
final name = ref('Alice');

// Auto-tracks all .value accesses
ObserveEffect(
  builder: (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      Text('Name: ${name.value}'),
    ],
  ),
)
```

### Fine-Grained `.watch(context)`

Use `.watch(context)` in any widget for automatic rebuilds:

```dart
class MyStatelessWidget extends StatelessWidget {
  final Ref<int> count;
  
  @override
  Widget build(BuildContext context) {
    // Only THIS widget rebuilds when count changes
    return Text('Count: ${count.watch(context)}');
  }
}
```

## Lifecycle Hooks

| Hook | When |
|------|------|
| `onMounted` | After first build |
| `onUpdated` | After rebuild |
| `onUnmounted` | After dispose |
| `onBeforeMount` | Before first build |
| `onBeforeUpdate` | Before rebuild |
| `onBeforeUnmount` | Before dispose |
| `onDependenciesChanged` | When InheritedWidget deps change |
| `onAfterDependenciesChanged` | After processing dep changes |
| `onErrorCaptured` | Error boundary |
| `onActivated` | Widget activated |
| `onDeactivated` | Widget deactivated |

All lifecycle callbacks receive `BuildContext` as a parameter, allowing access to InheritedWidgets:

```dart
@override
void setup() {
  onMounted((context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    print('Mounted with screen width: ${size.width}');
  });

  onDependenciesChanged((context) {
    // React to theme, locale, or media query changes
    final brightness = Theme.of(context).brightness;
    print('Theme changed to: $brightness');
  });
  
  // Use underscore if context not needed
  onUpdated((_) => print('Widget updated'));
}
```

## Composable Architecture

The library uses a composable mixin architecture:

```dart
// ReactiveWidget = BindMixin + LifecycleHooks + auto-reactivity
abstract class ReactiveWidget extends Widget with BindMixin, LifecycleHooks { ... }

// BindWidget = BindMixin + LifecycleHooks (no auto-reactivity)
abstract class BindWidget extends Widget with BindMixin, LifecycleHooks { ... }

// Custom widget with just bind()
class MyWidget extends Widget with BindMixin {
  late final state = bind(() => MyState());
  // ...
}
```

## State Mixins for StatefulWidget

Use lifecycle hooks and reactivity with standard `StatefulWidget`:

```dart
class _MyWidgetState extends State<MyWidget>
    with LifecycleHooksStateMixin, ReactiveProviderStateMixin {

  late final count = ref(0);

  @override
  void setup() {
    onMounted((context) => print('Mounted!'));
    onUnmounted((context) => print('Unmounted!'));

    watchEffect((onCleanup) {
      print('Count changed: ${count.value}');
    });
  }

  @override
  Widget build(BuildContext context) {
    scheduleLifecycleCallbacks();
    return Text('Count: ${count.value}');
  }
}
```

**Available mixins:**

- `LifecycleHooksStateMixin` - Lifecycle hooks (`onMounted`, `onUnmounted`, etc.)
- `ReactiveProviderStateMixin` - `EffectScope` for `watchEffect()`, `watch()` with auto-cleanup

## Dependency Injection

DI comes from `redus` package with key support:

```dart
// By type
register<ApiService>(ApiService());
final api = get<ApiService>();

// By key (multiple instances)
register<Logger>(ConsoleLogger(), key: #console);
register<Logger>(FileLogger(), key: #file);
final log = get<Logger>(key: #console);
```

## When to Use What

| Widget | Use When |
|--------|----------|
| `ReactiveWidget` | Full component with auto-reactivity, lifecycle, stores |
| `BindWidget` | State persistence + lifecycle, explicit reactivity control |
| `Observe<T>` | Watch specific source(s), explicit dependency |
| `ObserveEffect` | Auto-track multiple dependencies in builder |
| `.watch(context)` | Simple inline reactive values in any widget |

## License

MIT License
