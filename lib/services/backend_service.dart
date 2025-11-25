// Backend Service
// Centralized service for all backend operations
// Replaces mock data with real Supabase connections

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  final _supabase = Supabase.instance.client;

  // Connection status
  bool _isConnected = false;
  bool _useMockData = false; // Fallback flag

  bool get isConnected => _isConnected;
  bool get useMockData => _useMockData;

  /// Initialize backend connection
  Future<void> initialize() async {
    try {
      // Test connection
      await _supabase.from('profiles').select('id').limit(1);

      _isConnected = true;
      _useMockData = false;

      if (kDebugMode) {
        debugPrint('✅ Backend connected successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backend connection failed, using mock data: $e');
      }
      _isConnected = false;
      _useMockData = true;
    }
  }

  /// Generic query wrapper with mock data fallback
  Future<T> query<T>({
    required Future<T> Function() realQuery,
    required T Function() mockData,
    bool forceMock = false,
  }) async {
    if (forceMock || _useMockData) {
      return mockData();
    }

    try {
      return await realQuery();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Query failed, falling back to mock: $e');
      }
      return mockData();
    }
  }

  /// Check if table exists and has data
  Future<bool> tableExists(String tableName) async {
    try {
      await _supabase.from(tableName).select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Get user role
  Future<int?> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role_id')
          .eq('id', userId)
          .single();

      return response['role_id'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user role: $e');
      }
      return null;
    }
  }

  // ==================== STUDENT OPERATIONS ====================

  /// Get all students
  Future<List<Map<String, dynamic>>> getStudents({
    int? gradeLevel,
    String? section,
    bool? isActive,
  }) async {
    return query(
      realQuery: () async {
        var query = _supabase.from('students').select();

        if (gradeLevel != null) query = query.eq('grade_level', gradeLevel);
        if (section != null) query = query.eq('section', section);
        if (isActive != null) query = query.eq('is_active', isActive);

        return await query;
      },
      mockData: () => _getMockStudents(gradeLevel, section),
    );
  }

  /// Get student by ID
  Future<Map<String, dynamic>?> getStudent(String studentId) async {
    return query(
      realQuery: () async {
        return await _supabase
            .from('students')
            .select()
            .eq('id', studentId)
            .single();
      },
      mockData: () => _getMockStudent(studentId),
    );
  }

  /// Get student by LRN
  Future<Map<String, dynamic>?> getStudentByLrn(String lrn) async {
    return query(
      realQuery: () async {
        return await _supabase
            .from('students')
            .select()
            .eq('lrn', lrn)
            .maybeSingle();
      },
      mockData: () => _getMockStudentByLrn(lrn),
    );
  }

  /// Get the current authenticated student's record
  Future<Map<String, dynamic>?> getCurrentStudent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      return await getStudent(userId);
    } catch (e) {
      if (kDebugMode) {
        // Keep logging minimal to avoid noise in production builds
        debugPrint('Error fetching current student: $e');
      }
      return null;
    }
  }

  /// Update student profile fields for a single student.
  ///
  /// [updates] should use database column names (snake_case), e.g.
  /// 'lrn', 'birth_date', 'gender', 'address', 'guardian_name',
  /// and other allowed self-service fields such as 'school_level', 'track', 'strand',
  /// or 'parent_access_code'.
  Future<bool> updateStudentProfile(
    String studentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (_useMockData) {
        // In mock mode, just pretend the update succeeded.
        return true;
      }

      if (updates.isEmpty) {
        return true;
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('students').update(updates).eq('id', studentId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating student profile: $e');
      }
      return false;
    }
  }

  /// Generate or regenerate a parent access code for the given student.
  /// Returns the new code as a string.
  Future<String?> generateParentAccessCode(String studentId) async {
    try {
      if (_useMockData) {
        // Simple mock: fixed code for development.
        return 'Ab1#Xy';
      }

      final code = _generateParentAccessCodeValue();

      final response = await _supabase
          .from('students')
          .update({
            'parent_access_code': code,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId)
          .select('parent_access_code')
          .single();

      return response['parent_access_code'] as String?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating parent access code: $e');
      }
      return null;
    }
  }

  String _generateParentAccessCodeValue() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%*';
    final random = Random();
    final codeChars = List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return codeChars;
  }

  // ==================== TEACHER OPERATIONS ====================

  // ==================== TEACHER OPERATIONS ====================

  /// Get teacher courses
  Future<List<Map<String, dynamic>>> getTeacherCourses(String teacherId) async {
    return query(
      realQuery: () async {
        return await _supabase
            .from('course_assignments')
            .select('*, courses(*)')
            .eq('teacher_id', teacherId)
            .eq('status', 'active');
      },
      mockData: () => _getMockTeacherCourses(teacherId),
    );
  }

  /// Get teacher students
  Future<List<Map<String, dynamic>>> getTeacherStudents(
    String teacherId,
  ) async {
    return query(
      realQuery: () async {
        // Get courses taught by teacher
        final courses = await getTeacherCourses(teacherId);
        final courseIds = courses.map((c) => c['course_id']).toList();

        if (courseIds.isEmpty) return [];

        // Get enrollments for those courses
        final enrollments = await _supabase
            .from('enrollments')
            .select('*, students(*)')
            .inFilter('course_id', courseIds)
            .eq('status', 'active');

        return enrollments;
      },
      mockData: () => _getMockTeacherStudents(teacherId),
    );
  }

  // ==================== PARENT OPERATIONS ====================

  /// Get parent children
  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    return query(
      realQuery: () async {
        return await _supabase
            .from('parent_students')
            .select('*, students(*)')
            .eq('parent_id', parentId)
            .eq('is_active', true);
      },
      mockData: () => _getMockParentChildren(parentId),
    );
  }

  // ==================== GRADE OPERATIONS ====================

  /// Get student grades
  Future<List<Map<String, dynamic>>> getStudentGrades(
    String studentId, {
    int? courseId,
    String? quarter,
  }) async {
    return query(
      realQuery: () async {
        var query = _supabase
            .from('grades')
            .select('*, courses(*)')
            .eq('student_id', studentId);

        if (courseId != null) query = query.eq('course_id', courseId);
        if (quarter != null) query = query.eq('quarter', quarter);

        return await query;
      },
      mockData: () => _getMockStudentGrades(studentId),
    );
  }

  /// Save grade
  Future<bool> saveGrade(Map<String, dynamic> gradeData) async {
    try {
      if (_useMockData) {
        // In mock mode, just return success
        return true;
      }

      await _supabase.from('grades').upsert(gradeData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving grade: $e');
      }
      return false;
    }
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  /// Get attendance records
  Future<List<Map<String, dynamic>>> getAttendanceRecords({
    String? studentId,
    int? courseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return query(
      realQuery: () async {
        var query = _supabase.from('attendance').select();

        if (studentId != null) query = query.eq('student_id', studentId);
        if (courseId != null) query = query.eq('course_id', courseId);
        if (startDate != null) {
          query = query.gte('date', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('date', endDate.toIso8601String());
        }

        return await query;
      },
      mockData: () => _getMockAttendanceRecords(studentId),
    );
  }

  /// Record attendance
  Future<bool> recordAttendance(Map<String, dynamic> attendanceData) async {
    try {
      if (_useMockData) {
        return true;
      }

      await _supabase.from('attendance').insert(attendanceData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording attendance: $e');
      }
      return false;
    }
  }

  // ==================== ANNOUNCEMENT OPERATIONS ====================

  /// Get announcements
  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? targetRole,
    int? gradeLevel,
  }) async {
    return query(
      realQuery: () async {
        var query = _supabase
            .from('announcements')
            .select()
            .eq('is_published', true);

        if (targetRole != null) {
          query = query.contains('target_roles', [targetRole]);
        }
        if (gradeLevel != null) {
          query = query.eq('grade_level', gradeLevel);
        }

        return await query.order('created_at', ascending: false);
      },
      mockData: () => _getMockAnnouncements(),
    );
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  /// Get notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    return query(
      realQuery: () async {
        return await _supabase
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      },
      mockData: () => _getMockNotifications(userId),
    );
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      if (_useMockData) {
        return true;
      }

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
      return false;
    }
  }

  // ==================== MOCK DATA GENERATORS ====================

  List<Map<String, dynamic>> _getMockStudents(
    int? gradeLevel,
    String? section,
  ) {
    final students = <Map<String, dynamic>>[];
    final targetGrade = gradeLevel ?? 7;
    final targetSection = section ?? 'A';

    for (int i = 1; i <= 35; i++) {
      students.add({
        'id': 'student-$targetGrade-$targetSection-$i',
        'lrn': '${100000000000 + i}',
        'first_name': 'Student',
        'last_name': '$i',
        'middle_name': 'M',
        'grade_level': targetGrade,
        'section': '$targetGrade-$targetSection',
        'email': 'student$i@orosite.edu.ph',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return students;
  }

  Map<String, dynamic>? _getMockStudent(String studentId) {
    return {
      'id': studentId,
      'lrn': '100000000001',
      'first_name': 'Juan',
      'last_name': 'Dela Cruz',
      'middle_name': 'M',
      'grade_level': 7,
      'section': '7-A',
      'email': 'juan.delacruz@orosite.edu.ph',
      'is_active': true,
    };
  }

  Map<String, dynamic>? _getMockStudentByLrn(String lrn) {
    return {
      'id': 'student-1',
      'lrn': lrn,
      'first_name': 'Student',
      'last_name': 'One',
      'middle_name': 'M',
      'grade_level': 7,
      'section': '7-A',
      'is_active': true,
    };
  }

  List<Map<String, dynamic>> _getMockTeacherCourses(String teacherId) {
    return [
      {
        'id': 'assignment-1',
        'teacher_id': teacherId,
        'course_id': 1,
        'status': 'active',
        'courses': {
          'id': 1,
          'name': 'Mathematics 7',
          'code': 'MATH7',
          'grade_level': 7,
        },
      },
      {
        'id': 'assignment-2',
        'teacher_id': teacherId,
        'course_id': 2,
        'status': 'active',
        'courses': {
          'id': 2,
          'name': 'Science 7',
          'code': 'SCI7',
          'grade_level': 7,
        },
      },
    ];
  }

  List<Map<String, dynamic>> _getMockTeacherStudents(String teacherId) {
    final students = <Map<String, dynamic>>[];

    for (int i = 1; i <= 35; i++) {
      students.add({
        'enrollment_id': 'enroll-$i',
        'student_id': 'student-$i',
        'course_id': 1,
        'status': 'active',
        'students': {
          'id': 'student-$i',
          'lrn': '${100000000000 + i}',
          'first_name': 'Student',
          'last_name': '$i',
          'grade_level': 7,
          'section': '7-A',
        },
      });
    }

    return students;
  }

  List<Map<String, dynamic>> _getMockParentChildren(String parentId) {
    return [
      {
        'id': 'ps-1',
        'parent_id': parentId,
        'student_id': 'student-1',
        'relationship': 'mother',
        'is_primary_guardian': true,
        'students': {
          'id': 'student-1',
          'lrn': '100000000001',
          'first_name': 'Juan',
          'last_name': 'Dela Cruz',
          'grade_level': 7,
          'section': '7-A',
        },
      },
      {
        'id': 'ps-2',
        'parent_id': parentId,
        'student_id': 'student-2',
        'relationship': 'mother',
        'is_primary_guardian': true,
        'students': {
          'id': 'student-2',
          'lrn': '100000000002',
          'first_name': 'Maria',
          'last_name': 'Dela Cruz',
          'grade_level': 9,
          'section': '9-B',
        },
      },
    ];
  }

  List<Map<String, dynamic>> _getMockStudentGrades(String studentId) {
    return [
      {
        'id': 1,
        'student_id': studentId,
        'course_id': 1,
        'quarter': 'Q1',
        'grade': 85.5,
        'courses': {'name': 'Mathematics 7', 'code': 'MATH7'},
      },
      {
        'id': 2,
        'student_id': studentId,
        'course_id': 2,
        'quarter': 'Q1',
        'grade': 88.0,
        'courses': {'name': 'Science 7', 'code': 'SCI7'},
      },
    ];
  }

  List<Map<String, dynamic>> _getMockAttendanceRecords(String? studentId) {
    final records = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < 20; i++) {
      final date = now.subtract(Duration(days: i));
      records.add({
        'id': 'attendance-$i',
        'student_id': studentId ?? 'student-1',
        'course_id': 1,
        'date': date.toIso8601String(),
        'status': i % 10 == 0 ? 'absent' : (i % 5 == 0 ? 'late' : 'present'),
        'time_in': date.add(Duration(hours: 7, minutes: 30)).toIso8601String(),
      });
    }

    return records;
  }

  List<Map<String, dynamic>> _getMockAnnouncements() {
    return [
      {
        'id': 'announce-1',
        'title': 'School Year 2023-2024 Opening',
        'message': 'Welcome to the new school year!',
        'priority': 'high',
        'target_roles': ['student', 'parent', 'teacher'],
        'created_at': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 'announce-2',
        'title': 'Parent-Teacher Conference',
        'message': 'Scheduled for next Friday',
        'priority': 'normal',
        'target_roles': ['parent', 'teacher'],
        'created_at': DateTime.now()
            .subtract(Duration(days: 2))
            .toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _getMockNotifications(String userId) {
    return [
      {
        'id': 'notif-1',
        'user_id': userId,
        'title': 'New Grade Posted',
        'message': 'Your Math 7 Q1 grade has been posted',
        'type': 'grade',
        'is_read': false,
        'created_at': DateTime.now()
            .subtract(Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'notif-2',
        'user_id': userId,
        'title': 'Attendance Recorded',
        'message': 'Your attendance for today has been recorded',
        'type': 'attendance',
        'is_read': false,
        'created_at': DateTime.now()
            .subtract(Duration(hours: 4))
            .toIso8601String(),
      },
    ];
  }

  /// Get system statistics for admin dashboard
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // User counts
      final studentsCount = await _supabase
          .from('profiles')
          .count()
          .eq('role_id', 4); // 4 is Student

      final teachersCount = await _supabase
          .from('profiles')
          .count()
          .eq('role_id', 3); // 3 is Teacher

      final parentsCount = await _supabase
          .from('profiles')
          .count()
          .eq('role_id', 5); // 5 is Parent

      // Course count
      final coursesCount = await _supabase
          .from('courses')
          .count()
          .eq('is_active', true);

      // Attendance Rate (simplified: average of session attendance rates)
      // This is expensive, so we might want to cache or simplify
      // For now, let's just get the last 100 sessions
      final sessions = await _supabase
          .from('attendance_sessions')
          .select('present_count, total_students')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(100);

      double attendanceRate = 0.0;
      if ((sessions as List).isNotEmpty) {
        double totalRate = 0;
        int count = 0;
        for (final session in sessions) {
          final present = session['present_count'] as int? ?? 0;
          final total = session['total_students'] as int? ?? 0;
          if (total > 0) {
            totalRate += (present / total);
            count++;
          }
        }
        if (count > 0) {
          attendanceRate = (totalRate / count) * 100;
        }
      }

      // Average Grade (simplified: average of last 100 submissions)
      final submissions = await _supabase
          .from('assignment_submissions')
          .select('score, max_score')
          .eq('status', 'graded')
          .order('graded_at', ascending: false)
          .limit(100);

      double averageGrade = 0.0;
      if ((submissions as List).isNotEmpty) {
        double totalPercentage = 0;
        int count = 0;
        for (final sub in submissions) {
          final score = sub['score'] as num? ?? 0;
          final maxScore = sub['max_score'] as num? ?? 0;
          if (maxScore > 0) {
            totalPercentage += (score / maxScore);
            count++;
          }
        }
        if (count > 0) {
          averageGrade = (totalPercentage / count) * 100;
        }
      }

      return {
        'totalStudents': studentsCount,
        'totalTeachers': teachersCount,
        'totalParents': parentsCount,
        'activeCourses': coursesCount,
        'attendanceRate': attendanceRate,
        'averageGrade': averageGrade,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching system stats: $e');
      }
      return {
        'totalStudents': 0,
        'totalTeachers': 0,
        'totalParents': 0,
        'activeCourses': 0,
        'attendanceRate': 0.0,
        'averageGrade': 0.0,
      };
    }
  }
}
