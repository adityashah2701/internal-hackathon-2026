import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/phone_login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/common/presentation/splash_screen.dart';
import '../../features/cooperative/presentation/cooperative_shell.dart';
import '../../features/cooperative/presentation/tabs/cooperative_dashboard_tab.dart';
import '../../features/cooperative/presentation/tabs/cooperative_profile_tab.dart';

import '../../features/federation/presentation/federation_shell.dart';
import '../../features/federation/presentation/tabs/federation_dashboard_tab.dart';
import '../../features/federation/presentation/tabs/federation_profile_tab.dart';

import '../../features/verification/presentation/verification_screen.dart';

// Customer Shell & Tabs
import '../../features/customer/presentation/customer_shell.dart';
import '../../features/customer/presentation/tabs/customer_home_tab.dart';
import '../../features/customer/presentation/tabs/customer_services_tab.dart';
import '../../features/customer/presentation/tabs/customer_bookings_tab.dart';
import '../../features/customer/presentation/tabs/customer_alerts_tab.dart';
import '../../features/customer/presentation/tabs/customer_profile_tab.dart';

// Worker Shell & Tabs
import '../../features/worker/presentation/worker_shell.dart';
import '../../features/worker/presentation/tabs/worker_home_tab.dart';
import '../../features/worker/presentation/tabs/worker_jobs_tab.dart';
import '../../features/worker/presentation/tabs/worker_earnings_tab.dart';
import '../../features/worker/presentation/tabs/worker_alerts_tab.dart';
import '../../features/worker/presentation/tabs/worker_profile_tab.dart';
import '../../features/worker/presentation/active_job_screen.dart';

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
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    routes: <RouteBase>[
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),

      // Public / Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneLogin,
        builder: (BuildContext context, GoRouterState state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (BuildContext context, GoRouterState state) {
          final String phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
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

      // =======================================================
      // Customer Stateful Shell Route (Bottom Navigation)
      // =======================================================
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return CustomerShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.customerDashboard,
                builder: (BuildContext context, GoRouterState state) => const CustomerHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.customerServices,
                builder: (BuildContext context, GoRouterState state) => const CustomerServicesTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.customerBookings,
                builder: (BuildContext context, GoRouterState state) => const CustomerBookingsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.customerAlerts,
                builder: (BuildContext context, GoRouterState state) => const CustomerAlertsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.customerProfile,
                builder: (BuildContext context, GoRouterState state) => const CustomerProfileTab(),
              ),
            ],
          ),
        ],
      ),

      // =======================================================
      // Worker Stateful Shell Route (Bottom Navigation)
      // =======================================================
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return WorkerShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workerDashboard,
                builder: (BuildContext context, GoRouterState state) => const WorkerHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workerJobs,
                builder: (BuildContext context, GoRouterState state) => const WorkerJobsTab(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'active/:id',
                    builder: (BuildContext context, GoRouterState state) {
                      final String bookingId = state.pathParameters['id']!;
                      return ActiveJobScreen(bookingId: bookingId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workerEarnings,
                builder: (BuildContext context, GoRouterState state) => const WorkerEarningsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workerAlerts,
                builder: (BuildContext context, GoRouterState state) => const WorkerAlertsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workerProfile,
                builder: (BuildContext context, GoRouterState state) => const WorkerProfileTab(),
              ),
            ],
          ),
        ],
      ),

      // =======================================================
      // Cooperative Stateful Shell Route (Bottom Navigation)
      // =======================================================
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return CooperativeShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.cooperativeDashboard,
                builder: (BuildContext context, GoRouterState state) => const CooperativeDashboardTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '${AppRoutes.cooperativeDashboard}/profile',
                builder: (BuildContext context, GoRouterState state) => const CooperativeProfileTab(),
              ),
            ],
          ),
        ],
      ),

      // =======================================================
      // Federation Stateful Shell Route (Bottom Navigation)
      // =======================================================
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return FederationShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.federationDashboard,
                builder: (BuildContext context, GoRouterState state) => const FederationDashboardTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '${AppRoutes.federationDashboard}/profile',
                builder: (BuildContext context, GoRouterState state) => const FederationProfileTab(),
              ),
            ],
          ),
        ],
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

      // Allow splash screen to display its animation and handle its own transition
      if (location == AppRoutes.splash) {
        return null;
      }

      // Always permit developer diagnostics
      if (location == AppRoutes.verification) {
        return null;
      }

      final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
      final AppAuthState? authState = authAsync.value;

      // While checking session on launch, stay on splash
      if (authState is AuthInitial) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Fallback state if authAsync is loading and value is temporarily null
      final AppAuthState effectiveState = authState ?? const AuthUnauthenticated();

      // 1. Unauthenticated: Force to Login or Register
      if (effectiveState is AuthUnauthenticated) {
        final bool isAuthRoute = location == AppRoutes.login || 
                                 location == AppRoutes.register || 
                                 location == AppRoutes.phoneLogin || 
                                 location == AppRoutes.otpVerify;
        return isAuthRoute ? null : AppRoutes.login;
      }

      // 2. Onboarding Required: Force to Onboarding
      if (effectiveState is AuthOnboardingRequired) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // 3. Authenticated & Onboarded: Direct to appropriate Role-Based Home
      if (effectiveState is AuthAuthenticated) {
        final String roleHome = switch (effectiveState.profile.role) {
          UserRole.customer => AppRoutes.customerDashboard,
          UserRole.worker => AppRoutes.workerDashboard,
          UserRole.cooperativeAdmin => AppRoutes.cooperativeDashboard,
          UserRole.federationAdmin => AppRoutes.federationDashboard,
        };

        // If user is on an auth, splash, or onboarding screen, redirect to their role home
        final bool isOnEntryFlow = location == AppRoutes.splash ||
            location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.phoneLogin ||
            location == AppRoutes.otpVerify ||
            location == AppRoutes.onboarding ||
            location == AppRoutes.root;

        if (isOnEntryFlow) {
          return roleHome;
        }

        // Prevent cross-role navigation if attempting to access a different role portal
        // Since we now have sub-routes like /customer/bookings, we check if the path starts with the role portal
        final bool isCustomerFlow = location.startsWith('/customer');
        final bool isWorkerFlow = location.startsWith('/worker');
        final bool isCoopFlow = location.startsWith('/cooperative');
        final bool isFedFlow = location.startsWith('/federation');

        if (isCustomerFlow && effectiveState.profile.role != UserRole.customer) return roleHome;
        if (isWorkerFlow && effectiveState.profile.role != UserRole.worker) return roleHome;
        if (isCoopFlow && effectiveState.profile.role != UserRole.cooperativeAdmin) return roleHome;
        if (isFedFlow && effectiveState.profile.role != UserRole.federationAdmin) return roleHome;

        return null;
      }

      return null;
    },
  );
});
