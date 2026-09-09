import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/booking.dart';
import 'package:mobile/data/repositories/booking_repository.dart';

void main() {
  group('BookingRepository Tests', () {
    late SupabaseBookingRepository repository;

    setUp(() {
      repository = SupabaseBookingRepository();
    });

    test('createBooking successfully registers booking in fallback store', () async {
      final Booking newBooking = Booking(
        id: '',
        trackingCode: '',
        customerId: 'cust-test-01',
        customerName: 'Karan Mehta',
        serviceCategory: 'Carpentry',
        serviceTitle: 'Door Lock Replacement',
        scheduledDate: DateTime(2026, 9, 12),
        timeSlot: 'Morning (9 AM - 1 PM)',
        serviceAddress: '12 Sector 15, Gandhinagar',
        isUrgent: false,
        baseFare: 600,
        welfareFee: 60, // 10%
        totalAmount: 660,
        cooperativeId: 'coop-gandhinagar-01',
        workerName: 'Anil Suthar',
      );

      final Booking created = await repository.createBooking(newBooking);

      expect(created.id, startsWith('bk-'));
      expect(created.trackingCode, startsWith('BK-'));
      expect(created.serviceCategory, equals('Carpentry'));
      expect(created.baseFare, equals(600));
      expect(created.welfareFee, equals(60));
      expect(created.totalAmount, equals(660));
      expect(created.status, equals(BookingStatus.requested));
    });

    test('updateBookingStatus updates booking state correctly', () async {
      final Booking newBooking = Booking(
        id: '',
        trackingCode: '',
        customerId: 'cust-test-02',
        serviceCategory: 'Painting',
        serviceTitle: 'Room Wall Painting',
        scheduledDate: DateTime(2026, 9, 15),
        serviceAddress: '99 Ring Road',
        baseFare: 800,
        welfareFee: 80,
        totalAmount: 880,
      );

      final Booking created = await repository.createBooking(newBooking);

      final Booking updated = await repository.updateBookingStatus(
        bookingId: created.id,
        status: BookingStatus.completed,
      );

      expect(updated.id, equals(created.id));
      expect(updated.status, equals(BookingStatus.completed));
    });

    test('getWelfareMetrics computes completed jobs count and welfare pool', () async {
      final Map<String, int> metrics = await repository.getWelfareMetrics();

      expect(metrics.containsKey('activeWorkers'), isTrue);
      expect(metrics.containsKey('completedBookings'), isTrue);
      expect(metrics.containsKey('welfarePoolInr'), isTrue);
      expect(metrics['activeWorkers']!, greaterThanOrEqualTo(0));
      expect(metrics['completedBookings']!, greaterThanOrEqualTo(0));
      expect(metrics['welfarePoolInr']!, greaterThanOrEqualTo(0));
    });
  });
}
