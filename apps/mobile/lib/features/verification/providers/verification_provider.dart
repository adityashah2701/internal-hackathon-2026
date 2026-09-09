import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/supabase_client.dart';

enum SupabaseConnectivityStatus {
  notConfigured,
  connecting,
  connected,
  unreachable,
}

class DiagnosticsState {
  const DiagnosticsState({
    required this.isConfigured,
    required this.sanitizedHost,
    required this.environment,
    required this.appVersion,
    required this.connectivityStatus,
    required this.hasActiveAuthSession,
    this.errorMessage,
  });

  final bool isConfigured;
  final String sanitizedHost;
  final String environment;
  final String appVersion;
  final SupabaseConnectivityStatus connectivityStatus;
  final bool hasActiveAuthSession;
  final String? errorMessage;
}

class DiagnosticsNotifier extends Notifier<DiagnosticsState> {
  @override
  DiagnosticsState build() {
    final bool configured = AppConfig.isSupabaseConfigured;
    final SupabaseClient? client = ref.watch(supabaseClientProvider);

    final DiagnosticsState initialState = DiagnosticsState(
      isConfigured: configured,
      sanitizedHost: AppConfig.sanitizedSupabaseHost,
      environment: AppConfig.environment.name,
      appVersion: AppConfig.appVersion,
      connectivityStatus: configured
          ? SupabaseConnectivityStatus.connecting
          : SupabaseConnectivityStatus.notConfigured,
      hasActiveAuthSession: client?.auth.currentSession != null,
    );

    if (configured && client != null) {
      // Trigger async check
      Future<void>.microtask(checkConnectivity);
    }

    return initialState;
  }

  Future<void> checkConnectivity() async {
    final SupabaseClient? client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = DiagnosticsState(
        isConfigured: false,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.notConfigured,
        hasActiveAuthSession: false,
      );
      return;
    }

    state = DiagnosticsState(
      isConfigured: true,
      sanitizedHost: AppConfig.sanitizedSupabaseHost,
      environment: AppConfig.environment.name,
      appVersion: AppConfig.appVersion,
      connectivityStatus: SupabaseConnectivityStatus.connecting,
      hasActiveAuthSession: client.auth.currentSession != null,
    );

    try {
      // Lightweight health check against Supabase
      await client.from('_health_check_dummy_').select().limit(1).maybeSingle();
      // If no exception was thrown, connection is active
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.connected,
        hasActiveAuthSession: client.auth.currentSession != null,
      );
    } on PostgrestException catch (e) {
      // Even if table does not exist (error code 42P01 or relation does not exist),
      // the Supabase database responded over the network, confirming connectivity!
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.connected,
        hasActiveAuthSession: client.auth.currentSession != null,
        errorMessage: e.code == 'PGRST204' || e.code == '42P01' || e.code == 'PGRST205' ? null : e.message,
      );
    } catch (_) {
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.unreachable,
        hasActiveAuthSession: client.auth.currentSession != null,
        errorMessage: 'Backend is unreachable or offline',
      );
    }
  }
}

final NotifierProvider<DiagnosticsNotifier, DiagnosticsState> diagnosticsProvider =
    NotifierProvider<DiagnosticsNotifier, DiagnosticsState>(
  DiagnosticsNotifier.new,
  isAutoDispose: true,
);
