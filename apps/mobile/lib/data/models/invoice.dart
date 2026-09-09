/// Dart model for the `invoices` table.
class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.bookingId,
    required this.customerId,
    this.workerId,
    required this.serviceDescription,
    required this.baseAmountInr,
    required this.welfareContributionInr,
    required this.totalAmountInr,
    this.paymentStatus = 'unpaid',
    this.issuedAt,
  });

  final String id;
  final String invoiceNumber;
  final String bookingId;
  final String customerId;
  final String? workerId;
  final String serviceDescription;
  final int baseAmountInr;
  final int welfareContributionInr;
  final int totalAmountInr;
  final String paymentStatus; // 'unpaid', 'paid', 'refunded'
  final DateTime? issuedAt;

  bool get isPaid => paymentStatus == 'paid';

  factory Invoice.fromJson(Map<String, Object?> json) {
    return Invoice(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      workerId: json['worker_id'] as String?,
      serviceDescription: json['service_description'] as String? ?? '',
      baseAmountInr: (json['base_amount_inr'] as num?)?.toInt() ?? 0,
      welfareContributionInr: (json['welfare_contribution_inr'] as num?)?.toInt() ?? 0,
      totalAmountInr: (json['total_amount_inr'] as num?)?.toInt() ?? 0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      issuedAt: json['issued_at'] != null
          ? DateTime.tryParse(json['issued_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'invoice_number': invoiceNumber,
      'booking_id': bookingId,
      'customer_id': customerId,
      'worker_id': workerId,
      'service_description': serviceDescription,
      'base_amount_inr': baseAmountInr,
      'welfare_contribution_inr': welfareContributionInr,
      'total_amount_inr': totalAmountInr,
      'payment_status': paymentStatus,
    };
  }
}
