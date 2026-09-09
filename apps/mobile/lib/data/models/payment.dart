/// Payment status tracking.
enum PaymentStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed'),
  refunded('refunded', 'Refunded');

  const PaymentStatus(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static PaymentStatus fromDbValue(String? value) {
    for (final PaymentStatus s in PaymentStatus.values) {
      if (s.dbValue == value) return s;
    }
    return PaymentStatus.pending;
  }
}

/// Dart model for the `payments` table.
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amountInr,
    this.paymentMethod = 'razorpay',
    this.gatewayOrderId,
    this.gatewayPaymentId,
    this.gatewaySignature,
    this.status = PaymentStatus.pending,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final int amountInr;
  final String paymentMethod;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final String? gatewaySignature;
  final PaymentStatus status;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Payment.fromJson(Map<String, Object?> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      amountInr: (json['amount_inr'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'razorpay',
      gatewayOrderId: json['gateway_order_id'] as String?,
      gatewayPaymentId: json['gateway_payment_id'] as String?,
      gatewaySignature: json['gateway_signature'] as String?,
      status: PaymentStatus.fromDbValue(json['status'] as String?),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at']! as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'booking_id': bookingId,
      'amount_inr': amountInr,
      'payment_method': paymentMethod,
      'gateway_order_id': gatewayOrderId,
      'gateway_payment_id': gatewayPaymentId,
      'gateway_signature': gatewaySignature,
      'status': status.dbValue,
    };
  }
}
