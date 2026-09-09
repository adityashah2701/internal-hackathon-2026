import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_profile.dart';
import 'package:mobile/data/models/user_role.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/cooperative_admin_repository.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';
import 'package:mobile/features/cooperative/presentation/cooperative_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class TestCooperativeAdminRepository extends SupabaseCooperativeAdminRepository {
  TestCooperativeAdminRepository({required this.workers}) : super(client: null);

  final List<WorkerProfile> workers;

  @override
  Future<List<WorkerProfile>> getWorkers({String? statusFilter}) async => workers;
}

void main() {
  testWidgets('CooperativeHomeScreen renders pending worker requests and review actions',
      (WidgetTester tester) async {
    const String testAdminId = 'admin-coop-uuid-1';
    final UserProfile adminProfile = UserProfile(
      id: testAdminId,
      email: 'admin@sahayog.coop',
      fullName: 'Society Officer',
      phoneNumber: '+91 99000 11223',
      role: UserRole.cooperativeAdmin,
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

    final List<WorkerProfile> testWorkers = <WorkerProfile>[
      const WorkerProfile(
        id: 'worker-test-1',
        fullName: 'Aakash Verma',
        phoneNumber: '+91 98877 66554',
        skills: <String>['Electrician'],
        experienceYears: 4,
        verificationStatus: WorkerVerificationStatus.pending,
      ),
    ];

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
          cooperativeAdminRepositoryProvider.overrideWithValue(
            TestCooperativeAdminRepository(workers: testWorkers),
          ),
        ],
        child: const MaterialApp(
          home: CooperativeHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cooperative Operations'), findsOneWidget);
    expect(find.text('Aakash Verma'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('View Documents'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._initialState);

  final AsyncValue<AppAuthState> _initialState;

  @override
  AsyncValue<AppAuthState> build() => _initialState;
}
