import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Centralized wrapper for Supabase client initialization and access.
abstract final class SupabaseClientManager {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initializes the Supabase SDK safely.
  /// If credentials are not configured, logs a warning rather than crashing.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!AppConfig.isSupabaseConfigured) {
      AppLogger.warning(
        'Supabase credentials not found. Running in unconfigured/offline mode.',
        tag: 'SupabaseInit',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        debug: AppConfig.environment == AppEnvironment.development,
      );
      _isInitialized = true;
      AppLogger.info('Supabase client initialized successfully.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to initialize Supabase client.',
        tag: 'SupabaseInit',
        error: e,
        stackTrace: st,
      );
      _isInitialized = false;
    }
  }

  /// Direct client accessor (returns null if uninitialized/unconfigured)
  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for the SupabaseClient instance (nullable if not initialized).
final Provider<SupabaseClient?> supabaseClientProvider = Provider<SupabaseClient?>((Ref ref) {
  return SupabaseClientManager.client;
});

/// Riverpod provider checking whether Supabase is configured and initialized.
final Provider<bool> isSupabaseInitializedProvider = Provider<bool>((Ref ref) {
  return SupabaseClientManager.isInitialized;
});

/// Riverpod provider for Supabase Auth state changes.
final StreamProvider<AuthState?> authStateStreamProvider = StreamProvider<AuthState?>((Ref ref) {
  final SupabaseClient? client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return const Stream<AuthState?>.empty();
  }
  return client.auth.onAuthStateChange;
});
