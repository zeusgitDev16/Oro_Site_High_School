/// DepEd-Compliant Quarterly Grade Model
/// Based on DepEd Order No. 8, s. 2015
/// 
/// Grading Formula:
/// - Written Work: 30%
/// - Performance Task: 50%
/// - Quarterly Assessment: 20%
/// 
/// Final Grade = Average of 4 Quarters

class QuarterlyGrade {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final int quarter; // 1-4
  final String schoolYear; // e.g., "2023-2024"
  
  // DepEd Components (0-100 scale)
  final double writtenWork;      // 30% weight
  final double performanceTask;  // 50% weight
  final double quarterlyAssessment; // 20% weight
  
  // Calculated fields
  final double quarterGrade; // Weighted average
  final String transmutedGrade; // For reporting (e.g., "92")
  
  // Metadata
  final String teacherId;
  final String teacherName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String status; // 'draft', 'submitted', 'approved'
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuarterlyGrade({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.quarter,
    required this.schoolYear,
    required this.writtenWork,
    required this.performanceTask,
    required this.quarterlyAssessment,
    required this.quarterGrade,
    required this.transmutedGrade,
    required this.teacherId,
    required this.teacherName,
    this.submittedAt,
    this.approvedAt,
    this.status = 'draft',
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate quarter grade using DepEd formula
  static double calculateQuarterGrade({
    required double writtenWork,
    required double performanceTask,
    required double quarterlyAssessment,
  }) {
    return (writtenWork * 0.30) + 
           (performanceTask * 0.50) + 
           (quarterlyAssessment * 0.20);
  }

  /// Calculate final grade (average of 4 quarters)
  static double calculateFinalGrade(List<double> quarterGrades) {
    if (quarterGrades.isEmpty) return 0.0;
    return quarterGrades.reduce((a, b) => a + b) / quarterGrades.length;
  }

  /// Get grade descriptor based on DepEd scale
  static String getGradeDescriptor(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  /// Check if student passed (75% is passing)
  bool get isPassing => quarterGrade >= 75.0;

  /// Get grade remarks
  String get gradeRemarks => getGradeDescriptor(quarterGrade);

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'course_id': courseId,
      'course_name': courseName,
      'quarter': quarter,
      'school_year': schoolYear,
      'written_work': writtenWork,
      'performance_task': performanceTask,
      'quarterly_assessment': quarterlyAssessment,
      'quarter_grade': quarterGrade,
      'transmuted_grade': transmutedGrade,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QuarterlyGrade.fromJson(Map<String, dynamic> json) {
    return QuarterlyGrade(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      quarter: json['quarter'],
      schoolYear: json['school_year'],
      writtenWork: (json['written_work'] as num).toDouble(),
      performanceTask: (json['performance_task'] as num).toDouble(),
      quarterlyAssessment: (json['quarterly_assessment'] as num).toDouble(),
      quarterGrade: (json['quarter_grade'] as num).toDouble(),
      transmutedGrade: json['transmuted_grade'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : null,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      status: json['status'] ?? 'draft',
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Create a copy with updated fields
  QuarterlyGrade copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    int? quarter,
    String? schoolYear,
    double? writtenWork,
    double? performanceTask,
    double? quarterlyAssessment,
    double? quarterGrade,
    String? transmutedGrade,
    String? teacherId,
    String? teacherName,
    DateTime? submittedAt,
    DateTime? approvedAt,
    String? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuarterlyGrade(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      quarter: quarter ?? this.quarter,
      schoolYear: schoolYear ?? this.schoolYear,
      writtenWork: writtenWork ?? this.writtenWork,
      performanceTask: performanceTask ?? this.performanceTask,
      quarterlyAssessment: quarterlyAssessment ?? this.quarterlyAssessment,
      quarterGrade: quarterGrade ?? this.quarterGrade,
      transmutedGrade: transmutedGrade ?? this.transmutedGrade,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Final Grade Model (Average of 4 quarters)
class FinalGrade {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String schoolYear;
  
  // Quarter grades
  final double? quarter1;
  final double? quarter2;
  final double? quarter3;
  final double? quarter4;
  
  // Final grade (average of 4 quarters)
  final double finalGrade;
  final String transmutedGrade;
  final String gradeRemarks;
  final bool isPassing;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  FinalGrade({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.schoolYear,
    this.quarter1,
    this.quarter2,
    this.quarter3,
    this.quarter4,
    required this.finalGrade,
    required this.transmutedGrade,
    required this.gradeRemarks,
    required this.isPassing,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate final grade from quarters
  static double calculateFinal(
    double? q1,
    double? q2,
    double? q3,
    double? q4,
  ) {
    final grades = [q1, q2, q3, q4].whereType<double>().toList();
    if (grades.isEmpty) return 0.0;
    return grades.reduce((a, b) => a + b) / grades.length;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'course_id': courseId,
      'course_name': courseName,
      'school_year': schoolYear,
      'quarter_1': quarter1,
      'quarter_2': quarter2,
      'quarter_3': quarter3,
      'quarter_4': quarter4,
      'final_grade': finalGrade,
      'transmuted_grade': transmutedGrade,
      'grade_remarks': gradeRemarks,
      'is_passing': isPassing,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FinalGrade.fromJson(Map<String, dynamic> json) {
    return FinalGrade(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      schoolYear: json['school_year'],
      quarter1: json['quarter_1']?.toDouble(),
      quarter2: json['quarter_2']?.toDouble(),
      quarter3: json['quarter_3']?.toDouble(),
      quarter4: json['quarter_4']?.toDouble(),
      finalGrade: (json['final_grade'] as num).toDouble(),
      transmutedGrade: json['transmuted_grade'],
      gradeRemarks: json['grade_remarks'],
      isPassing: json['is_passing'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
