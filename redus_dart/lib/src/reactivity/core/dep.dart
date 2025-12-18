/// Dependency tracking for reactive values.
library;

import 'effect.dart';

/// Tracks subscribers (effects) that depend on a reactive value.
///
/// Each reactive value (Ref, Computed) has a [Dep] instance that:
/// - Tracks which effects depend on it during reads via [track]
/// - Notifies dependent effects when the value changes via [trigger]
class Dep {
  /// Set of effects that depend on this value.
  final Set<ReactiveEffect> _subscribers = {};

  /// Track the current active effect as a subscriber.
  ///
  /// Called when a reactive value is read. If there's an active effect
  /// running, it will be added as a subscriber to this dep.
  void track() {
    final effect = activeEffect;
    if (effect != null && effect.isActive && !effect.isPaused) {
      _subscribers.add(effect);
      effect.addDep(this);
    }
  }

  /// Notify all subscribers that the value has changed.
  ///
  /// Called when a reactive value is written. All subscribed effects
  /// will be scheduled to re-run based on their flush mode.
  void trigger() {
    // Create a copy to avoid modification during iteration
    final effects = Set<ReactiveEffect>.from(_subscribers);
    for (final effect in effects) {
      if (effect.isActive && !effect.isPaused) {
        Scheduler.queueEffect(effect);
      }
    }
  }

  /// Remove an effect from subscribers.
  void unsubscribe(ReactiveEffect effect) {
    _subscribers.remove(effect);
  }

  /// Number of subscribers (for testing/debugging).
  int get subscriberCount => _subscribers.length;
}
