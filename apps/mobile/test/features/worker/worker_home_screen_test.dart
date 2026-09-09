import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_profile.dart';
import 'package:mobile/data/models/user_role.dart';
import 'package:mobile/data/models/worker_profile.dart';
import 'package:mobile/data/repositories/worker_repository.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';
import 'package:mobile/features/worker/presentation/worker_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class TestWorkerRepository extends SupabaseWorkerRepository {
  TestWorkerRepository({required this.stubProfile}) : super(client: null);

  final WorkerProfile stubProfile;

  @override
  Future<WorkerProfile> getWorkerProfile(String workerId) async => stubProfile;
}

void main() {
  testWidgets('WorkerHomeScreen renders unsubmitted verification banner and trade skills',
      (WidgetTester tester) async {
    const String testUserId = 'test-worker-uuid-1';
    final UserProfile profile = UserProfile(
      id: testUserId,
      email: 'worker@sahayog.coop',
      fullName: 'Dev Worker',
      phoneNumber: '+91 99887 76655',
      role: UserRole.worker,
      isOnboarded: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sb.User sbUser = sb.User(
      id: testUserId,
      appMetadata: const <String, Object>{},
      userMetadata: const <String, Object>{},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    const WorkerProfile stubWorker = WorkerProfile(
      id: testUserId,
      skills: <String>['Electrician'],
      experienceYears: 3,
      dailyRateInr: 650,
      verificationStatus: WorkerVerificationStatus.unsubmitted,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              AsyncValue<AppAuthState>.data(
                AuthAuthenticated(user: sbUser, profile: profile),
              ),
            ),
          ),
          workerRepositoryProvider.overrideWithValue(
            TestWorkerRepository(stubProfile: stubWorker),
          ),
        ],
        child: const MaterialApp(
          home: WorkerHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Worker Workspace'), findsOneWidget);
    expect(find.text('Verification Required'), findsOneWidget);
    expect(find.text('Dev Worker'), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('3 Years'), findsOneWidget);
    expect(find.text('₹650 / day'), findsOneWidget);
    expect(find.text('Submit for Cooperative Verification'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._initialState);

  final AsyncValue<AppAuthState> _initialState;

  @override
  AsyncValue<AppAuthState> build() => _initialState;
}
