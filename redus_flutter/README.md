# Redus Flutter

Vue-like **Component system** for Flutter with reactive state and lifecycle hooks.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)

## Features

- 🎯 **Vue-like Components** - Familiar setup/render pattern
- 🔄 **Lifecycle Hooks** - onMounted, onUpdated, onUnmounted, etc.
- ⚡ **Reactive State** - Built on redus reactivity system
- 💉 **Dependency Injection** - Simple global service locator
- 🧹 **Auto Cleanup** - Effect scopes tied to widget lifecycle

## Installation

```yaml
dependencies:
  redus_flutter:
    path: ../redus_flutter  # or pub.dev when published
```

## Quick Start

```dart
import 'package:redus_flutter/redus_flutter.dart';

class CounterComponent extends Component {
  late final Ref<int> count;

  @override
  void setup() {
    count = ref(0);

    onMounted(() => print('Mounted!'));
    onUnmounted(() => print('Unmounted!'));

    // Set up reactive rebuilding
    watchEffect((_) {
      count.value;
      rebuild();
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

// Usage
CounterComponent()
```

## Lifecycle Hooks

| Hook | Flutter Equivalent | Description |
|------|-------------------|-------------|
| `onBeforeMount` | Before first build | Setup complete, before render |
| `onMounted` | After first build | Widget fully rendered |
| `onBeforeUpdate` | `didUpdateWidget` | Before rebuild |
| `onUpdated` | After rebuild | Rebuild complete |
| `onBeforeUnmount` | `dispose` start | Cleanup starting |
| `onUnmounted` | After `dispose` | Widget removed |
| `onErrorCaptured` | Error boundary | Catch render errors |
| `onActivated` | Route visible | Widget activated |
| `onDeactivated` | Route hidden | Widget deactivated |

## Dependency Injection

```dart
// Register singleton
register<ApiService>(ApiService());

// Register factory (new instance each time)
registerFactory<Logger>(() => Logger());

// Get instance
final api = get<ApiService>();

// Check registration
if (isRegistered<ApiService>()) { ... }

// Remove registration
unregister<ApiService>();
```

## Full Example

```dart
import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  // Setup DI
  register<ApiService>(ApiService());

  runApp(MaterialApp(home: TodoComponent()));
}

class TodoComponent extends Component {
  late final Ref<List<String>> todos;
  late final ApiService api;

  @override
  void setup() {
    todos = ref<List<String>>([]);
    api = get<ApiService>();

    onMounted(() async {
      todos.value = await api.fetchTodos();
    });

    // Rebuild when todos change
    watchEffect((_) {
      todos.value;
      rebuild();
    });
  }

  @override
  Widget render(BuildContext context) {
    return ListView(
      children: todos.value.map((t) => ListTile(title: Text(t))).toList(),
    );
  }
}
```

## License

MIT License
