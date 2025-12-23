/// Bind - Provides bind() for state persistence across widget recreation.
///
/// This module provides the core bind() functionality as mixins,
/// allowing composition with other widget features like LifecycleHooks.
library;

import 'package:flutter/widgets.dart';

/// Mixin that provides the bind() API for state persistence.
///
/// Requires association with a [BindableElement] to function.
/// Use [bindExpando] to link widget instances to their element.
///
/// Example:
/// ```dart
/// abstract class MyWidget extends Widget with BindMixin, LifecycleHooks {
///   late final count = bind(() => ref(0));
///   late final store = bind(() => MyStore());
/// }
/// ```
mixin BindMixin on Widget {
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
  ///     onMounted((context) => print('Mounted!'));
  ///   }
  ///
  ///   @override
  ///   Widget render(BuildContext context) {
  ///     return Text('${store.count.value}');
  ///   }
  /// }
  /// ```
  T bind<T>(T Function() factory) {
    final element = bindExpando[this];
    assert(
      element != null,
      'bind() can only be called after element is created',
    );
    return element!.getOrCreateByNextIndex(factory);
  }
}

/// Expando to link Widget instances to their BindableElement.
///
/// Custom elements should register themselves:
/// ```dart
/// @override
/// void mount(Element? parent, Object? newSlot) {
///   bindExpando[widget] = this;
///   // ...
/// }
/// ```
final Expando<BindableElement> bindExpando = Expando('BindableElement');

/// Mixin that provides state storage for bind().
///
/// Handles:
/// - Index-based state storage
/// - Bind index reset on widget recreation
/// - State persistence across parent rebuilds
///
/// Use this mixin on your custom element class:
/// ```dart
/// class MyElement extends ComponentElement with BindableElementMixin {
///   // ...
/// }
/// ```
mixin BindableElementMixin on ComponentElement {
  /// State storage - persists across Widget recreation.
  /// Uses index-based keys from bind() calls.
  final Map<int, dynamic> stateStorage = {};

  /// Current bind index - reset before each build/access cycle.
  int _bindIndex = 0;

  /// Track the last widget we processed bind() calls for.
  /// Used to reset _bindIndex when widget instance changes.
  Widget? _lastBoundWidget;

  /// Get or create state by next index. Factory only called on first access.
  T getOrCreateByNextIndex<T>(T Function() factory) {
    final index = _bindIndex++;
    return stateStorage.putIfAbsent(index, factory) as T;
  }

  /// Reset bind index if widget instance changed (parent rebuild scenario).
  ///
  /// Call this at the start of build() to ensure correct index assignment
  /// when the widget is recreated.
  void resetBindIndexIfNeeded(Widget currentWidget) {
    if (!identical(currentWidget, _lastBoundWidget)) {
      _bindIndex = 0;
      _lastBoundWidget = currentWidget;
    }
  }

  /// Force reset bind index and track widget.
  ///
  /// Call this at mount() to initialize tracking.
  void resetBindIndex(Widget currentWidget) {
    _bindIndex = 0;
    _lastBoundWidget = currentWidget;
  }
}

/// Base element class with bind() support.
///
/// Extends [ComponentElement] with [BindableElementMixin] for convenience.
/// Both [ReactiveElement] and [BindWidgetElement] inherit from this.
abstract class BindableElement extends ComponentElement
    with BindableElementMixin {
  /// Creates a BindableElement for the given widget.
  BindableElement(super.widget);
}
