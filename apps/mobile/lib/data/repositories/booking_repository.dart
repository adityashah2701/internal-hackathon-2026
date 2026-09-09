import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/booking.dart';
import '../models/worker_profile.dart';
import 'worker_data_store.dart';

abstract interface class IBookingRepository {
  Future<Booking> createBooking(Booking booking);

  Future<List<Booking>> getCustomerBookings(String customerId);

  Future<List<Booking>> getWorkerBookings(String workerId);

  Future<List<Booking>> getAllBookings({String? cooperativeId});

  Future<Booking> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? workerId,
  });

  Future<Map<String, int>> getWelfareMetrics({String? cooperativeId});
}

class BookingDataStore {
  static final List<Booking> inMemoryBookings = <Booking>[];
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

  @override
  Future<Booking> createBooking(Booking booking) async {
    final String trackingCode = 'BK-${(1000 + Random().nextInt(9000))}-${DateTime.now().year % 100}';
    final Booking withTracking = booking.copyWith(
      id: booking.id.isEmpty ? 'bk-${DateTime.now().millisecondsSinceEpoch}' : booking.id,
      trackingCode: booking.trackingCode.isEmpty ? trackingCode : booking.trackingCode,
      createdAt: DateTime.now(),
    );

    // Save locally
    BookingDataStore.inMemoryBookings.insert(0, withTracking);

    try {
      final Map<String, Object?> payload = withTracking.toJson();
      final Map<String, Object?> data = await _safeClient
          .from('bookings')
          .insert(payload)
          .select()
          .single();

      final Booking created = Booking.fromJson(data);
      BookingDataStore.inMemoryBookings[0] = created;
      return created;
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException inserting booking: ${e.message}', tag: 'BookingRepo');
      return withTracking;
    } catch (e, st) {
      AppLogger.error('Error creating booking', error: e, stackTrace: st);
      return withTracking;
    }
  }

  @override
  Future<List<Booking>> getCustomerBookings(String customerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('bookings')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return response.map(Booking.fromJson).toList();
      }
      return BookingDataStore.inMemoryBookings
          .where((Booking b) => b.customerId == customerId)
          .toList();
    } catch (e) {
      AppLogger.warning('Customer bookings fallback: $e', tag: 'BookingRepo');
      return BookingDataStore.inMemoryBookings
          .where((Booking b) => b.customerId == customerId)
          .toList();
    }
  }

  @override
  Future<List<Booking>> getWorkerBookings(String workerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('bookings')
          .select()
          .eq('worker_id', workerId)
          .order('scheduled_date', ascending: false);

      if (response.isNotEmpty) {
        return response.map(Booking.fromJson).toList();
      }
      return BookingDataStore.inMemoryBookings.where((Booking b) => b.workerId == workerId).toList();
    } catch (e) {
      AppLogger.warning('Worker bookings fallback: $e', tag: 'BookingRepo');
      return BookingDataStore.inMemoryBookings.where((Booking b) => b.workerId == workerId).toList();
    }
  }

  @override
  Future<List<Booking>> getAllBookings({String? cooperativeId}) async {
    try {
      var query = _safeClient.from('bookings').select();
      if (cooperativeId != null && cooperativeId.isNotEmpty && cooperativeId != 'all') {
        query = query.eq('cooperative_id', cooperativeId);
      }
      final List<Map<String, Object?>> response = await query.order('created_at', ascending: false);
      if (response.isNotEmpty) {
        return response.map(Booking.fromJson).toList();
      }
      return BookingDataStore.inMemoryBookings;
    } catch (e) {
      return BookingDataStore.inMemoryBookings;
    }
  }

  @override
  Future<Booking> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? workerId,
  }) async {
    final int idx = BookingDataStore.inMemoryBookings.indexWhere((Booking b) => b.id == bookingId);
    if (idx != -1) {
      final Booking existing = BookingDataStore.inMemoryBookings[idx];
      final Booking updated = existing.copyWith(
        status: status,
        workerId: workerId ?? existing.workerId,
        updatedAt: DateTime.now(),
      );
      BookingDataStore.inMemoryBookings[idx] = updated;
    }

    try {
      final Map<String, Object?> updates = <String, Object?>{
        'status': status.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (workerId != null) {
        updates['worker_id'] = workerId;
      }

      final Map<String, Object?> data = await _safeClient
          .from('bookings')
          .update(updates)
          .eq('id', bookingId)
          .select()
          .single();

      return Booking.fromJson(data);
    } catch (e) {
      AppLogger.warning('Update booking status fallback: $e', tag: 'BookingRepo');
      if (idx != -1) {
        return BookingDataStore.inMemoryBookings[idx];
      }
      throw ServerException(message: 'Booking not found: $bookingId');
    }
  }

  @override
  Future<Map<String, int>> getWelfareMetrics({String? cooperativeId}) async {
    try {
      final List<Booking> all = await getAllBookings(cooperativeId: cooperativeId);
      final int completedCount = all.where((Booking b) => b.status == BookingStatus.completed).length;
      final int welfareSum = all
          .where((Booking b) => b.status == BookingStatus.completed)
          .fold<int>(0, (int acc, Booking b) => acc + b.welfareFee);

      // Active workers calculation
      final int activeWorkers = WorkerDataStore.profiles.values
          .where((WorkerProfile p) => p.isAvailable && p.verificationStatus.isApproved)
          .length;

      return <String, int>{
        'activeWorkers': activeWorkers,
        'completedBookings': completedCount,
        'welfarePoolInr': welfareSum,
      };
    } catch (e) {
      return const <String, int>{
        'activeWorkers': 0,
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
