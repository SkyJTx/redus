/// Flutter extensions for fine-grained reactivity.
///
/// Provides `.watch(context)` extension methods on [Ref] and [Computed]
/// that enable surgical widget rebuilds - only the widget calling
/// `.watch(context)` will rebuild when the value changes.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'reactive_context.dart';

/// Extension to watch [Ref] values with automatic Element rebuild.
extension RefWatchExtension<T> on Ref<T> {
  /// Watch this ref's value and rebuild only this widget when it changes.
  ///
  /// This enables fine-grained reactivity - only the specific widget
  /// calling `.watch(context)` will rebuild, not the entire component tree.
  ///
  /// ```dart
  /// class MyWidget extends StatelessWidget {
  ///   final Ref<int> count;
  ///
  ///   const MyWidget({required this.count, super.key});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // Only this Text widget rebuilds when count changes
  ///     return Text('Count: ${count.watch(context)}');
  ///   }
  /// }
  /// ```
  ///
  /// Compare with `.value` which does not trigger rebuilds in regular widgets:
  /// - Use `.watch(context)` in widget build methods for reactive UI
  /// - Use `.value` in callbacks, event handlers, or non-widget code
  T watch(BuildContext context) {
    final element = context as Element;
    final effect = ReactiveContext.getEffect(element);

    // Temporarily set this effect as active to track dependencies
    effectStack.add(effect);
    final previousEffect = activeEffect;
    activeEffect = effect;

    try {
      // Reading .value will call _dep.track() which registers
      // the effect as a subscriber
      return value;
    } finally {
      // Restore previous effect state
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
    }
  }
}

/// Extension to watch [Computed] values with automatic Element rebuild.
extension ComputedWatchExtension<T> on Computed<T> {
  /// Watch this computed's value and rebuild only this widget when it changes.
  ///
  /// This enables fine-grained reactivity - only the specific widget
  /// calling `.watch(context)` will rebuild, not the entire component tree.
  ///
  /// ```dart
  /// class MyWidget extends StatelessWidget {
  ///   final Computed<String> fullName;
  ///
  ///   const MyWidget({required this.fullName, super.key});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // Only this Text widget rebuilds when fullName changes
  ///     return Text('Hello, ${fullName.watch(context)}!');
  ///   }
  /// }
  /// ```
  T watch(BuildContext context) {
    final element = context as Element;
    final effect = ReactiveContext.getEffect(element);

    effectStack.add(effect);
    final previousEffect = activeEffect;
    activeEffect = effect;

    try {
      return value;
    } finally {
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
    }
  }
}
