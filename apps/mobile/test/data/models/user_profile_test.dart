import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_profile.dart';
import 'package:mobile/data/models/user_role.dart';

void main() {
  group('UserProfile Tests', () {
    final DateTime testDate = DateTime(2026, 9, 9, 12, 0, 0);

    test('fromJson parses full profile JSON correctly', () {
      final Map<String, Object> json = <String, Object>{
        'id': 'user-123',
        'email': 'artisan@coop.org',
        'full_name': 'Ramesh Kumar',
        'phone_number': '+919876543210',
        'role': 'worker',
        'is_onboarded': true,
        'created_at': testDate.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };

      final UserProfile profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.email, 'artisan@coop.org');
      expect(profile.fullName, 'Ramesh Kumar');
      expect(profile.phoneNumber, '+919876543210');
      expect(profile.role, UserRole.worker);
      expect(profile.isOnboarded, isTrue);
    });

    test('fromJson handles null/missing fields gracefully', () {
      final Map<String, Object?> json = <String, Object?>{
        'id': 'user-456',
      };

      final UserProfile profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-456');
      expect(profile.email, '');
      expect(profile.fullName, '');
      expect(profile.phoneNumber, '');
      expect(profile.role, UserRole.customer); // defaults to customer
      expect(profile.isOnboarded, isFalse);
    });

    test('toJson serializes correctly for database persistence', () {
      final UserProfile profile = UserProfile(
        id: 'user-789',
        email: 'admin@coop.org',
        fullName: 'Anita Sharma',
        phoneNumber: '+919123456780',
        role: UserRole.cooperativeAdmin,
        isOnboarded: true,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final Map<String, Object> json = profile.toJson();

      expect(json['id'], 'user-789');
      expect(json['email'], 'admin@coop.org');
      expect(json['full_name'], 'Anita Sharma');
      expect(json['phone_number'], '+919123456780');
      expect(json['role'], 'cooperative_admin');
      expect(json['is_onboarded'], true);
      expect(json.containsKey('updated_at'), isTrue);
    });

    test('copyWith produces expected updated instance', () {
      final UserProfile original = UserProfile(
        id: 'user-001',
        email: 'test@example.com',
        fullName: 'Initial Name',
        phoneNumber: '',
        role: UserRole.customer,
        isOnboarded: false,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final UserProfile updated = original.copyWith(
        fullName: 'Final Name',
        phoneNumber: '+919999999999',
        role: UserRole.worker,
        isOnboarded: true,
      );

      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.fullName, 'Final Name');
      expect(updated.phoneNumber, '+919999999999');
      expect(updated.role, UserRole.worker);
      expect(updated.isOnboarded, isTrue);
    });

    test('equality and hashcode match based on contents', () {
      final UserProfile p1 = UserProfile(
        id: '1',
        email: 'a@b.com',
        fullName: 'Name',
        phoneNumber: '123',
        role: UserRole.customer,
        isOnboarded: true,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final UserProfile p2 = UserProfile(
        id: '1',
        email: 'a@b.com',
        fullName: 'Name',
        phoneNumber: '123',
        role: UserRole.customer,
        isOnboarded: true,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
