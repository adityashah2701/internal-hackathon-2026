import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/booking.dart';

/// Repository for booking CRUD and lifecycle operations.
///
/// All data flows through Supabase — no in-memory fallback.
/// State transitions are validated server-side by the
/// `validate_booking_transition` trigger.
abstract interface class IBookingRepository {
  Future<Booking> createBooking(Booking booking);

  Future<List<Booking>> getCustomerBookings(String customerId, {int limit, int offset});

  Future<List<Booking>> getWorkerBookings(String workerId, {int limit, int offset});

  /// Gets bookings available for a worker to accept (unassigned, matching skills).
  Future<List<Booking>> getAvailableBookingsForWorker({
    required String workerId,
    List<String>? skills,
    int limit,
    int offset,
  });

  Future<List<Booking>> getAllBookings({String? cooperativeId, int limit, int offset});

  Future<Booking> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? workerId,
    String? cancellationReason,
  });

  /// Worker accepts a booking — sets status to 'accepted' and assigns worker.
  Future<Booking> acceptBooking({required String bookingId, required String workerId});

  /// Worker rejects a booking — sets status to 'rejected'.
  Future<Booking> rejectBooking({required String bookingId, String? reason});

  /// Customer cancels a booking — sets status to 'cancelled'.
  Future<Booking> cancelBooking({required String bookingId, String? reason});

  /// Worker starts the job — sets status to 'in_progress'.
  Future<Booking> startJob(String bookingId);

  /// Worker completes the job — sets status to 'completed'.
  Future<Booking> completeJob(String bookingId);

  Future<Map<String, int>> getWelfareMetrics({String? cooperativeId});
}

class SupabaseBookingRepository implements IBookingRepository {
  SupabaseBookingRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  /// Standard select query with joined names for display.
  static const String _bookingSelectQuery =
      '*, customer_profile:profiles!customer_id(full_name), '
      'worker_profile:profiles!worker_id(full_name), '
      'cooperatives(name)';

  @override
  Future<Booking> createBooking(Booking booking) async {
    final String trackingCode = 'BK-${(1000 + Random().nextInt(9000))}-${DateTime.now().year % 100}';
    final String startCode = (1000 + Random().nextInt(9000)).toString(); // 4 digit code

    final Map<String, Object?> payload = booking.toJson();
    // Let DB generate the UUID
    payload.remove('id');
    if (booking.trackingCode.isEmpty) {
      payload['tracking_code'] = trackingCode;
    }
    if (booking.startCode == null || booking.startCode!.isEmpty) {
      payload['start_code'] = startCode;
    }
    payload['created_at'] = DateTime.now().toIso8601String();

    try {
      final Map<String, Object?> data = await _safeClient
          .from('bookings')
          .insert(payload)
          .select(_bookingSelectQuery)
          .single();

      return Booking.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException inserting booking: ${e.message}', tag: 'BookingRepo');
      throw ServerException(message: 'Failed to create booking: ${e.message}');
    } catch (e, st) {
      AppLogger.error('Error creating booking', error: e, stackTrace: st);
      throw ServerException(message: 'Failed to create booking: $e');
    }
  }

  @override
  Future<List<Booking>> getCustomerBookings(String customerId, {int limit = 50, int offset = 0}) async {
    try {
      final List<dynamic> response = await _safeClient
          .from('bookings')
          .select(_bookingSelectQuery)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((dynamic item) => Booking.fromJson(item as Map<String, Object?>)).toList();
    } catch (e) {
      AppLogger.warning('Error loading customer bookings: $e', tag: 'BookingRepo');
      return const <Booking>[];
    }
  }

  @override
  Future<List<Booking>> getWorkerBookings(String workerId, {int limit = 50, int offset = 0}) async {
    try {
      final List<dynamic> response = await _safeClient
          .from('bookings')
          .select(_bookingSelectQuery)
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((dynamic item) => Booking.fromJson(item as Map<String, Object?>)).toList();
    } catch (e) {
      AppLogger.warning('Error loading worker bookings: $e', tag: 'BookingRepo');
      return const <Booking>[];
    }
  }

