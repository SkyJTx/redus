/// ReactiveWidget - A single-class reactive component with custom Element.
///
/// Provides Vue-like reactive state and lifecycle hooks with fine-grained
/// reactivity using custom ReactiveElement.
///
/// Composed of:
/// - [BindMixin] for state persistence via bind()
/// - [LifecycleHooks] for lifecycle callbacks
/// - Automatic reactive dependency tracking in render()
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:redus/reactivity.dart';

import 'bind.dart';
import 'lifecycle.dart';

export 'bind.dart';
export 'lifecycle.dart';

/// A reactive widget with Vue-like lifecycle and automatic reactivity.
///
/// ReactiveWidget is a single-class component where state lives on
/// the Element (not Widget), solving Flutter's widget recreation issue.
///
/// **Key Features:**
/// - State persists across parent rebuilds (via [BindMixin])
/// - Fine-grained reactivity via `markNeedsBuild()`
/// - Vue-like lifecycle hooks (via [LifecycleHooks])
/// - Automatic reactive dependency tracking in render()
///
/// **Composition:**
/// ReactiveWidget = BindMixin + LifecycleHooks + auto-reactivity
///
/// For a simpler widget without auto-reactivity, see [BindWidget].
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
abstract class ReactiveWidget extends Widget with BindMixin, LifecycleHooks {
  /// Creates a reactive widget.
  ReactiveWidget({super.key});

  /// Called once when the Element is mounted.
  ///
  /// Use this to:
  /// - Register lifecycle hooks with [onMounted], [onUnmounted], etc.
  /// - Set up watchers with [watchEffect], [watch], etc.
  ///
  /// Note: State is declared using [bind] on the class body.
  void setup();

  /// Build the UI for this widget.
  ///
  /// **Automatic Reactivity**: Any reactive values (Ref, Computed) accessed
  /// here are automatically tracked. The widget rebuilds when they change.
  Widget render(BuildContext context);

  @override
  ReactiveElement createElement() => ReactiveElement(this);
}

/// Element that manages ReactiveWidget lifecycle and state storage.
///
/// Extends [BindableElement] for state persistence and adds:
/// - EffectScope for cleanup
/// - ReactiveEffect for automatic dependency tracking
/// - Error boundary support
class ReactiveElement extends BindableElement {
  late EffectScope _scope;
  late ReactiveEffect _renderEffect;
  bool _isFirstBuild = true;
  bool _isRendering = false;
  Object? _error;

  /// Creates a ReactiveElement for the given ReactiveWidget.
  ReactiveElement(ReactiveWidget super.widget);

  /// The associated ReactiveWidget.
  ReactiveWidget get reactiveWidget => widget as ReactiveWidget;

  @override
  void mount(Element? parent, Object? newSlot) {
    // Link widget to this element
    bindExpando[reactiveWidget] = this;
    resetBindIndex(reactiveWidget);

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
    // Re-link widget to element (widget may be new instance after parent rebuild)
    bindExpando[reactiveWidget] = this;
    resetBindIndexIfNeeded(reactiveWidget);

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

    // Clear old widget's expando reference
    bindExpando[reactiveWidget] = null;

    // Link new widget to this element
    bindExpando[newWidget] = this;

    super.update(newWidget);

    // Force rebuild to ensure render() uses the new widget's props
    rebuild(force: true);
  }

  @override
  void activate() {
    super.activate();
    bindExpando[reactiveWidget] = this;
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
    // Clear callbacks to prevent accumulation if widget instance is reused
    reactiveWidget.clearLifecycleCallbacks();
    bindExpando[reactiveWidget] = null;
    super.unmount();
  }
}
