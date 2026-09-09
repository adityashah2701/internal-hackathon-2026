import 'package:flutter/material.dart';

/// Centralized modern design tokens for the Sahayog platform.
/// Visual identity: Modern Indian fintech / SaaS / mobility platform (Indigo/Violet + Cool Neutrals).
abstract final class AppColors {
  // Brand Primary (Deep Indigo / Blue-Violet)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4338CA);

  // Secondary Accent (Soft Violet)
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF6D28D9);

  // Surface & Neutral (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Surface & Neutral (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF16A34A); // Muted modern green for verified/completed
  static const Color warning = Color(0xFFD97706); // Warm amber
  static const Color error = Color(0xFFDC2626);   // Clean red
  static const Color info = Color(0xFF3B82F6);    // Neutral blue

  // Role Badges & Contextual Accents
  static const Color roleCustomer = Color(0xFF4F46E5);    // Indigo
  static const Color roleWorker = Color(0xFFEA580C);      // Warm Craftsman Orange (replaces green)
  static const Color roleCooperative = Color(0xFF7C3AED); // Soft Violet
  static const Color roleFederation = Color(0xFF0EA5E9);  // Sky Blue
}
