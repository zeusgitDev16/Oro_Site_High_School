import 'package:flutter/material.dart';

/// Student Settings Logic - Interactive logic for student settings management
/// Handles notification preferences, display settings, and privacy options
/// UI components in lib/screens/student/profile/settings_screen.dart
class StudentSettingsLogic extends ChangeNotifier {
  // Settings state
  Map<String, dynamic> _settings = {
    'notifications': {
      'assignments': true,
      'grades': true,
      'messages': true,
      'announcements': true,
      'attendance': true,
      'courseUpdates': true,
    },
    'display': {
      'theme': 'light', // light, dark, auto
      'language': 'en', // en, fil
      'fontSize': 'medium', // small, medium, large
    },
    'privacy': {
      'showProfile': true,
      'showGrades': false,
      'showAttendance': false,
      'allowMessages': true,
    },
    'app': {
      'autoSaveDrafts': true,
      'downloadOverWiFi': true,
      'showNotificationBadge': true,
      'soundEnabled': true,
    },
  };

  // Getters
  Map<String, dynamic> get settings => _settings;

  // Notification settings getters
  bool getNotificationSetting(String key) {
    return _settings['notifications'][key] ?? false;
  }

  bool get assignmentsNotification => _settings['notifications']['assignments'] ?? false;
  bool get gradesNotification => _settings['notifications']['grades'] ?? false;
  bool get messagesNotification => _settings['notifications']['messages'] ?? false;
  bool get announcementsNotification => _settings['notifications']['announcements'] ?? false;
  bool get attendanceNotification => _settings['notifications']['attendance'] ?? false;
  bool get courseUpdatesNotification => _settings['notifications']['courseUpdates'] ?? false;

  // Display settings getters
  String getDisplaySetting(String key) {
    return _settings['display'][key] ?? '';
  }

  String get theme => _settings['display']['theme'] ?? 'light';
  String get language => _settings['display']['language'] ?? 'en';
  String get fontSize => _settings['display']['fontSize'] ?? 'medium';

  // Privacy settings getters
  bool getPrivacySetting(String key) {
    return _settings['privacy'][key] ?? false;
  }

  bool get showProfile => _settings['privacy']['showProfile'] ?? true;
  bool get showGrades => _settings['privacy']['showGrades'] ?? false;
  bool get showAttendance => _settings['privacy']['showAttendance'] ?? false;
  bool get allowMessages => _settings['privacy']['allowMessages'] ?? true;

  // App settings getters
  bool getAppSetting(String key) {
    return _settings['app'][key] ?? false;
  }

  bool get autoSaveDrafts => _settings['app']['autoSaveDrafts'] ?? true;
  bool get downloadOverWiFi => _settings['app']['downloadOverWiFi'] ?? true;
  bool get showNotificationBadge => _settings['app']['showNotificationBadge'] ?? true;
  bool get soundEnabled => _settings['app']['soundEnabled'] ?? true;

  // Methods - Notification toggles
  void toggleNotification(String key) {
    _settings['notifications'][key] = !_settings['notifications'][key];
    notifyListeners();
  }

  void toggleAssignmentsNotification() {
    _settings['notifications']['assignments'] = !_settings['notifications']['assignments'];
    notifyListeners();
  }

  void toggleGradesNotification() {
    _settings['notifications']['grades'] = !_settings['notifications']['grades'];
    notifyListeners();
  }

  void toggleMessagesNotification() {
    _settings['notifications']['messages'] = !_settings['notifications']['messages'];
    notifyListeners();
  }

  void toggleAnnouncementsNotification() {
    _settings['notifications']['announcements'] = !_settings['notifications']['announcements'];
    notifyListeners();
  }

  void toggleAttendanceNotification() {
    _settings['notifications']['attendance'] = !_settings['notifications']['attendance'];
    notifyListeners();
  }

  void toggleCourseUpdatesNotification() {
    _settings['notifications']['courseUpdates'] = !_settings['notifications']['courseUpdates'];
    notifyListeners();
  }

  // Methods - Display settings
  void setDisplaySetting(String key, String value) {
    _settings['display'][key] = value;
    notifyListeners();
  }

  void setTheme(String theme) {
    _settings['display']['theme'] = theme;
    notifyListeners();
  }

  void setLanguage(String language) {
    _settings['display']['language'] = language;
    notifyListeners();
  }

  void setFontSize(String fontSize) {
    _settings['display']['fontSize'] = fontSize;
    notifyListeners();
  }

  // Methods - Privacy toggles
  void togglePrivacy(String key) {
    _settings['privacy'][key] = !_settings['privacy'][key];
    notifyListeners();
  }

  void toggleShowProfile() {
    _settings['privacy']['showProfile'] = !_settings['privacy']['showProfile'];
    notifyListeners();
  }

  void toggleShowGrades() {
    _settings['privacy']['showGrades'] = !_settings['privacy']['showGrades'];
    notifyListeners();
  }

  void toggleShowAttendance() {
    _settings['privacy']['showAttendance'] = !_settings['privacy']['showAttendance'];
    notifyListeners();
  }

  void toggleAllowMessages() {
    _settings['privacy']['allowMessages'] = !_settings['privacy']['allowMessages'];
    notifyListeners();
  }

  // Methods - App settings toggles
  void toggleAppSetting(String key) {
    _settings['app'][key] = !_settings['app'][key];
    notifyListeners();
  }

  void toggleAutoSaveDrafts() {
    _settings['app']['autoSaveDrafts'] = !_settings['app']['autoSaveDrafts'];
    notifyListeners();
  }

  void toggleDownloadOverWiFi() {
    _settings['app']['downloadOverWiFi'] = !_settings['app']['downloadOverWiFi'];
    notifyListeners();
  }

  void toggleShowNotificationBadge() {
    _settings['app']['showNotificationBadge'] = !_settings['app']['showNotificationBadge'];
    notifyListeners();
  }

  void toggleSoundEnabled() {
    _settings['app']['soundEnabled'] = !_settings['app']['soundEnabled'];
    notifyListeners();
  }

  // Save settings (placeholder for backend integration)
  void saveSettings() {
    // TODO: Save to backend when ready
    // await SettingsService.saveStudentSettings(_settings);
    notifyListeners();
  }

  // Reset settings to default
  void resetToDefaults() {
    _settings = {
      'notifications': {
        'assignments': true,
        'grades': true,
        'messages': true,
        'announcements': true,
        'attendance': true,
        'courseUpdates': true,
      },
      'display': {
        'theme': 'light',
        'language': 'en',
        'fontSize': 'medium',
      },
      'privacy': {
        'showProfile': true,
        'showGrades': false,
        'showAttendance': false,
        'allowMessages': true,
      },
      'app': {
        'autoSaveDrafts': true,
        'downloadOverWiFi': true,
        'showNotificationBadge': true,
        'soundEnabled': true,
      },
    };
    notifyListeners();
  }

  // Load settings (placeholder for backend integration)
  Future<void> loadSettings() async {
    // TODO: Load from backend when ready
    // final savedSettings = await SettingsService.getStudentSettings();
    // if (savedSettings != null) {
    //   _settings = savedSettings;
    //   notifyListeners();
    // }
  }
}
