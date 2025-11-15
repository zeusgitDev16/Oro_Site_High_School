/// Classroom Model
/// Represents a classroom created by a teacher
class Classroom {
  static const String schoolLevelJhs = 'JHS';
  static const String schoolLevelShs = 'SHS';

  final String id;
  final String teacherId;
  final String title;
  final String? description;
  final int gradeLevel;
  final String schoolLevel;
  final int maxStudents;
  final int currentStudents;
  final bool isActive;
  final String? accessCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Classroom({
    required this.id,
    required this.teacherId,
    required this.title,
    this.description,
    required this.gradeLevel,
    required this.schoolLevel,
    required this.maxStudents,
    this.currentStudents = 0,
    this.isActive = true,
    this.accessCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Classroom from JSON
  factory Classroom.fromJson(Map<String, dynamic> json) {
    final gradeLevel = json['grade_level'] as int;
    final rawSchoolLevel = json['school_level'] as String?;
    final schoolLevel =
        rawSchoolLevel ?? _deriveSchoolLevelFromGradeLevel(gradeLevel);

    return Classroom(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      gradeLevel: gradeLevel,
      schoolLevel: schoolLevel,
      maxStudents: json['max_students'] as int,
      currentStudents: json['current_students'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      accessCode: json['access_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Classroom to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'grade_level': gradeLevel,
      'school_level': schoolLevel,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'is_active': isActive,
      'access_code': accessCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if classroom is full
  bool get isFull => currentStudents >= maxStudents;

  /// Get available slots
  int get availableSlots => maxStudents - currentStudents;

  /// Get occupancy percentage
  double get occupancyPercentage =>
      maxStudents > 0 ? (currentStudents / maxStudents) * 100 : 0;

  static String _deriveSchoolLevelFromGradeLevel(int gradeLevel) {
    if (gradeLevel >= 7 && gradeLevel <= 10) {
      return schoolLevelJhs;
    } else if (gradeLevel == 11 || gradeLevel == 12) {
      return schoolLevelShs;
    } else {
      // Fallback: default to JHS for out-of-range values
      return schoolLevelJhs;
    }
  }

  /// Copy with method for updates
  Classroom copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? description,
    int? gradeLevel,
    String? schoolLevel,
    int? maxStudents,
    int? currentStudents,
    bool? isActive,
    String? accessCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Classroom(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      schoolLevel: schoolLevel ?? this.schoolLevel,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      isActive: isActive ?? this.isActive,
      accessCode: accessCode ?? this.accessCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
