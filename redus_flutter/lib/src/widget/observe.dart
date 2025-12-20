/// Observe widget - Watches a reactive source and rebuilds when it changes.
///
/// Similar to `watch()` but as a widget. Takes an explicit source function
/// that returns the value to track.
library;

import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

/// A widget that observes a reactive source and rebuilds when it changes.
///
/// `Observe` is the widget equivalent of `watch()` - it takes an explicit
/// source function and rebuilds only when that source's value changes.
///
/// The source can be:
/// - A [Ref] (e.g., `count`) - since Ref is callable
/// - A [Computed] (e.g., `doubled`) - since Computed is callable
/// - A getter function (e.g., `() => x.value + y.value`)
///
/// **Example:**
/// ```dart
/// final count = ref(0);
///
/// // Observe a Ref directly
/// Observe<int>(
///   source: count,
///   builder: (context, value) => Text('Count: $value'),
/// )
///
/// // Observe a derived value
/// Observe<int>(
///   source: () => count.value * 2,
///   builder: (context, doubled) => Text('Doubled: $doubled'),
/// )
/// ```
///
/// For observing multiple sources, use [ObserveMultiple].
class Observe<T> extends StatefulWidget {
  /// The reactive source to watch.
  ///
  /// This can be a [Ref], [Computed], or any function that returns T.
  /// The widget rebuilds when the source's return value changes.
  final T Function() source;

  /// Builder function called with the current value.
  final Widget Function(BuildContext context, T value) builder;

  /// Creates an Observe widget.
  const Observe({
    super.key,
    required this.source,
    required this.builder,
  });

  @override
  State<Observe<T>> createState() => _ObserveState<T>();
}

class _ObserveState<T> extends State<Observe<T>> {
  late T _value;
  WatchHandle? _watchHandle;

  @override
  void initState() {
    super.initState();
    _value = widget.source();
    _setupWatch();
  }

  void _setupWatch() {
    _watchHandle?.stop();
    _watchHandle = watch<T>(
      widget.source,
      (newValue, oldValue, onCleanup) {
        if (mounted) {
          setState(() {
            _value = newValue;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(Observe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-setup watch if source changed
    if (widget.source != oldWidget.source) {
      _value = widget.source();
      _setupWatch();
    }
  }

  @override
  void dispose() {
    _watchHandle?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value);
  }
}

/// A widget that observes multiple reactive sources and rebuilds when any change.
///
/// Similar to `watchMultiple()` but as a widget.
///
/// **Example:**
/// ```dart
/// final firstName = ref('John');
/// final lastName = ref('Doe');
///
/// ObserveMultiple<String>(
///   sources: [firstName, lastName],
///   builder: (context, values) => Text('${values[0]} ${values[1]}'),
/// )
/// ```
class ObserveMultiple<T> extends StatefulWidget {
  /// The reactive sources to watch.
  final List<T Function()> sources;

  /// Builder function called with the current values.
  final Widget Function(BuildContext context, List<T> values) builder;

  /// Creates an ObserveMultiple widget.
  const ObserveMultiple({
    super.key,
    required this.sources,
    required this.builder,
  });

  @override
  State<ObserveMultiple<T>> createState() => _ObserveMultipleState<T>();
}

class _ObserveMultipleState<T> extends State<ObserveMultiple<T>> {
  late List<T> _values;
  WatchHandle? _watchHandle;

  @override
  void initState() {
    super.initState();
    _values = widget.sources.map((s) => s()).toList();
    _setupWatch();
  }

  void _setupWatch() {
    _watchHandle?.stop();
    _watchHandle = watchMultiple<T>(
      widget.sources,
      (newValues, oldValues, onCleanup) {
        if (mounted) {
          setState(() {
            _values = newValues;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(ObserveMultiple<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sources != oldWidget.sources) {
      _values = widget.sources.map((s) => s()).toList();
      _setupWatch();
    }
  }

  @override
  void dispose() {
    _watchHandle?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values);
  }
}
