import 'package:flutter/material.dart';

/// Interactive logic for Parent Children Management
/// Handles children list, selection, and detail viewing
/// Separated from UI as per architecture guidelines
class ParentChildrenLogic extends ChangeNotifier {
  // Selected child
  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mock children data
  List<Map<String, dynamic>> _children = [
    {
      'id': 'student123',
      'name': 'Juan Dela Cruz',
      'lrn': '123456789012',
      'gradeLevel': 7,
      'section': 'Diamond',
      'adviser': 'Maria Santos',
      'relationship': 'mother',
      'isPrimary': true,
      'overallGrade': 91.5,
      'attendanceRate': 95.0,
      'photoUrl': null,
      'email': 'juan.delacruz@student.oshs.edu.ph',
      'contactNumber': '+63 912 345 6789',
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
      'overallGrade': 88.3,
      'attendanceRate': 92.5,
      'photoUrl': null,
      'email': 'maria.delacruz@student.oshs.edu.ph',
      'contactNumber': '+63 912 345 6789',
    },
  ];

  List<Map<String, dynamic>> get children => _children;

  // Get child by ID
  Map<String, dynamic>? getChildById(String id) {
    try {
      return _children.firstWhere((child) => child['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Select child
  void selectChild(String childId) {
    _selectedChildId = childId;
    notifyListeners();
  }

  // Load children data
  Future<void> loadChildren() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - ParentService.getChildren(parentId)

    _isLoading = false;
    notifyListeners();
  }

  // Refresh child data
  Future<void> refreshChildData(String childId) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - ParentService.getChildDetails(childId)
    // - EnrollmentService.getEnrollmentsByStudent(childId)
    // - GradeService.getGradesByStudent(childId)
    // - AttendanceService.getAttendanceByStudent(childId)

    _isLoading = false;
    notifyListeners();
  }

  // Get child initials
  String getChildInitials(String childId) {
    final child = getChildById(childId);
    if (child == null) return '??';
    
    final nameParts = (child['name'] as String).split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
