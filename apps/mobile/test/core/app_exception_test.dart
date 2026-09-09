import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/errors/failure.dart';

void main() {
  group('AppException & Failure Mapping Tests', () {
    test('NetworkException correctly maps to NetworkFailure', () {
      const NetworkException exception = NetworkException(
        message: 'No internet connection',
        code: 'NETWORK_ERR',
      );
      final Failure failure = Failure.fromException(exception);

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'No internet connection');
      expect(failure.code, 'NETWORK_ERR');
    });

    test('AuthException correctly maps to AuthFailure', () {
      const AuthException exception = AuthException(
        message: 'Invalid OTP credentials',
        code: 'AUTH_INVALID_CREDENTIALS',
      );
      final Failure failure = Failure.fromException(exception);

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Invalid OTP credentials');
      expect(failure.code, 'AUTH_INVALID_CREDENTIALS');
    });

    test('ValidationException correctly maps to ValidationFailure', () {
      const ValidationException exception = ValidationException(
        message: 'Phone number must be 10 digits',
        code: 'VAL_PHONE',
      );
      final Failure failure = Failure.fromException(exception);

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Phone number must be 10 digits');
      expect(failure.code, 'VAL_PHONE');
    });
  });
}
