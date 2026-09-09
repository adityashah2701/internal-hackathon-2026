import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/cooperative_society.dart';
import 'package:mobile/data/models/worker_document.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/worker_repository.dart';

void main() {
  group('WorkerRepository Tests', () {
    late IWorkerRepository repository;

    setUp(() {
      repository = SupabaseWorkerRepository(client: null);
    });

    test('getWorkerProfile returns profile or fallback', () async {
      final WorkerProfile profile = await repository.getWorkerProfile('test-worker-1');
      expect(profile.id, 'test-worker-1');
      expect(profile.verificationStatus, WorkerVerificationStatus.unsubmitted);
    });

    test('updateWorkerProfile updates and persists profile', () async {
      const WorkerProfile updated = WorkerProfile(
        id: 'test-worker-2',
        skills: <String>['Plumber', 'Electrician'],
        experienceYears: 5,
        dailyRateInr: 700,
        serviceArea: 'Pune Camp',
      );

      final WorkerProfile result = await repository.updateWorkerProfile(updated);
      expect(result.skills, contains('Plumber'));
      expect(result.experienceYears, 5);
      expect(result.dailyRateInr, 700);
    });

    test('uploadDocument, getDocuments, and deleteDocument lifecycle', () async {
      const String workerId = 'test-worker-3';
      final List<int> mockBytes = utf8.encode('MOCK_AADHAAR_DATA');

      final WorkerDocument uploaded = await repository.uploadDocument(
        workerId: workerId,
        documentType: DocumentType.aadhaar,
        fileName: 'aadhaar_front.pdf',
        bytes: mockBytes,
        mimeType: 'application/pdf',
      );

      expect(uploaded.workerId, workerId);
      expect(uploaded.documentType, DocumentType.aadhaar);
      expect(uploaded.fileName, 'aadhaar_front.pdf');

      final List<WorkerDocument> docs = await repository.getDocuments(workerId);
      expect(docs, isNotEmpty);
      expect(docs.first.fileName, 'aadhaar_front.pdf');

      await repository.deleteDocument(documentId: uploaded.id, filePath: uploaded.filePath);
      final List<WorkerDocument> docsAfterDelete = await repository.getDocuments(workerId);
      expect(docsAfterDelete.any((WorkerDocument d) => d.id == uploaded.id), isFalse);
    });

    test('submitForVerification transitions status to pending', () async {
      const String workerId = 'test-worker-4';
      final WorkerProfile result = await repository.submitForVerification(workerId);
      expect(result.verificationStatus, WorkerVerificationStatus.pending);
      expect(result.rejectionReason, isNull);
    });

    test('getCooperatives returns societies', () async {
      final List<CooperativeSociety> societies = await repository.getCooperatives();
      expect(societies, isNotEmpty);
      expect(societies.first.name, isNotEmpty);
    });
  });
}
