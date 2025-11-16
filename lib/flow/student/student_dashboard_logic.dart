import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/backend_service.dart';

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
    'id': 'student123',
    'firstName': 'Juan',
    'lastName': 'Dela Cruz',
    'lrn': '123456789012',
    'gradeLevel': 7,
    'section': 'Diamond',
    'adviser': 'Maria Santos',
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

  // Mock dashboard data
  final Map<String, dynamic> _dashboardData = {
    'todayClasses': [
      {
        'subject': 'Mathematics 7',
        'time': '7:00 AM - 8:00 AM',
        'teacher': 'Maria Santos',
        'room': 'Room 201',
      },
      {
        'subject': 'Science 7',
        'time': '8:00 AM - 9:00 AM',
        'teacher': 'Juan Cruz',
        'room': 'Room 202',
      },
      {
        'subject': 'English 7',
        'time': '9:00 AM - 10:00 AM',
        'teacher': 'Ana Reyes',
        'room': 'Room 203',
      },
    ],
    'upcomingAssignments': [
      {
        'id': 1,
        'title': 'Math Quiz 3: Integers',
        'dueDate': '2024-01-15T23:59:00',
        'course': 'Mathematics 7',
        'status': 'not_started',
        'pointsPossible': 50,
      },
      {
        'id': 2,
        'title': 'Science Project: Solar System',
        'dueDate': '2024-01-18T23:59:00',
        'course': 'Science 7',
        'status': 'in_progress',
        'pointsPossible': 100,
      },
      {
        'id': 3,
        'title': 'English Essay: My Hero',
        'dueDate': '2024-01-20T23:59:00',
        'course': 'English 7',
        'status': 'not_started',
        'pointsPossible': 75,
      },
    ],
    'recentAnnouncements': [
      {
        'id': 1,
        'title': 'Midterm Exam Schedule Released',
        'date': '2024-01-10T08:00:00',
        'author': 'Principal Office',
        'type': 'school_wide',
        'priority': 'high',
      },
      {
        'id': 2,
        'title': 'Math 7 Module 4 Available',
        'date': '2024-01-12T10:30:00',
        'author': 'Maria Santos',
        'type': 'course_specific',
        'course': 'Mathematics 7',
      },
      {
        'id': 3,
        'title': 'Science Fair Registration Open',
        'date': '2024-01-13T14:00:00',
        'author': 'Science Department',
        'type': 'school_wide',
      },
    ],
    'recentGrades': [
      {
        'id': 1,
        'assignmentTitle': 'Math Quiz 2',
        'course': 'Mathematics 7',
        'pointsEarned': 45,
        'pointsPossible': 50,
        'percentage': 90,
        'dateGraded': '2024-01-08',
      },
      {
        'id': 2,
        'assignmentTitle': 'Science Lab Report 1',
        'course': 'Science 7',
        'pointsEarned': 38,
        'pointsPossible': 40,
        'percentage': 95,
        'dateGraded': '2024-01-09',
      },
    ],
    'attendanceSummary': {
      'totalDays': 20,
      'present': 18,
      'late': 1,
      'absent': 1,
      'percentage': 90.0,
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

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - EnrollmentService.getEnrollmentsByStudent(studentId)
    // - AssignmentService.getUpcomingAssignments(courseIds)
    // - AnnouncementService.getRecentAnnouncements(courseIds)
    // - GradeService.getRecentGrades(studentId)
    // - AttendanceService.getAttendanceSummary(studentId)
    // - CalendarEventService.getTodayEvents(studentId)

    _isLoadingDashboard = false;
    notifyListeners();
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
      final student = await _backendService.getCurrentStudent();
      if (student == null) {
        return;
      }

      final dbGradeLevel = student['grade_level'];
      final derivedSchoolLevel = _deriveSchoolLevel(dbGradeLevel);

      _studentData = {
        'id': student['id'] as String? ?? _studentData['id'],
        'firstName':
            (student['first_name'] ?? _studentData['firstName']) as String,
        'lastName':
            (student['last_name'] ?? _studentData['lastName']) as String,
        'lrn': (student['lrn'] ?? _studentData['lrn']) as String,
        'gradeLevel': dbGradeLevel ?? _studentData['gradeLevel'],
        'section':
            student['section_name'] ??
            student['section'] ??
            _studentData['section'],
        'adviser': _studentData['adviser'],
        'birthDate': student['birth_date'],
        'gender': student['gender'],
        'address': student['address'],
        'guardianName': student['guardian_name'],
        'guardianContact': student['guardian_contact'],
        'schoolLevel':
            student['school_level'] ??
            _studentData['schoolLevel'] ??
            derivedSchoolLevel,
        'track': student['track'] ?? _studentData['track'],
        'strand': student['strand'] ?? _studentData['strand'],
      };

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading student profile: $e');
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
