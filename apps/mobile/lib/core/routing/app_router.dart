import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/verification/presentation/verification_screen.dart';
import 'app_routes.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.root,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (BuildContext context, GoRouterState state) {
          return const VerificationScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (BuildContext context, GoRouterState state) {
          return const VerificationScreen();
        },
      ),
    ],
    // Architecture readiness: future redirect logic for Role-Based Navigation
    redirect: (BuildContext context, GoRouterState state) {
      // Future authentication and role checks will plug in here.
      return null;
    },
  );
});
