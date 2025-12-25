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
  ReactiveState<TestReactiveWidget> createState() => _TestReactiveState();
}

class _TestReactiveState extends ReactiveState<TestReactiveWidget> {
  @override
  void setup() {
    widget.onSetupCallback?.call();
    if (widget.onMountedCallback != null) {
      onMounted(widget.onMountedCallback!);
    }
    if (widget.onDisposeCallback != null) {
      onDispose(widget.onDisposeCallback!);
    }
  }

  @override
  Widget render(BuildContext context) {
    return widget.builder?.call(context) ?? const Text('Test');
  }
}

/// Test component for store persistence testing.
class BindStoreTestWidget extends ReactiveWidget {
  final void Function(CounterStore)? onStoreCreated;

  const BindStoreTestWidget({super.key, this.onStoreCreated});

  @override
  ReactiveState<BindStoreTestWidget> createState() => _BindStoreTestWidgetState();
}

class _BindStoreTestWidgetState extends ReactiveState<BindStoreTestWidget> {
  late final CounterStore store;

  @override
  void setup() {
    store = CounterStore();
    widget.onStoreCreated?.call(store);
  }

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component to count store creations.
class StoreCreationCountWidget extends ReactiveWidget {
  final void Function() onCreation;

  const StoreCreationCountWidget({super.key, required this.onCreation});

  @override
  ReactiveState<StoreCreationCountWidget> createState() => _StoreCreationCountWidgetState();
}

class _StoreCreationCountWidgetState extends ReactiveState<StoreCreationCountWidget> {
  late final CounterStore store;

  @override
  void setup() {
    widget.onCreation();
    store = CounterStore();
  }

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

/// Test component with multiple stores.
class MultiBindTestWidget extends ReactiveWidget {
  const MultiBindTestWidget({super.key});

  @override
  ReactiveState<MultiBindTestWidget> createState() => _MultiBindTestWidgetState();
}

class _MultiBindTestWidgetState extends ReactiveState<MultiBindTestWidget> {
  late final CounterStore storeA;
  late final CounterStore storeB;

  @override
  void setup() {
    storeA = CounterStore();
    storeB = CounterStore()..count.value = 100;
  }

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
  ReactiveState<PropTestWidget> createState() => _PropTestWidgetState();
}

class _PropTestWidgetState extends ReactiveState<PropTestWidget> {
  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Prop: ${widget.propValue}');
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
