/// Model for course-teacher assignments
/// Represents the relationship between courses and teachers
class CourseAssignment {
  final String id;
  final String courseId;
  final String teacherId;
  final String teacherName;
  final String courseName;
  final String section;
  final DateTime assignedDate;
  final String status; // 'active', 'completed', 'archived'
  final int studentCount;
  final String schoolYear;
  final String? assignedBy; // Admin who made the assignment
  final String? notes;

  CourseAssignment({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.teacherName,
    required this.courseName,
    required this.section,
    required this.assignedDate,
    required this.status,
    required this.studentCount,
    required this.schoolYear,
    this.assignedBy,
    this.notes,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'course_name': courseName,
      'section': section,
      'assigned_date': assignedDate.toIso8601String(),
      'status': status,
      'student_count': studentCount,
      'school_year': schoolYear,
      'assigned_by': assignedBy,
      'notes': notes,
    };
  }

  // Create from JSON
  factory CourseAssignment.fromJson(Map<String, dynamic> json) {
    return CourseAssignment(
      id: json['id'],
      courseId: json['course_id'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      courseName: json['course_name'],
      section: json['section'],
      assignedDate: DateTime.parse(json['assigned_date']),
      status: json['status'],
      studentCount: json['student_count'],
      schoolYear: json['school_year'],
      assignedBy: json['assigned_by'],
      notes: json['notes'],
    );
  }

  // Copy with method for updates
  CourseAssignment copyWith({
    String? id,
    String? courseId,
    String? teacherId,
    String? teacherName,
    String? courseName,
    String? section,
    DateTime? assignedDate,
    String? status,
    int? studentCount,
    String? schoolYear,
    String? assignedBy,
    String? notes,
  }) {
    return CourseAssignment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      courseName: courseName ?? this.courseName,
      section: section ?? this.section,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      studentCount: studentCount ?? this.studentCount,
      schoolYear: schoolYear ?? this.schoolYear,
      assignedBy: assignedBy ?? this.assignedBy,
      notes: notes ?? this.notes,
    );
  }
}
