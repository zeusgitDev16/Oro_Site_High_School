// Monthly attendance summary for SF9.
// Represents totals per student, per month, per school year,
// backed by the `attendance_monthly_summary` table.

class AttendanceMonthlySummary {
  final String id;
  final String studentId;
  final String schoolYear;
  final int month; // 1-12

  final int schoolDays;
  final int daysPresent;
  final int daysAbsent;

  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceMonthlySummary({
    required this.id,
    required this.studentId,
    required this.schoolYear,
    required this.month,
    required this.schoolDays,
    required this.daysPresent,
    required this.daysAbsent,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Attendance rate as a percentage (0-100).
  double get attendanceRate {
    if (schoolDays <= 0) return 0.0;
    return (daysPresent / schoolDays) * 100.0;
  }

  /// Number of school days that have no recorded present/absent mark.
  int get daysNotRecorded => schoolDays - (daysPresent + daysAbsent);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_year': schoolYear,
      'month': month,
      'school_days': schoolDays,
      'days_present': daysPresent,
      'days_absent': daysAbsent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceMonthlySummary.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthlySummary(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id'] as String,
      schoolYear: json['school_year'] as String,
      month: json['month'] as int,
      schoolDays: json['school_days'] as int,
      daysPresent: json['days_present'] as int,
      daysAbsent: json['days_absent'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
