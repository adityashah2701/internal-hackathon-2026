import 'app_exception.dart';

sealed class Failure {
  const Failure({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;

  factory Failure.fromException(AppException exception) {
    return switch (exception) {
      NetworkException() => NetworkFailure(message: exception.message, code: exception.code),
      AuthException() => AuthFailure(message: exception.message, code: exception.code),
      AuthorizationException() => AuthorizationFailure(message: exception.message, code: exception.code),
      ServerException() => ServerFailure(message: exception.message, code: exception.code),
      ValidationException() => ValidationFailure(message: exception.message, code: exception.code),
      StorageException() => StorageFailure(message: exception.message, code: exception.code),
      UnexpectedException() => UnexpectedFailure(message: exception.message, code: exception.code),
    };
  }

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

final class AuthorizationFailure extends Failure {
  const AuthorizationFailure({required super.message, super.code});
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
