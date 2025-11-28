/// Model for student TLE sub-subject enrollments
/// Tracks which TLE sub-subject each student is enrolled in
class StudentSubjectEnrollment {
  final String id;
  final String studentId;
  final String classroomId;
  final String parentSubjectId; // TLE parent subject ID
  final String enrolledSubjectId; // TLE sub-subject ID (Cookery, ICT, etc.)
  final String? enrolledBy; // Teacher who enrolled (Grades 7-8)
  final bool selfEnrolled; // True if student chose (Grades 9-10)
  final DateTime enrolledAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins (optional)
  final String? studentName;
  final String? enrolledSubjectName;
  final String? parentSubjectName;

  StudentSubjectEnrollment({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.parentSubjectId,
    required this.enrolledSubjectId,
    this.enrolledBy,
    required this.selfEnrolled,
    required this.enrolledAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.enrolledSubjectName,
    this.parentSubjectName,
  });

  factory StudentSubjectEnrollment.fromJson(Map<String, dynamic> json) {
    return StudentSubjectEnrollment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classroomId: json['classroom_id'] as String,
      parentSubjectId: json['parent_subject_id'] as String,
      enrolledSubjectId: json['enrolled_subject_id'] as String,
      enrolledBy: json['enrolled_by'] as String?,
      selfEnrolled: json['self_enrolled'] as bool? ?? false,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      studentName: json['student_name'] as String?,
      enrolledSubjectName: json['enrolled_subject_name'] as String?,
      parentSubjectName: json['parent_subject_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'classroom_id': classroomId,
      'parent_subject_id': parentSubjectId,
      'enrolled_subject_id': enrolledSubjectId,
      'enrolled_by': enrolledBy,
      'self_enrolled': selfEnrolled,
      'enrolled_at': enrolledAt.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StudentSubjectEnrollment copyWith({
    String? id,
    String? studentId,
    String? classroomId,
    String? parentSubjectId,
    String? enrolledSubjectId,
    String? enrolledBy,
    bool? selfEnrolled,
    DateTime? enrolledAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentName,
    String? enrolledSubjectName,
    String? parentSubjectName,
  }) {
    return StudentSubjectEnrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classroomId: classroomId ?? this.classroomId,
      parentSubjectId: parentSubjectId ?? this.parentSubjectId,
      enrolledSubjectId: enrolledSubjectId ?? this.enrolledSubjectId,
      enrolledBy: enrolledBy ?? this.enrolledBy,
      selfEnrolled: selfEnrolled ?? this.selfEnrolled,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      enrolledSubjectName: enrolledSubjectName ?? this.enrolledSubjectName,
      parentSubjectName: parentSubjectName ?? this.parentSubjectName,
    );
  }

  @override
  String toString() {
    return 'StudentSubjectEnrollment(id: $id, studentId: $studentId, '
        'enrolledSubjectId: $enrolledSubjectId, selfEnrolled: $selfEnrolled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudentSubjectEnrollment &&
        other.id == id &&
        other.studentId == studentId &&
        other.classroomId == classroomId &&
        other.parentSubjectId == parentSubjectId &&
        other.enrolledSubjectId == enrolledSubjectId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        classroomId.hashCode ^
        parentSubjectId.hashCode ^
        enrolledSubjectId.hashCode;
  }
}

