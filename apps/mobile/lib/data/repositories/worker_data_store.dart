import '../models/worker_document.dart';
import '../models/worker_profile.dart';

/// In-memory reactive synchronized data store for worker profiles and documents.
/// Ensures that updates from Worker, Cooperative Admin, and Federation Admin
/// are immediately reflected across all role portals during offline / local fallback operation.
abstract final class WorkerDataStore {
  static final Map<String, WorkerProfile> profiles = <String, WorkerProfile>{
    'worker-ramesh-01': const WorkerProfile(
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
    'worker-sunita-02': const WorkerProfile(
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
    'worker-anil-03': const WorkerProfile(
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
  };

  static final Map<String, List<WorkerDocument>> documents = <String, List<WorkerDocument>>{
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

  static WorkerProfile getOrCreateProfile(String workerId) {
    return profiles.putIfAbsent(
      workerId,
      () => WorkerProfile(
        id: workerId,
        skills: const <String>['Electrician'],
        experienceYears: 2,
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
}
