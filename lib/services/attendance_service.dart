import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../models/attendance_session.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;

  // ==================== ATTENDANCE SESSION METHODS ====================

  /// Create a new attendance session
  Future<AttendanceSession> createAttendanceSession({
    required String teacherId,
    required String teacherName,
    required int courseId,
    required String courseName,
    int? sectionId,
    String? sectionName,
    required String dayOfWeek,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
    required int scanTimeLimitMinutes,
  }) async {
    // Calculate scan deadline
    final scanDeadline = scheduleStart.add(Duration(minutes: scanTimeLimitMinutes));

    final response = await _supabase.from('attendance_sessions').insert({
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
      'scan_deadline': scanDeadline.toIso8601String(),
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
    }).select().single();

    return AttendanceSession.fromMap(response);
  }

  /// Get active attendance sessions
  Future<List<AttendanceSession>> getActiveSessions({String? teacherId}) async {
    var query = _supabase
        .from('attendance_sessions')
        .select()
        .eq('status', 'active');

    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }

    final response = await query;
    final sessions = (response as List).map((item) => AttendanceSession.fromMap(item)).toList();
    
    // Sort in Dart instead of database
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  /// Get all attendance sessions with filters
  Future<List<AttendanceSession>> getAttendanceSessions({
    String? teacherId,
    int? courseId,
    int? sectionId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('attendance_sessions')
        .select();

    if (teacherId != null) query = query.eq('teacher_id', teacherId);
    if (courseId != null) query = query.eq('course_id', courseId);
    if (sectionId != null) query = query.eq('section_id', sectionId);
    if (status != null) query = query.eq('status', status);
    if (startDate != null) query = query.gte('created_at', startDate.toIso8601String());
    if (endDate != null) query = query.lte('created_at', endDate.toIso8601String());

    final response = await query;
    final sessions = (response as List).map((item) => AttendanceSession.fromMap(item)).toList();
    
    // Sort in Dart instead of database
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  /// Get a specific attendance session by ID
  Future<AttendanceSession?> getAttendanceSession(int sessionId) async {
    final response = await _supabase
        .from('attendance_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return AttendanceSession.fromMap(response);
  }

  /// Update attendance session status
  Future<void> updateSessionStatus(int sessionId, String status) async {
    final updateData = {
      'status': status,
    };

    if (status == 'completed') {
      updateData['completed_at'] = DateTime.now().toIso8601String();
    }

    await _supabase
        .from('attendance_sessions')
        .update(updateData)
        .eq('id', sessionId);
  }

  /// Auto-expire sessions that have passed their scan deadline
  Future<void> autoExpireSessions() async {
    final now = DateTime.now();
    await _supabase
        .from('attendance_sessions')
        .update({'status': 'expired'})
        .eq('status', 'active')
        .lt('scan_deadline', now.toIso8601String());
  }

  // ==================== ATTENDANCE RECORD METHODS ====================

  /// Record attendance (from scanner or manual entry)
  Future<Attendance> recordAttendance({
    required String studentId,
    required String studentLrn,
    required int courseId,
    int? sessionId,
    required DateTime date,
    DateTime? timeIn,
    String? remarks,
  }) async {
    // Determine status based on time
    String status = 'present';
    
    if (sessionId != null) {
      final session = await getAttendanceSession(sessionId);
      if (session != null && timeIn != null) {
        // Check if student is late
        if (session.scanDeadline != null && timeIn.isAfter(session.scanDeadline!)) {
          status = 'late';
        }
      }
    }

    final response = await _supabase.from('attendance').insert({
      'student_id': studentId,
      'student_lrn': studentLrn,
      'course_id': courseId,
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'status': status,
      'time_in': timeIn?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'remarks': remarks,
    }).select().single();

    // Update session counts
    if (sessionId != null) {
      await _updateSessionCounts(sessionId);
    }

    return Attendance.fromMap(response);
  }

  /// Get attendance records for a student
  Future<List<Attendance>> getAttendanceForStudent(
    String studentId, 
    int courseId,
  ) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .eq('course_id', courseId);
    
    final records = (response as List).map((item) => Attendance.fromMap(item)).toList();
    
    // Sort in Dart instead of database
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Get attendance records for a session
  Future<List<Attendance>> getAttendanceForSession(int sessionId) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('session_id', sessionId);
    
    final records = (response as List).map((item) => Attendance.fromMap(item)).toList();
    
    // Sort in Dart instead of database
    records.sort((a, b) {
      if (a.timeIn == null && b.timeIn == null) return 0;
      if (a.timeIn == null) return 1;
      if (b.timeIn == null) return -1;
      return a.timeIn!.compareTo(b.timeIn!);
    });
    return records;
  }

  /// Get attendance records with filters
  Future<List<Attendance>> getAttendanceRecords({
    String? studentId,
    int? courseId,
    int? sessionId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    var query = _supabase
        .from('attendance')
        .select();

    if (studentId != null) query = query.eq('student_id', studentId);
    if (courseId != null) query = query.eq('course_id', courseId);
    if (sessionId != null) query = query.eq('session_id', sessionId);
    if (status != null) query = query.eq('status', status);
    if (startDate != null) query = query.gte('date', startDate.toIso8601String());
    if (endDate != null) query = query.lte('date', endDate.toIso8601String());

    final response = await query;
    final records = (response as List).map((item) => Attendance.fromMap(item)).toList();
    
    // Sort in Dart instead of database
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Mark students as absent who didn't scan
  Future<void> markAbsentStudents(int sessionId, List<String> studentIds) async {
    final session = await getAttendanceSession(sessionId);
    if (session == null) return;

    // Get students who already have attendance records
    final existingAttendance = await getAttendanceForSession(sessionId);
    final scannedStudentIds = existingAttendance.map((a) => a.studentId).toSet();

    // Mark remaining students as absent
    final absentStudentIds = studentIds.where((id) => !scannedStudentIds.contains(id));

    for (final studentId in absentStudentIds) {
      await _supabase.from('attendance').insert({
        'student_id': studentId,
        'student_lrn': '', // Would need to fetch from student record
        'course_id': session.courseId,
        'session_id': sessionId,
        'date': session.scheduleStart,
        'status': 'absent',
        'remarks': 'Auto-marked absent - did not scan',
      });
    }

    // Update session counts
    await _updateSessionCounts(sessionId);
  }

  // ==================== SCANNING PERMISSION METHODS ====================

  /// Grant scanning permission to a student
  Future<void> grantScanningPermission(String studentId, int courseId) async {
    await _supabase
        .from('attendance')
        .update({'can_scan': true})
        .eq('student_id', studentId)
        .eq('course_id', courseId);
  }

  /// Revoke scanning permission from a student
  Future<void> revokeScanningPermission(String studentId, int courseId) async {
    await _supabase
        .from('attendance')
        .update({'can_scan': false})
        .eq('student_id', studentId)
        .eq('course_id', courseId);
  }

  /// Check if student has scanning permission
  Future<bool> hasScanningPermission(String studentId, int courseId) async {
    final response = await _supabase
        .from('attendance')
        .select('can_scan')
        .eq('student_id', studentId)
        .eq('course_id', courseId)
        .maybeSingle();

    if (response == null) return false;
    return response['can_scan'] ?? false;
  }

  // ==================== STATISTICS & REPORTS ====================

  /// Get attendance statistics for a student
  Future<Map<String, dynamic>> getStudentAttendanceStats(
    String studentId,
    int courseId,
  ) async {
    final records = await getAttendanceForStudent(studentId, courseId);
    
    final total = records.length;
    final present = records.where((r) => r.status == 'present').length;
    final late = records.where((r) => r.status == 'late').length;
    final absent = records.where((r) => r.status == 'absent').length;
    
    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'attendance_rate': total > 0 ? ((present + late) / total * 100) : 0.0,
    };
  }

  /// Get attendance statistics for a session
  Future<Map<String, dynamic>> getSessionAttendanceStats(int sessionId) async {
    final records = await getAttendanceForSession(sessionId);
    
    final total = records.length;
    final present = records.where((r) => r.status == 'present').length;
    final late = records.where((r) => r.status == 'late').length;
    final absent = records.where((r) => r.status == 'absent').length;
    
    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'attendance_rate': total > 0 ? ((present + late) / total * 100) : 0.0,
    };
  }

  // ==================== EXPORT FUNCTIONALITY ====================

  /// Export attendance records to Excel format (returns data structure)
  Future<List<Map<String, dynamic>>> exportAttendanceToExcel({
    int? courseId,
    int? sectionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final records = await getAttendanceRecords(
      courseId: courseId,
      startDate: startDate,
      endDate: endDate,
    );

    return records.map((record) => {
      'Student LRN': record.studentLrn,
      'Student ID': record.studentId,
      'Date': record.date.toString(),
      'Time In': record.timeIn?.toString() ?? 'N/A',
      'Time Out': record.timeOut?.toString() ?? 'N/A',
      'Status': record.status.toUpperCase(),
      'Remarks': record.remarks ?? '',
    }).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Update session attendance counts
  Future<void> _updateSessionCounts(int sessionId) async {
    final records = await getAttendanceForSession(sessionId);
    
    final presentCount = records.where((r) => r.status == 'present').length;
    final lateCount = records.where((r) => r.status == 'late').length;
    final absentCount = records.where((r) => r.status == 'absent').length;
    
    await _supabase
        .from('attendance_sessions')
        .update({
          'total_students': records.length,
          'present_count': presentCount,
          'late_count': lateCount,
          'absent_count': absentCount,
        })
        .eq('id', sessionId);
  }

  /// Integration point for scanner subsystem
  /// This method will be called by the scanner subsystem to record attendance
  Future<Attendance> recordAttendanceFromScanner({
    required String studentLrn,
    required int sessionId,
  }) async {
    // Get session details
    final session = await getAttendanceSession(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    // Check if session is still active
    if (session.status != 'active') {
      throw Exception('Session is not active');
    }

    // Get student ID from LRN (would need to query students table)
    // For now, using LRN as student ID
    final studentId = studentLrn;

    // Record attendance with current time
    return await recordAttendance(
      studentId: studentId,
      studentLrn: studentLrn,
      courseId: session.courseId,
      sessionId: sessionId,
      date: DateTime.now(),
      timeIn: DateTime.now(),
      remarks: 'Scanned via barcode scanner',
    );
  }

  // Legacy method for backward compatibility
  Future<Attendance> createAttendance(Attendance attendance) async {
    return await recordAttendance(
      studentId: attendance.studentId,
      studentLrn: attendance.studentLrn,
      courseId: attendance.courseId,
      sessionId: attendance.sessionId,
      date: attendance.date,
      timeIn: attendance.timeIn,
      remarks: attendance.remarks,
    );
  }
}
