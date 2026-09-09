enum BookingStatus {
  requested('requested', 'Requested', 'Awaiting worker assignment by cooperative'),
  assigned('assigned', 'Assigned', 'Cooperative worker assigned to service request'),
  inProgress('in_progress', 'In Progress', 'Worker is currently executing the service'),
  completed('completed', 'Completed', 'Service fulfilled and verified'),
  cancelled('cancelled', 'Cancelled', 'Booking has been cancelled');

  const BookingStatus(this.dbValue, this.displayName, this.description);

  final String dbValue;
  final String displayName;
  final String description;

  static BookingStatus fromDbValue(String? value) {
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
    required this.scheduledDate,
    this.timeSlot = 'Morning (9 AM - 1 PM)',
    required this.serviceAddress,
    this.isUrgent = false,
    this.baseFare = 300,
    this.welfareFee = 30,
    this.totalAmount = 330,
    this.status = BookingStatus.requested,
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
  final DateTime scheduledDate;
  final String timeSlot;
  final String serviceAddress;
  final bool isUrgent;
  final int baseFare;
  final int welfareFee;
  final int totalAmount;
  final BookingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    DateTime? scheduledDate,
    String? timeSlot,
    String? serviceAddress,
    bool? isUrgent,
    int? baseFare,
    int? welfareFee,
    int? totalAmount,
    BookingStatus? status,
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
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      isUrgent: isUrgent ?? this.isUrgent,
      baseFare: baseFare ?? this.baseFare,
      welfareFee: welfareFee ?? this.welfareFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
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
      scheduledDate: parsedDate,
      timeSlot: json['time_slot'] as String? ?? 'Morning (9 AM - 1 PM)',
      serviceAddress: json['service_address'] as String? ?? '',
      isUrgent: json['is_urgent'] as bool? ?? false,
      baseFare: (json['base_fare'] as num?)?.toInt() ?? 300,
      welfareFee: (json['welfare_fee'] as num?)?.toInt() ?? 30,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 330,
      status: BookingStatus.fromDbValue(json['status'] as String?),
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
      'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
      'time_slot': timeSlot,
      'service_address': serviceAddress,
      'is_urgent': isUrgent,
      'base_fare': baseFare,
      'welfare_fee': welfareFee,
      'total_amount': totalAmount,
      'status': status.dbValue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
