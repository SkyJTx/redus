/// ObserveEffect widget - Auto-tracks reactive dependencies and rebuilds.
///
/// Similar to `watchEffect()` but as a widget. Automatically tracks any
/// reactive values accessed during build.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

/// A widget that auto-tracks reactive dependencies and rebuilds when they change.
///
/// `ObserveEffect` is the widget equivalent of `watchEffect()` - it automatically
/// tracks any reactive values (Ref, Computed) accessed in the builder function
/// and rebuilds when any of them change.
///
/// **Example:**
/// ```dart
/// final count = ref(0);
/// final name = ref('Alice');
///
/// // Auto-tracks both count and name
/// ObserveEffect(
///   builder: (context) => Column(
///     children: [
///       Text('Count: ${count.value}'),
///       Text('Name: ${name.value}'),
///     ],
///   ),
/// )
/// ```
///
/// For explicit source watching, use [Observe] instead.
class ObserveEffect extends StatefulWidget {
  /// Builder function that accesses reactive values.
  ///
  /// Any [Ref] or [Computed] accessed via `.value` will be tracked,
  /// and the widget will rebuild when they change.
  final Widget Function(BuildContext context) builder;

  /// Creates an ObserveEffect widget.
  const ObserveEffect({
    super.key,
    required this.builder,
  });

  @override
  State<ObserveEffect> createState() => _ObserveEffectState();
}

class _ObserveEffectState extends State<ObserveEffect> {
  ReactiveEffect? _effect;
  Widget? _cachedWidget;
  bool _needsRebuild = true;

  @override
  void initState() {
    super.initState();
    _setupEffect();
  }

  void _setupEffect() {
    _effect?.stop();
    _effect = ReactiveEffect(
      () {
        // This will be called when dependencies change
        if (mounted && !_needsRebuild) {
          setState(() {
            _needsRebuild = true;
          });
        }
      },
      flush: FlushMode.sync,
    );
  }

  @override
  void didUpdateWidget(ObserveEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.builder != oldWidget.builder) {
      _needsRebuild = true;
      _setupEffect();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_needsRebuild) {
      // Track dependencies during build
      effectStack.add(_effect!);
      final previousEffect = activeEffect;
      activeEffect = _effect;

      try {
        _cachedWidget = widget.builder(context);
      } finally {
        effectStack.removeLast();
        activeEffect = effectStack.isEmpty ? null : effectStack.last;
        if (previousEffect != null && effectStack.contains(previousEffect)) {
          activeEffect = previousEffect;
        }
      }

      _needsRebuild = false;
    }

    return _cachedWidget ?? const SizedBox.shrink();
  }
}
