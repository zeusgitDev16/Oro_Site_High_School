class AttendanceSession {
  final int id;
  final DateTime createdAt;
  final String teacherId;
  final String teacherName;
  final int courseId;
  final String courseName;
  final int? sectionId;
  final String? sectionName;
  final String dayOfWeek; // 'Monday', 'Tuesday', etc.
  final DateTime scheduleStart; // e.g., 7:00 AM
  final DateTime scheduleEnd; // e.g., 9:00 AM
  final int scanTimeLimitMinutes; // e.g., 15 minutes
  final DateTime? scanDeadline; // Calculated: scheduleStart + scanTimeLimitMinutes
  final String status; // 'active', 'expired', 'completed', 'cancelled'
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalStudents;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final String? remarks;

  AttendanceSession({
    required this.id,
    required this.createdAt,
    required this.teacherId,
    required this.teacherName,
    required this.courseId,
    required this.courseName,
    this.sectionId,
    this.sectionName,
    required this.dayOfWeek,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.scanTimeLimitMinutes,
    this.scanDeadline,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.absentCount = 0,
    this.remarks,
  });

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      teacherId: map['teacher_id'],
      teacherName: map['teacher_name'] ?? '',
      courseId: map['course_id'],
      courseName: map['course_name'] ?? '',
      sectionId: map['section_id'],
      sectionName: map['section_name'],
      dayOfWeek: map['day_of_week'],
      scheduleStart: DateTime.parse(map['schedule_start']),
      scheduleEnd: DateTime.parse(map['schedule_end']),
      scanTimeLimitMinutes: map['scan_time_limit_minutes'],
      scanDeadline: map['scan_deadline'] != null 
          ? DateTime.parse(map['scan_deadline']) 
          : null,
      status: map['status'],
      startedAt: map['started_at'] != null 
          ? DateTime.parse(map['started_at']) 
          : null,
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : null,
      totalStudents: map['total_students'] ?? 0,
      presentCount: map['present_count'] ?? 0,
      lateCount: map['late_count'] ?? 0,
      absentCount: map['absent_count'] ?? 0,
      remarks: map['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'course_id': courseId,
      'course_name': courseName,
      'section_id': sectionId,
      'section_name': sectionName,
      'day_of_week': dayOfWeek,
      'schedule_start': scheduleStart.toIso8601String(),
      'schedule_end': scheduleEnd.toIso8601String(),
      'scan_time_limit_minutes': scanTimeLimitMinutes,
      'scan_deadline': scanDeadline?.toIso8601String(),
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_students': totalStudents,
      'present_count': presentCount,
      'late_count': lateCount,
      'absent_count': absentCount,
      'remarks': remarks,
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Calculate attendance rate
  double get attendanceRate {
    if (totalStudents == 0) return 0.0;
    return (presentCount + lateCount) / totalStudents * 100;
  }

  // Check if scan deadline has passed
  bool get isScanDeadlinePassed {
    if (scanDeadline == null) return false;
    return DateTime.now().isAfter(scanDeadline!);
  }

  // Get remaining scan time in minutes
  int get remainingScanMinutes {
    if (scanDeadline == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(scanDeadline!)) return 0;
    return scanDeadline!.difference(now).inMinutes;
  }
}
