import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/models/user_profile.dart';
import 'package:mobile/data/models/user_role.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/data/repositories/profile_repository.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class FakeAuthRepository implements IAuthRepository {
  sb.User? mockUser;
  final StreamController<sb.AuthState> _authStreamController =
      StreamController<sb.AuthState>.broadcast();

  @override
  sb.User? get currentUser => mockUser;

  @override
  sb.Session? get currentSession => null;

  @override
  Stream<sb.AuthState> get onAuthStateChange => _authStreamController.stream;

  @override
  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email == 'error@test.com') {
      throw const AuthException(message: 'Invalid credentials');
    }
    return sb.AuthResponse();
  }

  @override
  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  }) async {
    return sb.AuthResponse();
  }

  @override
  Future<void> signInWithOtp({required String phone}) async {}

  @override
  Future<sb.AuthResponse> verifyOtp({required String phone, required String token}) async {
    return sb.AuthResponse();
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
    _authStreamController.add(const sb.AuthState(sb.AuthChangeEvent.signedOut, null));
  }
}

class FakeProfileRepository implements IProfileRepository {
  UserProfile? mockProfile;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return mockProfile;
  }

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    mockProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> completeOnboarding({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    final UserProfile updated = UserProfile(
      id: userId,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      role: role,
      isOnboarded: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockProfile = updated;
    return updated;
  }
}

void main() {
  group('AuthController Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeProfileRepository fakeProfileRepo;
    late ProviderContainer container;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      fakeProfileRepo = FakeProfileRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial build starts unauthenticated when currentUser is null', () async {
      // Pump initial read
      final AsyncValue<AppAuthState> state = container.read(authControllerProvider);
      expect(state.value, isA<AuthUnauthenticated>());
    });

    test('Transitions to AuthAuthenticated when user has complete profile', () async {
      const sb.User testUser = sb.User(
        id: 'u-1',
        appMetadata: <String, dynamic>{},
        userMetadata: <String, dynamic>{},
        aud: 'authenticated',
        createdAt: '2026-09-09T00:00:00Z',
      );
      final UserProfile testProfile = UserProfile(
        id: 'u-1',
        email: 'test@example.com',
        fullName: 'Worker User',
        phoneNumber: '1234567890',
        role: UserRole.worker,
        isOnboarded: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeAuthRepo.mockUser = testUser;
      fakeProfileRepo.mockProfile = testProfile;

      // Refresh session
      await container.read(authControllerProvider.notifier).refreshSession();

      final AsyncValue<AppAuthState> updated = container.read(authControllerProvider);
      expect(updated.value, isA<AuthAuthenticated>());
      final AuthAuthenticated auth = updated.value! as AuthAuthenticated;
      expect(auth.profile.role, UserRole.worker);
      expect(auth.profile.fullName, 'Worker User');
    });

    test('Transitions to AuthOnboardingRequired when user has un-onboarded profile', () async {
      const sb.User testUser = sb.User(
        id: 'u-2',
        appMetadata: <String, dynamic>{},
        userMetadata: <String, dynamic>{},
        aud: 'authenticated',
        createdAt: '2026-09-09T00:00:00Z',
      );
      final UserProfile testProfile = UserProfile(
        id: 'u-2',
        email: 'newuser@example.com',
        fullName: '',
        phoneNumber: '',
        role: UserRole.customer,
        isOnboarded: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeAuthRepo.mockUser = testUser;
      fakeProfileRepo.mockProfile = testProfile;

      await container.read(authControllerProvider.notifier).refreshSession();

      final AsyncValue<AppAuthState> updated = container.read(authControllerProvider);
      expect(updated.value, isA<AuthOnboardingRequired>());
      final AuthOnboardingRequired onboarding = updated.value! as AuthOnboardingRequired;
      expect(onboarding.user.id, 'u-2');
    });

    test('signOut resets state to AuthUnauthenticated', () async {
      await container.read(authControllerProvider.notifier).signOut();
      final AsyncValue<AppAuthState> updated = container.read(authControllerProvider);
      expect(updated.value, isA<AuthUnauthenticated>());
    });
  });
}
