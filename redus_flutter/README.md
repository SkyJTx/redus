# Redus Flutter

Vue-like **ReactiveWidget** for Flutter with fine-grained reactivity, lifecycle hooks, and dependency injection.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/redus_flutter.svg)](https://pub.dev/packages/redus_flutter)

## Features

- 🎯 **ReactiveWidget** - Single-class component with state on Element
- 👁️ **Observe** - Widget that watches a source and rebuilds
- ⚡ **ObserveEffect** - Widget that auto-tracks dependencies
- 🔄 **Lifecycle Hooks** - onMounted, onUpdated, onUnmounted, etc.
- 💉 **Dependency Injection** - Type + key-based lookup (from `redus`)
- 🧹 **Auto Cleanup** - Effect scopes tied to widget lifecycle

## Installation

```yaml
dependencies:
  redus_flutter: ^0.5.0
```

## Quick Start

### ReactiveWidget with `bind()`

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
    onMounted(() => print('Count: ${store.count.value}'));
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: store.increment,
      child: Text('Count: ${store.count.value}'),
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
| `onErrorCaptured` | Error boundary |
| `onActivated` | Widget activated |
| `onDeactivated` | Widget deactivated |

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
| `ReactiveWidget` | Full component with lifecycle, stores |
| `Observe<T>` | Watch specific source(s), explicit dependency |
| `ObserveEffect` | Auto-track multiple dependencies |
| `.watch(context)` | Simple inline reactive values |

## License

MIT License
