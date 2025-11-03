
enum NotificationType {
  enrollment,
  submission,
  message,
  systemAlert,
  courseCompletion,
  attendance,
  gradeDispute,
  resourceRequest,
  assignmentCreated,
  announcementPosted,
}

class AdminNotification {
  final String id;
  final DateTime createdAt;
  final String recipientId;
  final String title;
  final String content;
  final bool isRead;
  final String? link;
  final NotificationType type;
  final String? senderName;
  final String? senderAvatar;
  final Map<String, dynamic>? metadata;

  AdminNotification({
    required this.id,
    required this.createdAt,
    required this.recipientId,
    required this.title,
    required this.content,
    required this.isRead,
    this.link,
    required this.type,
    this.senderName,
    this.senderAvatar,
    this.metadata,
  });

  factory AdminNotification.fromMap(Map<String, dynamic> map) {
    return AdminNotification(
      id: map['id'].toString(),
      createdAt: DateTime.parse(map['created_at']),
      recipientId: map['recipient_id'],
      title: map['title'] ?? '',
      content: map['content'],
      isRead: map['is_read'] ?? false,
      link: map['link'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.systemAlert,
      ),
      senderName: map['sender_name'],
      senderAvatar: map['sender_avatar'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'recipient_id': recipientId,
      'title': title,
      'content': content,
      'is_read': isRead,
      'link': link,
      'type': type.toString().split('.').last,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'metadata': metadata,
    };
  }

  AdminNotification copyWith({
    String? id,
    DateTime? createdAt,
    String? recipientId,
    String? title,
    String? content,
    bool? isRead,
    String? link,
    NotificationType? type,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? metadata,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      link: link ?? this.link,
      type: type ?? this.type,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Keep the old Notification class for backward compatibility
class Notification {
  final int id;
  final DateTime createdAt;
  final String recipientId;
  final String content;
  final bool isRead;
  final String? link;

  Notification({
    required this.id,
    required this.createdAt,
    required this.recipientId,
    required this.content,
    required this.isRead,
    this.link,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      recipientId: map['recipient_id'],
      content: map['content'],
      isRead: map['is_read'],
      link: map['link'],
    );
  }
}
