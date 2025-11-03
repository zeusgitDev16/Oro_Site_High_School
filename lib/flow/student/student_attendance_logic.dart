import 'package:flutter/material.dart';

/// Interactive logic for Student Attendance
/// Handles state management for attendance records and statistics
/// Separated from UI as per architecture guidelines
class StudentAttendanceLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingAttendance = false;
  bool _isLoadingDetails = false;

  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingDetails => _isLoadingDetails;

  // Filter options
  String _selectedPeriod = 'This Month'; // This Month, This Quarter, This Year, All Time
  String _selectedCourse = 'All Courses'; // All Courses, or specific course

  String get selectedPeriod => _selectedPeriod;
  String get selectedCourse => _selectedCourse;

  // Mock attendance data - organized by date and course
  final List<Map<String, dynamic>> _attendanceRecords = [
    // This week
    {
      'id': 1,
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'status': 'present', // present, absent, late, excused
      'timeIn': '7:05 AM',
      'timeOut': '8:00 AM',
      'remarks': null,
    },
    {
      'id': 2,
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'course': 'Science 7',
      'courseId': 2,
      'teacher': 'Juan Cruz',
      'status': 'present',
      'timeIn': '8:05 AM',
      'timeOut': '9:00 AM',
      'remarks': null,
    },
    {
      'id': 3,
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'course': 'English 7',
      'courseId': 3,
      'teacher': 'Ana Reyes',
      'status': 'present',
      'timeIn': '9:05 AM',
      'timeOut': '10:00 AM',
      'remarks': null,
    },
    {
      'id': 4,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'status': 'late',
      'timeIn': '7:15 AM',
      'timeOut': '8:00 AM',
      'remarks': 'Arrived 10 minutes late',
    },
    {
      'id': 5,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'course': 'Science 7',
      'courseId': 2,
      'teacher': 'Juan Cruz',
      'status': 'present',
      'timeIn': '8:05 AM',
      'timeOut': '9:00 AM',
      'remarks': null,
    },
    {
      'id': 6,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'course': 'English 7',
      'courseId': 3,
      'teacher': 'Ana Reyes',
      'status': 'present',
      'timeIn': '9:05 AM',
      'timeOut': '10:00 AM',
      'remarks': null,
    },
    {
      'id': 7,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'status': 'present',
      'timeIn': '7:05 AM',
      'timeOut': '8:00 AM',
      'remarks': null,
    },
    {
      'id': 8,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'course': 'Science 7',
      'courseId': 2,
      'teacher': 'Juan Cruz',
      'status': 'absent',
      'timeIn': null,
      'timeOut': null,
      'remarks': 'Sick leave - Medical certificate submitted',
    },
    {
      'id': 9,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'course': 'English 7',
      'courseId': 3,
      'teacher': 'Ana Reyes',
      'status': 'excused',
      'timeIn': null,
      'timeOut': null,
      'remarks': 'School event participation',
    },
    // Last week
    {
      'id': 10,
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'status': 'present',
      'timeIn': '7:05 AM',
      'timeOut': '8:00 AM',
      'remarks': null,
    },
    {
      'id': 11,
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'course': 'Science 7',
      'courseId': 2,
      'teacher': 'Juan Cruz',
      'status': 'present',
      'timeIn': '8:05 AM',
      'timeOut': '9:00 AM',
      'remarks': null,
    },
    {
      'id': 12,
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'status': 'late',
      'timeIn': '7:20 AM',
      'timeOut': '8:00 AM',
      'remarks': 'Traffic delay',
    },
    {
      'id': 13,
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'course': 'Filipino 7',
      'courseId': 4,
      'teacher': 'Pedro Santos',
      'status': 'present',
      'timeIn': '10:05 AM',
      'timeOut': '11:00 AM',
      'remarks': null,
    },
  ];

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

  // Get overall attendance statistics
  Map<String, dynamic> getOverallStatistics() {
    if (_attendanceRecords.isEmpty) {
      return {
        'totalDays': 0,
        'presentCount': 0,
        'absentCount': 0,
        'lateCount': 0,
        'excusedCount': 0,
        'attendanceRate': 0.0,
      };
    }

    // Group by date to count unique days
    final uniqueDates = <String>{};
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    int excusedCount = 0;

    for (var record in _attendanceRecords) {
      final dateKey = _formatDateKey(record['date']);
      uniqueDates.add(dateKey);

      switch (record['status']) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'late':
          lateCount++;
          break;
        case 'excused':
          excusedCount++;
          break;
      }
    }

    final totalDays = uniqueDates.length;
    final attendedCount = presentCount + lateCount; // Late still counts as attended
    final attendanceRate = totalDays > 0 ? (attendedCount / _attendanceRecords.length) * 100 : 0.0;

    return {
      'totalDays': totalDays,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'excusedCount': excusedCount,
      'attendanceRate': attendanceRate,
      'totalRecords': _attendanceRecords.length,
    };
  }

  // Get attendance by course
  Map<int, Map<String, dynamic>> getAttendanceByCourse() {
    final Map<int, Map<String, dynamic>> courseAttendance = {};

    for (var record in _attendanceRecords) {
      final courseId = record['courseId'] as int;

      if (!courseAttendance.containsKey(courseId)) {
        courseAttendance[courseId] = {
          'courseId': courseId,
          'courseName': record['course'],
          'teacher': record['teacher'],
          'present': 0,
          'absent': 0,
          'late': 0,
          'excused': 0,
          'total': 0,
        };
      }

      courseAttendance[courseId]!['total'] = (courseAttendance[courseId]!['total'] as int) + 1;

      switch (record['status']) {
        case 'present':
          courseAttendance[courseId]!['present'] = (courseAttendance[courseId]!['present'] as int) + 1;
          break;
        case 'absent':
          courseAttendance[courseId]!['absent'] = (courseAttendance[courseId]!['absent'] as int) + 1;
          break;
        case 'late':
          courseAttendance[courseId]!['late'] = (courseAttendance[courseId]!['late'] as int) + 1;
          break;
        case 'excused':
          courseAttendance[courseId]!['excused'] = (courseAttendance[courseId]!['excused'] as int) + 1;
          break;
      }
    }

    // Calculate attendance rate for each course
    courseAttendance.forEach((courseId, data) {
      final total = data['total'] as int;
      final attended = (data['present'] as int) + (data['late'] as int);
      data['attendanceRate'] = total > 0 ? (attended / total) * 100 : 0.0;
    });

    return courseAttendance;
  }

  // Get attendance records grouped by date
  Map<String, List<Map<String, dynamic>>> getAttendanceByDate() {
    final Map<String, List<Map<String, dynamic>>> groupedRecords = {};

    for (var record in _attendanceRecords) {
      final dateKey = _formatDateKey(record['date']);

      if (!groupedRecords.containsKey(dateKey)) {
        groupedRecords[dateKey] = [];
      }

      groupedRecords[dateKey]!.add(record);
    }

    return groupedRecords;
  }

  // Get filtered records
  List<Map<String, dynamic>> getFilteredRecords() {
    var filtered = List<Map<String, dynamic>>.from(_attendanceRecords);

    // Filter by course
    if (_selectedCourse != 'All Courses') {
      filtered = filtered.where((record) => record['course'] == _selectedCourse).toList();
    }

    // Filter by period
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        filtered = filtered.where((record) {
          final date = record['date'] as DateTime;
          return date.year == now.year && date.month == now.month;
        }).toList();
        break;
      case 'This Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        filtered = filtered.where((record) {
          final date = record['date'] as DateTime;
          final recordQuarter = ((date.month - 1) ~/ 3) + 1;
          return date.year == now.year && recordQuarter == currentQuarter;
        }).toList();
        break;
      case 'This Year':
        filtered = filtered.where((record) {
          final date = record['date'] as DateTime;
          return date.year == now.year;
        }).toList();
        break;
      // 'All Time' - no filter
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return filtered;
  }

  // Get attendance trend (last 7 days)
  List<Map<String, dynamic>> getAttendanceTrend() {
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);

      final dayRecords = _attendanceRecords.where((record) {
        return _formatDateKey(record['date']) == dateKey;
      }).toList();

      final presentCount = dayRecords.where((r) => r['status'] == 'present' || r['status'] == 'late').length;
      final totalCount = dayRecords.length;

      trend.add({
        'date': date,
        'dateKey': dateKey,
        'presentCount': presentCount,
        'totalCount': totalCount,
        'attendanceRate': totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0,
      });
    }

    return trend;
  }

  // Get available courses for filter
  List<String> getAvailableCourses() {
    final courses = <String>{'All Courses'};
    for (var record in _attendanceRecords) {
      courses.add(record['course']);
    }
    return courses.toList();
  }

  // Set filters
  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setCourse(String course) {
    _selectedCourse = course;
    notifyListeners();
  }

  // Load attendance data
  Future<void> loadAttendance() async {
    _isLoadingAttendance = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final enrollments = await EnrollmentService.getEnrollmentsByStudent(studentId);
    // final courseIds = enrollments.map((e) => e.courseId).toList();
    // final attendance = await AttendanceService.getStudentAttendance(studentId, courseIds);

    _isLoadingAttendance = false;
    notifyListeners();
  }

  // Helper method to format date key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
