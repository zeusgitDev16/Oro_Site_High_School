/// Model for classroom subjects
class ClassroomSubject {
  final String id;
  final String classroomId;
  final String subjectName;
  final String? subjectCode;
  final String? description;
  final String? teacherId;
  final String? parentSubjectId; // For sub-subjects (e.g., Music under MAPEH)
  final int? courseId; // Link to courses table for attendance compatibility
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  // Additional fields from view
  final String? classroomTitle;
  final int? gradeLevel;
  final String? schoolLevel;
  final String? schoolYear;
  final String? teacherName;
  final int? moduleCount;
  final int? enrolledStudentsCount;

  ClassroomSubject({
    required this.id,
    required this.classroomId,
    required this.subjectName,
    this.subjectCode,
    this.description,
    this.teacherId,
    this.parentSubjectId,
    this.courseId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.classroomTitle,
    this.gradeLevel,
    this.schoolLevel,
    this.schoolYear,
    this.teacherName,
    this.moduleCount,
    this.enrolledStudentsCount,
  });

  factory ClassroomSubject.fromJson(Map<String, dynamic> json) {
    return ClassroomSubject(
      id: json['id'] as String,
      classroomId: json['classroom_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String?,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String?,
      parentSubjectId: json['parent_subject_id'] as String?,
      courseId: json['course_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      classroomTitle: json['classroom_title'] as String?,
      gradeLevel: json['grade_level'] as int?,
      schoolLevel: json['school_level'] as String?,
      schoolYear: json['school_year'] as String?,
      teacherName: json['teacher_name'] as String?,
      moduleCount: json['module_count'] as int?,
      enrolledStudentsCount: json['enrolled_students_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'description': description,
      'teacher_id': teacherId,
      'parent_subject_id': parentSubjectId,
      'course_id': courseId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  ClassroomSubject copyWith({
    String? id,
    String? classroomId,
    String? subjectName,
    String? subjectCode,
    String? description,
    String? teacherId,
    bool clearTeacherId = false, // Special flag to clear teacherId
    String? parentSubjectId,
    int? courseId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? classroomTitle,
    int? gradeLevel,
    String? schoolLevel,
    String? schoolYear,
    String? teacherName,
    int? moduleCount,
    int? enrolledStudentsCount,
  }) {
    return ClassroomSubject(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      description: description ?? this.description,
      teacherId: clearTeacherId ? null : (teacherId ?? this.teacherId),
      parentSubjectId: parentSubjectId ?? this.parentSubjectId,
      courseId: courseId ?? this.courseId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      classroomTitle: classroomTitle ?? this.classroomTitle,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      schoolLevel: schoolLevel ?? this.schoolLevel,
      schoolYear: schoolYear ?? this.schoolYear,
      teacherName: teacherName ?? this.teacherName,
      moduleCount: moduleCount ?? this.moduleCount,
      enrolledStudentsCount:
          enrolledStudentsCount ?? this.enrolledStudentsCount,
    );
  }
}
