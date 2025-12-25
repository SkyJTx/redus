# Redus Flutter

Vue-like **ReactiveWidget** for Flutter with fine-grained reactivity, lifecycle hooks, and dependency injection.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/redus_flutter.svg)](https://pub.dev/packages/redus_flutter)

## Features

- 🎯 **ReactiveWidget** - Reactive widget with auto-reactivity in `render()` (supports Flutter mixins)
- 👁️ **Observe** - Widget that watches a source and rebuilds
- ⚡ **ObserveEffect** - Widget that auto-tracks dependencies
- 🔄 **Lifecycle Hooks** - onInitState, onMounted, onDispose, etc.
- 🧩 **Composable Mixins** - LifecycleCallbacks for custom widgets
- 💉 **Dependency Injection** - Type + key-based lookup (from `redus`)
- 🧹 **Auto Cleanup** - Effect scopes tied to widget lifecycle

## Installation

```yaml
dependencies:
  redus_flutter: ^0.11.0
```

## Quick Start

### ReactiveWidget

Full reactivity with automatic dependency tracking in `render()`:

```dart
import 'package:redus_flutter/redus_flutter.dart';

class CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

class Counter extends ReactiveWidget {
  const Counter({super.key});

  @override
  ReactiveState<Counter> createState() => _CounterState();
}

class _CounterState extends ReactiveState<Counter> {
  late final CounterStore store;

  @override
  void setup() {
    store = CounterStore();
    onMounted(() => print('Count: ${store.count.value}'));
    onDispose(() => print('Cleaning up...'));
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

### ReactiveWidget with Flutter Mixins

When you need Flutter's built-in State mixins (for animations, keep-alive, etc.):

```dart
class AnimatedCounter extends ReactiveWidget {
  const AnimatedCounter({super.key});

  @override
  ReactiveState<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends ReactiveState<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Ref<int> count;

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    count = ref(0);
    onMounted(() => controller.forward());
    onDispose(() => controller.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: ElevatedButton(
        onPressed: () => count.value++,
        child: Text('Count: ${count.value}'),
      ),
    );
  }
}
```

#### Using with AutomaticKeepAliveClientMixin

Some Flutter mixins require overriding `build()`. Use `reactiveBuild()` to get full reactive functionality:

```dart
class _KeepAliveState extends ReactiveState<KeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  late final Ref<int> count;

  @override
  bool get wantKeepAlive => true;

  @override
  void setup() {
    count = ref(0);
  }

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

| Hook | When | Default Timing |
|------|------|----------------|
| `onInitState` | During initState | after |
| `onMounted` | After first frame | - |
| `onDidChangeDependencies` | When InheritedWidget deps change | after |
| `onDidUpdateWidget` | When widget props change | after |
| `onDeactivate` | Widget removed from tree | after |
| `onActivate` | Widget reinserted into tree | after |
| `onDispose` | Widget disposed | before |
| `onErrorCaptured` | Error boundary | - |

### Timing Control

All hooks support `timing` parameter for before/after control:

```dart
@override
void setup() {
  // Fire before super.initState()
  onInitState(() => print('before'), timing: LifecycleTiming.before);
  
  // Fire after super.initState() (default)
  onInitState(() => print('after'));
  
  // Fire before dispose (default for onDispose)
  onDispose(() => cleanup(), timing: LifecycleTiming.before);
  
  // Access old and new widget
  onDidUpdateWidget<MyWidget>((oldWidget, newWidget) {
    if (oldWidget.value != newWidget.value) {
      print('Value changed!');
    }
  });
}
```

## Composable Architecture

The library uses a composable mixin architecture:

```dart
// ReactiveWidget uses State-based mixins internally
class ReactiveState extends State<ReactiveWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin, 
         ReactiveStateMixin { ... }

// Use mixins in your own StatefulWidget
class _MyWidgetState extends State<MyWidget>
    with LifecycleCallbacks, LifecycleHooksStateMixin {
  
  late final MyStore store;
  
  @override
  void initState() {
    store = MyStore();
    onMounted(() => print('Mounted!'));
    onDispose(() => print('Disposing...'));
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    scheduleMountedCallbackIfNeeded();
    return Text('Value: ${store.value}');
  }
}
```

**Available mixins:**

- `LifecycleCallbacks` - Callback storage and registration
- `LifecycleHooksStateMixin` - Flutter lifecycle method overrides
- `ReactiveStateMixin` - EffectScope and reactivity for auto-tracking

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
| `Observe<T>` | Watch specific source(s), explicit dependency |
| `ObserveEffect` | Auto-track multiple dependencies in builder |
| `.watch(context)` | Simple inline reactive values in any widget |

## License

MIT License
