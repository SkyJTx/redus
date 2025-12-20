/// Manages Element subscriptions to reactive values for fine-grained reactivity.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

/// Manages the relationship between Flutter Elements and ReactiveEffects.
///
/// Uses [Expando] for automatic cleanup when Elements are garbage collected.
class ReactiveContext {
  ReactiveContext._();

  /// Stores ReactiveEffect for each Element.
  /// Expando automatically cleans up when Element is disposed.
  static final Expando<ReactiveEffect> _elementEffects =
      Expando('ReactiveContext');

  /// Get or create a [ReactiveEffect] for the given [Element].
  ///
  /// The effect will call [Element.markNeedsBuild] when triggered,
  /// causing only that specific widget to rebuild.
  static ReactiveEffect getEffect(Element element) {
    var effect = _elementEffects[element];
    if (effect == null) {
      effect = ReactiveEffect(
        () {
          // Only mark for rebuild if element is still in the tree
          if (element.mounted) {
            element.markNeedsBuild();
          }
        },
        flush: FlushMode.sync, // Immediate UI updates
      );
      _elementEffects[element] = effect;
    }
    return effect;
  }

  /// Clear the effect for an element (for testing or manual cleanup).
  static void clearEffect(Element element) {
    final effect = _elementEffects[element];
    if (effect != null) {
      effect.stop();
      _elementEffects[element] = null;
    }
  }
}
