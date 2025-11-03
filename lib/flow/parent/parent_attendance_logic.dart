import 'package:flutter/material.dart';

/// Interactive logic for Parent Attendance View
/// Handles attendance data, calendar, and summaries
/// Separated from UI as per architecture guidelines
class ParentAttendanceLogic extends ChangeNotifier {
  // Selected child
  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  // Selected month
  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mock attendance records
  List<Map<String, dynamic>> _attendanceRecords = [
    {
      'date': '2024-01-15',
      'timeIn': '07:05:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
    {
      'date': '2024-01-14',
      'timeIn': '07:25:00',
      'timeOut': '16:30:00',
      'status': 'late',
      'notes': 'Traffic',
    },
    {
      'date': '2024-01-13',
      'timeIn': null,
      'timeOut': null,
      'status': 'absent',
      'notes': 'Sick leave - excused',
    },
    {
      'date': '2024-01-12',
      'timeIn': '07:00:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
    {
      'date': '2024-01-11',
      'timeIn': '07:03:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
    {
      'date': '2024-01-10',
      'timeIn': '07:10:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
    {
      'date': '2024-01-09',
      'timeIn': '07:05:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
    {
      'date': '2024-01-08',
      'timeIn': '07:08:00',
      'timeOut': '16:30:00',
      'status': 'present',
      'notes': null,
    },
  ];

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

  // Mock attendance summary
  Map<String, dynamic> _attendanceSummary = {
    'totalDays': 20,
    'present': 18,
    'late': 1,
    'absent': 1,
    'percentage': 95.0,
  };

  Map<String, dynamic> get attendanceSummary => _attendanceSummary;

  // Set selected child
  void setSelectedChild(String childId) {
    _selectedChildId = childId;
    notifyListeners();
  }

  // Set month
  void setMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Navigate to previous month
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  // Navigate to next month
  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  // Load attendance
  Future<void> loadAttendance(String childId, DateTime month) async {
    _isLoading = true;
    _selectedChildId = childId;
    _selectedMonth = month;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - AttendanceService.getAttendanceByStudent(childId, month)

    _isLoading = false;
    notifyListeners();
  }

  // Get attendance status for a specific date
  String getAttendanceStatus(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    try {
      final record = _attendanceRecords.firstWhere((r) => r['date'] == dateStr);
      return record['status'];
    } catch (e) {
      return 'no_data';
    }
  }

  // Get attendance record for a specific date
  Map<String, dynamic>? getAttendanceRecord(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    try {
      return _attendanceRecords.firstWhere((r) => r['date'] == dateStr);
    } catch (e) {
      return null;
    }
  }

  // Get attendance summary
  Map<String, dynamic> getAttendanceSummary() {
    return _attendanceSummary;
  }

  // Calculate attendance percentage
  double calculateAttendancePercentage() {
    final total = _attendanceSummary['totalDays'] as int;
    final present = _attendanceSummary['present'] as int;
    
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  // Export attendance report (mock)
  Future<void> exportAttendanceReport() async {
    // Simulate export process
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // In real implementation, this would:
    // - Generate Excel/PDF with attendance data
    // - Save to device or share
  }

  // Get color for attendance status
  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get icon for attendance status
  IconData getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
