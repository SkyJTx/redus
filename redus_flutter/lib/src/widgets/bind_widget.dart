/// BindWidget - Widget with bind() and lifecycle, without auto-reactivity.
///
/// Use this when you want state persistence and lifecycle hooks
/// but prefer explicit reactivity via Observe/ObserveEffect widgets.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../mixins/bind_mixin.dart';
import '../mixins/lifecycle_mixin.dart';

/// A widget with bind() for state persistence, without reactive auto-tracking.
///
/// Use this when you want:
/// - State that persists across parent rebuilds (via bind())
/// - Lifecycle hooks (onMounted, onUnmounted, etc.)
/// - Explicit reactivity via Observe/ObserveEffect widgets
///
/// **Comparison with ReactiveWidget:**
/// - ReactiveWidget: Auto-tracks reactive values in render()
/// - BindWidget: No auto-tracking, use Observe/ObserveEffect explicitly
///
/// **Example:**
/// ```dart
/// class Counter extends BindWidget {
///   late final count = bind(() => ref(0));
///
///   @override
///   void setup() {
///     onMounted((context) => print('Mounted with count: ${count.value}'));
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Observe<int>(
///       source: count.call,
///       builder: (_, value) => GestureDetector(
///         onTap: () => count.value++,
///         child: Text('Count: $value'),
///       ),
///     );
///   }
/// }
/// ```
abstract class BindWidget extends Widget with BindMixin, LifecycleHooks {
  /// Creates a bind widget.
  BindWidget({super.key});

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
  /// **No automatic reactivity** - reactive values accessed here are not
  /// automatically tracked. Use [Observe] or [ObserveEffect] widgets
  /// for reactive parts of your UI.
  Widget build(BuildContext context);

  @override
  BindWidgetElement createElement() => BindWidgetElement(this);
}

/// Element for BindWidget - provides bind() and lifecycle without reactivity.
class BindWidgetElement extends BindableElement {
  bool _isFirstBuild = true;
  bool _dependenciesInitialized = false;

  /// Creates a BindWidgetElement for the given BindWidget.
  BindWidgetElement(BindWidget super.widget);

  /// The associated BindWidget.
  BindWidget get bindWidget => widget as BindWidget;

  @override
  void didChangeDependencies() {
    // Skip first call (during mount) - use onMounted for initial setup
    if (!_dependenciesInitialized) {
      _dependenciesInitialized = true;
      super.didChangeDependencies();
      return;
    }

    // Run before hook
    bindWidget.runDependenciesChanged(this);

    super.didChangeDependencies();

    // Run after hook
    bindWidget.runAfterDependenciesChanged(this);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    // Link widget to this element
    bindExpando[bindWidget] = this;
    resetBindIndex(bindWidget);

    // Run setup
    bindWidget.setup();

    // Before mount hook
    bindWidget.runBeforeMount(this);

    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    // Re-link widget to element (widget may be new instance after parent rebuild)
    bindExpando[bindWidget] = this;
    resetBindIndexIfNeeded(bindWidget);

    final result = bindWidget.build(this);

    // Schedule lifecycle callbacks
    if (_isFirstBuild) {
      _isFirstBuild = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bindWidget.runMounted(this);
        }
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bindWidget.runUpdated(this);
        }
      });
    }

    return result;
  }

  @override
  void update(covariant BindWidget newWidget) {
    // Before update hook (on old widget)
    bindWidget.runBeforeUpdate(this);

    // Clear old widget's expando reference
    bindExpando[bindWidget] = null;

    // Link new widget to this element
    bindExpando[newWidget] = this;

    super.update(newWidget);

    // Force rebuild
    rebuild(force: true);
  }

  @override
  void activate() {
    super.activate();
    bindExpando[bindWidget] = this;
    bindWidget.runActivated(this);
  }

  @override
  void deactivate() {
    bindWidget.runDeactivated(this);
    super.deactivate();
  }

  @override
  void unmount() {
    bindWidget.runBeforeUnmount(this);
    bindWidget.runUnmounted(this);
    // Clear callbacks to prevent accumulation if widget instance is reused
    bindWidget.clearLifecycleCallbacks();
    bindExpando[bindWidget] = null;
    super.unmount();
  }
}
