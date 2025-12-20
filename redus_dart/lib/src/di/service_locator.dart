/// Global dependency injection container with type and key-based lookup.
///
/// Provides a simple service locator pattern for registering and retrieving
/// dependencies throughout the application.
library;

/// Global service locator instance.
final ServiceLocator _locator = ServiceLocator._();

/// Register a singleton instance.
///
/// The same instance is returned every time [get] is called.
/// Optionally provide a [key] to register multiple instances of the same type.
///
/// Example:
/// ```dart
/// // By type only
/// register<ApiService>(ApiService());
///
/// // By type + key
/// register<ApiService>(ApiService(), key: #primary);
/// register<ApiService>(ApiService(), key: #backup);
/// ```
void register<T extends Object>(T instance, {Symbol? key}) {
  _locator.register<T>(instance, key: key);
}

/// Register a factory function.
///
/// A new instance is created every time [get] is called.
/// Optionally provide a [key] for key-based lookup.
///
/// Example:
/// ```dart
/// registerFactory<Logger>(() => Logger());
/// registerFactory<Logger>(() => FileLogger(), key: #file);
/// ```
void registerFactory<T extends Object>(T Function() factory, {Symbol? key}) {
  _locator.registerFactory<T>(factory, key: key);
}

/// Get a registered instance or factory result.
///
/// Throws [StateError] if the type (and key) is not registered.
///
/// Example:
/// ```dart
/// final api = get<ApiService>();
/// final backup = get<ApiService>(key: #backup);
/// ```
T get<T extends Object>({Symbol? key}) {
  return _locator.get<T>(key: key);
}

/// Check if a type (and optional key) is registered.
bool isRegistered<T extends Object>({Symbol? key}) {
  return _locator.isRegistered<T>(key: key);
}

/// Remove a registered instance or factory.
void unregister<T extends Object>({Symbol? key}) {
  _locator.unregister<T>(key: key);
}

/// Reset all registrations.
void resetLocator() {
  _locator.reset();
}

/// Composite key for type + optional Symbol key.
class _RegistrationKey {
  final Type type;
  final Symbol? key;

  const _RegistrationKey(this.type, this.key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RegistrationKey && type == other.type && key == other.key;

  @override
  int get hashCode => Object.hash(type, key);

  @override
  String toString() => key != null ? '$type[$key]' : '$type';
}

/// Service locator for dependency injection.
///
/// Supports:
/// - Singleton instances and factory functions
/// - Type-based lookup (default)
/// - Key-based lookup for multiple instances of same type
class ServiceLocator {
  ServiceLocator._();

  final Map<_RegistrationKey, Object> _singletons = {};
  final Map<_RegistrationKey, Object Function()> _factories = {};

  /// Register a singleton instance.
  void register<T extends Object>(T instance, {Symbol? key}) {
    final regKey = _RegistrationKey(T, key);
    _singletons[regKey] = instance;
    _factories.remove(regKey);
  }

  /// Register a factory function.
  void registerFactory<T extends Object>(T Function() factory, {Symbol? key}) {
    final regKey = _RegistrationKey(T, key);
    _factories[regKey] = factory;
    _singletons.remove(regKey);
  }

  /// Get instance or create from factory.
  T get<T extends Object>({Symbol? key}) {
    final regKey = _RegistrationKey(T, key);

    // Check singletons first
    if (_singletons.containsKey(regKey)) {
      return _singletons[regKey] as T;
    }

    // Check factories
    if (_factories.containsKey(regKey)) {
      return _factories[regKey]!() as T;
    }

    final keyStr = key != null ? ' with key $key' : '';
    throw StateError(
      'No registration found for type $T$keyStr. '
      'Did you forget to call register<$T>() or registerFactory<$T>()?',
    );
  }

  /// Check if a type (and optional key) is registered.
  bool isRegistered<T extends Object>({Symbol? key}) {
    final regKey = _RegistrationKey(T, key);
    return _singletons.containsKey(regKey) || _factories.containsKey(regKey);
  }

  /// Remove a registration.
  void unregister<T extends Object>({Symbol? key}) {
    final regKey = _RegistrationKey(T, key);
    _singletons.remove(regKey);
    _factories.remove(regKey);
  }

  /// Reset all registrations.
  void reset() {
    _singletons.clear();
    _factories.clear();
  }
}
