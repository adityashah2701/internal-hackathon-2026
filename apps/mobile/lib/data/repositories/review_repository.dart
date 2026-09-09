import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/review.dart';

/// Repository for reviews and ratings.
///
/// Rules enforced:
/// - One review per booking (DB constraint `reviews_one_per_booking`)
/// - Only the booking's customer can create a review (RLS policy)
/// - Booking must be in `payment_confirmed`, `completed`, or `reviewed` status (RLS policy)
abstract interface class IReviewRepository {
  /// Submit a review for a completed/paid booking.
  Future<Review> submitReview({
    required String bookingId,
    required String reviewerId,
    required String workerId,
    required int rating,
    String comment,
  });

  /// Get all reviews for a worker, paginated and newest first.
  Future<List<Review>> getWorkerReviews(String workerId, {int limit, int offset});

  /// Get the average rating for a worker. Returns 0 if no reviews exist.
  Future<double> getWorkerAverageRating(String workerId);
}

class SupabaseReviewRepository implements IReviewRepository {
  SupabaseReviewRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String reviewerId,
    required String workerId,
    required int rating,
    String comment = '',
  }) async {
    try {
      final Map<String, Object?> data = await _safeClient
          .from('reviews')
          .insert(<String, Object?>{
            'booking_id': bookingId,
            'reviewer_id': reviewerId,
            'worker_id': workerId,
            'rating': rating,
            'comment': comment,
          })
          .select()
          .single();

      // Also update booking status to 'reviewed'
      await _safeClient
          .from('bookings')
          .update(<String, Object?>{'status': 'reviewed'})
          .eq('id', bookingId);

      return Review.fromJson(data);
    } on sb.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ServerException(message: 'You have already reviewed this booking.');
      }
      throw ServerException(message: 'Failed to submit review: ${e.message}');
    } catch (e, st) {
      AppLogger.error('Error submitting review', error: e, stackTrace: st);
      throw ServerException(message: 'Failed to submit review: $e');
    }
  }

  @override
  Future<List<Review>> getWorkerReviews(String workerId, {int limit = 20, int offset = 0}) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('reviews')
          .select('*, reviewer_profile:profiles!reviewer_id(full_name)')
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map(Review.fromJson).toList();
    } catch (e, st) {
      AppLogger.error('Error loading worker reviews', error: e, stackTrace: st);
      return const <Review>[];
    }
  }

  @override
  Future<double> getWorkerAverageRating(String workerId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('reviews')
          .select('rating')
          .eq('worker_id', workerId);

      if (response.isEmpty) return 0;

      final double sum = response.fold<double>(
        0,
        (double acc, Map<String, Object?> row) => acc + ((row['rating'] as num?)?.toDouble() ?? 0),
      );
      return sum / response.length;
    } catch (e) {
      AppLogger.warning('Error calculating average rating: $e', tag: 'ReviewRepo');
      return 0;
    }
  }
}

final Provider<IReviewRepository> reviewRepositoryProvider =
    Provider<IReviewRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseReviewRepository(client: client);
});
