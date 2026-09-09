/// Dart model for the `welfare_contributions` table.
class WelfareContribution {
  const WelfareContribution({
    required this.id,
    required this.bookingId,
    required this.workerId,
    this.cooperativeId,
    required this.amountInr,
    this.contributionType = 'booking_deduction',
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String workerId;
  final String? cooperativeId;
  final int amountInr;
  final String contributionType; // 'booking_deduction' or 'manual_contribution'
  final DateTime? createdAt;

  factory WelfareContribution.fromJson(Map<String, Object?> json) {
    return WelfareContribution(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      cooperativeId: json['cooperative_id'] as String?,
      amountInr: (json['amount_inr'] as num?)?.toInt() ?? 0,
      contributionType: json['contribution_type'] as String? ?? 'booking_deduction',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'booking_id': bookingId,
      'worker_id': workerId,
      'cooperative_id': cooperativeId,
      'amount_inr': amountInr,
      'contribution_type': contributionType,
    };
  }
}
