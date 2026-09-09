enum UserRole {
  customer('customer', 'Customer'),
  worker('worker', 'Worker / Service Provider'),
  cooperativeAdmin('cooperative_admin', 'Cooperative Admin'),
  federationAdmin('federation_admin', 'Federation Admin');

  const UserRole(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  /// Whether a normal user is allowed to choose this role during self-registration/onboarding.
  bool get canSelfSelect => this == UserRole.customer || this == UserRole.worker;

  /// Parse from PostgreSQL string.
  static UserRole fromDbValue(String value) {
    for (final UserRole role in UserRole.values) {
      if (role.dbValue == value) {
        return role;
      }
    }
    // Fallback safely to customer for unrecognized string values
    return UserRole.customer;
  }
}
