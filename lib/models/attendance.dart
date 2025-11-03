class Attendance {
  final int id;
  final DateTime createdAt;
  final String studentId;
  final String studentLrn; // Learner Reference Number
  final int courseId;
  final int? sessionId; // Reference to AttendanceSession
  final DateTime date;
  final String status; // 'present', 'late', 'absent'
  final DateTime? timeIn;
  final DateTime? timeOut;
  final bool canScan; // Permission to scan (granted by teacher)
  final String? remarks;

  Attendance({
    required this.id,
    required this.createdAt,
    required this.studentId,
    required this.studentLrn,
    required this.courseId,
    this.sessionId,
    required this.date,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.canScan = false,
    this.remarks,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      studentId: map['student_id'],
      studentLrn: map['student_lrn'] ?? '',
      courseId: map['course_id'],
      sessionId: map['session_id'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      timeIn: map['time_in'] != null ? DateTime.parse(map['time_in']) : null,
      timeOut: map['time_out'] != null ? DateTime.parse(map['time_out']) : null,
      canScan: map['can_scan'] ?? false,
      remarks: map['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'student_id': studentId,
      'student_lrn': studentLrn,
      'course_id': courseId,
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'status': status,
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'can_scan': canScan,
      'remarks': remarks,
    };
  }

  // Helper method to check if student is late
  bool get isLate => status == 'late';
  
  // Helper method to check if student is present
  bool get isPresent => status == 'present';
  
  // Helper method to check if student is absent
  bool get isAbsent => status == 'absent';
}
