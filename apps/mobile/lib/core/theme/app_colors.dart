import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Primary (Cooperative Trust & Sustainability - Forest/Emerald)
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primaryDark = Color(0xFF003300);

  // Secondary (Warm Cooperative Gold / Amber)
  static const Color secondary = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF833A);
  static const Color secondaryDark = Color(0xFFAC1900);

  // Surface & Neutral (Light)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF616161);
  static const Color borderLight = Color(0xFFE0E0E0);

  // Surface & Neutral (Dark)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFEDEDED);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color borderDark = Color(0xFF2C2C2C);

  // Feedback Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // Role Badges & Accent Colors
  static const Color roleCustomer = Color(0xFF1976D2);
  static const Color roleWorker = Color(0xFF2E7D32);
  static const Color roleCooperative = Color(0xFFE65100);
  static const Color roleFederation = Color(0xFF6A1B9A);
}
