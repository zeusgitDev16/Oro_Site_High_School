/// School Year Management
/// Manages academic year, quarters, and important dates
/// Based on DepEd school calendar

/// School Year Status
enum SchoolYearStatus {
  upcoming,   // Not yet started
  active,     // Currently active
  completed,  // Finished
  archived,   // Archived for historical records
}

extension SchoolYearStatusExtension on SchoolYearStatus {
  String get displayName {
    switch (this) {
      case SchoolYearStatus.upcoming:
        return 'Upcoming';
      case SchoolYearStatus.active:
        return 'Active';
      case SchoolYearStatus.completed:
        return 'Completed';
      case SchoolYearStatus.archived:
        return 'Archived';
    }
  }
}

/// Quarter Status
enum QuarterStatus {
  upcoming,
  active,
  completed,
}

/// School Year Model
class SchoolYear {
  final String id;
  final String name; // e.g., "2023-2024"
  final DateTime startDate;
  final DateTime endDate;
  final SchoolYearStatus status;
  
  // Quarter Information
  final List<Quarter> quarters;
  
  // Important Dates
  final DateTime? enrollmentStartDate;
  final DateTime? enrollmentEndDate;
  final DateTime? classesStartDate;
  final DateTime? classesEndDate;
  final DateTime? graduationDate;
  
  // Settings
  final int totalSchoolDays;
  final bool isCurrentYear;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.quarters,
    this.enrollmentStartDate,
    this.enrollmentEndDate,
    this.classesStartDate,
    this.classesEndDate,
    this.graduationDate,
    required this.totalSchoolDays,
    required this.isCurrentYear,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get current quarter
  Quarter? get currentQuarter {
    final now = DateTime.now();
    return quarters.firstWhere(
      (q) => now.isAfter(q.startDate) && now.isBefore(q.endDate),
      orElse: () => quarters.first,
    );
  }

  /// Get active quarter
  Quarter? get activeQuarter {
    return quarters.firstWhere(
      (q) => q.status == QuarterStatus.active,
      orElse: () => quarters.first,
    );
  }

  /// Check if school year is active
  bool get isActive => status == SchoolYearStatus.active;

  /// Get progress percentage
  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;
    
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    
    return (elapsedDays / totalDays) * 100;
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'quarters': quarters.map((q) => q.toJson()).toList(),
      'enrollment_start_date': enrollmentStartDate?.toIso8601String(),
      'enrollment_end_date': enrollmentEndDate?.toIso8601String(),
      'classes_start_date': classesStartDate?.toIso8601String(),
      'classes_end_date': classesEndDate?.toIso8601String(),
      'graduation_date': graduationDate?.toIso8601String(),
      'total_school_days': totalSchoolDays,
      'is_current_year': isCurrentYear,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SchoolYear.fromJson(Map<String, dynamic> json) {
    return SchoolYear(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: SchoolYearStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      quarters: (json['quarters'] as List)
          .map((q) => Quarter.fromJson(q))
          .toList(),
      enrollmentStartDate: json['enrollment_start_date'] != null
          ? DateTime.parse(json['enrollment_start_date'])
          : null,
      enrollmentEndDate: json['enrollment_end_date'] != null
          ? DateTime.parse(json['enrollment_end_date'])
          : null,
      classesStartDate: json['classes_start_date'] != null
          ? DateTime.parse(json['classes_start_date'])
          : null,
      classesEndDate: json['classes_end_date'] != null
          ? DateTime.parse(json['classes_end_date'])
          : null,
      graduationDate: json['graduation_date'] != null
          ? DateTime.parse(json['graduation_date'])
          : null,
      totalSchoolDays: json['total_school_days'],
      isCurrentYear: json['is_current_year'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Quarter Model
class Quarter {
  final String id;
  final String schoolYearId;
  final int quarterNumber; // 1-4
  final String name; // e.g., "First Quarter"
  final DateTime startDate;
  final DateTime endDate;
  final QuarterStatus status;
  
  // Important Dates
  final DateTime? examStartDate;
  final DateTime? examEndDate;
  final DateTime? gradeSubmissionDeadline;
  final DateTime? cardDistributionDate;
  
  // Settings
  final int totalSchoolDays;
  final int minimumAttendanceDays;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Quarter({
    required this.id,
    required this.schoolYearId,
    required this.quarterNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.examStartDate,
    this.examEndDate,
    this.gradeSubmissionDeadline,
    this.cardDistributionDate,
    required this.totalSchoolDays,
    required this.minimumAttendanceDays,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if quarter is active
  bool get isActive => status == QuarterStatus.active;

  /// Check if quarter is completed
  bool get isCompleted => status == QuarterStatus.completed;

  /// Get progress percentage
  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;
    
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    
    return (elapsedDays / totalDays) * 100;
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Check if in exam period
  bool get isExamPeriod {
    if (examStartDate == null || examEndDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(examStartDate!) && now.isBefore(examEndDate!);
  }

  /// Check if grade submission is overdue
  bool get isGradeSubmissionOverdue {
    if (gradeSubmissionDeadline == null) return false;
    return DateTime.now().isAfter(gradeSubmissionDeadline!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_year_id': schoolYearId,
      'quarter_number': quarterNumber,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'exam_start_date': examStartDate?.toIso8601String(),
      'exam_end_date': examEndDate?.toIso8601String(),
      'grade_submission_deadline': gradeSubmissionDeadline?.toIso8601String(),
      'card_distribution_date': cardDistributionDate?.toIso8601String(),
      'total_school_days': totalSchoolDays,
      'minimum_attendance_days': minimumAttendanceDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quarter.fromJson(Map<String, dynamic> json) {
    return Quarter(
      id: json['id'],
      schoolYearId: json['school_year_id'],
      quarterNumber: json['quarter_number'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: QuarterStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      examStartDate: json['exam_start_date'] != null
          ? DateTime.parse(json['exam_start_date'])
          : null,
      examEndDate: json['exam_end_date'] != null
          ? DateTime.parse(json['exam_end_date'])
          : null,
      gradeSubmissionDeadline: json['grade_submission_deadline'] != null
          ? DateTime.parse(json['grade_submission_deadline'])
          : null,
      cardDistributionDate: json['card_distribution_date'] != null
          ? DateTime.parse(json['card_distribution_date'])
          : null,
      totalSchoolDays: json['total_school_days'],
      minimumAttendanceDays: json['minimum_attendance_days'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Academic Calendar Event
class AcademicCalendarEvent {
  final String id;
  final String schoolYearId;
  final String? quarterId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String eventType; // 'holiday', 'exam', 'activity', 'deadline', etc.
  final bool isHoliday;
  final bool affectsAttendance;
  final DateTime createdAt;

  AcademicCalendarEvent({
    required this.id,
    required this.schoolYearId,
    this.quarterId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.eventType,
    required this.isHoliday,
    required this.affectsAttendance,
    required this.createdAt,
  });

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
           startDate.month == now.month &&
           startDate.day == now.day;
  }

  /// Check if event is upcoming (within 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final diff = startDate.difference(now).inDays;
    return diff >= 0 && diff <= 7;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_year_id': schoolYearId,
      'quarter_id': quarterId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'event_type': eventType,
      'is_holiday': isHoliday,
      'affects_attendance': affectsAttendance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AcademicCalendarEvent.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarEvent(
      id: json['id'],
      schoolYearId: json['school_year_id'],
      quarterId: json['quarter_id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      eventType: json['event_type'],
      isHoliday: json['is_holiday'],
      affectsAttendance: json['affects_attendance'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
