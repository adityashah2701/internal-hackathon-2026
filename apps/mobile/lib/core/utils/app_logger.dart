import 'dart:developer' as developer;

abstract final class AppLogger {
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? 'Sahayog.DEBUG',
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'Sahayog.INFO',
      level: 800,
    );
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? 'Sahayog.WARN',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? 'Sahayog.ERROR',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
