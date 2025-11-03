/// Remedial Tracking System
/// Tracks students who need academic intervention and remedial classes
/// Based on DepEd guidelines for students below 75% passing grade

/// Remedial Status
enum RemedialStatus {
  identified,    // Student identified as needing remedial
  planned,       // Intervention plan created
  ongoing,       // Currently undergoing remedial
  completed,     // Remedial completed
  passed,        // Student passed after remedial
  failed,        // Student failed after remedial
  cancelled,     // Remedial cancelled
}

extension RemedialStatusExtension on RemedialStatus {
  String get displayName {
    switch (this) {
      case RemedialStatus.identified:
        return 'Identified';
      case RemedialStatus.planned:
        return 'Planned';
      case RemedialStatus.ongoing:
        return 'Ongoing';
      case RemedialStatus.completed:
        return 'Completed';
      case RemedialStatus.passed:
        return 'Passed';
      case RemedialStatus.failed:
        return 'Failed';
      case RemedialStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case RemedialStatus.identified:
        return 'Student identified as needing remedial support';
      case RemedialStatus.planned:
        return 'Intervention plan has been created';
      case RemedialStatus.ongoing:
        return 'Student is currently undergoing remedial classes';
      case RemedialStatus.completed:
        return 'Remedial classes completed, awaiting assessment';
      case RemedialStatus.passed:
        return 'Student passed after remedial intervention';
      case RemedialStatus.failed:
        return 'Student did not pass after remedial';
      case RemedialStatus.cancelled:
        return 'Remedial was cancelled';
    }
  }
}

/// Remedial Record
class RemedialRecord {
  final String id;
  final String studentId;
  final String studentLrn;
  final String studentName;
  final String courseId;
  final String courseName;
  final String teacherId;
  final String teacherName;
  
  // Academic Information
  final String schoolYear;
  final int quarter;
  final int gradeLevel;
  
  // Grade Information
  final double currentGrade;
  final double targetGrade; // Usually 75%
  final double? finalGrade; // After remedial
  
  // Remedial Details
  final RemedialStatus status;
  final DateTime identifiedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? completionDate;
  
  // Intervention Plan
  final String? interventionPlan;
  final List<String>? learningCompetencies; // Specific competencies to address
  final String? teachingStrategy;
  final String? materials;
  
  // Progress Tracking
  final List<RemedialSession> sessions;
  final String? progressNotes;
  
  // Parent Notification
  final bool parentNotified;
  final DateTime? parentNotificationDate;
  final String? parentResponse;
  
