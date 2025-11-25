import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/backend_service.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';

/// Interactive logic for Student Dashboard
/// Handles state management, navigation, and data operations
/// Separated from UI as per architecture guidelines
class StudentDashboardLogic extends ChangeNotifier {
  final BackendService _backendService = BackendService();

  // Navigation state
  int _sideNavIndex = 0;
  int get sideNavIndex => _sideNavIndex;

  // Tab controller state
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Notification and message counts
  int _notificationUnreadCount = 5;
  int _messageUnreadCount = 3;

  int get notificationUnreadCount => _notificationUnreadCount;
  int get messageUnreadCount => _messageUnreadCount;

  // Loading states
  bool _isLoadingDashboard = false;
  bool get isLoadingDashboard => _isLoadingDashboard;

  // Student data (mock defaults, will be replaced by real data when available)
  Map<String, dynamic> _studentData = {
    'id': '',
    'firstName': '',
    'lastName': '',
    'lrn': '',
    'gradeLevel': null,
    'section': '',
    'adviser': '',
    'birthDate': null,
    'gender': null,
    'address': '',
    'guardianName': '',
    'guardianContact': '',
    'schoolLevel': null, // 'JHS' or 'SHS'
    'track': null, // SHS only
    'strand': null, // SHS only
  };

  Map<String, dynamic> get studentData => _studentData;

  // Dashboard data - will be populated from database
  final Map<String, dynamic> _dashboardData = {
    'todayClasses': [],
    'upcomingAssignments': [],
    'recentAnnouncements': [],
    'recentGrades': [],
    'attendanceSummary': {
      'totalDays': 0,
      'present': 0,
      'late': 0,
      'absent': 0,
      'percentage': 0.0,
    },
  };

  Map<String, dynamic> get dashboardData => _dashboardData;

