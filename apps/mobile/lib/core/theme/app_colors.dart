import 'package:flutter/material.dart';

/// Centralized modern design tokens for the Sahayog platform.
/// Visual identity: Modern Indian fintech / SaaS / mobility platform (Indigo/Violet + Cool Neutrals).
abstract final class AppColors {
  // Brand Primary (Vibrant Solar Gold / Warm Amber)
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryLight = Color(0xFFFBBF24);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color onPrimary = Color(0xFF18181B); // High-contrast deep charcoal text/icons on yellow

  // Secondary Accent (Refined Charcoal & Slate Gray)
  static const Color secondary = Color(0xFF3F3F46);
  static const Color secondaryLight = Color(0xFF71717A);
  static const Color secondaryDark = Color(0xFF18181B);

  // Surface & Neutral (Light Mode)
  static const Color backgroundLight = Color(0xFFF4F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF18181B);
  static const Color textSecondaryLight = Color(0xFF71717A);
  static const Color borderLight = Color(0xFFE4E4E7);

  // Surface & Neutral (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F0F12);
  static const Color surfaceDark = Color(0xFF18181B);
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color borderDark = Color(0xFF27272A);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald green for verified/completed
  static const Color warning = Color(0xFFF59E0B); // Warm amber
  static const Color error = Color(0xFFEF4444);   // Crisp crimson red
  static const Color info = Color(0xFF64748B);    // Neutral slate

  // Role Badges & Contextual Accents (Harmonized with Yellow & Gray)
  static const Color roleCustomer = Color(0xFFF59E0B);    // Solar Gold
  static const Color roleWorker = Color(0xFFEA580C);      // Craftsman Ochre / Warm Amber-Orange
  static const Color roleCooperative = Color(0xFF52525B); // Industrial Steel Slate
  static const Color roleFederation = Color(0xFFD97706);  // Apex Amber
}
