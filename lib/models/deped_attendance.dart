/// DepEd-Compliant Attendance Model
/// Uses official DepEd attendance codes for SF2 (School Form 2) compliance
/// 
/// Official DepEd Attendance Codes:
/// P  - Present
/// A  - Absent
/// L  - Late
/// E  - Excused
/// S  - Sick
/// SL - Sick Leave (with medical certificate)
/// OL - Official Leave
/// UA - Unexcused Absence

enum DepEdAttendanceCode {
  P,  // Present
  A,  // Absent
  L,  // Late
  E,  // Excused
  S,  // Sick
  SL, // Sick Leave (with medical certificate)
  OL, // Official Leave
  UA, // Unexcused Absence
}

extension DepEdAttendanceCodeExtension on DepEdAttendanceCode {
  String get code {
    switch (this) {
      case DepEdAttendanceCode.P:
        return 'P';
      case DepEdAttendanceCode.A:
        return 'A';
      case DepEdAttendanceCode.L:
        return 'L';
      case DepEdAttendanceCode.E:
        return 'E';
      case DepEdAttendanceCode.S:
        return 'S';
      case DepEdAttendanceCode.SL:
        return 'SL';
      case DepEdAttendanceCode.OL:
        return 'OL';
      case DepEdAttendanceCode.UA:
        return 'UA';
    }
  }

  String get description {
    switch (this) {
      case DepEdAttendanceCode.P:
        return 'Present';
      case DepEdAttendanceCode.A:
        return 'Absent';
      case DepEdAttendanceCode.L:
        return 'Late';
      case DepEdAttendanceCode.E:
        return 'Excused';
      case DepEdAttendanceCode.S:
        return 'Sick';
      case DepEdAttendanceCode.SL:
        return 'Sick Leave (with certificate)';
      case DepEdAttendanceCode.OL:
        return 'Official Leave';
      case DepEdAttendanceCode.UA:
        return 'Unexcused Absence';
    }
  }

  bool get countsAsPresent => this == DepEdAttendanceCode.P;
  bool get countsAsAbsent => [
        DepEdAttendanceCode.A,
        DepEdAttendanceCode.UA,
      ].contains(this);
  bool get countsAsExcused => [
        DepEdAttendanceCode.E,
        DepEdAttendanceCode.S,
        DepEdAttendanceCode.SL,
        DepEdAttendanceCode.OL,
      ].contains(this);
}

class DepEdAttendance {
  final String id;
  final String studentId;
  final String studentName;
  final String studentLrn; // Learner Reference Number (required)
  final String courseId;
  final String courseName;
  final String? sessionId;
  final DateTime date;
  final DepEdAttendanceCode status;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? remarks;
  final String? supportingDocument; // For SL, OL (e.g., medical cert, excuse letter)
  final String recordedBy; // Teacher ID
  final String recordedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepEdAttendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentLrn,
    required this.courseId,
    required this.courseName,
    this.sessionId,
    required this.date,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.remarks,
    this.supportingDocument,
    required this.recordedBy,
    required this.recordedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper getters
  bool get isPresent => status.countsAsPresent;
  bool get isAbsent => status.countsAsAbsent;
  bool get isLate => status == DepEdAttendanceCode.L;
  bool get isExcused => status.countsAsExcused;
  bool get requiresDocument => [
        DepEdAttendanceCode.SL,
        DepEdAttendanceCode.OL,
      ].contains(status);

  /// Get status code for SF2 form
  String get sf2Code => status.code;

  /// Get status description
  String get statusDescription => status.description;

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_lrn': studentLrn,
      'course_id': courseId,
      'course_name': courseName,
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'status': status.code,
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'remarks': remarks,
      'supporting_document': supportingDocument,
      'recorded_by': recordedBy,
      'recorded_by_name': recordedByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DepEdAttendance.fromJson(Map<String, dynamic> json) {
    return DepEdAttendance(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentLrn: json['student_lrn'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      sessionId: json['session_id'],
      date: DateTime.parse(json['date']),
      status: _parseAttendanceCode(json['status']),
      timeIn: json['time_in'] != null ? DateTime.parse(json['time_in']) : null,
      timeOut: json['time_out'] != null ? DateTime.parse(json['time_out']) : null,
      remarks: json['remarks'],
      supportingDocument: json['supporting_document'],
      recordedBy: json['recorded_by'],
      recordedByName: json['recorded_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Parse attendance code from string
  static DepEdAttendanceCode _parseAttendanceCode(String code) {
    switch (code.toUpperCase()) {
      case 'P':
        return DepEdAttendanceCode.P;
      case 'A':
        return DepEdAttendanceCode.A;
      case 'L':
        return DepEdAttendanceCode.L;
      case 'E':
        return DepEdAttendanceCode.E;
      case 'S':
        return DepEdAttendanceCode.S;
      case 'SL':
        return DepEdAttendanceCode.SL;
      case 'OL':
        return DepEdAttendanceCode.OL;
      case 'UA':
        return DepEdAttendanceCode.UA;
      default:
        return DepEdAttendanceCode.A; // Default to absent
    }
  }

  /// Copy with updated fields
  DepEdAttendance copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentLrn,
    String? courseId,
    String? courseName,
    String? sessionId,
    DateTime? date,
    DepEdAttendanceCode? status,
    DateTime? timeIn,
    DateTime? timeOut,
    String? remarks,
    String? supportingDocument,
    String? recordedBy,
    String? recordedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepEdAttendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentLrn: studentLrn ?? this.studentLrn,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      status: status ?? this.status,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      remarks: remarks ?? this.remarks,
      supportingDocument: supportingDocument ?? this.supportingDocument,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedByName: recordedByName ?? this.recordedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Attendance Summary for reporting
class AttendanceSummary {
  final String studentId;
  final String studentLrn;
  final String period; // e.g., "Quarter 1", "January 2024"
  
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  
  final double attendanceRate; // Percentage
  final int consecutiveAbsences;
  final bool hasAttendanceIssue; // True if < 90% or 3+ consecutive absences

  AttendanceSummary({
    required this.studentId,
    required this.studentLrn,
    required this.period,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.attendanceRate,
    required this.consecutiveAbsences,
    required this.hasAttendanceIssue,
  });

  /// Calculate attendance rate
  static double calculateRate(int presentDays, int totalDays) {
    if (totalDays == 0) return 0.0;
    return (presentDays / totalDays) * 100;
  }

  /// Check if student has attendance issue
  static bool hasIssue(double rate, int consecutive) {
    return rate < 90.0 || consecutive >= 3;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_lrn': studentLrn,
      'period': period,
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'excused_days': excusedDays,
      'attendance_rate': attendanceRate,
      'consecutive_absences': consecutiveAbsences,
      'has_attendance_issue': hasAttendanceIssue,
    };
  }

  /// Create from JSON
  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      period: json['period'],
      totalDays: json['total_days'],
      presentDays: json['present_days'],
      absentDays: json['absent_days'],
      lateDays: json['late_days'],
      excusedDays: json['excused_days'],
      attendanceRate: (json['attendance_rate'] as num).toDouble(),
      consecutiveAbsences: json['consecutive_absences'],
      hasAttendanceIssue: json['has_attendance_issue'],
    );
  }
}