  // Navigation methods
  void setSideNavIndex(int index) {
    _sideNavIndex = index;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Data loading methods
  Future<void> loadDashboardData() async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      // Get current student ID
      final studentId = _studentData['id'] as String?;
      if (studentId == null || studentId.isEmpty) {
        debugPrint('Cannot load dashboard: student ID is null');
        _isLoadingDashboard = false;
        notifyListeners();
        return;
      }

      // Fetch student's classrooms
      final classroomService = ClassroomService();
      final classrooms = await classroomService.getStudentClassrooms(studentId);

      if (classrooms.isEmpty) {
        debugPrint('No classrooms found for student');
        _dashboardData['todayClasses'] = [];
        _dashboardData['upcomingAssignments'] = [];
        _dashboardData['recentAnnouncements'] = [];
        _dashboardData['recentGrades'] = [];
        _dashboardData['attendanceSummary'] = {
          'percentage': 0.0,
          'present': 0,
          'absent': 0,
          'late': 0,
        };
        _isLoadingDashboard = false;
        notifyListeners();
        return;
      }

      // Get the first active classroom (students typically have one main classroom)
      final classroom = classrooms.first;
      final classroomId = classroom.id;

      // Fetch data in parallel
      final results = await Future.wait([
        _fetchTodayClasses(classroomId),
        _fetchUpcomingAssignments(classroomId),
        _fetchRecentAnnouncements(),
        _fetchRecentGrades(studentId),
        _fetchAttendanceSummary(studentId),
      ]);

      _dashboardData['todayClasses'] = results[0];
      _dashboardData['upcomingAssignments'] = results[1];
      _dashboardData['recentAnnouncements'] = results[2];
      _dashboardData['recentGrades'] = results[3];
      _dashboardData['attendanceSummary'] = results[4];

      _isLoadingDashboard = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTodayClasses(
    String classroomId,
  ) async {
    try {
      // For now, return empty list as we need course schedule implementation
      // TODO: Implement course schedule fetching for today
      return [];
    } catch (e) {
      debugPrint('Error fetching today classes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUpcomingAssignments(
    String classroomId,
  ) async {
    try {
      final assignmentService = AssignmentService();
      final assignments = await assignmentService.getUpcomingAssignments(
        classroomId,
      );

      // Transform to match expected format
      return assignments.map((a) {
        return {
          'id': a['id'],
          'title': a['title'] ?? 'Untitled Assignment',
          'dueDate': a['due_date'],
          'course': a['course_name'] ?? 'Unknown Course',
          'status': 'not_started', // Default status
          'pointsPossible': a['max_score'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming assignments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentAnnouncements() async {
    try {
      final announcements = await _backendService.getAnnouncements();

      // Get the 5 most recent announcements
      final recent = announcements.take(5).toList();

      return recent.map((a) {
        return {
          'id': a['id'],
          'title': a['title'] ?? 'Untitled Announcement',
          'message': a['message'] ?? a['content'] ?? '',
          'date': a['created_at'],
          'priority': a['priority'] ?? 'normal',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent announcements: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentGrades(
    String studentId,
  ) async {
    try {
      final grades = await _backendService.getStudentGrades(studentId);

      // Get the 5 most recent grades
      final recent = grades.take(5).toList();

      return recent.map((g) {
        final score = g['grade'] ?? g['score'] ?? 0;
        final maxScore = g['max_score'] ?? 100;
        final percentage = maxScore > 0 ? (score / maxScore * 100) : 0;

        return {
          'id': g['id'],
          'course': g['course_name'] ?? 'Unknown Course',
          'assignment': g['assignment_name'] ?? 'Grade',
          'score': score,
          'maxScore': maxScore,
          'percentage': percentage,
          'date': g['created_at'] ?? g['graded_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent grades: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchAttendanceSummary(String studentId) async {
    try {
      // Get attendance records for the current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final records = await _backendService.getAttendanceRecords(
        studentId: studentId,
        startDate: startOfMonth,
        endDate: now,
      );

      if (records.isEmpty) {
        return {'percentage': 0.0, 'present': 0, 'absent': 0, 'late': 0};
      }

      final present = records.where((r) => r['status'] == 'present').length;
      final late = records.where((r) => r['status'] == 'late').length;
      final absent = records.where((r) => r['status'] == 'absent').length;
      final total = records.length;

      final percentage = total > 0 ? ((present + late) / total * 100) : 0.0;

      return {
        'percentage': percentage,
        'present': present,
        'absent': absent,
        'late': late,
      };
    } catch (e) {
      debugPrint('Error fetching attendance summary: $e');
      return {'percentage': 0.0, 'present': 0, 'absent': 0, 'late': 0};
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Load the current student's profile data from the backend.
  ///
  /// This uses the Supabase auth user as the source of truth for which
  /// student record to load, and falls back to the mock defaults if
  /// anything goes wrong.
  Future<void> loadStudentProfile() async {
    try {
      debugPrint('Loading student profile...');
      final student = await _backendService.getCurrentStudent();

      if (student == null) {
        debugPrint('No student data returned from getCurrentStudent()');
        notifyListeners(); // Still notify even if no data
        return;
      }

      debugPrint(
        'Student data loaded: ${student['first_name']} ${student['last_name']}',
      );

      final dbGradeLevel = student['grade_level'];
      final derivedSchoolLevel = _deriveSchoolLevel(dbGradeLevel);

      _studentData = {
        'id': student['id'] as String? ?? '',
        'firstName': (student['first_name'] as String?) ?? '',
        'lastName': (student['last_name'] as String?) ?? '',
        'lrn': (student['lrn'] as String?) ?? '',
        'gradeLevel': dbGradeLevel,
        'section': student['section_name'] ?? student['section'] ?? '',
        'adviser': '', // Not available in student table
        'birthDate': student['birth_date'],
        'gender': student['gender'],
        'address': student['address'] ?? '',
        'guardianName': student['guardian_name'] ?? '',
        'guardianContact': student['guardian_contact'] ?? '',
        'schoolLevel': student['school_level'] ?? derivedSchoolLevel,
        'track': student['track'],
        'strand': student['strand'],
      };

      debugPrint(
        'Student data updated: firstName=${_studentData['firstName']}, lastName=${_studentData['lastName']}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading student profile: $e');
      notifyListeners(); // Still notify even on error
    }
  }

  String? _deriveSchoolLevel(dynamic gradeLevel) {
    if (gradeLevel is int) {
      if (gradeLevel >= 7 && gradeLevel <= 10) return 'JHS';
      if (gradeLevel >= 11 && gradeLevel <= 12) return 'SHS';
    }
    return null;
  }

  /// Update the current student's profile fields.
  ///
  /// [updates] uses local camelCase keys (e.g. 'lrn', 'gender', 'birthDate',
  /// 'address', 'guardianName', 'guardianContact', 'schoolLevel', 'track',
  /// 'strand').
  Future<bool> updateStudentProfile(Map<String, dynamic> updates) async {
    try {
      final studentId = _studentData['id'] as String?;
      if (studentId == null || studentId.isEmpty) {
        debugPrint('Cannot update student profile: missing student id');
        return false;
      }

      final dbUpdates = <String, dynamic>{};

      if (updates.containsKey('lrn')) {
        dbUpdates['lrn'] = updates['lrn'];
      }
      if (updates.containsKey('gender')) {
        dbUpdates['gender'] = updates['gender'];
      }
      if (updates.containsKey('birthDate')) {
        final birthDate = updates['birthDate'];
        if (birthDate is DateTime) {
          dbUpdates['birth_date'] = birthDate.toIso8601String();
        } else if (birthDate is String && birthDate.isNotEmpty) {
          dbUpdates['birth_date'] = DateTime.parse(birthDate).toIso8601String();
        }
      }
      if (updates.containsKey('address')) {
        dbUpdates['address'] = updates['address'];
      }
      if (updates.containsKey('guardianName')) {
        dbUpdates['guardian_name'] = updates['guardianName'];
      }
      if (updates.containsKey('guardianContact')) {
        dbUpdates['guardian_contact'] = updates['guardianContact'];
      }
      if (updates.containsKey('schoolLevel')) {
        final level = updates['schoolLevel'] as String?;
        if (level != null && level.isNotEmpty) {
          dbUpdates['school_level'] = level;
        }
      }
      if (updates.containsKey('track')) {
        dbUpdates['track'] = updates['track'];
      }
      if (updates.containsKey('strand')) {
        dbUpdates['strand'] = updates['strand'];
      }

      if (dbUpdates.isEmpty) {
        return true;
      }

      final success = await _backendService.updateStudentProfile(
        studentId,
        dbUpdates,
      );

      if (success) {
        _studentData.addAll(updates);
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error updating student profile: $e');
      return false;
    }
  }

  // Notification methods
  void updateNotificationCount(int count) {
    _notificationUnreadCount = count;
    notifyListeners();
  }

  void updateMessageCount(int count) {
    _messageUnreadCount = count;
    notifyListeners();
  }

  void markNotificationAsRead() {
    if (_notificationUnreadCount > 0) {
      _notificationUnreadCount--;
      notifyListeners();
    }
  }

  void markMessageAsRead() {
    if (_messageUnreadCount > 0) {
      _messageUnreadCount--;
      notifyListeners();
    }
  }

  // Quick stats calculation
  Map<String, dynamic> getQuickStats() {
    return {
      'courses': _dashboardData['todayClasses'].length,
      'assignments': _dashboardData['upcomingAssignments'].length,
      'unreadAnnouncements': _dashboardData['recentAnnouncements'].length,
      'averageGrade': _calculateAverageGrade(),
      'attendanceRate': _dashboardData['attendanceSummary']['percentage'],
    };
  }

  double _calculateAverageGrade() {
    final grades = _dashboardData['recentGrades'] as List;
    if (grades.isEmpty) return 0.0;

    final sum = grades.fold<double>(
      0.0,
      (sum, grade) => sum + (grade['percentage'] as num).toDouble(),
    );
    return sum / grades.length;
  }

  // Get upcoming assignments count
  int getUpcomingAssignmentsCount() {
    return (_dashboardData['upcomingAssignments'] as List).length;
  }

  // Get today's classes count
  int getTodayClassesCount() {
    return (_dashboardData['todayClasses'] as List).length;
  }
}
