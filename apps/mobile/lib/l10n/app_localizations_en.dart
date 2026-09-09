// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sahayog';

  @override
  String get appTagline => 'Cooperative-Owned Digital Service Marketplace';

  @override
  String get systemVerification => 'System Diagnostics';

  @override
  String get supabaseStatus => 'Supabase Client';

  @override
  String get statusConfigured => 'Configured & Ready';

  @override
  String get statusNotConfigured => 'Pending Configuration';

  @override
  String get environment => 'Environment';

  @override
  String get appVersion => 'App Version';

  @override
  String get authSession => 'Auth Session';

  @override
  String get noActiveSession => 'No active session (Guest)';

  @override
  String get supportedLanguages => 'Supported Languages';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleWorker => 'Worker';

  @override
  String get roleCooperativeAdmin => 'Cooperative Admin';

  @override
  String get roleFederationAdmin => 'Federation Admin';

  @override
  String get refreshDiagnostics => 'Re-check Diagnostics';
}