  @override
  Future<List<Booking>> getAvailableBookingsForWorker({
    required String workerId,
    List<String>? skills,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get bookings that are 'requested' and not yet assigned
      final List<dynamic> response = await _safeClient
          .from('bookings')
          .select(_bookingSelectQuery)
          .eq('status', 'requested')
          .isFilter('worker_id', null)
          .order('is_urgent', ascending: false) // Urgent first
          .order('created_at', ascending: true)  // FIFO
          .range(offset, offset + limit - 1);

      return response.map((dynamic item) => Booking.fromJson(item as Map<String, Object?>)).toList();
    } catch (e) {
      AppLogger.warning('Error loading available bookings: $e', tag: 'BookingRepo');
      return const <Booking>[];
    }
  }

  @override
  Future<List<Booking>> getAllBookings({String? cooperativeId, int limit = 50, int offset = 0}) async {
    try {
      var query = _safeClient.from('bookings').select(_bookingSelectQuery);
      if (cooperativeId != null && cooperativeId.isNotEmpty && cooperativeId != 'all') {
        query = query.eq('cooperative_id', cooperativeId);
      }
      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((dynamic item) => Booking.fromJson(item as Map<String, Object?>)).toList();
    } catch (e) {
      AppLogger.warning('Error loading all bookings: $e', tag: 'BookingRepo');
      return const <Booking>[];
    }
  }

  @override
  Future<Booking> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? workerId,
    String? cancellationReason,
  }) async {
    try {
      final Map<String, Object?> updates = <String, Object?>{
        'status': status.dbValue,
      };
      if (workerId != null) {
        updates['worker_id'] = workerId;
      }
      if (cancellationReason != null) {
        updates['cancellation_reason'] = cancellationReason;
      }

      final Map<String, Object?> data = await _safeClient
          .from('bookings')
          .update(updates)
          .eq('id', bookingId)
          .select(_bookingSelectQuery)
          .single();

      return Booking.fromJson(data);
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('Invalid booking status transition')) {
        throw ServerException(message: 'Invalid status transition. ${e.message}');
      }
      throw ServerException(message: 'Failed to update booking: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to update booking status: $e');
    }
  }

  @override
  Future<Booking> acceptBooking({required String bookingId, required String workerId}) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.accepted,
      workerId: workerId,
    );
  }

  @override
  Future<Booking> rejectBooking({required String bookingId, String? reason}) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.rejected,
      cancellationReason: reason,
    );
  }

  @override
  Future<Booking> cancelBooking({required String bookingId, String? reason}) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.cancelled,
      cancellationReason: reason,
    );
  }

  @override
  Future<Booking> startJob(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.inProgress,
    );
  }

  @override
  Future<Booking> completeJob(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.completed,
    );
  }

  @override
  Future<Map<String, int>> getWelfareMetrics({String? cooperativeId}) async {
    try {
      final List<Booking> all = await getAllBookings(cooperativeId: cooperativeId);
      final Iterable<Booking> completed = all.where(
        (Booking b) => b.status == BookingStatus.completed ||
            b.status == BookingStatus.paymentConfirmed ||
            b.status == BookingStatus.reviewed,
      );
      final int completedCount = completed.length;
      final int welfareSum = completed.fold<int>(0, (int acc, Booking b) => acc + b.welfareFee);

      return <String, int>{
        'completedBookings': completedCount,
        'welfarePoolInr': welfareSum,
      };
    } catch (e) {
      return const <String, int>{
        'completedBookings': 0,
        'welfarePoolInr': 0,
      };
    }
  }
}

final Provider<IBookingRepository> bookingRepositoryProvider = Provider<IBookingRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseBookingRepository(client: client);
});
