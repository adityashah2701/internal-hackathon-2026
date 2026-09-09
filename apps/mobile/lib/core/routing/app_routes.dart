abstract final class AppRoutes {
  // Verification / Diagnostic Root
  static const String root = '/';
  static const String verification = '/verification';

  // Future Authentication Routes (Architecture readiness)
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';

  // Future Role-Specific Route Hubs
  static const String customerDashboard = '/customer';
  static const String workerDashboard = '/worker';
  static const String cooperativeDashboard = '/cooperative';
  static const String federationDashboard = '/federation';
}
