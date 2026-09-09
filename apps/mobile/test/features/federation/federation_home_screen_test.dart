import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/cooperative_society.dart';
import 'package:mobile/data/models/user_profile.dart';
import 'package:mobile/data/models/user_role.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/federation_admin_repository.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';
import 'package:mobile/features/federation/presentation/federation_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class TestFederationAdminRepository extends SupabaseFederationAdminRepository {
  TestFederationAdminRepository() : super(client: null);

  @override
  Future<FederationMetrics> getMetrics() async => const FederationMetrics(
        totalWorkers: 15,
        verifiedWorkers: 12,
        pendingVerifications: 3,
        activeCooperatives: 3,
      );

  @override
  Future<List<WorkerProfile>> getFilteredWorkers({
    String? searchQuery,
    String? statusFilter,
    String? cooperativeId,
  }) async =>
      <WorkerProfile>[
        const WorkerProfile(
          id: 'fed-1',
          fullName: 'Test Artisan',
          skills: <String>['Carpenter'],
          experienceYears: 7,
          verificationStatus: WorkerVerificationStatus.approved,
        ),
      ];

  @override
  Future<List<CooperativeSociety>> getCooperatives() async => CooperativeSociety.fallbackSocieties;
}

void main() {
  testWidgets('FederationHomeScreen renders telemetry metrics and workforce directory',
      (WidgetTester tester) async {
    const String testAdminId = 'admin-fed-uuid-1';
    final UserProfile adminProfile = UserProfile(
      id: testAdminId,
      email: 'fed.officer@sahayog.coop',
      fullName: 'Apex Officer',
      phoneNumber: '+91 91122 33445',
      role: UserRole.federationAdmin,
      isOnboarded: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sb.User sbAdmin = sb.User(
      id: testAdminId,
      appMetadata: const <String, Object>{},
      userMetadata: const <String, Object>{},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              AsyncValue<AppAuthState>.data(
                AuthAuthenticated(user: sbAdmin, profile: adminProfile),
              ),
            ),
          ),
          federationAdminRepositoryProvider.overrideWithValue(
            TestFederationAdminRepository(),
          ),
        ],
        child: const MaterialApp(
          home: FederationHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Federation Apex Oversight'), findsOneWidget);
    expect(find.text('Total Workforce'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Certified Active'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2)); // pending count and active societies count
    expect(find.text('Test Artisan'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._initialState);

  final AsyncValue<AppAuthState> _initialState;

  @override
  AsyncValue<AppAuthState> build() => _initialState;
}
