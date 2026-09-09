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

  // Fallback workers for instant demo & testing
  static final List<WorkerProfile> _sampleWorkers = <WorkerProfile>[
    const WorkerProfile(
      id: 'fed-worker-01',
      fullName: 'Ramesh Kumar',
      phoneNumber: '+91 98765 43210',
      email: 'ramesh.kumar@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Electrician', 'Solar PV'],
      experienceYears: 6,
      dailyRateInr: 750,
      serviceArea: 'Pune',
      verificationStatus: WorkerVerificationStatus.pending,
    ),
    const WorkerProfile(
      id: 'fed-worker-02',
      fullName: 'Sunita Devi',
      phoneNumber: '+91 98123 45678',
      email: 'sunita.devi@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Plumber'],
      experienceYears: 4,
      dailyRateInr: 600,
      serviceArea: 'Pune',
      verificationStatus: WorkerVerificationStatus.pending,
    ),
    const WorkerProfile(
      id: 'fed-worker-03',
      fullName: 'Anil Shinde',
      phoneNumber: '+91 97654 32109',
      email: 'anil.shinde@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Mason', 'Tiler'],
      experienceYears: 8,
      dailyRateInr: 800,
      serviceArea: 'Pune',
      verificationStatus: WorkerVerificationStatus.approved,
    ),
    const WorkerProfile(
      id: 'fed-worker-04',
      fullName: 'Venkatesh Rao',
      phoneNumber: '+91 94480 12345',
      email: 'venkatesh.rao@example.com',
      cooperativeId: 'coop-blr-02',
      cooperativeName: 'Sahakar Nirman Workers Union',
      skills: <String>['Carpenter', 'Wood Finisher'],
      experienceYears: 10,
      dailyRateInr: 950,
      serviceArea: 'Bengaluru',
      verificationStatus: WorkerVerificationStatus.approved,
    ),
    const WorkerProfile(
      id: 'fed-worker-05',
      fullName: 'Mohammed Tariq',
      phoneNumber: '+91 98110 54321',
      email: 'tariq.m@example.com',
      cooperativeId: 'coop-del-03',
      cooperativeName: 'Lokseva Artisan Cooperative Federation',
      skills: <String>['Painter', 'Waterproofing'],
      experienceYears: 5,
      dailyRateInr: 700,
      serviceArea: 'Central Delhi',
      verificationStatus: WorkerVerificationStatus.approved,
    ),
  ];

  @override
  Future<FederationMetrics> getMetrics() async {
    try {
      final List<Map<String, Object?>> workerRows =
          await _safeClient.from('worker_profiles').select('verification_status');

      final List<Map<String, Object?>> coopRows =
          await _safeClient.from('cooperatives').select('id');

      if (workerRows.isNotEmpty || coopRows.isNotEmpty) {
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
          activeCooperatives: coopRows.isNotEmpty ? coopRows.length : 3,
        );
      }

      return _sampleMetrics;
    } catch (e) {
      AppLogger.warning('FederationAdminRepo: using sample metrics: $e');
      return _sampleMetrics;
    }
  }

  FederationMetrics get _sampleMetrics {
    int total = _sampleWorkers.length;
    int verified = _sampleWorkers.where((WorkerProfile w) => w.verificationStatus.isApproved).length;
    int pending = _sampleWorkers.where((WorkerProfile w) => w.verificationStatus.isPending).length;
    return FederationMetrics(
      totalWorkers: total,
      verifiedWorkers: verified,
      pendingVerifications: pending,
      activeCooperatives: CooperativeSociety.fallbackSocieties.length,
    );
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
      if (response.isNotEmpty) {
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
      }

      return _filterSampleWorkers(searchQuery, statusFilter, cooperativeId);
    } catch (e) {
      return _filterSampleWorkers(searchQuery, statusFilter, cooperativeId);
    }
  }

  List<WorkerProfile> _filterSampleWorkers(
    String? searchQuery,
    String? statusFilter,
    String? cooperativeId,
  ) {
    Iterable<WorkerProfile> results = _sampleWorkers;
    if (statusFilter != null && statusFilter != 'all') {
      results = results.where((WorkerProfile w) => w.verificationStatus.dbValue == statusFilter);
    }
    if (cooperativeId != null && cooperativeId.isNotEmpty) {
      results = results.where((WorkerProfile w) => w.cooperativeId == cooperativeId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final String q = searchQuery.toLowerCase().trim();
      results = results.where((WorkerProfile w) {
        final String name = (w.fullName ?? '').toLowerCase();
        final String skills = w.skills.join(' ').toLowerCase();
        final String area = w.serviceArea.toLowerCase();
        return name.contains(q) || skills.contains(q) || area.contains(q);
      });
    }
    return results.toList();
  }

  @override
  Future<List<CooperativeSociety>> getCooperatives() async {
    try {
      final List<Map<String, Object?>> response =
          await _safeClient.from('cooperatives').select().order('name');
      if (response.isNotEmpty) {
        return response.map(CooperativeSociety.fromJson).toList();
      }
      return CooperativeSociety.fallbackSocieties;
    } catch (_) {
      return CooperativeSociety.fallbackSocieties;
    }
  }
}

final Provider<IFederationAdminRepository> federationAdminRepositoryProvider =
    Provider<IFederationAdminRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseFederationAdminRepository(client: client);
});
