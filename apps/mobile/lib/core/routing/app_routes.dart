abstract final class AppRoutes {
  // Splash & Entry
  static const String splash = '/splash';
  static const String root = '/';
  static const String verification = '/verification';

  // Future Authentication Routes (Architecture readiness)
  static const String login = '/login';
  static const String phoneLogin = '/phone-login';
  static const String otpVerify = '/otp-verify';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';

  // Customer Hub
  static const String customerDashboard = '/customer';
  static const String customerServices = '/customer/services';
  static const String customerBookings = '/customer/bookings';
  static const String customerAlerts = '/customer/alerts';
  static const String customerProfile = '/customer/profile';

  // Worker Hub
  static const String workerDashboard = '/worker';
  static const String workerJobs = '/worker/jobs';
  static const String workerActiveJob = '/worker/active-job';
  static const String workerEarnings = '/worker/earnings';
  static const String workerAlerts = '/worker/alerts';
  static const String workerProfile = '/worker/profile';

  // Cooperative & Federation Hubs (to be expanded later)
  static const String cooperativeDashboard = '/cooperative';
  static const String federationDashboard = '/federation';
}