  // Assessment
  final double? preTestScore;
  final double? postTestScore;
  final String? assessmentRemarks;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  RemedialRecord({
    required this.id,
    required this.studentId,
    required this.studentLrn,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.teacherId,
    required this.teacherName,
    required this.schoolYear,
    required this.quarter,
    required this.gradeLevel,
    required this.currentGrade,
    required this.targetGrade,
    this.finalGrade,
    required this.status,
    required this.identifiedDate,
    this.startDate,
    this.endDate,
    this.completionDate,
    this.interventionPlan,
    this.learningCompetencies,
    this.teachingStrategy,
    this.materials,
    required this.sessions,
    this.progressNotes,
    required this.parentNotified,
    this.parentNotificationDate,
    this.parentResponse,
    this.preTestScore,
    this.postTestScore,
    this.assessmentRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if student passed remedial
  bool get passedRemedial => finalGrade != null && finalGrade! >= targetGrade;

  /// Calculate improvement
  double? get improvement => 
      finalGrade != null ? finalGrade! - currentGrade : null;

  /// Get grade gap
  double get gradeGap => targetGrade - currentGrade;

  /// Check if remedial is overdue
  bool get isOverdue {
    if (endDate == null || status == RemedialStatus.completed) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get duration in days
  int? get durationDays {
    if (startDate == null || completionDate == null) return null;
    return completionDate!.difference(startDate!).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'student_name': studentName,
      'course_id': courseId,
      'course_name': courseName,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'school_year': schoolYear,
      'quarter': quarter,
      'grade_level': gradeLevel,
      'current_grade': currentGrade,
      'target_grade': targetGrade,
      'final_grade': finalGrade,
      'status': status.toString().split('.').last,
      'identified_date': identifiedDate.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'intervention_plan': interventionPlan,
      'learning_competencies': learningCompetencies,
      'teaching_strategy': teachingStrategy,
      'materials': materials,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'progress_notes': progressNotes,
      'parent_notified': parentNotified,
      'parent_notification_date': parentNotificationDate?.toIso8601String(),
      'parent_response': parentResponse,
      'pre_test_score': preTestScore,
      'post_test_score': postTestScore,
      'assessment_remarks': assessmentRemarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RemedialRecord.fromJson(Map<String, dynamic> json) {
    return RemedialRecord(
      id: json['id'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      studentName: json['student_name'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      schoolYear: json['school_year'],
      quarter: json['quarter'],
      gradeLevel: json['grade_level'],
      currentGrade: (json['current_grade'] as num).toDouble(),
      targetGrade: (json['target_grade'] as num).toDouble(),
      finalGrade: json['final_grade']?.toDouble(),
      status: RemedialStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      identifiedDate: DateTime.parse(json['identified_date']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      completionDate: json['completion_date'] != null
          ? DateTime.parse(json['completion_date'])
          : null,
      interventionPlan: json['intervention_plan'],
      learningCompetencies: json['learning_competencies'] != null
          ? List<String>.from(json['learning_competencies'])
          : null,
      teachingStrategy: json['teaching_strategy'],
      materials: json['materials'],
      sessions: (json['sessions'] as List)
          .map((s) => RemedialSession.fromJson(s))
          .toList(),
      progressNotes: json['progress_notes'],
      parentNotified: json['parent_notified'],
      parentNotificationDate: json['parent_notification_date'] != null
          ? DateTime.parse(json['parent_notification_date'])
          : null,
      parentResponse: json['parent_response'],
      preTestScore: json['pre_test_score']?.toDouble(),
      postTestScore: json['post_test_score']?.toDouble(),
      assessmentRemarks: json['assessment_remarks'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  RemedialRecord copyWith({
    RemedialStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? completionDate,
    double? finalGrade,
    String? progressNotes,
    bool? parentNotified,
    DateTime? parentNotificationDate,
  }) {
    return RemedialRecord(
      id: id,
      studentId: studentId,
      studentLrn: studentLrn,
      studentName: studentName,
      courseId: courseId,
      courseName: courseName,
      teacherId: teacherId,
      teacherName: teacherName,
      schoolYear: schoolYear,
      quarter: quarter,
      gradeLevel: gradeLevel,
      currentGrade: currentGrade,
      targetGrade: targetGrade,
      finalGrade: finalGrade ?? this.finalGrade,
      status: status ?? this.status,
      identifiedDate: identifiedDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completionDate: completionDate ?? this.completionDate,
      interventionPlan: interventionPlan,
      learningCompetencies: learningCompetencies,
      teachingStrategy: teachingStrategy,
      materials: materials,
      sessions: sessions,
      progressNotes: progressNotes ?? this.progressNotes,
      parentNotified: parentNotified ?? this.parentNotified,
      parentNotificationDate: parentNotificationDate ?? this.parentNotificationDate,
      parentResponse: parentResponse,
      preTestScore: preTestScore,
      postTestScore: postTestScore,
      assessmentRemarks: assessmentRemarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Remedial Session
class RemedialSession {
  final String id;
  final String remedialRecordId;
  final DateTime date;
  final int sessionNumber;
  final String topic;
  final String? activities;
  final String? materialsUsed;
  final String? studentPerformance;
  final String? teacherObservations;
  final bool studentAttended;
  final DateTime createdAt;

  RemedialSession({
    required this.id,
    required this.remedialRecordId,
    required this.date,
    required this.sessionNumber,
    required this.topic,
    this.activities,
    this.materialsUsed,
    this.studentPerformance,
    this.teacherObservations,
    required this.studentAttended,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remedial_record_id': remedialRecordId,
      'date': date.toIso8601String(),
      'session_number': sessionNumber,
      'topic': topic,
      'activities': activities,
      'materials_used': materialsUsed,
      'student_performance': studentPerformance,
      'teacher_observations': teacherObservations,
      'student_attended': studentAttended,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RemedialSession.fromJson(Map<String, dynamic> json) {
    return RemedialSession(
      id: json['id'],
      remedialRecordId: json['remedial_record_id'],
      date: DateTime.parse(json['date']),
      sessionNumber: json['session_number'],
      topic: json['topic'],
      activities: json['activities'],
      materialsUsed: json['materials_used'],
      studentPerformance: json['student_performance'],
      teacherObservations: json['teacher_observations'],
      studentAttended: json['student_attended'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Remedial Summary Statistics
class RemedialSummary {
  final String schoolYear;
  final int quarter;
  final int totalStudents;
  final int studentsNeedingRemedial;
  final int studentsInRemedial;
  final int studentsCompleted;
  final int studentsPassed;
  final int studentsFailed;
  final double passRate;
  final double averageImprovement;

  RemedialSummary({
    required this.schoolYear,
    required this.quarter,
    required this.totalStudents,
    required this.studentsNeedingRemedial,
    required this.studentsInRemedial,
    required this.studentsCompleted,
    required this.studentsPassed,
    required this.studentsFailed,
    required this.passRate,
    required this.averageImprovement,
  });

  Map<String, dynamic> toJson() {
    return {
      'school_year': schoolYear,
      'quarter': quarter,
      'total_students': totalStudents,
      'students_needing_remedial': studentsNeedingRemedial,
      'students_in_remedial': studentsInRemedial,
      'students_completed': studentsCompleted,
      'students_passed': studentsPassed,
      'students_failed': studentsFailed,
      'pass_rate': passRate,
      'average_improvement': averageImprovement,
    };
  }

  factory RemedialSummary.fromJson(Map<String, dynamic> json) {
    return RemedialSummary(
      schoolYear: json['school_year'],
      quarter: json['quarter'],
      totalStudents: json['total_students'],
      studentsNeedingRemedial: json['students_needing_remedial'],
      studentsInRemedial: json['students_in_remedial'],
      studentsCompleted: json['students_completed'],
      studentsPassed: json['students_passed'],
      studentsFailed: json['students_failed'],
      passRate: (json['pass_rate'] as num).toDouble(),
      averageImprovement: (json['average_improvement'] as num).toDouble(),
    );
  }
}
