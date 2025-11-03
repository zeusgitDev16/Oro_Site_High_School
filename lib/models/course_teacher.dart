/// Course-Teacher Link Model
/// Represents the relationship between courses and teachers
class CourseTeacher {
  final String id;
  final String courseId;
  final String teacherId;
  final DateTime createdAt;

  CourseTeacher({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.createdAt,
  });

  /// Create from JSON
  factory CourseTeacher.fromJson(Map<String, dynamic> json) {
    return CourseTeacher(
      id: json['id'].toString(),
      courseId: json['course_id'].toString(),
      teacherId: json['teacher_id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
