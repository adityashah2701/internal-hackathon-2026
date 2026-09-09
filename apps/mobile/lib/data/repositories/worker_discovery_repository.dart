import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';

/// A discovered worker result returned by the nearby worker search.
class DiscoveredWorker {
  const DiscoveredWorker({
    required this.workerId,
    required this.fullName,
    required this.skills,
    required this.experienceYears,
    required this.hourlyRateInr,
    required this.dailyRateInr,
    this.cooperativeName,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.distanceKm = 0,
  });

  final String workerId;
  final String fullName;
  final List<String> skills;
  final int experienceYears;
  final int hourlyRateInr;
  final int dailyRateInr;
  final String? cooperativeName;
  final double ratingAvg;
  final int reviewCount;
  final double distanceKm;

  factory DiscoveredWorker.fromJson(Map<String, Object?> json) {
    final Object? rawSkills = json['skills'];
    final List<String> parsedSkills = <String>[];
    if (rawSkills is List) {
      for (final Object? item in rawSkills) {
        if (item is String) parsedSkills.add(item);
      }
    }

    return DiscoveredWorker(
      workerId: json['worker_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Worker',
      skills: parsedSkills,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      hourlyRateInr: (json['hourly_rate_inr'] as num?)?.toInt() ?? 150,
      dailyRateInr: (json['daily_rate_inr'] as num?)?.toInt() ?? 500,
      cooperativeName: json['cooperative_name'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Display-friendly distance string.
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

/// Repository for discovering nearby verified workers based on location, skill, and availability.
abstract interface class IWorkerDiscoveryRepository {
  /// Finds nearby workers matching the given criteria.
  ///
  /// Uses the server-side `find_nearby_workers` Postgres function for efficient
  /// geo-distance calculation (Haversine).
  Future<List<DiscoveredWorker>> findNearbyWorkers({
    required double latitude,
    required double longitude,
    String? skill,
    double radiusKm,
    int limit,
    int offset,
  });
}

class SupabaseWorkerDiscoveryRepository implements IWorkerDiscoveryRepository {
  SupabaseWorkerDiscoveryRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  @override
  Future<List<DiscoveredWorker>> findNearbyWorkers({
    required double latitude,
    required double longitude,
    String? skill,
    double radiusKm = 25,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> response = await _safeClient.rpc(
        'find_nearby_workers',
        params: <String, Object?>{
          'p_lat': latitude,
          'p_lng': longitude,
          'p_skill': skill,
          'p_radius_km': radiusKm,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      return response
          .cast<Map<String, Object?>>()
          .map(DiscoveredWorker.fromJson)
          .toList();
    } catch (e, st) {
      AppLogger.error('Error finding nearby workers', error: e, stackTrace: st);
      return const <DiscoveredWorker>[];
    }
  }
}

final Provider<IWorkerDiscoveryRepository> workerDiscoveryRepositoryProvider =
    Provider<IWorkerDiscoveryRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseWorkerDiscoveryRepository(client: client);
});
