enum BookingStatus {
  requested('requested', 'Requested', 'Awaiting worker acceptance'),
  accepted('accepted', 'Accepted', 'Worker has accepted the booking'),
  scheduled('scheduled', 'Scheduled', 'Service has been scheduled'),
  arrived('arrived', 'Worker Arrived', 'Worker has arrived and needs OTP verification'),
  inProgress('in_progress', 'In Progress', 'Worker is currently performing the service'),
  completed('completed', 'Completed', 'Service fulfilled and verified'),
  paymentConfirmed('payment_confirmed', 'Payment Confirmed', 'Payment has been received and verified'),
  reviewed('reviewed', 'Reviewed', 'Customer has submitted a review'),
  rejected('rejected', 'Rejected', 'Worker declined the booking'),
  cancelled('cancelled', 'Cancelled', 'Booking has been cancelled'),
  expired('expired', 'Expired', 'Booking expired without acceptance');

  const BookingStatus(this.dbValue, this.displayName, this.description);

  final String dbValue;
  final String displayName;
  final String description;

  /// Whether this status represents an active (in-flight) booking.
  bool get isActive => this == requested || this == accepted || this == scheduled || this == inProgress;

  /// Whether this status represents a terminal (final) state.
  bool get isTerminal => this == reviewed || this == cancelled || this == expired || this == rejected;

  /// Whether payment is expected at this status.
  bool get awaitingPayment => this == completed;

  /// Whether a review can be submitted at this status.
  bool get canReview => this == paymentConfirmed;

  static BookingStatus fromDbValue(String? value) {
    if (value == 'assigned') return BookingStatus.accepted;
    for (final BookingStatus s in BookingStatus.values) {
      if (s.dbValue == value) {
        return s;
      }
    }
    return BookingStatus.requested;
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.trackingCode,
    required this.customerId,
    this.customerName,
    this.workerId,
    this.workerName,
    this.cooperativeId,
    this.cooperativeName,
    required this.serviceCategory,
    required this.serviceTitle,
    this.serviceDescription = '',
    this.serviceId,
    required this.scheduledDate,
    this.timeSlot = 'Morning (9 AM - 1 PM)',
    required this.serviceAddress,
    this.isUrgent = false,
    this.baseFare = 300,
    this.welfareFee = 30,
    this.totalAmount = 330,
    this.status = BookingStatus.requested,
    this.customerLatitude,
    this.customerLongitude,
    this.acceptedAt,
    this.completedAt,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String trackingCode;
  final String customerId;
  final String? customerName;
  final String? workerId;
  final String? workerName;
  final String? cooperativeId;
  final String? cooperativeName;
  final String serviceCategory;
  final String serviceTitle;
  final String serviceDescription;
  final String? serviceId;
  final DateTime scheduledDate;
  final String timeSlot;
  final String serviceAddress;
  final bool isUrgent;
  final int baseFare;
  final int welfareFee;
  final int totalAmount;
  final BookingStatus status;
  final double? customerLatitude;
  final double? customerLongitude;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 4-digit OTP code to verify worker on-site arrival
  String get startOtp => trackingCode.length >= 4 ? trackingCode.substring(trackingCode.length - 4) : '4821';

  Booking copyWith({
    String? id,
    String? trackingCode,
    String? customerId,
    String? customerName,
    String? workerId,
    String? workerName,
    String? cooperativeId,
    String? cooperativeName,
    String? serviceCategory,
    String? serviceTitle,
    String? serviceDescription,
    String? serviceId,
    DateTime? scheduledDate,
    String? timeSlot,
    String? serviceAddress,
    bool? isUrgent,
    int? baseFare,
    int? welfareFee,
    int? totalAmount,
    BookingStatus? status,
    double? customerLatitude,
    double? customerLongitude,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      trackingCode: trackingCode ?? this.trackingCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      cooperativeName: cooperativeName ?? this.cooperativeName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      serviceId: serviceId ?? this.serviceId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      isUrgent: isUrgent ?? this.isUrgent,
      baseFare: baseFare ?? this.baseFare,
      welfareFee: welfareFee ?? this.welfareFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Booking.fromJson(Map<String, Object?> json) {
    String? customerNameJoined;
    String? workerNameJoined;
    String? coopNameJoined;

    if (json['customer_profile'] is Map) {
      customerNameJoined = (json['customer_profile']! as Map<String, Object?>)['full_name'] as String?;
    } else {
      customerNameJoined = json['customer_name'] as String?;
    }

    if (json['worker_profile'] is Map) {
      workerNameJoined = (json['worker_profile']! as Map<String, Object?>)['full_name'] as String?;
    } else {
      workerNameJoined = json['worker_name'] as String?;
    }

    if (json['cooperatives'] is Map) {
      coopNameJoined = (json['cooperatives']! as Map<String, Object?>)['name'] as String?;
    } else {
      coopNameJoined = json['cooperative_name'] as String?;
    }

    final String dateStr = json['scheduled_date'] as String? ?? DateTime.now().toIso8601String();
    final DateTime parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    return Booking(
      id: json['id'] as String? ?? '',
      trackingCode: json['tracking_code'] as String? ?? 'BK-${DateTime.now().millisecondsSinceEpoch % 100000}',
      customerId: json['customer_id'] as String? ?? '',
      customerName: customerNameJoined,
      workerId: json['worker_id'] as String?,
      workerName: workerNameJoined,
      cooperativeId: json['cooperative_id'] as String?,
      cooperativeName: coopNameJoined,
      serviceCategory: json['service_category'] as String? ?? 'General',
      serviceTitle: json['service_title'] as String? ?? 'Home Service',
      serviceDescription: json['service_description'] as String? ?? '',
      serviceId: json['service_id'] as String?,
      scheduledDate: parsedDate,
      timeSlot: json['time_slot'] as String? ?? 'Morning (9 AM - 1 PM)',
      serviceAddress: json['service_address'] as String? ?? '',
      isUrgent: json['is_urgent'] as bool? ?? false,
      baseFare: (json['base_fare'] as num?)?.toInt() ?? 300,
      welfareFee: (json['welfare_fee'] as num?)?.toInt() ?? 30,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 330,
      status: BookingStatus.fromDbValue(json['status'] as String?),
      customerLatitude: (json['customer_latitude'] as num?)?.toDouble(),
      customerLongitude: (json['customer_longitude'] as num?)?.toDouble(),
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at']! as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']! as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']! as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']! as String) : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'tracking_code': trackingCode,
      'customer_id': customerId,
      'worker_id': workerId,
      'cooperative_id': cooperativeId,
      'service_category': serviceCategory,
      'service_title': serviceTitle,
      'service_description': serviceDescription,
      'service_id': serviceId,
      'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
      'time_slot': timeSlot,
      'service_address': serviceAddress,
      'is_urgent': isUrgent,
      'base_fare': baseFare,
      'welfare_fee': welfareFee,
      'total_amount': totalAmount,
      'status': status.dbValue,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
