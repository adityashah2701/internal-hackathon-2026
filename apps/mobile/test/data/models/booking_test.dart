import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('BookingStatus parsing and dbValue works correctly', () {
      expect(BookingStatus.fromDbValue('requested'), equals(BookingStatus.requested));
      expect(BookingStatus.fromDbValue('assigned'), equals(BookingStatus.accepted));
      expect(BookingStatus.fromDbValue('in_progress'), equals(BookingStatus.inProgress));
      expect(BookingStatus.fromDbValue('completed'), equals(BookingStatus.completed));
      expect(BookingStatus.fromDbValue('cancelled'), equals(BookingStatus.cancelled));
      expect(BookingStatus.fromDbValue('unknown_status'), equals(BookingStatus.requested));

      expect(BookingStatus.requested.dbValue, equals('requested'));
      expect(BookingStatus.inProgress.dbValue, equals('in_progress'));
      expect(BookingStatus.completed.displayName, equals('Completed'));
    });

    test('Booking JSON serialization and deserialization preserves all fields', () {
      final DateTime testDate = DateTime(2026, 9, 10, 10, 0);
      final Booking booking = Booking(
        id: 'bk-test-101',
        trackingCode: 'BK-7492-PUN',
        customerId: 'cust-101',
        customerName: 'Priya Sharma',
        workerId: 'wrk-101',
        workerName: 'Ramesh Patel',
        cooperativeId: 'coop-01',
        serviceCategory: 'Plumbing',
        serviceTitle: 'Pipe Leakage Repair',
        scheduledDate: testDate,
        timeSlot: 'Morning (9 AM - 1 PM)',
        serviceAddress: '42 MG Road, Sector 4',
        isUrgent: true,
        baseFare: 450,
        welfareFee: 45,
        totalAmount: 495,
        status: BookingStatus.requested,
      );

      final Map<String, dynamic> json = booking.toJson();
      expect(json['id'], equals('bk-test-101'));
      expect(json['tracking_code'], equals('BK-7492-PUN'));
      expect(json['service_category'], equals('Plumbing'));
      expect(json['service_title'], equals('Pipe Leakage Repair'));
      expect(json['is_urgent'], isTrue);
      expect(json['base_fare'], equals(450));
      expect(json['welfare_fee'], equals(45));
      expect(json['total_amount'], equals(495));
      expect(json['status'], equals('requested'));

      final Booking parsed = Booking.fromJson(json);
      expect(parsed.id, equals(booking.id));
      expect(parsed.serviceCategory, equals(booking.serviceCategory));
      expect(parsed.isUrgent, isTrue);
      expect(parsed.totalAmount, equals(495));
      expect(parsed.status, equals(BookingStatus.requested));
    });

    test('Booking copyWith produces modified clone', () {
      final Booking original = Booking(
        id: 'bk-test-102',
        trackingCode: 'BK-8821-MUM',
        customerId: 'cust-102',
        serviceCategory: 'Electrical',
        serviceTitle: 'Ceiling Fan Installation',
        scheduledDate: DateTime(2026, 9, 11),
        timeSlot: 'Afternoon (1 PM - 5 PM)',
        serviceAddress: '10 Park Avenue',
        baseFare: 500,
        welfareFee: 50,
        totalAmount: 550,
        status: BookingStatus.requested,
      );

      final Booking updated = original.copyWith(
        status: BookingStatus.completed,
        workerName: 'Vikram Singh',
      );

      expect(updated.id, equals(original.id));
      expect(updated.status, equals(BookingStatus.completed));
      expect(updated.workerName, equals('Vikram Singh'));
      expect(original.status, equals(BookingStatus.requested));
    });
  });
}
