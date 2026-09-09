import '../models/worker_document.dart';
import '../models/worker_profile.dart';

/// In-memory reactive synchronized data store for active session workers.
/// Only contains real registered workers who have interacted with the platform,
/// without hardcoded dummy personas.
abstract final class WorkerDataStore {
  static final Map<String, WorkerProfile> profiles = <String, WorkerProfile>{};
  static final Map<String, List<WorkerDocument>> documents = <String, List<WorkerDocument>>{};
  static final Map<String, String> documentPayloads = <String, String>{};

  static WorkerProfile getOrCreateProfile(String workerId) {
    return profiles.putIfAbsent(
      workerId,
      () => WorkerProfile(
        id: workerId,
        skills: const <String>[],
        experienceYears: 0,
        dailyRateInr: 500,
        verificationStatus: WorkerVerificationStatus.unsubmitted,
      ),
    );
  }

  static void upsertProfile(WorkerProfile profile) {
    profiles[profile.id] = profile;
  }

  static WorkerProfile approve(String workerId, String adminId) {
    final WorkerProfile current = getOrCreateProfile(workerId);
    final WorkerProfile approved = current.copyWith(
      verificationStatus: WorkerVerificationStatus.approved,
      rejectionReason: null,
      verifiedAt: DateTime.now(),
      verifiedBy: adminId,
    );
    profiles[workerId] = approved;
    return approved;
  }

  static WorkerProfile reject(String workerId, String adminId, String reason) {
    final WorkerProfile current = getOrCreateProfile(workerId);
    final WorkerProfile rejected = current.copyWith(
      verificationStatus: WorkerVerificationStatus.rejected,
      rejectionReason: reason,
      verifiedAt: DateTime.now(),
      verifiedBy: adminId,
    );
    profiles[workerId] = rejected;
    return rejected;
  }

  static List<WorkerProfile> getAllWorkers({String? statusFilter}) {
    final List<WorkerProfile> list = profiles.values.toList();
    if (statusFilter == null || statusFilter == 'all') {
      return list;
    }
    return list.where((WorkerProfile w) => w.verificationStatus.dbValue == statusFilter).toList();
  }

  static void clear() {
    profiles.clear();
    documents.clear();
    documentPayloads.clear();
  }
}
