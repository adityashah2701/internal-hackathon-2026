/// Dart model for the `reviews` table.
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.workerId,
    required this.rating,
    this.comment = '',
    this.reviewerName,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String reviewerId;
  final String workerId;
  final int rating;
  final String comment;
  final String? reviewerName;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, Object?> json) {
    // Handle joined reviewer profile
    String? joinedReviewerName;
    if (json['reviewer_profile'] is Map) {
      joinedReviewerName =
          (json['reviewer_profile']! as Map<String, Object?>)['full_name'] as String?;
    } else {
      joinedReviewerName = json['reviewer_name'] as String?;
    }

    return Review(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewerName: joinedReviewerName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'worker_id': workerId,
      'rating': rating,
      'comment': comment,
    };
  }
}
