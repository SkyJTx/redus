/// ReactiveWidget - A single-class reactive component with custom Element.
///
/// Provides Vue-like reactive state and lifecycle hooks with fine-grained
/// reactivity using custom ReactiveElement.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'lifecycle.dart';

export 'lifecycle.dart';

/// A reactive widget with Vue-like lifecycle and automatic reactivity.
///
/// ReactiveWidget is a single-class component where state lives on
/// the Element (not Widget), solving Flutter's widget recreation issue.
///
/// **Key Features:**
/// - State persists across parent rebuilds
/// - Fine-grained reactivity via `markNeedsBuild()`
/// - Vue-like lifecycle hooks (onMounted, onUnmounted, etc.)
/// - Automatic reactive dependency tracking in render()
///
/// **Example:**
/// ```dart
/// class CounterStore {
///   final count = ref(0);
///   void increment() => count.value++;
/// }
///
/// class Counter extends ReactiveWidget {
///   late final store = bind(() => CounterStore());
///
///   @override
///   void setup() {
///     onMounted(() => print('Mounted with count: ${store.count.value}'));
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
abstract class ReactiveWidget extends Widget with LifecycleHooks {
  /// Creates a reactive widget.
  ReactiveWidget({super.key});

  /// Called once when the Element is mounted.
  ///
  /// Use this to:
  /// - Register lifecycle hooks with [onMounted], [onUnmounted], etc.
  /// - Set up watchers with [watchEffect], [watch], etc.
  ///
  /// Note: State is now declared using [bind] on the class body.
  void setup();

  /// Build the UI for this widget.
  ///
  /// **Automatic Reactivity**: Any reactive values (Ref, Computed) accessed
  /// here are automatically tracked. The widget rebuilds when they change.
  Widget render(BuildContext context);

  /// Bind a value to the Element's state storage.
  ///
  /// The factory is called once on first access. Subsequent calls
  /// (including after parent rebuilds) return the existing value.
  ///
  /// Use this to create stores or reactive state that persists
  /// across widget recreation:
  ///
  /// ```dart
  /// class Counter extends ReactiveWidget {
  ///   // State created once, persists across parent rebuilds
  ///   late final store = bind(() => CounterStore());
  ///
  ///   // Can also bind individual refs
  ///   late final count = bind(() => ref(0));
  ///
  ///   @override
  ///   void setup() {
  ///     onMounted(() => print('Mounted!'));
  ///   }
  ///
  ///   @override
  ///   Widget render(BuildContext context) {
  ///     return Text('${store.count.value}');
  ///   }
  /// }
  /// ```
  T bind<T>(T Function() factory) {
    final element = _elementExpando[this];
    assert(
        element != null, 'bind() can only be called after element is created');
    return element!.getOrCreateByNextIndex(factory);
  }

  @override
  ReactiveElement createElement() => ReactiveElement(this);
}

/// Expando to store Element reference for each Widget instance.
/// This avoids non-final fields on the immutable Widget.
final Expando<ReactiveElement> _elementExpando = Expando('ReactiveElement');

/// Element that manages ReactiveWidget lifecycle and state storage.
///
/// State is stored on the Element, not the Widget, so it persists
/// across parent widget rebuilds.
class ReactiveElement extends ComponentElement {
  /// State storage - persists across Widget recreation.
  /// Uses index-based keys from bind() calls.
  final Map<int, dynamic> _stateStorage = {};

  /// Current bind index - reset before each build/access cycle.
  int _bindIndex = 0;

  late EffectScope _scope;
  late ReactiveEffect _renderEffect;
  bool _isFirstBuild = true;
  bool _isRendering = false;
  Object? _error;

  /// Track the last widget we processed bind() calls for.
  /// Used to reset _bindIndex when widget instance changes.
  ReactiveWidget? _lastBoundWidget;

  /// Creates a ReactiveElement for the given ReactiveWidget.
  ReactiveElement(ReactiveWidget super.widget);

