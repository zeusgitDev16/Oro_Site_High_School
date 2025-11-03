/// Model for teacher requests to admin
/// Represents feedback, issues, and requests from teachers
class TeacherRequest {
  final String id;
  final String teacherId;
  final String teacherName;
  final String requestType; // 'password_reset', 'resource', 'technical', 'course_modification', 'section_change', 'other'
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed', 'rejected'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminResponse;
  final String? resolvedBy;
  final Map<String, dynamic>? metadata; // Additional data (e.g., student LRN for password reset)

  TeacherRequest({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.requestType,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminResponse,
    this.resolvedBy,
    this.metadata,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'request_type': requestType,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'admin_response': adminResponse,
      'resolved_by': resolvedBy,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory TeacherRequest.fromJson(Map<String, dynamic> json) {
    return TeacherRequest(
      id: json['id'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      requestType: json['request_type'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      adminResponse: json['admin_response'],
      resolvedBy: json['resolved_by'],
      metadata: json['metadata'],
    );
  }

  // Copy with method for updates
  TeacherRequest copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? requestType,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminResponse,
    String? resolvedBy,
    Map<String, dynamic>? metadata,
  }) {
    return TeacherRequest(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      requestType: requestType ?? this.requestType,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isResolved => isCompleted || isRejected;
  bool get isUrgent => priority == 'urgent';
  bool get isPasswordReset => requestType == 'password_reset';
}
