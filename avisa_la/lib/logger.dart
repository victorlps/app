import 'dart:developer' as developer;

/// Simple centralized logger that routes to `developer.log` with the app tag.
class Log {
  const Log._();

  static void alarm(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'AvisaLa',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