  /// The associated ReactiveWidget.
  ReactiveWidget get reactiveWidget => widget as ReactiveWidget;

  /// Get or create state by next index. Factory only called on first access.
  T getOrCreateByNextIndex<T>(T Function() factory) {
    final index = _bindIndex++;
    return _stateStorage.putIfAbsent(index, factory) as T;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    // Link widget to this element via expando
    _elementExpando[reactiveWidget] = this;

    // Reset bind index and track widget for first mount
    _bindIndex = 0;
    _lastBoundWidget = reactiveWidget;

    // Create effect scope for cleanup
    _scope = effectScope();

    // Create render effect for reactive tracking
    _renderEffect = ReactiveEffect(
      () {
        if (mounted && !_isFirstBuild && !_isRendering) {
          markNeedsBuild(); // Fine-grained rebuild!
        }
      },
      flush: FlushMode.sync,
    );

    // Run setup within scope
    _scope.run(() {
      try {
        reactiveWidget.setup();
      } catch (e, stack) {
        if (reactiveWidget.runErrorCaptured(e, stack)) {
          _error = e;
        } else {
          rethrow;
        }
      }
    });

    // Before mount hook
    reactiveWidget.runBeforeMount();

    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    // Re-link widget to element via expando (widget may be new instance after parent rebuild)
    _elementExpando[reactiveWidget] = this;

    // Reset bind index when widget instance changes (parent rebuild scenario).
    // This ensures the new widget's late final fields get correct indices.
    // Don't reset if it's the same widget (e.g., between setup() and first render()).
    if (!identical(reactiveWidget, _lastBoundWidget)) {
      _bindIndex = 0;
      _lastBoundWidget = reactiveWidget;
    }

    // Handle error state
    if (_error != null) {
      return _buildError();
    }

    Widget? result;
    _isRendering = true;

    // Track dependencies during render
    effectStack.add(_renderEffect);
    final previousEffect = activeEffect;
    activeEffect = _renderEffect;

    try {
      _scope.run(() {
        try {
          result = reactiveWidget.render(this);
        } catch (e, stack) {
          if (reactiveWidget.runErrorCaptured(e, stack)) {
            _error = e;
            result = _buildError();
          } else {
            rethrow;
          }
        }
      });
    } finally {
      effectStack.removeLast();
      activeEffect = effectStack.isEmpty ? null : effectStack.last;
      if (previousEffect != null && effectStack.contains(previousEffect)) {
        activeEffect = previousEffect;
      }
      _isRendering = false;
    }

    // Schedule lifecycle callbacks
    if (_isFirstBuild) {
      _isFirstBuild = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          reactiveWidget.runMounted();
        }
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          reactiveWidget.runUpdated();
        }
      });
    }

    return result ?? const SizedBox.shrink();
  }

  Widget _buildError() {
    return ErrorWidget.withDetails(
      message: _error.toString(),
      error: _error is FlutterError ? _error as FlutterError : null,
    );
  }

  @override
  void update(covariant ReactiveWidget newWidget) {
    // Before update hook (on old widget)
    reactiveWidget.runBeforeUpdate();

    // Clear old widget's expando reference to prevent stale access
    _elementExpando[reactiveWidget] = null;

    // Link new widget to this element via expando BEFORE super.update
    // This is critical - newWidget may have different props
    _elementExpando[newWidget] = this;

    super.update(newWidget);

    // Force rebuild to ensure render() uses the new widget's props
    // ComponentElement.update() should do this, but we enforce it
    rebuild(force: true);
  }

  @override
  void activate() {
    super.activate();
    _elementExpando[reactiveWidget] = this;
    reactiveWidget.runActivated();
  }

  @override
  void deactivate() {
    reactiveWidget.runDeactivated();
    super.deactivate();
  }

  @override
  void unmount() {
    reactiveWidget.runBeforeUnmount();
    _renderEffect.stop();
    _scope.stop();
    reactiveWidget.runUnmounted();
    _elementExpando[reactiveWidget] = null;
    super.unmount();
  }
}
