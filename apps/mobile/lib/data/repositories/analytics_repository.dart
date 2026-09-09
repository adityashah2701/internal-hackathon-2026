import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';

/// Federation-wide and cooperative-level analytics from real Supabase data.
///
/// All metrics are derived from server-side aggregation (not client-side counting).
/// If no data exists, values are 0 — never fabricated.
class FederationMetrics {
  const FederationMetrics({
    this.totalWorkers = 0,
    this.verifiedWorkers = 0,
    this.pendingVerifications = 0,
    this.activeCooperatives = 0,
    this.completedBookings = 0,
    this.totalServiceValueInr = 0,
    this.totalWelfarePoolInr = 0,
    this.totalBookings = 0,
    this.activeWorkers = 0,
  });

  final int totalWorkers;
  final int verifiedWorkers;
  final int pendingVerifications;
  final int activeCooperatives;
  final int completedBookings;
  final int totalServiceValueInr;
  final int totalWelfarePoolInr;
  final int totalBookings;
  final int activeWorkers;

  factory FederationMetrics.fromJson(Map<String, Object?> json) {
    return FederationMetrics(
      totalWorkers: (json['total_workers'] as num?)?.toInt() ?? 0,
      verifiedWorkers: (json['verified_workers'] as num?)?.toInt() ?? 0,
      pendingVerifications: (json['pending_verifications'] as num?)?.toInt() ?? 0,
      activeCooperatives: (json['active_cooperatives'] as num?)?.toInt() ?? 0,
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      totalServiceValueInr: (json['total_service_value_inr'] as num?)?.toInt() ?? 0,
      totalWelfarePoolInr: (json['total_welfare_pool_inr'] as num?)?.toInt() ?? 0,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      activeWorkers: (json['active_workers'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract interface class IAnalyticsRepository {
  /// Fetches federation-wide metrics via server-side aggregation function.
  Future<FederationMetrics> getFederationMetrics();

  /// Checks if enough booking data exists for demand forecasting.
  /// Returns the count of completed bookings.
  Future<int> getCompletedBookingCount();
}

class SupabaseAnalyticsRepository implements IAnalyticsRepository {
  SupabaseAnalyticsRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  @override
  Future<FederationMetrics> getFederationMetrics() async {
    try {
      final dynamic response = await _safeClient.rpc('get_federation_metrics');
      if (response is Map<String, Object?>) {
        return FederationMetrics.fromJson(response);
      }
      return const FederationMetrics();
    } catch (e, st) {
      AppLogger.error('Error loading federation metrics', error: e, stackTrace: st);
      return const FederationMetrics();
    }
  }

  @override
  Future<int> getCompletedBookingCount() async {
    try {
      final sb.PostgrestResponse response = await _safeClient
          .from('bookings')
          .select()
          .inFilter('status', <String>['completed', 'payment_confirmed', 'reviewed'])
          .count(sb.CountOption.exact);

      return response.count;
    } catch (e) {
      AppLogger.warning('Error counting completed bookings: $e', tag: 'AnalyticsRepo');
      return 0;
    }
  }
}

final Provider<IAnalyticsRepository> analyticsRepositoryProvider =
    Provider<IAnalyticsRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseAnalyticsRepository(client: client);
});
