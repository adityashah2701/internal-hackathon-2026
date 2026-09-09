import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/models/worker_document.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/cooperative_admin_repository.dart';

void main() {
  group('CooperativeAdminRepository Tests', () {
    late ICooperativeAdminRepository repository;

    setUp(() {
      repository = SupabaseCooperativeAdminRepository(client: null);
    });

    test('getWorkers returns pending workers by default filter', () async {
      final List<WorkerProfile> workers = await repository.getWorkers(statusFilter: 'pending');
      expect(workers, isNotEmpty);
      expect(workers.every((WorkerProfile w) => w.verificationStatus == WorkerVerificationStatus.pending), isTrue);
    });

    test('getWorkerDocuments returns document attachments', () async {
      final List<WorkerDocument> docs = await repository.getWorkerDocuments('worker-ramesh-01');
      expect(docs, isNotEmpty);
      expect(docs.first.fileName, contains('aadhaar'));
    });

    test('approveWorker certifies worker', () async {
      final WorkerProfile approved = await repository.approveWorker(
        workerId: 'worker-ramesh-01',
        adminId: 'admin-coop-01',
      );

      expect(approved.verificationStatus, WorkerVerificationStatus.approved);
      expect(approved.rejectionReason, isNull);
      expect(approved.verifiedBy, 'admin-coop-01');
    });

    test('rejectWorker requires non-empty reason', () async {
      expect(
        () => repository.rejectWorker(
          workerId: 'worker-sunita-02',
          adminId: 'admin-coop-01',
          reason: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejectWorker marks worker as rejected with reason', () async {
      const String reason = 'Aadhaar copy is blurry. Please re-upload a clear scanned document.';
      final WorkerProfile rejected = await repository.rejectWorker(
        workerId: 'worker-sunita-02',
        adminId: 'admin-coop-01',
        reason: reason,
      );

      expect(rejected.verificationStatus, WorkerVerificationStatus.rejected);
      expect(rejected.rejectionReason, reason);
    });
  });
}
