/// Teacher Load Management
/// Manages teacher workload and ensures DepEd compliance
/// Based on DepEd Order No. 3, s. 2018 (Teaching Load)

/// Teacher Load Model
class TeacherLoad {
  final String id;
  final String teacherId;
  final String teacherName;
  final String schoolYear;
  
  // Teaching Assignments
  final List<TeachingAssignment> assignments;
  
  // Load Summary
  final int totalTeachingHours;
  final int totalPreparationHours;
  final int totalStudents;
  final int totalSections;
  final int totalSubjects;
  
  // DepEd Compliance
  final bool isCompliant; // Within DepEd limits
  final String? complianceNotes;
  
  // Additional Responsibilities
  final List<AdditionalResponsibility> additionalResponsibilities;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherLoad({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.schoolYear,
    required this.assignments,
    required this.totalTeachingHours,
    required this.totalPreparationHours,
    required this.totalStudents,
    required this.totalSections,
    required this.totalSubjects,
    required this.isCompliant,
    this.complianceNotes,
    required this.additionalResponsibilities,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total workload hours (teaching + preparation)
  int get totalWorkloadHours => totalTeachingHours + totalPreparationHours;

  /// Check if overloaded (more than DepEd standard)
  bool get isOverloaded {
    // DepEd standard: 6 hours teaching per day (30 hours/week)
    return totalTeachingHours > 30;
  }

  /// Get load percentage (based on 30 hours standard)
  double get loadPercentage => (totalTeachingHours / 30) * 100;

  /// Get average students per section
  double get averageStudentsPerSection {
    if (totalSections == 0) return 0.0;
    return totalStudents / totalSections;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'school_year': schoolYear,
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'total_teaching_hours': totalTeachingHours,
      'total_preparation_hours': totalPreparationHours,
      'total_students': totalStudents,
      'total_sections': totalSections,
      'total_subjects': totalSubjects,
      'is_compliant': isCompliant,
      'compliance_notes': complianceNotes,
      'additional_responsibilities': 
          additionalResponsibilities.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TeacherLoad.fromJson(Map<String, dynamic> json) {
    return TeacherLoad(
      id: json['id'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      schoolYear: json['school_year'],
      assignments: (json['assignments'] as List)
          .map((a) => TeachingAssignment.fromJson(a))
          .toList(),
      totalTeachingHours: json['total_teaching_hours'],
      totalPreparationHours: json['total_preparation_hours'],
      totalStudents: json['total_students'],
      totalSections: json['total_sections'],
      totalSubjects: json['total_subjects'],
      isCompliant: json['is_compliant'],
      complianceNotes: json['compliance_notes'],
      additionalResponsibilities: (json['additional_responsibilities'] as List)
          .map((r) => AdditionalResponsibility.fromJson(r))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Teaching Assignment
class TeachingAssignment {
  final String id;
  final String courseId;
  final String courseName;
  final String subjectCode;
  final int gradeLevel;
  final String sectionId;
  final String sectionName;
  
  // Schedule
  final List<ClassSchedule> schedules;
  final int hoursPerWeek;
  
  // Students
  final int studentCount;
  
  // Room
  final String? roomNumber;
  
  final DateTime createdAt;

  TeachingAssignment({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.subjectCode,
    required this.gradeLevel,
    required this.sectionId,
    required this.sectionName,
    required this.schedules,
    required this.hoursPerWeek,
    required this.studentCount,
    this.roomNumber,
    required this.createdAt,
  });

  /// Get schedule summary
  String get scheduleSummary {
    return schedules.map((s) => '${s.dayOfWeek} ${s.timeSlot}').join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_name': courseName,
      'subject_code': subjectCode,
      'grade_level': gradeLevel,
      'section_id': sectionId,
      'section_name': sectionName,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'hours_per_week': hoursPerWeek,
      'student_count': studentCount,
      'room_number': roomNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TeachingAssignment.fromJson(Map<String, dynamic> json) {
    return TeachingAssignment(
      id: json['id'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      subjectCode: json['subject_code'],
      gradeLevel: json['grade_level'],
      sectionId: json['section_id'],
      sectionName: json['section_name'],
      schedules: (json['schedules'] as List)
          .map((s) => ClassSchedule.fromJson(s))
          .toList(),
      hoursPerWeek: json['hours_per_week'],
      studentCount: json['student_count'],
      roomNumber: json['room_number'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Class Schedule
class ClassSchedule {
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String timeSlot; // e.g., "8:00 AM - 9:00 AM"
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  ClassSchedule({
    required this.dayOfWeek,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      dayOfWeek: json['day_of_week'],
      timeSlot: json['time_slot'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      durationMinutes: json['duration_minutes'],
    );
  }
}

/// Additional Responsibility
class AdditionalResponsibility {
  final String id;
  final String title;
  final String description;
  final String type; // 'adviser', 'coordinator', 'club', 'committee', etc.
  final int estimatedHoursPerWeek;
  final DateTime assignedDate;

  AdditionalResponsibility({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.estimatedHoursPerWeek,
    required this.assignedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'estimated_hours_per_week': estimatedHoursPerWeek,
      'assigned_date': assignedDate.toIso8601String(),
    };
  }

  factory AdditionalResponsibility.fromJson(Map<String, dynamic> json) {
    return AdditionalResponsibility(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      estimatedHoursPerWeek: json['estimated_hours_per_week'],
      assignedDate: DateTime.parse(json['assigned_date']),
    );
  }
}

/// Teacher Load Summary (for reporting)
class TeacherLoadSummary {
  final String schoolYear;
  final int totalTeachers;
  final int compliantTeachers;
  final int overloadedTeachers;
  final double averageTeachingHours;
  final double averageStudentsPerTeacher;
  final int totalSections;
  final Map<int, int> teachersByGradeLevel; // Grade level -> teacher count

  TeacherLoadSummary({
    required this.schoolYear,
    required this.totalTeachers,
    required this.compliantTeachers,
    required this.overloadedTeachers,
    required this.averageTeachingHours,
    required this.averageStudentsPerTeacher,
    required this.totalSections,
    required this.teachersByGradeLevel,
  });

  /// Get compliance rate
  double get complianceRate {
    if (totalTeachers == 0) return 0.0;
    return (compliantTeachers / totalTeachers) * 100;
  }

  /// Get overload rate
  double get overloadRate {
    if (totalTeachers == 0) return 0.0;
    return (overloadedTeachers / totalTeachers) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'school_year': schoolYear,
      'total_teachers': totalTeachers,
      'compliant_teachers': compliantTeachers,
      'overloaded_teachers': overloadedTeachers,
      'average_teaching_hours': averageTeachingHours,
      'average_students_per_teacher': averageStudentsPerTeacher,
      'total_sections': totalSections,
      'teachers_by_grade_level': teachersByGradeLevel,
    };
  }

  factory TeacherLoadSummary.fromJson(Map<String, dynamic> json) {
    return TeacherLoadSummary(
      schoolYear: json['school_year'],
      totalTeachers: json['total_teachers'],
      compliantTeachers: json['compliant_teachers'],
      overloadedTeachers: json['overloaded_teachers'],
      averageTeachingHours: (json['average_teaching_hours'] as num).toDouble(),
      averageStudentsPerTeacher: 
          (json['average_students_per_teacher'] as num).toDouble(),
      totalSections: json['total_sections'],
      teachersByGradeLevel: 
          Map<int, int>.from(json['teachers_by_grade_level']),
    );
  }
}

/// DepEd Teaching Load Standards
class DepEdTeachingLoadStandards {
  // Standard teaching hours per week
  static const int STANDARD_TEACHING_HOURS = 30;
  
  // Maximum teaching hours per week
  static const int MAXIMUM_TEACHING_HOURS = 36;
  
  // Standard preparation hours per week
  static const int STANDARD_PREPARATION_HOURS = 10;
  
  // Maximum students per teacher (ideal)
  static const int IDEAL_STUDENTS_PER_TEACHER = 150;
  
  // Maximum students per class
  static const int MAXIMUM_STUDENTS_PER_CLASS = 45;
  
  // Ideal students per class
  static const int IDEAL_STUDENTS_PER_CLASS = 35;

  /// Check if teaching load is compliant
  static bool isCompliant(int teachingHours, int totalStudents) {
    return teachingHours <= MAXIMUM_TEACHING_HOURS &&
           totalStudents <= IDEAL_STUDENTS_PER_TEACHER;
  }

  /// Get compliance status message
  static String getComplianceMessage(int teachingHours, int totalStudents) {
    if (teachingHours > MAXIMUM_TEACHING_HOURS) {
      return 'Teaching hours exceed DepEd maximum (${MAXIMUM_TEACHING_HOURS} hours/week)';
    }
    if (totalStudents > IDEAL_STUDENTS_PER_TEACHER) {
      return 'Total students exceed ideal load (${IDEAL_STUDENTS_PER_TEACHER} students)';
    }
    if (teachingHours > STANDARD_TEACHING_HOURS) {
      return 'Teaching hours above standard but within limits';
    }
    return 'Teaching load is compliant with DepEd standards';
  }
}
