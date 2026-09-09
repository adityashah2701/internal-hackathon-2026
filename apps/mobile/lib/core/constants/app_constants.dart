import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'Sahayog';
  static const String appTagline =
      'Cooperative-Owned Digital Service Marketplace';

  // Network & Timeout constants
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Supported Locales
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
  ];

  // Storage Buckets (Pre-declared for future Supabase storage)
  static const String kycBucket = 'kyc-documents';
  static const String certificatesBucket = 'skill-certificates';
  static const String avatarsBucket = 'user-avatars';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 1.0;
}
