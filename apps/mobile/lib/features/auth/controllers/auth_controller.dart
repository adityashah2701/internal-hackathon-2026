import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';

sealed class AppAuthState {
  const AppAuthState();
}

final class AuthInitial extends AppAuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

final class AuthOnboardingRequired extends AppAuthState {
  const AuthOnboardingRequired({
    required this.user,
    this.profile,
  });

  final sb.User user;
  final UserProfile? profile;
}

final class AuthAuthenticated extends AppAuthState {
  const AuthAuthenticated({
    required this.user,
    required this.profile,
  });

  final sb.User user;
  final UserProfile profile;
}

class AuthController extends Notifier<AsyncValue<AppAuthState>> {
  StreamSubscription<sb.AuthState>? _authSubscription;

  @override
  AsyncValue<AppAuthState> build() {
    final IAuthRepository authRepo = ref.watch(authRepositoryProvider);

    _authSubscription?.cancel();
    _authSubscription = authRepo.onAuthStateChange.listen((sb.AuthState data) {
      _handleAuthStateChange(data);
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    // Check current session synchronously on startup
    final sb.Session? session = authRepo.currentSession;
    if (session != null && authRepo.currentUser != null) {
      Future<void>.microtask(() => _loadProfileForUser(authRepo.currentUser!));
      return const AsyncValue<AppAuthState>.data(AuthInitial());
    }

    return const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
  }

  Future<void> _handleAuthStateChange(sb.AuthState authState) async {
    final sb.AuthChangeEvent event = authState.event;
    final sb.Session? session = authState.session;

    AppLogger.info('Auth state change event: ${event.name}');

    switch (event) {
      case sb.AuthChangeEvent.initialSession:
      case sb.AuthChangeEvent.signedIn:
      case sb.AuthChangeEvent.tokenRefreshed:
      case sb.AuthChangeEvent.userUpdated:
        if (session != null) {
          await _loadProfileForUser(session.user);
        }
        break;
      case sb.AuthChangeEvent.signedOut:
        state = const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
        break;
      case sb.AuthChangeEvent.passwordRecovery:
      case sb.AuthChangeEvent.mfaChallengeVerified:
        break;
      default:
        break;
    }
  }

  Future<void> _loadProfileForUser(sb.User user) async {
    final IProfileRepository profileRepo = ref.read(profileRepositoryProvider);

    try {
      final UserProfile? profile = await profileRepo.getProfile(user.id);

      if (profile == null || !profile.isOnboarded) {
        state = AsyncValue<AppAuthState>.data(
          AuthOnboardingRequired(user: user, profile: profile),
        );
      } else {
        state = AsyncValue<AppAuthState>.data(
          AuthAuthenticated(user: user, profile: profile),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to load profile for user ${user.id}', error: e, stackTrace: st);
      // Even if remote profile fails, require onboarding rather than crashing
      state = AsyncValue<AppAuthState>.data(
        AuthOnboardingRequired(user: user, profile: null),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<AppAuthState>.loading();
    final IAuthRepository authRepo = ref.read(authRepositoryProvider);

    try {
      final sb.AuthResponse response = await authRepo.signInWithEmail(
        email: email,
        password: password,
      );

      final sb.User? user = response.user;
      if (user != null) {
        await _loadProfileForUser(user);
      } else {
        state = const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
      }
    } on AppException catch (e, st) {
      state = AsyncValue<AppAuthState>.error(Failure.fromException(e), st);
    } catch (e, st) {
      state = AsyncValue<AppAuthState>.error(
        UnexpectedFailure(message: 'Sign in failed: ${e.toString()}'),
        st,
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  }) async {
    state = const AsyncValue<AppAuthState>.loading();
    final IAuthRepository authRepo = ref.read(authRepositoryProvider);

    try {
      final sb.AuthResponse response = await authRepo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      final sb.User? user = response.user;
      if (user != null) {
        await _loadProfileForUser(user);
      } else {
        state = const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
      }
    } on AppException catch (e, st) {
      state = AsyncValue<AppAuthState>.error(Failure.fromException(e), st);
    } catch (e, st) {
      state = AsyncValue<AppAuthState>.error(
        UnexpectedFailure(message: 'Sign up failed: ${e.toString()}'),
        st,
      );
    }
  }

  Future<void> completeOnboarding({
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    final AppAuthState? currentState = state.value;
    if (currentState is! AuthOnboardingRequired) {
      throw const AuthorizationException(message: 'Not in an onboarding state.');
    }

    final sb.User user = currentState.user;
    state = const AsyncValue<AppAuthState>.loading();
    final IProfileRepository profileRepo = ref.read(profileRepositoryProvider);

    try {
      final UserProfile updatedProfile = await profileRepo.completeOnboarding(
        userId: user.id,
        email: user.email ?? '',
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );

      state = AsyncValue<AppAuthState>.data(
        AuthAuthenticated(user: user, profile: updatedProfile),
      );
    } on AppException catch (e, st) {
      state = AsyncValue<AppAuthState>.error(Failure.fromException(e), st);
      // Revert state back to onboarding required so UI can display form
      state = AsyncValue<AppAuthState>.data(
        AuthOnboardingRequired(user: user, profile: currentState.profile),
      );
    } catch (e, st) {
      state = AsyncValue<AppAuthState>.error(
        UnexpectedFailure(message: 'Onboarding failed: ${e.toString()}'),
        st,
      );
      state = AsyncValue<AppAuthState>.data(
        AuthOnboardingRequired(user: user, profile: currentState.profile),
      );
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue<AppAuthState>.loading();
    final IAuthRepository authRepo = ref.read(authRepositoryProvider);

    try {
      await authRepo.signOut();
      state = const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
    } on AppException catch (e, st) {
      state = AsyncValue<AppAuthState>.error(Failure.fromException(e), st);
    } catch (e, st) {
      state = AsyncValue<AppAuthState>.error(
        UnexpectedFailure(message: 'Sign out failed: ${e.toString()}'),
        st,
      );
    }
  }

  /// Re-fetches the current session and user profile from the repositories.
  Future<void> refreshSession() async {
    final IAuthRepository authRepo = ref.read(authRepositoryProvider);
    final sb.User? currentUser = authRepo.currentUser;
    if (currentUser != null) {
      await _loadProfileForUser(currentUser);
    } else {
      state = const AsyncValue<AppAuthState>.data(AuthUnauthenticated());
    }
  }

  /// Sets a demo user persona for offline/hackathon walkthrough testing
  void setDemoUser(UserRole role) {
    final sb.User demoUser = sb.User(
      id: 'demo-${role.dbValue}-user',
      appMetadata: const <String, dynamic>{},
      userMetadata: <String, dynamic>{'full_name': 'Demo ${role.displayName}'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    final UserProfile demoProfile = UserProfile(
      id: demoUser.id,
      email: 'demo.${role.dbValue}@sahayog.coop',
      fullName: 'Demo ${role.displayName}',
      phoneNumber: '+91 98765 43210',
      role: role,
      isOnboarded: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = AsyncValue<AppAuthState>.data(
      AuthAuthenticated(user: demoUser, profile: demoProfile),
    );
  }
}


final NotifierProvider<AuthController, AsyncValue<AppAuthState>> authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppAuthState>>(AuthController.new);
