import 'package:flutter/material.dart';

/// Interactive logic for Parent Profile
/// Handles profile data and settings
/// Separated from UI as per architecture guidelines
class ParentProfileLogic extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mock profile data
  Map<String, dynamic> _profileData = {
    'id': 'parent123',
    'firstName': 'Maria',
    'lastName': 'Santos',
    'email': 'maria.santos@parent.com',
    'phone': '+63 912 345 6789',
    'address': '123 Main St, Cagayan de Oro City',
    'emergencyContact': '+63 912 345 6790',
    'photoUrl': null,
  };

  Map<String, dynamic> get profileData => _profileData;

  // Mock notification preferences
  Map<String, bool> _notificationPreferences = {
    'gradeUpdates': true,
    'attendanceAlerts': true,
    'assignmentReminders': true,
    'schoolAnnouncements': true,
    'behaviorReports': true,
    'emailNotifications': true,
    'smsNotifications': false,
  };

  Map<String, bool> get notificationPreferences => _notificationPreferences;

  // Load profile data
  Future<void> loadProfileData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - ParentService.getParentProfile(parentId)

    _isLoading = false;
    notifyListeners();
  }

  // Update profile data
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // In real implementation, this would call:
    // - ParentService.updateParentProfile(parentId, updates)

    // Update local data
    _profileData.addAll(updates);

    _isLoading = false;
    notifyListeners();

    return true; // Success
  }

  // Update notification preference
  void updateNotificationPreference(String key, bool value) {
    _notificationPreferences[key] = value;
    notifyListeners();

    // In real implementation, this would call:
    // - ParentService.updateNotificationPreferences(parentId, preferences)
  }

  // Change password (mock)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1000));

    // In real implementation, this would call:
    // - AuthService.changePassword(currentPassword, newPassword)

    _isLoading = false;
    notifyListeners();

    return true; // Success
  }

  // Get initials
  String getInitials() {
    final firstName = _profileData['firstName'] as String;
    final lastName = _profileData['lastName'] as String;
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  // Get full name
  String getFullName() {
    return '${_profileData['firstName']} ${_profileData['lastName']}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
