/// Course Model
/// Represents a course in the system
class Course {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? teacherId; // owner id

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.teacherId,
  });

  /// Create Course from JSON (from Supabase)
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(), // Handle both int and String IDs
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      // Accept multiple possible owner keys from backend
      teacherId: (json['teacher_id'] ?? json['created_by'] ?? json['owner_id'])?.toString(),
    );
  }

  /// Convert Course to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      if (teacherId != null) 'teacher_id': teacherId,
    };
  }

  /// Create a copy with updated fields
  Course copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? teacherId,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}
