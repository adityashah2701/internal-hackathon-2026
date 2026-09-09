/// Dart model for the `notifications` table.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.eventType,
    this.referenceId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String eventType;
  final String? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? eventType,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      eventType: eventType ?? this.eventType,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, Object?> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'user_id': userId,
      'title': title,
      'body': body,
      'event_type': eventType,
      'reference_id': referenceId,
      'is_read': isRead,
    };
  }
}
