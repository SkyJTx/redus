/// Effect scope implementation.
library;

import '../core/effect.dart';

/// The currently active effect scope.
EffectScope? _activeScope;

/// Stack of effect scopes for nesting.
final List<EffectScope> _scopeStack = [];

/// Creates an effect scope for grouping reactive effects.
///
/// Effects created within the scope can be disposed together.
///
/// Example:
/// ```dart
/// final scope = effectScope();
///
/// scope.run(() {
///   final doubled = computed(() => counter.value * 2);
///   watchEffect((_) => print(doubled.value));
/// });
///
/// // Dispose all effects in the scope
/// scope.stop();
/// ```
EffectScope effectScope({bool detached = false}) {
  return EffectScope._(detached: detached);
}

/// Get the currently active effect scope.
///
/// Returns null if there is no active scope.
EffectScope? getCurrentScope() => _activeScope;

/// Register a dispose callback on the current active effect scope.
///
/// The callback will be invoked when the associated effect scope is stopped.
///
/// Example:
/// ```dart
/// final scope = effectScope();
/// scope.run(() {
///   onScopeDispose(() => print('Scope disposed!'));
/// });
/// scope.stop(); // Prints: "Scope disposed!"
/// ```
void onScopeDispose(void Function() callback, {bool failSilently = false}) {
  if (_activeScope != null) {
    _activeScope!._addDisposable(callback);
  } else if (!failSilently) {
    throw StateError(
      'onScopeDispose called outside of an active effect scope.',
    );
  }
}

/// An effect scope for grouping and disposing reactive effects.
class EffectScope {
  /// Whether this scope is detached from parent.
  final bool detached;

  /// Whether this scope is still active.
  bool _active = true;

  /// Effects created within this scope.
  final List<ReactiveEffect> _effects = [];

  /// Dispose callbacks registered via onScopeDispose.
  final List<void Function()> _disposables = [];

  /// Child scopes.
  final List<EffectScope> _children = [];

  /// Parent scope (if not detached).
  EffectScope? _parent;

  EffectScope._({this.detached = false}) {
    if (!detached && _activeScope != null) {
      _parent = _activeScope;
      _activeScope!._children.add(this);
    }
  }

  /// Whether this scope is active.
  bool get isActive => _active;

  /// Run a function within this scope, capturing any effects created.
  ///
  /// Returns the function's return value, or null if scope is inactive.
  T? run<T>(T Function() fn) {
    if (!_active) return null;

    final previousScope = _activeScope;
    _scopeStack.add(this);
    _activeScope = this;

    try {
      return fn();
    } finally {
      _scopeStack.removeLast();
      _activeScope = _scopeStack.isEmpty ? previousScope : _scopeStack.last;
    }
  }

  /// Stop this scope and dispose all effects.
  void stop() {
    if (!_active) return;

    // Stop all effects
    for (final effect in _effects) {
      effect.stop();
    }
    _effects.clear();

    // Run all dispose callbacks
    for (final disposable in _disposables) {
      disposable();
    }
    _disposables.clear();

    // Stop child scopes
    for (final child in _children) {
      child.stop();
    }
    _children.clear();

    // Remove from parent
    _parent?._children.remove(this);

    _active = false;
  }

  /// Internal: Add an effect to this scope.
  void _addEffect(ReactiveEffect effect) {
    if (_active) {
      _effects.add(effect);
    }
  }

  /// Internal: Add a disposable callback.
  void _addDisposable(void Function() callback) {
    if (_active) {
      _disposables.add(callback);
    }
  }
}

/// Extension to register effects with the current scope.
extension ScopedEffect on ReactiveEffect {
  /// Register this effect with the current scope (if any).
  void registerWithScope() {
    _activeScope?._addEffect(this);
  }
}
