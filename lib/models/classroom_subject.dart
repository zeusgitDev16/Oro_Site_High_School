/// Subject type enum for sub-subject tree enhancement
enum SubjectType {
  standard,      // Regular subject (Math, English, etc.)
  mapehParent,   // MAPEH parent subject
  mapehSub,      // MAPEH sub-subject (Music, Arts, PE, Health)
  tleParent,     // TLE parent subject
  tleSub;        // TLE sub-subject (Cookery, Carpentry, ICT, etc.)

  /// Convert enum to database string value
  String toDbString() {
    switch (this) {
      case SubjectType.standard:
        return 'standard';
      case SubjectType.mapehParent:
        return 'mapeh_parent';
      case SubjectType.mapehSub:
        return 'mapeh_sub';
      case SubjectType.tleParent:
        return 'tle_parent';
      case SubjectType.tleSub:
        return 'tle_sub';
    }
  }

  /// Parse database string value to enum
  static SubjectType fromDbString(String? value) {
    switch (value) {
      case 'mapeh_parent':
        return SubjectType.mapehParent;
      case 'mapeh_sub':
        return SubjectType.mapehSub;
      case 'tle_parent':
        return SubjectType.tleParent;
      case 'tle_sub':
        return SubjectType.tleSub;
      case 'standard':
      default:
        return SubjectType.standard;
    }
  }
}

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
  final SubjectType subjectType; // NEW: Type of subject (standard, mapeh_parent, etc.)
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
    this.subjectType = SubjectType.standard, // Default to standard
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
      subjectType: SubjectType.fromDbString(json['subject_type'] as String?),
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
      'subject_type': subjectType.toDbString(),
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
    SubjectType? subjectType,
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
      subjectType: subjectType ?? this.subjectType,
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

  /// Helper methods for subject type checks
  bool get isStandard => subjectType == SubjectType.standard;
  bool get isMAPEHParent => subjectType == SubjectType.mapehParent;
  bool get isMAPEHSub => subjectType == SubjectType.mapehSub;
  bool get isTLEParent => subjectType == SubjectType.tleParent;
  bool get isTLESub => subjectType == SubjectType.tleSub;
  bool get isParentSubject => isMAPEHParent || isTLEParent;
  bool get isSubSubject => isMAPEHSub || isTLESub;
}
