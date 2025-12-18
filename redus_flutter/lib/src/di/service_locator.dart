/// Global dependency injection container.
///
/// Provides a simple service locator pattern for registering and retrieving
/// dependencies throughout the application.
library;

/// Global service locator instance.
final ServiceLocator _locator = ServiceLocator._();

/// Register a singleton instance.
///
/// The same instance is returned every time [get] is called.
///
/// Example:
/// ```dart
/// register<ApiService>(ApiService());
/// ```
void register<T extends Object>(T instance) {
  _locator.register<T>(instance);
}

/// Register a factory function.
///
/// A new instance is created every time [get] is called.
///
/// Example:
/// ```dart
/// registerFactory<Logger>(() => Logger());
/// ```
void registerFactory<T extends Object>(T Function() factory) {
  _locator.registerFactory<T>(factory);
}

/// Get a registered instance or factory result.
///
/// Throws [StateError] if the type is not registered.
///
/// Example:
/// ```dart
/// final api = get<ApiService>();
/// ```
T get<T extends Object>() {
  return _locator.get<T>();
}

/// Check if a type is registered.
bool isRegistered<T extends Object>() {
  return _locator.isRegistered<T>();
}

/// Remove a registered instance or factory.
void unregister<T extends Object>() {
  _locator.unregister<T>();
}

/// Reset all registrations.
void resetLocator() {
  _locator.reset();
}

/// Service locator for dependency injection.
///
/// Supports both singleton instances and factory functions.
class ServiceLocator {
  ServiceLocator._();

  final Map<Type, Object> _singletons = {};
  final Map<Type, Object Function()> _factories = {};

  /// Register a singleton instance.
  void register<T extends Object>(T instance) {
    _singletons[T] = instance;
    _factories.remove(T);
  }

  /// Register a factory function.
  void registerFactory<T extends Object>(T Function() factory) {
    _factories[T] = factory;
    _singletons.remove(T);
  }

  /// Get instance or create from factory.
  T get<T extends Object>() {
    // Check singletons first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw StateError(
      'No registration found for type $T. '
      'Did you forget to call register<$T>() or registerFactory<$T>()?',
    );
  }

  /// Check if a type is registered.
  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  /// Remove a registration.
  void unregister<T extends Object>() {
    _singletons.remove(T);
    _factories.remove(T);
  }

  /// Reset all registrations.
  void reset() {
    _singletons.clear();
    _factories.clear();
  }
}
