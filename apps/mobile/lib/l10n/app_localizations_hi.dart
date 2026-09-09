// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'सहयोग';

  @override
  String get appTagline => 'सहकारी स्वामित्व वाला डिजिटल सेवा बाज़ार';

  @override
  String get systemVerification => 'सिस्टम निदान';

  @override
  String get supabaseStatus => 'सुपाबेस क्लाइंट';

  @override
  String get statusConfigured => 'कॉन्फ़िगर और तैयार';

  @override
  String get statusNotConfigured => 'कॉन्फ़िगरेशन प्रतीक्षारत';

  @override
  String get environment => 'पर्यावरण';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get authSession => 'ऑथ सत्र';

  @override
  String get noActiveSession => 'कोई सक्रिय सत्र नहीं (अतिथि)';

  @override
  String get supportedLanguages => 'समर्थित भाषाएँ';

  @override
  String get roleCustomer => 'ग्राहक';

  @override
  String get roleWorker => 'श्रमिक';

  @override
  String get roleCooperativeAdmin => 'सहकारी प्रबंधक';

  @override
  String get roleFederationAdmin => 'महासंघ व्यवस्थापक';

  @override
  String get refreshDiagnostics => 'निदान पुनः जांचें';
}
