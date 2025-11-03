/// Enrollment Model - Enhanced with status tracking
/// Links students to courses with enrollment metadata
class Enrollment {
  final int id;
  final DateTime createdAt;
  final String studentId;
  final int courseId;
  final String status; // 'active', 'dropped', 'completed', 'pending'
  final DateTime enrolledAt;
  final String enrollmentType; // 'manual', 'auto', 'section_based'

  Enrollment({
    required this.id,
    required this.createdAt,
    required this.studentId,
    required this.courseId,
    this.status = 'active',
    required this.enrolledAt,
    this.enrollmentType = 'manual',
  });

  /// Create Enrollment from database map
  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      studentId: map['student_id'] as String,
      courseId: map['course_id'] as int,
      status: map['status'] as String? ?? 'active',
      enrolledAt: map['enrolled_at'] != null
          ? DateTime.parse(map['enrolled_at'] as String)
          : DateTime.now(),
      enrollmentType: map['enrollment_type'] as String? ?? 'manual',
    );
  }

  /// Convert Enrollment to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'student_id': studentId,
      'course_id': courseId,
      'status': status,
      'enrolled_at': enrolledAt.toIso8601String(),
      'enrollment_type': enrollmentType,
    };
  }

  /// Convert to map for INSERT (without id and created_at)
  Map<String, dynamic> toInsertMap() {
    return {
      'student_id': studentId,
      'course_id': courseId,
      'status': status,
      'enrolled_at': enrolledAt.toIso8601String(),
      'enrollment_type': enrollmentType,
    };
  }

  /// Check if enrollment is active
  bool get isActive => status == 'active';

  /// Check if enrollment is completed
  bool get isCompleted => status == 'completed';

  /// Check if enrollment is dropped
  bool get isDropped => status == 'dropped';

  /// Check if enrollment is pending
  bool get isPending => status == 'pending';

  /// Check if enrollment was automatic
  bool get isAutomatic => enrollmentType == 'auto' || enrollmentType == 'section_based';

  /// Check if enrollment was manual
  bool get isManual => enrollmentType == 'manual';

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'dropped':
        return 'Dropped';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  /// Get enrollment type display name
  String get enrollmentTypeDisplay {
    switch (enrollmentType) {
      case 'manual':
        return 'Manual';
      case 'auto':
        return 'Automatic';
      case 'section_based':
        return 'Section-based';
      default:
        return enrollmentType;
    }
  }

  /// Copy with updated fields
  Enrollment copyWith({
    int? id,
    DateTime? createdAt,
    String? studentId,
    int? courseId,
    String? status,
    DateTime? enrolledAt,
    String? enrollmentType,
  }) {
    return Enrollment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      enrollmentType: enrollmentType ?? this.enrollmentType,
    );
  }

  @override
  String toString() {
    return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enrollment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enrollment status enum
enum EnrollmentStatus {
  active,
  dropped,
  completed,
  pending;

  String get displayName {
    switch (this) {
      case EnrollmentStatus.active:
        return 'Active';
      case EnrollmentStatus.dropped:
        return 'Dropped';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.pending:
        return 'Pending';
    }
  }

  String get value {
    return name;
  }
}

/// Enrollment type enum
enum EnrollmentType {
  manual,
  auto,
  sectionBased;

  String get displayName {
    switch (this) {
      case EnrollmentType.manual:
        return 'Manual';
      case EnrollmentType.auto:
        return 'Automatic';
      case EnrollmentType.sectionBased:
        return 'Section-based';
    }
  }

  String get value {
    switch (this) {
      case EnrollmentType.manual:
        return 'manual';
      case EnrollmentType.auto:
        return 'auto';
      case EnrollmentType.sectionBased:
        return 'section_based';
    }
  }
}
