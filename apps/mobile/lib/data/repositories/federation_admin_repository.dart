import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/cooperative_society.dart';
import '../models/worker_profile.dart';

class FederationMetrics {
  const FederationMetrics({
    required this.totalWorkers,
    required this.verifiedWorkers,
    required this.pendingVerifications,
    required this.activeCooperatives,
  });

  final int totalWorkers;
  final int verifiedWorkers;
  final int pendingVerifications;
  final int activeCooperatives;
}

abstract interface class IFederationAdminRepository {
  Future<FederationMetrics> getMetrics();

  Future<List<WorkerProfile>> getFilteredWorkers({
    String? searchQuery,
    String? statusFilter,
    String? cooperativeId,
  });

  Future<List<CooperativeSociety>> getCooperatives();
}

class SupabaseFederationAdminRepository implements IFederationAdminRepository {
  SupabaseFederationAdminRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline.');
    }
    return safeClient;
  }

  @override
  Future<FederationMetrics> getMetrics() async {
    try {
      final List<Map<String, Object?>> workerRows =
          await _safeClient.from('worker_profiles').select('verification_status');

      final List<Map<String, Object?>> coopRows =
          await _safeClient.from('cooperatives').select('id');

      int total = workerRows.length;
      int verified = 0;
      int pending = 0;
      for (final Map<String, Object?> row in workerRows) {
        final String? status = row['verification_status'] as String?;
        if (status == WorkerVerificationStatus.approved.dbValue) {
          verified++;
        } else if (status == WorkerVerificationStatus.pending.dbValue) {
          pending++;
        }
      }
      return FederationMetrics(
        totalWorkers: total,
        verifiedWorkers: verified,
        pendingVerifications: pending,
        activeCooperatives: coopRows.length,
      );
    } catch (e) {
      AppLogger.warning('FederationAdminRepo: error fetching metrics: $e');
      return const FederationMetrics(
        totalWorkers: 0,
        verifiedWorkers: 0,
        pendingVerifications: 0,
        activeCooperatives: 0,
      );
    }
  }

  @override
  Future<List<WorkerProfile>> getFilteredWorkers({
    String? searchQuery,
    String? statusFilter,
    String? cooperativeId,
  }) async {
    try {
      var query = _safeClient
          .from('worker_profiles')
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)');

      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('verification_status', statusFilter);
      }
      if (cooperativeId != null && cooperativeId.isNotEmpty) {
        query = query.eq('cooperative_id', cooperativeId);
      }

      final List<Map<String, Object?>> response = await query;
      List<WorkerProfile> workers = response.map(WorkerProfile.fromJson).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final String q = searchQuery.toLowerCase().trim();
        workers = workers.where((WorkerProfile w) {
          final String name = (w.fullName ?? '').toLowerCase();
          final String skills = w.skills.join(' ').toLowerCase();
          final String area = w.serviceArea.toLowerCase();
          return name.contains(q) || skills.contains(q) || area.contains(q);
        }).toList();
      }
      return workers;
    } catch (e) {
      AppLogger.warning('FederationAdminRepo: error querying workers: $e');
      return <WorkerProfile>[];
    }
  }

  @override
  Future<List<CooperativeSociety>> getCooperatives() async {
    try {
      final List<Map<String, Object?>> response =
          await _safeClient.from('cooperatives').select().order('name');
      return response.map(CooperativeSociety.fromJson).toList();
    } catch (_) {
      return <CooperativeSociety>[];
    }
  }
}

final Provider<IFederationAdminRepository> federationAdminRepositoryProvider =
    Provider<IFederationAdminRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseFederationAdminRepository(client: client);
});
