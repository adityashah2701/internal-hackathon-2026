sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection failed. Please check your internet.',
    super.code,
    super.originalError,
  });
}

final class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });
}

final class AuthorizationException extends AppException {
  const AuthorizationException({
    super.message = 'You do not have permission to perform this action.',
    super.code,
    super.originalError,
  });
}

final class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.originalError,
  });
}

final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

final class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

final class UnexpectedException extends AppException {
  const UnexpectedException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code,
    super.originalError,
  });
}
