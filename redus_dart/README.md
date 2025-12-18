# Redus

A Vue-like **fine-grained reactivity system** for Dart, designed for developer convenience and performance.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)

## Features

- 🎯 **Fine-grained reactivity** - Only update what changed
- 🚀 **Lazy computed values** - Cached and recomputed only when dependencies change
- ⚡ **Efficient batching** - Multiple changes batched into single updates
- 🧹 **Automatic cleanup** - Cleanup callbacks for effects
- 🎮 **Full control** - Stop, pause, and resume watchers
- 🔬 **Effect scoping** - Group and dispose effects together

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  redus: ^0.1.0
```

## Module Structure

The package is organized into three modules:

```dart
import 'package:redus/reactivity.dart'; // All APIs

// Or import specific modules:
// Core: ref, computed, readonly, watchEffect, watch
// Utilities: isRef, unref, toRef, toValue, toRefs, isProxy, isReactive, isReadonly
// Advanced: shallowRef, customRef, effectScope, toRaw, markRaw
```

## Quick Start

```dart
import 'package:redus/reactivity.dart';

void main() {
  // Create reactive values
  final count = ref(0);
  final doubled = computed(() => count.value * 2);

  // React to changes
  watchEffect((_) {
    print('Count: ${count.value}, Doubled: ${doubled.value}');
  });
  // Prints: "Count: 0, Doubled: 0"

  count.value = 5;
  // Prints: "Count: 5, Doubled: 10"
}
```

## API Reference

### Core

| API | Description |
|-----|-------------|
| `ref<T>(value)` | Create mutable reactive reference |
| `computed<T>(getter)` | Create readonly computed value |
| `writableComputed<T>(get, set)` | Create writable computed value |
| `readonly<T>(source)` | Create readonly reactive wrapper |
| `watchEffect(effect)` | Run effect immediately, re-run on change |
| `watchPostEffect(effect)` | watchEffect with post-flush timing |
| `watchSyncEffect(effect)` | watchEffect with sync timing |
| `watch(source, callback)` | Watch sources with old/new values |
| `watchMultiple(sources, callback)` | Watch multiple sources |
| `onWatcherCleanup(fn)` | Register cleanup for current watcher |

### Utilities

| API | Description |
|-----|-------------|
| `isRef(value)` | Check if value is a Ref |
| `unref<T>(maybeRef)` | Unwrap ref or return value |
| `toRef<T>(source)` | Normalize value/getter to ref |
| `toValue<T>(source)` | Normalize ref/getter to value |
| `toRefs<T>(map)` | Convert map to refs |
| `isProxy(value)` | Check if reactive proxy |
| `isReactive(value)` | Check if reactive |
| `isReadonly(value)` | Check if readonly |

### Advanced

| API | Description |
|-----|-------------|
| `shallowRef<T>(value)` | Shallow reactive ref |
| `triggerRef(ref)` | Force trigger shallow ref |
| `shallowReadonly<T>(source)` | Shallow readonly wrapper |
| `customRef<T>(factory)` | Custom ref with track/trigger |
| `toRaw<T>(value)` | Get underlying value |
| `markRaw<T>(value)` | Prevent reactivity |
| `effectScope()` | Group effects for disposal |
| `getCurrentScope()` | Get active effect scope |
| `onScopeDispose(fn)` | Register scope cleanup |

## Examples

### Custom Debounced Ref

```dart
Ref<T> useDebouncedRef<T>(T value, {Duration delay = Duration(milliseconds: 200)}) {
  Timer? timeout;
  return customRef((track, trigger) => (
    get: () {
      track();
      return value;
    },
    set: (newValue) {
      timeout?.cancel();
      timeout = Timer(delay, () {
        value = newValue;
        trigger();
      });
    },
  ));
}
```

### Effect Scoping

```dart
final scope = effectScope();

scope.run(() {
  final doubled = computed(() => count.value * 2);
  
  watchEffect((_) {
    print('Count: ${doubled.value}');
  });
  
  onScopeDispose(() {
    print('Scope disposed!');
  });
});

// Dispose all effects at once
scope.stop();
```

### Shallow Ref for Large Objects

```dart
final largeData = shallowRef(loadLargeDataset());

// Nested mutations don't trigger (performance optimization)
largeData.value['items'][0] = newItem;

// Force trigger when needed
triggerRef(largeData);
```

## License

MIT License - see LICENSE file for details.
