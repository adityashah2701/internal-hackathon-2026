import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/cooperative_society.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/federation_admin_repository.dart';

void main() {
  group('FederationAdminRepository Tests', () {
    late IFederationAdminRepository repository;

    setUp(() {
      repository = SupabaseFederationAdminRepository(client: null);
    });

    test('getMetrics calculates telemetry numbers accurately', () async {
      final FederationMetrics metrics = await repository.getMetrics();
      expect(metrics.totalWorkers, greaterThanOrEqualTo(3));
      expect(metrics.verifiedWorkers, greaterThanOrEqualTo(1));
      expect(metrics.activeCooperatives, greaterThanOrEqualTo(1));
    });

    test('getFilteredWorkers filters by trade skills search query', () async {
      final List<WorkerProfile> results = await repository.getFilteredWorkers(searchQuery: 'electrician');
      expect(results, isNotEmpty);
      expect(results.first.skills.any((String s) => s.toLowerCase().contains('electrician')), isTrue);
    });

    test('getFilteredWorkers filters by verification status', () async {
      final List<WorkerProfile> verifiedList = await repository.getFilteredWorkers(statusFilter: 'approved');
      expect(verifiedList, isNotEmpty);
      expect(verifiedList.every((WorkerProfile w) => w.verificationStatus == WorkerVerificationStatus.approved), isTrue);
    });

    test('getCooperatives returns registered primary societies', () async {
      final List<CooperativeSociety> societies = await repository.getCooperatives();
      expect(societies.length, greaterThanOrEqualTo(3));
      expect(societies.any((CooperativeSociety s) => s.code == 'SKLCS-MH-01'), isTrue);
    });
  });
}
