/// ReactiveWidget - A stateful reactive component with lifecycle hooks.
///
/// Uses State for storage while keeping the original widget-centric API.
library;

import 'package:flutter/widgets.dart';

import '../mixins/lifecycle_mixin.dart';
import '../mixins/state_mixin.dart';

/// Expando to link ReactiveWidget instances to their ReactiveState.
final Expando<ReactiveState> _stateExpando = Expando('ReactiveState');

/// A reactive widget with lifecycle hooks and automatic reactivity.
///
/// **Example:**
/// ```dart
/// class Counter extends ReactiveWidget {
///   late final store = bind(() => CounterStore());
///
///   @override
///   void setup() {
///     onInitState(() => print('Count: ${store.count.value}'));
///     onDispose(() => print('Disposing...'));
///   }
///
///   @override
///   Widget render(BuildContext context) {
///     return GestureDetector(
///       onTap: store.increment,
///       child: Text('Count: ${store.count.value}'),
///     );
///   }
/// }
/// ```
abstract class ReactiveWidget extends StatefulWidget {
  /// Creates a reactive widget.
  const ReactiveWidget({super.key});

  /// The [BuildContext] for this widget.
  BuildContext get context {
    final state = _stateExpando[this];
    assert(state != null && state.mounted,
        'Cannot access context before mount or after dispose.');
    return state!.context;
  }

  /// Whether this widget is currently mounted.
  bool get mounted => _stateExpando[this]?.mounted ?? false;

  // ─────────────────────────────────────────────────────────────────────────
  // bind() API - delegates to State storage
  // ─────────────────────────────────────────────────────────────────────────

  /// Create or retrieve state that persists across parent rebuilds.
  T bind<T>(T Function() create) {
    final state = _stateExpando[this];
    assert(state != null, 'bind() can only be called after element is created');
    return state!.bind(create);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle hooks - delegate to State
  // ─────────────────────────────────────────────────────────────────────────

  /// Register a callback for initState lifecycle.
  void onInitState(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    _stateExpando[this]?.onInitState(callback, timing: timing);
  }

  /// Register a callback after the first frame renders.
  void onMounted(LifecycleCallback callback) {
    _stateExpando[this]?.onMounted(callback);
  }

  /// Register a callback for didChangeDependencies lifecycle.
  void onDidChangeDependencies(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    _stateExpando[this]?.onDidChangeDependencies(callback, timing: timing);
  }

  /// Register a callback for didUpdateWidget lifecycle.
  void onDidUpdateWidget<T>(DidUpdateWidgetCallback<T> callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    _stateExpando[this]?.onDidUpdateWidget(callback, timing: timing);
  }

  /// Register a callback for deactivate lifecycle.
  void onDeactivate(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    _stateExpando[this]?.onDeactivate(callback, timing: timing);
  }

  /// Register a callback for activate lifecycle.
  void onActivate(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.after}) {
    _stateExpando[this]?.onActivate(callback, timing: timing);
  }

  /// Register a callback for dispose lifecycle.
  void onDispose(LifecycleCallback callback,
      {LifecycleTiming timing = LifecycleTiming.before}) {
    _stateExpando[this]?.onDispose(callback, timing: timing);
  }

  /// Register an error handler.
  void onErrorCaptured(ErrorCallback callback) {
    _stateExpando[this]?.onErrorCaptured(callback);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Abstract methods for subclasses
  // ─────────────────────────────────────────────────────────────────────────

  /// Called once when the widget is first created.
  ///
  /// Use this to register lifecycle hooks and set up watchers.
  void setup();

  /// Build the UI for this widget.
  ///
  /// **Automatic Reactivity**: Any reactive values accessed here are
  /// automatically tracked. The widget rebuilds when they change.
  Widget render(BuildContext context);

  @override
  State<ReactiveWidget> createState() => ReactiveState();
}

/// State class for ReactiveWidget.
class ReactiveState extends State<ReactiveWidget>
    with
        LifecycleCallbacks,
        LifecycleHooksStateMixin,
        BindStateMixin,
        ReactiveStateMixin {
  Object? _error;

  @override
  void initState() {
    _stateExpando[widget] = this;

    runInScope(() {
      try {
        widget.setup();
      } catch (e, stack) {
        if (runErrorCapturedCallbacks(e, stack)) {
          _error = e;
        } else {
          rethrow;
        }
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ReactiveWidget oldWidget) {
    _stateExpando[oldWidget] = null;
    _stateExpando[widget] = this;
    super.didUpdateWidget(oldWidget);
    if (!identical(widget, oldWidget)) {
      resetBindIndex();
    }
  }

  @override
  void activate() {
    super.activate();
    _stateExpando[widget] = this;
  }

  @override
  void dispose() {
    stopReactivity();
    _stateExpando[widget] = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _stateExpando[widget] = this;

    if (_error != null) {
      return ErrorWidget.withDetails(message: _error.toString());
    }

    final result = buildReactive(context, () {
      try {
        return widget.render(context);
      } catch (e, stack) {
        if (runErrorCapturedCallbacks(e, stack)) {
          _error = e;
          return ErrorWidget.withDetails(message: _error.toString());
        } else {
          rethrow;
        }
      }
    });

    scheduleMountedCallbackIfNeeded();
    return result;
  }
}
