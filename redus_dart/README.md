# Redus

**Developer utilities for Dart** - Fine-grained reactivity, dependency injection, and more.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![pub package](https://img.shields.io/pub/v/redus.svg)](https://pub.dev/packages/redus)

## Modules

| Module | Import | Description |
|--------|--------|-------------|
| **Reactivity** | `package:redus/reactivity.dart` | Vue-like fine-grained reactivity |
| **DI** | `package:redus/di.dart` | Dependency injection with key support |
| **All** | `package:redus/redus.dart` | All modules combined |

## Installation

```yaml
dependencies:
  redus: ^0.4.0
```

---

## Dependency Injection

Simple service locator with type-based and key-based lookup.

```dart
import 'package:redus/di.dart';

// Register by type
register<ApiService>(ApiService());
final api = get<ApiService>();

// Register multiple instances with keys
register<Logger>(ConsoleLogger(), key: #console);
register<Logger>(FileLogger(), key: #file);
final log = get<Logger>(key: #console);

// Factory registration
registerFactory<DatabaseConnection>(() => DatabaseConnection());
```

### DI API

| API | Description |
|-----|-------------|
| `register<T>(instance, {key})` | Register singleton |
| `registerFactory<T>(factory, {key})` | Register factory |
| `get<T>({key})` | Get instance |
| `isRegistered<T>({key})` | Check registration |
| `unregister<T>({key})` | Remove registration |
| `resetLocator()` | Clear all |

---

## Reactivity

Vue-like fine-grained reactivity with automatic dependency tracking.

```dart
import 'package:redus/reactivity.dart';

final count = ref(0);
final doubled = computed(() => count.value * 2);

watchEffect((_) {
  print('Count: ${count.value}, Doubled: ${doubled.value}');
});

count.value = 5;  // Prints: "Count: 5, Doubled: 10"
```

### Core API

| API | Description |
|-----|-------------|
| `ref<T>(value)` | Mutable reactive reference |
| `computed<T>(getter)` | Cached computed value |
| `readonly<T>(source)` | Readonly wrapper |
| `watchEffect(effect)` | Auto-tracking effect |
| `watch(source, callback)` | Explicit source watching |

### Utilities

| API | Description |
|-----|-------------|
| `isRef(value)` | Check if Ref |
| `unref<T>(maybeRef)` | Unwrap ref or return value |
| `toRef<T>(source)` | Normalize to ref |
| `toValue<T>(source)` | Normalize to value |

### Advanced

| API | Description |
|-----|-------------|
| `shallowRef<T>(value)` | Shallow reactive ref |
| `customRef<T>(factory)` | Custom ref with track/trigger |
| `effectScope()` | Group effects for disposal |
| `markRaw<T>(value)` | Prevent reactivity |

---

## Examples

### Debounced Ref

```dart
Ref<T> useDebouncedRef<T>(T value, {Duration delay = const Duration(milliseconds: 200)}) {
  Timer? timeout;
  return customRef((track, trigger) => (
    get: () { track(); return value; },
    set: (newValue) {
      timeout?.cancel();
      timeout = Timer(delay, () { value = newValue; trigger(); });
    },
  ));
}
```

### Effect Scoping

```dart
final scope = effectScope();

scope.run(() {
  final doubled = computed(() => count.value * 2);
  watchEffect((_) => print('Doubled: ${doubled.value}'));
});

scope.stop();  // Dispose all effects
```

---

## License

MIT License
