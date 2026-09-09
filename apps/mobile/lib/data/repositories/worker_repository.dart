import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/cooperative_society.dart';
import '../models/worker_document.dart';
import '../models/worker_profile.dart';
import 'worker_data_store.dart';

abstract interface class IWorkerRepository {
  Future<WorkerProfile> getWorkerProfile(String workerId);

  Future<WorkerProfile> updateWorkerProfile(WorkerProfile profile);

  Future<WorkerProfile> submitForVerification(String workerId);

  Future<List<WorkerDocument>> getDocuments(String workerId);

  Future<WorkerDocument> uploadDocument({
    required String workerId,
    required DocumentType documentType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  });

  Future<void> deleteDocument({
    required String documentId,
    required String filePath,
  });

  Future<List<CooperativeSociety>> getCooperatives();
}

class SupabaseWorkerRepository implements IWorkerRepository {
  SupabaseWorkerRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or not configured.');
    }
    return safeClient;
  }

  @override
  Future<WorkerProfile> getWorkerProfile(String workerId) async {
    try {
      final Map<String, Object?>? data = await _safeClient
          .from('worker_profiles')
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)')
          .eq('id', workerId)
          .maybeSingle();

      if (data != null) {
        final WorkerProfile profile = WorkerProfile.fromJson(data);
        WorkerDataStore.upsertProfile(profile);
        return profile;
      }

      return WorkerDataStore.getOrCreateProfile(workerId);
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException fetching worker profile: ${e.message}', tag: 'WorkerRepo');
      return WorkerDataStore.getOrCreateProfile(workerId);
    } catch (e, st) {
      AppLogger.error('Error fetching worker profile', error: e, stackTrace: st);
      return WorkerDataStore.getOrCreateProfile(workerId);
    }
  }

  @override
  Future<WorkerProfile> updateWorkerProfile(WorkerProfile profile) async {
    WorkerDataStore.upsertProfile(profile);

    try {
      final Map<String, Object?> data = await _safeClient
          .from('worker_profiles')
          .upsert(profile.toJson())
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)')
          .single();

      final WorkerProfile updated = WorkerProfile.fromJson(data);
      WorkerDataStore.upsertProfile(updated);
      return updated;
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException updating worker profile: ${e.message}', tag: 'WorkerRepo');
      return profile;
    } catch (e, st) {
      AppLogger.error('Error updating worker profile', error: e, stackTrace: st);
      return profile;
    }
  }

  @override
  Future<WorkerProfile> submitForVerification(String workerId) async {
    final WorkerProfile current = WorkerDataStore.getOrCreateProfile(workerId);
    final WorkerProfile pendingProfile = current.copyWith(
      verificationStatus: WorkerVerificationStatus.pending,
      rejectionReason: null,
      updatedAt: DateTime.now(),
    );
    WorkerDataStore.upsertProfile(pendingProfile);

    try {
      final Map<String, Object?> payload = <String, Object?>{
        'id': workerId,
        'cooperative_id': current.cooperativeId,
        'skills': current.skills,
        'experience_years': current.experienceYears,
        'daily_rate_inr': current.dailyRateInr,
        'service_area': current.serviceArea,
        'bio': current.bio,
        'verification_status': WorkerVerificationStatus.pending.dbValue,
        'rejection_reason': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final Map<String, Object?> data = await _safeClient
          .from('worker_profiles')
          .upsert(payload)
          .select('*, cooperatives(name), profiles(full_name, phone_number, email)')
          .single();

      final WorkerProfile updated = WorkerProfile.fromJson(data);
      WorkerDataStore.upsertProfile(updated);
      return updated;
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException submitting verification: ${e.message}', tag: 'WorkerRepo');
      return pendingProfile;
    } catch (e, st) {
      AppLogger.error('Error submitting verification', error: e, stackTrace: st);
      return pendingProfile;
    }
  }

  @override
  Future<List<WorkerDocument>> getDocuments(String workerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('worker_documents')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final List<WorkerDocument> docs = response.map(WorkerDocument.fromJson).toList();
        WorkerDataStore.documents[workerId] = docs;
        return docs;
      }
      return WorkerDataStore.documents[workerId] ?? <WorkerDocument>[];
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException fetching documents: ${e.message}', tag: 'WorkerRepo');
      return WorkerDataStore.documents[workerId] ?? <WorkerDocument>[];
    } catch (e) {
      return WorkerDataStore.documents[workerId] ?? <WorkerDocument>[];
    }
  }

  @override
  Future<WorkerDocument> uploadDocument({
    required String workerId,
    required DocumentType documentType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String storagePath = '$workerId/${timestamp}_$sanitizedName';

    try {
      // 1. Upload to Supabase Storage bucket 'kyc-documents'
      try {
        await _safeClient.storage.from('kyc-documents').uploadBinary(
              storagePath,
              Uint8List.fromList(bytes),
              fileOptions: sb.FileOptions(
                contentType: mimeType,
                upsert: true,
              ),
            );
      } catch (storageErr) {
        AppLogger.warning('Storage upload note: $storageErr');
      }

      // 2. Insert document record in PostgreSQL database
      final Map<String, Object?> data = await _safeClient
          .from('worker_documents')
          .insert(<String, Object?>{
            'worker_id': workerId,
            'document_type': documentType.dbValue,
            'file_name': fileName,
            'file_path': storagePath,
            'file_size': bytes.length,
            'mime_type': mimeType,
            'status': 'pending',
          })
          .select()
          .single();

      final WorkerDocument newDoc = WorkerDocument.fromJson(data);
      WorkerDataStore.documents.putIfAbsent(workerId, () => <WorkerDocument>[]).insert(0, newDoc);
      return newDoc;
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException inserting document record: ${e.message}', tag: 'WorkerRepo');
      final WorkerDocument fallbackDoc = WorkerDocument(
        id: 'doc-$timestamp',
        workerId: workerId,
        documentType: documentType,
        fileName: fileName,
        filePath: storagePath,
        fileSize: bytes.length,
        mimeType: mimeType,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      WorkerDataStore.documents.putIfAbsent(workerId, () => <WorkerDocument>[]).insert(0, fallbackDoc);
      return fallbackDoc;
    } catch (e, st) {
      AppLogger.error('Error in document upload workflow', error: e, stackTrace: st);
      final WorkerDocument fallbackDoc = WorkerDocument(
        id: 'doc-$timestamp',
        workerId: workerId,
        documentType: documentType,
        fileName: fileName,
        filePath: storagePath,
        fileSize: bytes.length,
        mimeType: mimeType,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      WorkerDataStore.documents.putIfAbsent(workerId, () => <WorkerDocument>[]).insert(0, fallbackDoc);
      return fallbackDoc;
    }
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required String filePath,
  }) async {
    for (final List<WorkerDocument> list in WorkerDataStore.documents.values) {
      list.removeWhere((WorkerDocument d) => d.id == documentId);
    }
    try {
      try {
        await _safeClient.storage.from('kyc-documents').remove(<String>[filePath]);
      } catch (_) {}

      await _safeClient.from('worker_documents').delete().eq('id', documentId);
    } catch (e) {
      AppLogger.warning('Error deleting document: $e');
    }
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
    } catch (e) {
      AppLogger.warning('Fallback to default cooperatives: $e');
      return CooperativeSociety.fallbackSocieties;
    }
  }
}

final Provider<IWorkerRepository> workerRepositoryProvider = Provider<IWorkerRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseWorkerRepository(client: client);
});
