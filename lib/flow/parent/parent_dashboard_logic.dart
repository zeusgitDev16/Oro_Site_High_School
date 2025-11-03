import 'package:flutter/material.dart';

/// Interactive logic for Parent Dashboard
/// Handles state management, navigation, and data operations
/// Separated from UI as per architecture guidelines
class ParentDashboardLogic extends ChangeNotifier {
  // Navigation state
  int _sideNavIndex = 0;
  int get sideNavIndex => _sideNavIndex;

  // Tab controller state
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Selected child (for multi-child parents)
  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  // Notification and message counts
  int _notificationUnreadCount = 3;
  int _messageUnreadCount = 0;
  
  int get notificationUnreadCount => _notificationUnreadCount;
  int get messageUnreadCount => _messageUnreadCount;

  // Loading states
  bool _isLoadingDashboard = false;
  bool get isLoadingDashboard => _isLoadingDashboard;

  // Mock parent data
  Map<String, dynamic> _parentData = {
    'id': 'parent123',
    'firstName': 'Maria',
    'lastName': 'Santos',
    'email': 'maria.santos@parent.com',
    'phone': '+63 912 345 6789',
    'address': '123 Main St, Cagayan de Oro City',
    'children': [
      {
        'id': 'student123',
        'name': 'Juan Dela Cruz',
        'lrn': '123456789012',
        'gradeLevel': 7,
        'section': 'Diamond',
        'adviser': 'Maria Santos',
        'relationship': 'mother',
        'isPrimary': true,
      },
      {
        'id': 'student124',
        'name': 'Maria Dela Cruz',
        'lrn': '123456789013',
        'gradeLevel': 9,
        'section': 'Sapphire',
        'adviser': 'Juan Cruz',
        'relationship': 'mother',
        'isPrimary': false,
      },
    ],
  };

  Map<String, dynamic> get parentData => _parentData;

  // Mock dashboard data
  Map<String, dynamic> _dashboardData = {
    'selectedChild': {
      'id': 'student123',
      'name': 'Juan Dela Cruz',
      'lrn': '123456789012',
      'gradeLevel': 7,
      'section': 'Diamond',
      'adviser': 'Maria Santos',
      'overallGrade': 91.5,
      'attendanceRate': 95.0,
    },
    'todaySchedule': [
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
      {
        'subject': 'Filipino 7',
        'time': '10:00 AM - 11:00 AM',
        'teacher': 'Pedro Garcia',
        'room': 'Room 204',
      },
    ],
    'recentGrades': [
      {
        'subject': 'Mathematics 7',
        'assignment': 'Quiz 3',
        'score': 45,
        'total': 50,
        'percentage': 90,
        'date': '2024-01-15',
      },
      {
        'subject': 'Science 7',
        'assignment': 'Lab Report 2',
        'score': 38,
        'total': 40,
        'percentage': 95,
        'date': '2024-01-14',
      },
      {
        'subject': 'English 7',
        'assignment': 'Essay 1',
        'score': 42,
        'total': 50,
        'percentage': 84,
        'date': '2024-01-13',
      },
      {
        'subject': 'Filipino 7',
        'assignment': 'Pagsusulit 2',
        'score': 47,
        'total': 50,
        'percentage': 94,
        'date': '2024-01-12',
      },
      {
        'subject': 'Mathematics 7',
        'assignment': 'Quiz 2',
        'score': 48,
        'total': 50,
        'percentage': 96,
        'date': '2024-01-10',
      },
    ],
    'attendanceSummary': {
      'thisWeek': {
        'present': 4,
        'late': 1,
        'absent': 0,
        'total': 5,
      },
      'thisMonth': {
        'present': 18,
        'late': 1,
        'absent': 1,
        'total': 20,
      },
    },
    'upcomingAssignments': [
      {
        'subject': 'Science 7',
        'title': 'Solar System Project',
        'dueDate': '2024-01-20',
        'status': 'in_progress',
      },
      {
        'subject': 'Mathematics 7',
        'title': 'Problem Set 5',
        'dueDate': '2024-01-22',
        'status': 'not_started',
      },
      {
        'subject': 'English 7',
        'title': 'Book Report',
        'dueDate': '2024-01-25',
        'status': 'not_started',
      },
    ],
    'recentActivity': [
      {
        'type': 'grade_posted',
        'message': 'New grade posted for Math Quiz 3',
        'timestamp': '2024-01-15T10:30:00',
      },
      {
        'type': 'attendance',
        'message': 'Marked late on Jan 14 at 7:25 AM',
        'timestamp': '2024-01-14T07:25:00',
      },
      {
        'type': 'assignment_submitted',
        'message': 'Science Lab Report 2 submitted',
        'timestamp': '2024-01-13T16:45:00',
      },
    ],
  };

  Map<String, dynamic> get dashboardData => _dashboardData;

  // Constructor
  ParentDashboardLogic() {
    // Set initial selected child to first child
    if (_parentData['children'].isNotEmpty) {
      _selectedChildId = _parentData['children'][0]['id'];
    }
  }

  // Navigation methods
  void setSideNavIndex(int index) {
    _sideNavIndex = index;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Child selection methods
  void selectChild(String childId) {
    _selectedChildId = childId;
    // Update dashboard data for selected child
    _updateDashboardForChild(childId);
    notifyListeners();
  }

  Map<String, dynamic>? getSelectedChildData() {
    if (_selectedChildId == null) return null;
    
    final children = _parentData['children'] as List;
    try {
      return children.firstWhere((child) => child['id'] == _selectedChildId);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getAllChildren() {
    return List<Map<String, dynamic>>.from(_parentData['children']);
  }

  void _updateDashboardForChild(String childId) {
    // In real implementation, this would fetch data for the selected child
    // For now, we'll just update the selectedChild in dashboardData
    final children = _parentData['children'] as List;
    try {
      final child = children.firstWhere((c) => c['id'] == childId);
      _dashboardData['selectedChild'] = {
        'id': child['id'],
        'name': child['name'],
        'lrn': child['lrn'],
        'gradeLevel': child['gradeLevel'],
        'section': child['section'],
        'adviser': child['adviser'],
        'overallGrade': child['id'] == 'student123' ? 91.5 : 88.3,
        'attendanceRate': child['id'] == 'student123' ? 95.0 : 92.5,
      };
    } catch (e) {
      // Child not found
    }
  }

  // Data loading methods
  Future<void> loadDashboardData() async {
    _isLoadingDashboard = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - ParentService.getParentProfile(parentId)
    // - ParentService.getChildren(parentId)
    // - EnrollmentService.getEnrollmentsByStudent(selectedChildId)
    // - GradeService.getRecentGrades(selectedChildId)
    // - AttendanceService.getAttendanceSummary(selectedChildId)
    // - AssignmentService.getUpcomingAssignments(selectedChildId)

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
    final selectedChild = _dashboardData['selectedChild'];
    return {
      'overallGrade': selectedChild['overallGrade'],
      'attendanceRate': selectedChild['attendanceRate'],
      'pendingAssignments': _dashboardData['upcomingAssignments'].length,
      'recentActivities': _dashboardData['recentActivity'].length,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
