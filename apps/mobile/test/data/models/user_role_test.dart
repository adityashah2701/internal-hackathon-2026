import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_role.dart';

void main() {
  group('UserRole Tests', () {
    test('fromDbValue maps valid strings correctly', () {
      expect(UserRole.fromDbValue('customer'), UserRole.customer);
      expect(UserRole.fromDbValue('worker'), UserRole.worker);
      expect(UserRole.fromDbValue('cooperative_admin'), UserRole.cooperativeAdmin);
      expect(UserRole.fromDbValue('federation_admin'), UserRole.federationAdmin);
    });

    test('fromDbValue falls back to customer on invalid strings', () {
      expect(UserRole.fromDbValue('invalid_role'), UserRole.customer);
      expect(UserRole.fromDbValue(''), UserRole.customer);
    });

    test('canSelfSelect is true only for customer and worker', () {
      expect(UserRole.customer.canSelfSelect, isTrue);
      expect(UserRole.worker.canSelfSelect, isTrue);
      expect(UserRole.cooperativeAdmin.canSelfSelect, isFalse);
      expect(UserRole.federationAdmin.canSelfSelect, isFalse);
    });

    test('displayName and dbValue are properly defined', () {
      expect(UserRole.customer.dbValue, 'customer');
      expect(UserRole.customer.displayName, 'Customer');
      expect(UserRole.worker.dbValue, 'worker');
      expect(UserRole.cooperativeAdmin.dbValue, 'cooperative_admin');
      expect(UserRole.federationAdmin.dbValue, 'federation_admin');
    });
  });
}
