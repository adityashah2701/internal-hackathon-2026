import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('AppEnvironment fallback parsing defaults to development', () {
      expect(AppEnvironment.fromString('development'), AppEnvironment.development);
      expect(AppEnvironment.fromString('dev'), AppEnvironment.development);
      expect(AppEnvironment.fromString('unknown_string'), AppEnvironment.development);
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('production'), AppEnvironment.production);
    });

    test('sanitizedSupabaseHost returns Not Configured when empty', () {
      if (AppConfig.supabaseUrl.isEmpty) {
        expect(AppConfig.sanitizedSupabaseHost, 'Not Configured');
      }
    });

    test('AppConfig exposes version', () {
      expect(AppConfig.appVersion.isNotEmpty, isTrue);
    });
  });
}
