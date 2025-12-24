/// Shared test widgets and helpers for redus_flutter tests.
///
/// This file contains common test widget classes used across multiple
/// test files to avoid duplication.
library;

import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STORES
// ═══════════════════════════════════════════════════════════════════════════

/// Simple counter store for testing bind() and reactivity.
class CounterStore {
  final count = ref(0);
  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// REACTIVE WIDGET TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Generic test component for ReactiveWidget unit testing.
class TestReactiveWidget extends ReactiveWidget {
  final void Function()? onSetupCallback;
  final void Function()? onMountedCallback;
  final void Function()? onDisposeCallback;
  final Widget Function(BuildContext)? builder;

  const TestReactiveWidget({
    super.key,
    this.onSetupCallback,
    this.onMountedCallback,
    this.onDisposeCallback,
    this.builder,
  });

  @override
  void setup() {
    onSetupCallback?.call();
    if (onMountedCallback != null) {
      onMounted(onMountedCallback!);
    }
    if (onDisposeCallback != null) {
      onDispose(onDisposeCallback!);
    }
  }

  @override
  Widget render(BuildContext context) {
    return builder?.call(context) ?? const Text('Test');
  }
}

/// Test component with bind() for store persistence testing.
class BindStoreTestWidget extends ReactiveWidget {
  final void Function(CounterStore)? onStoreCreated;

  BindStoreTestWidget({super.key, this.onStoreCreated});

  late final store = bind(() {
    final s = CounterStore();
    onStoreCreated?.call(s);
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component to count store creations.
class StoreCreationCountWidget extends ReactiveWidget {
  final void Function() onCreation;

  StoreCreationCountWidget({super.key, required this.onCreation});

  late final store = bind(() {
    onCreation();
    return CounterStore();
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component with multiple binds.
class MultiBindTestWidget extends ReactiveWidget {
  MultiBindTestWidget({super.key});

  late final storeA = bind(() => CounterStore());
  late final storeB = bind(() {
    final s = CounterStore();
    s.count.value = 100;
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('A: ${storeA.count.value}, B: ${storeB.count.value}');
  }
}

/// Test widget for prop update testing.
class PropTestWidget extends ReactiveWidget {
  final int propValue;

  const PropTestWidget({super.key, required this.propValue});

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Prop: $propValue');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATELESS WIDGET TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// StatelessWidget for testing .watch(context) extension.
class WatchingStatelessWidget extends StatelessWidget {
  final Ref<int> count;

  const WatchingStatelessWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text('Value: ${count.watch(context)}');
  }
}
