/// Dependency injection module.
///
/// Provides a simple service locator pattern for registering and retrieving
/// dependencies. Supports both type-based and key-based lookup.
///
/// Example:
/// ```dart
/// import 'package:redus/di.dart';
///
/// // Register by type
/// register<ApiService>(ApiService());
/// final api = get<ApiService>();
///
/// // Register by type + key (for multiple instances)
/// register<Logger>(ConsoleLogger(), key: #console);
/// register<Logger>(FileLogger(), key: #file);
/// final consoleLogger = get<Logger>(key: #console);
/// ```
library;

export 'src/di/service_locator.dart';
