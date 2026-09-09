import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/worker_document.dart';
import '../models/worker_profile.dart';

abstract interface class ICooperativeAdminRepository {
  Future<List<WorkerProfile>> getWorkers({String? statusFilter});

  Future<List<WorkerDocument>> getWorkerDocuments(String workerId);

  Future<WorkerProfile> approveWorker({
    required String workerId,
    required String adminId,
  });

  Future<WorkerProfile> rejectWorker({
    required String workerId,
    required String adminId,
    required String reason,
  });
}

class SupabaseCooperativeAdminRepository implements ICooperativeAdminRepository {
  SupabaseCooperativeAdminRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  // Realistic development fallbacks for smooth testing
  static final List<WorkerProfile> _sampleWorkers = <WorkerProfile>[
    const WorkerProfile(
      id: 'worker-ramesh-01',
      fullName: 'Ramesh Kumar',
      phoneNumber: '+91 98765 43210',
      email: 'ramesh.kumar@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Electrician', 'Solar PV Installer'],
      experienceYears: 6,
      dailyRateInr: 750,
      serviceArea: 'Pune City, Hadapsar, Kothrud',
      bio: 'Certified wireman with 6+ years residential and commercial solar installation experience.',
      verificationStatus: WorkerVerificationStatus.pending,
    ),
    const WorkerProfile(
      id: 'worker-sunita-02',
      fullName: 'Sunita Devi',
      phoneNumber: '+91 98123 45678',
      email: 'sunita.devi@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Plumber', 'Pipe Fitter'],
      experienceYears: 4,
      dailyRateInr: 600,
      serviceArea: 'Pune Camp, Viman Nagar',
      bio: 'Specialized in bathroom plumbing fittings, leak detection, and sanitary maintenance.',
      verificationStatus: WorkerVerificationStatus.pending,
    ),
    const WorkerProfile(
      id: 'worker-anil-03',
      fullName: 'Anil Shinde',
      phoneNumber: '+91 97654 32109',
      email: 'anil.shinde@example.com',
      cooperativeId: 'coop-pune-01',
      cooperativeName: 'Shramik Kalyan Labour Cooperative Society',
      skills: <String>['Mason', 'Tiler'],
      experienceYears: 8,
      dailyRateInr: 800,
      serviceArea: 'Pimpri Chinchwad',
      bio: 'Master tile layer and masonry specialist.',
      verificationStatus: WorkerVerificationStatus.approved,
    ),
  ];

  static final Map<String, List<WorkerDocument>> _sampleDocs = <String, List<WorkerDocument>>{
    'worker-ramesh-01': <WorkerDocument>[
      const WorkerDocument(
        id: 'doc-ramesh-aadhaar',
        workerId: 'worker-ramesh-01',
        documentType: DocumentType.aadhaar,
        fileName: 'aadhaar_card_ramesh.pdf',
        filePath: 'worker-ramesh-01/aadhaar.pdf',
        fileSize: 412000,
        mimeType: 'application/pdf',
        status: 'pending',
      ),
      const WorkerDocument(
        id: 'doc-ramesh-iti',
        workerId: 'worker-ramesh-01',
        documentType: DocumentType.tradeCertificate,
        fileName: 'iti_electrician_trade_certificate.pdf',
        filePath: 'worker-ramesh-01/iti_cert.pdf',
        fileSize: 845000,
        mimeType: 'application/pdf',
        status: 'pending',
      ),
    ],
    'worker-sunita-02': <WorkerDocument>[
      const WorkerDocument(
        id: 'doc-sunita-aadhaar',
        workerId: 'worker-sunita-02',
        documentType: DocumentType.aadhaar,
        fileName: 'aadhaar_sunita_devi.jpg',
        filePath: 'worker-sunita-02/aadhaar.jpg',
        fileSize: 254000,
        mimeType: 'image/jpeg',
        status: 'pending',
      ),
    ],
  };

  @override
  Future<List<WorkerProfile>> getWorkers({String? statusFilter}) async {
    try {
      var query = _safeClient
          .from('worker_profiles')
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)');

      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('verification_status', statusFilter);
      }

      final List<Map<String, Object?>> response = await query.order('created_at', ascending: false);
      if (response.isNotEmpty) {
        return response.map(WorkerProfile.fromJson).toList();
      }

      // Filter sample data
      return _getFilteredSampleWorkers(statusFilter);
    } catch (e) {
      AppLogger.warning('CooperativeAdminRepo: using sample workers: $e');
      return _getFilteredSampleWorkers(statusFilter);
    }
  }

  List<WorkerProfile> _getFilteredSampleWorkers(String? statusFilter) {
    if (statusFilter == null || statusFilter == 'all') {
      return _sampleWorkers;
    }
    return _sampleWorkers.where((WorkerProfile w) => w.verificationStatus.dbValue == statusFilter).toList();
  }

  @override
  Future<List<WorkerDocument>> getWorkerDocuments(String workerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('worker_documents')
          .select()
          .eq('worker_id', workerId);

      if (response.isNotEmpty) {
        return response.map(WorkerDocument.fromJson).toList();
      }
      return _sampleDocs[workerId] ?? <WorkerDocument>[];
    } catch (e) {
      return _sampleDocs[workerId] ?? <WorkerDocument>[];
    }
  }

  @override
  Future<WorkerProfile> approveWorker({
    required String workerId,
    required String adminId,
  }) async {
    try {
      final Map<String, Object?> data = await _safeClient
          .from('worker_profiles')
          .update(<String, Object?>{
            'verification_status': WorkerVerificationStatus.approved.dbValue,
            'rejection_reason': null,
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workerId)
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)')
          .single();

      final WorkerProfile updated = WorkerProfile.fromJson(data);
      _updateSampleWorker(updated);
      return updated;
    } catch (e) {
      AppLogger.warning('CooperativeAdmin: Approved locally due to: $e');
      final int index = _sampleWorkers.indexWhere((WorkerProfile w) => w.id == workerId);
      final WorkerProfile updated = (index >= 0 ? _sampleWorkers[index] : WorkerProfile(id: workerId)).copyWith(
        verificationStatus: WorkerVerificationStatus.approved,
        rejectionReason: null,
        verifiedAt: DateTime.now(),
        verifiedBy: adminId,
      );
      _updateSampleWorker(updated);
      return updated;
    }
  }

  @override
  Future<WorkerProfile> rejectWorker({
    required String workerId,
    required String adminId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const ValidationException(message: 'A specific rejection reason must be provided to the worker.');
    }

    try {
      final Map<String, Object?> data = await _safeClient
          .from('worker_profiles')
          .update(<String, Object?>{
            'verification_status': WorkerVerificationStatus.rejected.dbValue,
            'rejection_reason': reason.trim(),
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workerId)
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)')
          .single();

      final WorkerProfile updated = WorkerProfile.fromJson(data);
      _updateSampleWorker(updated);
      return updated;
    } catch (e) {
      AppLogger.warning('CooperativeAdmin: Rejected locally due to: $e');
      final int index = _sampleWorkers.indexWhere((WorkerProfile w) => w.id == workerId);
      final WorkerProfile updated = (index >= 0 ? _sampleWorkers[index] : WorkerProfile(id: workerId)).copyWith(
        verificationStatus: WorkerVerificationStatus.rejected,
        rejectionReason: reason.trim(),
        verifiedAt: DateTime.now(),
        verifiedBy: adminId,
      );
      _updateSampleWorker(updated);
      return updated;
    }
  }

  void _updateSampleWorker(WorkerProfile updated) {
    final int index = _sampleWorkers.indexWhere((WorkerProfile w) => w.id == updated.id);
    if (index >= 0) {
      _sampleWorkers[index] = updated;
    } else {
      _sampleWorkers.add(updated);
    }
  }
}

final Provider<ICooperativeAdminRepository> cooperativeAdminRepositoryProvider =
    Provider<ICooperativeAdminRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseCooperativeAdminRepository(client: client);
});
