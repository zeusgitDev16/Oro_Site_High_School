
import 'dart:convert';

class ActivityLog {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final String action;
  final Map<String, dynamic>? details;

  ActivityLog({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.action,
    this.details,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      userId: map['user_id'],
      action: map['action'],
      details: map['details'] != null ? jsonDecode(map['details']) : null,
    );
  }
}
