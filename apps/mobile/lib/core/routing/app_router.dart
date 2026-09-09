import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cooperative/presentation/cooperative_home_screen.dart';
import '../../features/customer/presentation/customer_home_screen.dart';
import '../../features/federation/presentation/federation_home_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../features/worker/presentation/worker_home_screen.dart';
import 'app_routes.dart';

/// Listenable that notifies GoRouter when auth state changes in Riverpod
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AppAuthState>>(
      authControllerProvider,
      (AsyncValue<AppAuthState>? prev, AsyncValue<AppAuthState> next) {
        notifyListeners();
      },
    );
  }
}

final Provider<_RouterRefreshNotifier> _routerRefreshNotifierProvider =
    Provider<_RouterRefreshNotifier>((Ref ref) => _RouterRefreshNotifier(ref));

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefreshNotifier refreshNotifier = ref.watch(_routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    routes: <RouteBase>[
      // Public / Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
      ),

      // Onboarding Route
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
      ),

      // Role-Based Home Routes
      GoRoute(
        path: AppRoutes.customerDashboard,
        builder: (BuildContext context, GoRouterState state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.workerDashboard,
        builder: (BuildContext context, GoRouterState state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.cooperativeDashboard,
        builder: (BuildContext context, GoRouterState state) => const CooperativeHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.federationDashboard,
        builder: (BuildContext context, GoRouterState state) => const FederationHomeScreen(),
      ),

      // Developer Diagnostics & System Verification
      GoRoute(
        path: AppRoutes.verification,
        builder: (BuildContext context, GoRouterState state) => const VerificationScreen(),
      ),
    ],

    // Central Auth & Role Redirect Guard
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path;

      // Always permit developer diagnostics
      if (location == AppRoutes.verification) {
        return null;
      }

      final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
      final AppAuthState? authState = authAsync.value;

      // While checking session on launch, stay where we are
      if (authState is AuthInitial || authState == null) {
        return null;
      }

      // 1. Unauthenticated: Force to Login or Register
      if (authState is AuthUnauthenticated) {
        final bool isAuthRoute = location == AppRoutes.login || location == AppRoutes.register;
        return isAuthRoute ? null : AppRoutes.login;
      }

      // 2. Onboarding Required: Force to Onboarding
      if (authState is AuthOnboardingRequired) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // 3. Authenticated & Onboarded: Direct to appropriate Role-Based Home
      if (authState is AuthAuthenticated) {
        final String roleHome = switch (authState.profile.role) {
          UserRole.customer => AppRoutes.customerDashboard,
          UserRole.worker => AppRoutes.workerDashboard,
          UserRole.cooperativeAdmin => AppRoutes.cooperativeDashboard,
          UserRole.federationAdmin => AppRoutes.federationDashboard,
        };

        // If user is on an auth or onboarding screen, redirect to their role home
        final bool isOnEntryFlow = location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.onboarding ||
            location == AppRoutes.root;

        if (isOnEntryFlow) {
          return roleHome;
        }

        // Prevent cross-role navigation if attempting to access a different role portal
        final bool isAnotherRolePortal = (location == AppRoutes.customerDashboard && authState.profile.role != UserRole.customer) ||
            (location == AppRoutes.workerDashboard && authState.profile.role != UserRole.worker) ||
            (location == AppRoutes.cooperativeDashboard && authState.profile.role != UserRole.cooperativeAdmin) ||
            (location == AppRoutes.federationDashboard && authState.profile.role != UserRole.federationAdmin);

        if (isAnotherRolePortal) {
          return roleHome;
        }

        return null;
      }

      return null;
    },
  );
});
