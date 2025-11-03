import 'package:flutter/material.dart';

/// Interactive logic for Student Dashboard
/// Handles state management, navigation, and data operations
/// Separated from UI as per architecture guidelines
class StudentDashboardLogic extends ChangeNotifier {
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

  // Mock student data
  Map<String, dynamic> _studentData = {
    'id': 'student123',
    'firstName': 'Juan',
    'lastName': 'Dela Cruz',
    'lrn': '123456789012',
    'gradeLevel': 7,
    'section': 'Diamond',
    'adviser': 'Maria Santos',
  };

  Map<String, dynamic> get studentData => _studentData;

  // Mock dashboard data
  Map<String, dynamic> _dashboardData = {
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

  @override
  void dispose() {
    super.dispose();
  }
}
