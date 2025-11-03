import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_profile_logic.dart';
import 'package:oro_site_high_school/flow/student/student_settings_logic.dart';

/// Settings Screen - Allows students to configure app preferences
/// UI only - interactive logic in StudentSettingsLogic
class StudentSettingsScreen extends StatefulWidget {
  final StudentProfileLogic logic;

  const StudentSettingsScreen({super.key, required this.logic});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  late StudentSettingsLogic _settingsLogic;

  @override
  void initState() {
    super.initState();
    _settingsLogic = StudentSettingsLogic();
    _settingsLogic.loadSettings();
  }

  @override
  void dispose() {
    _settingsLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _settingsLogic,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildNotificationSettings(),
              const SizedBox(height: 24),
              _buildDisplaySettings(),
              const SizedBox(height: 24),
              _buildPrivacySettings(),
              const SizedBox(height: 24),
              _buildAppSettings(),
              const SizedBox(height: 24),
              _buildAccountSettings(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchTile(
              'Assignment Notifications',
              'Get notified about new assignments',
              _settingsLogic.assignmentsNotification,
              () => _settingsLogic.toggleAssignmentsNotification(),
            ),
            _buildSwitchTile(
              'Grade Notifications',
              'Get notified when grades are posted',
              _settingsLogic.gradesNotification,
              () => _settingsLogic.toggleGradesNotification(),
            ),
            _buildSwitchTile(
              'Message Notifications',
              'Get notified about new messages',
              _settingsLogic.messagesNotification,
              () => _settingsLogic.toggleMessagesNotification(),
            ),
            _buildSwitchTile(
              'Announcement Notifications',
              'Get notified about announcements',
              _settingsLogic.announcementsNotification,
              () => _settingsLogic.toggleAnnouncementsNotification(),
            ),
            _buildSwitchTile(
              'Attendance Notifications',
              'Get notified about attendance updates',
              _settingsLogic.attendanceNotification,
              () => _settingsLogic.toggleAttendanceNotification(),
            ),
            _buildSwitchTile(
              'Course Update Notifications',
              'Get notified about course updates',
              _settingsLogic.courseUpdatesNotification,
              () => _settingsLogic.toggleCourseUpdatesNotification(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Display',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDropdownTile(
              'Theme',
              'Choose your preferred theme',
              _settingsLogic.theme,
              ['light', 'dark', 'auto'],
              (value) {
                _settingsLogic.setTheme(value!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownTile(
              'Language',
              'Choose your preferred language',
              _settingsLogic.language,
              ['en', 'fil'],
              (value) {
                _settingsLogic.setLanguage(value!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownTile(
              'Font Size',
              'Choose your preferred font size',
              _settingsLogic.fontSize,
              ['small', 'medium', 'large'],
              (value) {
                _settingsLogic.setFontSize(value!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Font Size - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchTile(
              'Show Profile to Others',
              'Allow other students to view your profile',
              _settingsLogic.showProfile,
              () => _settingsLogic.toggleShowProfile(),
            ),
            _buildSwitchTile(
              'Show Grades to Others',
              'Allow others to see your grades',
              _settingsLogic.showGrades,
              () => _settingsLogic.toggleShowGrades(),
            ),
            _buildSwitchTile(
              'Show Attendance to Others',
              'Allow others to see your attendance',
              _settingsLogic.showAttendance,
              () => _settingsLogic.toggleShowAttendance(),
            ),
            _buildSwitchTile(
              'Allow Messages',
              'Allow teachers to send you messages',
              _settingsLogic.allowMessages,
              () => _settingsLogic.toggleAllowMessages(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'App Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchTile(
              'Auto-Save Drafts',
              'Automatically save your work',
              _settingsLogic.autoSaveDrafts,
              () => _settingsLogic.toggleAutoSaveDrafts(),
            ),
            _buildSwitchTile(
              'Download Over WiFi Only',
              'Only download files when connected to WiFi',
              _settingsLogic.downloadOverWiFi,
              () => _settingsLogic.toggleDownloadOverWiFi(),
            ),
            _buildSwitchTile(
              'Show Notification Badge',
              'Show unread count on app icon',
              _settingsLogic.showNotificationBadge,
              () => _settingsLogic.toggleShowNotificationBadge(),
            ),
            _buildSwitchTile(
              'Sound Enabled',
              'Play sounds for notifications',
              _settingsLogic.soundEnabled,
              () => _settingsLogic.toggleSoundEnabled(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              'Change Password',
              'Update your account password',
              Icons.lock,
              Colors.orange,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change Password - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              Colors.blue,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy Policy - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Terms of Service',
              'Read our terms of service',
              Icons.description,
              Colors.green,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms of Service - Coming Soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'About',
              'Version 1.0.0',
              Icons.info,
              Colors.purple,
              () {
                _showAboutDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Reset to Defaults',
              'Reset all settings to default values',
              Icons.restore,
              Colors.red,
              () {
                _showResetDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_formatOption(option)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatOption(String option) {
    switch (option) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'auto':
        return 'Auto';
      case 'en':
        return 'English';
      case 'fil':
        return 'Filipino';
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      default:
        return option;
    }
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _settingsLogic.saveSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      },
      icon: const Icon(Icons.save),
      label: const Text('Save Settings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About OSHS ELMS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oro Site High School'),
            Text('E-Learning Management System'),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            Text('Build: 2024.1'),
            SizedBox(height: 16),
            Text('© 2024 Oro Site High School'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _settingsLogic.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
