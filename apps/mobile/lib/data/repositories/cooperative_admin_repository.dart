import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/worker_document.dart';
import '../models/worker_profile.dart';
import 'worker_data_store.dart';

abstract interface class ICooperativeAdminRepository {
  Future<List<WorkerProfile>> getWorkers({String? statusFilter});

  Future<List<WorkerDocument>> getWorkerDocuments(String workerId);

  Future<String?> getDocumentPayload(String filePath);

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
      final List<WorkerProfile> dbWorkers = response.map(WorkerProfile.fromJson).toList();
      for (final WorkerProfile w in dbWorkers) {
        WorkerDataStore.upsertProfile(w);
      }
      return dbWorkers;
    } catch (e) {
      AppLogger.warning('CooperativeAdminRepo: error fetching from database, checking local store: $e');
      return WorkerDataStore.getAllWorkers(statusFilter: statusFilter);
    }
  }

  @override
  Future<List<WorkerDocument>> getWorkerDocuments(String workerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('worker_documents')
          .select()
          .eq('worker_id', workerId);

      if (response.isNotEmpty) {
        final List<WorkerDocument> docs = response.map(WorkerDocument.fromJson).toList();
        final List<WorkerDocument> enriched = await Future.wait(docs.map((WorkerDocument doc) async {
          if (doc.filePath.isNotEmpty) {
            try {
              final String signedUrl = await _safeClient.storage
                  .from('kyc-documents')
                  .createSignedUrl(doc.filePath, 3600);
              return doc.copyWith(downloadUrl: signedUrl);
            } catch (_) {
              return doc;
            }
          }
          return doc;
        }));
        return enriched;
      }
      return WorkerDataStore.documents[workerId] ?? <WorkerDocument>[];
    } catch (e) {
      return WorkerDataStore.documents[workerId] ?? <WorkerDocument>[];
    }
  }

  @override
  Future<String?> getDocumentPayload(String filePath) async {
    if (filePath.isEmpty) return null;
    try {
      final Uint8List bytes = await _safeClient.storage.from('kyc-documents').download(filePath);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      AppLogger.warning('CooperativeAdmin: Fallback payload lookup: $e');
      return WorkerDataStore.documentPayloads[filePath];
    }
  }

  @override
  Future<WorkerProfile> approveWorker({
    required String workerId,
    required String adminId,
  }) async {
    WorkerDataStore.approve(workerId, adminId);

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
      WorkerDataStore.upsertProfile(updated);
      return updated;
    } catch (e) {
      AppLogger.warning('CooperativeAdmin: Approved in local session due to: $e');
      return WorkerDataStore.getOrCreateProfile(workerId);
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

    WorkerDataStore.reject(workerId, adminId, reason);

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
      WorkerDataStore.upsertProfile(updated);
      return updated;
    } catch (e) {
      AppLogger.warning('CooperativeAdmin: Rejected in local session due to: $e');
      return WorkerDataStore.getOrCreateProfile(workerId);
    }
  }
}

final Provider<ICooperativeAdminRepository> cooperativeAdminRepositoryProvider =
    Provider<ICooperativeAdminRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseCooperativeAdminRepository(client: client);
});
