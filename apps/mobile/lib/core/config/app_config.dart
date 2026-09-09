enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }
}

/// Central application configuration.
///
/// Injected at compile time via:
/// `--dart-define-from-file=.env` or `--dart-define=KEY=VALUE`
///
/// CRITICAL: Only client-safe credentials (Project URL, Anon Key)
/// are allowed here. Service role keys or database credentials must NEVER be placed here.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jelpforpweirbgqlehof.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_awpZwynH60EvvoSOZFZgdw_01HTaj-0',
  );

  static const String _envString = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static final AppEnvironment environment = AppEnvironment.fromString(_envString);

  static const String appVersion = '1.0.0+1';

  /// Whether Supabase configuration credentials have been supplied.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sanitized host name for diagnostic display without leaking credentials.
  static String get sanitizedSupabaseHost {
    if (supabaseUrl.isEmpty) {
      return 'Not Configured';
    }
    try {
      final Uri uri = Uri.parse(supabaseUrl);
      return uri.host.isNotEmpty ? uri.host : 'Invalid URL';
    } on FormatException {
      return 'Malformed URL';
    }
  }
}
