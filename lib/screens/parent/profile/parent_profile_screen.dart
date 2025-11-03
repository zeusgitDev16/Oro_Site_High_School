import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_profile_logic.dart';
import 'package:oro_site_high_school/screens/parent/messaging/parent_messages_screen.dart';
import 'package:oro_site_high_school/screens/parent/messaging/parent_notifications_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';

/// Parent Profile Screen - View and edit parent profile
/// UI only - interactive logic in ParentProfileLogic
class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen>
    with SingleTickerProviderStateMixin {
  final ParentProfileLogic _logic = ParentProfileLogic();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _logic.loadProfileData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          return Column(
            children: [
              _buildProfileHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalInfoTab(),
                    _buildNotificationPreferencesTab(),
                    _buildAccountSettingsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _logic.profileData;
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange,
            child: Text(
              _logic.getInitials(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _logic.getFullName(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile['email'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile['phone'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.orange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.orange,
        tabs: const [
          Tab(
            icon: Icon(Icons.person),
            text: 'Personal Info',
          ),
          Tab(
            icon: Icon(Icons.notifications),
            text: 'Notifications',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    final profile = _logic.profileData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Personal Information',
            Icons.person,
            [
              _buildInfoRow('First Name', profile['firstName']),
              _buildInfoRow('Last Name', profile['lastName']),
              _buildInfoRow('Email', profile['email']),
              _buildInfoRow('Phone', profile['phone']),
              _buildInfoRow('Address', profile['address']),
              _buildInfoRow('Emergency Contact', profile['emergencyContact']),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Children Information',
            Icons.family_restroom,
            [
              _buildChildrenList(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesTab() {
    final preferences = _logic.notificationPreferences;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Notification Preferences',
            Icons.notifications_active,
            [
              _buildSwitchTile(
                'Grade Updates',
                'Receive notifications when grades are posted',
                preferences['gradeUpdates'] ?? false,
                (value) => _logic.updateNotificationPreference('gradeUpdates', value),
              ),
              _buildSwitchTile(
                'Attendance Alerts',
                'Get notified about attendance issues',
                preferences['attendanceAlerts'] ?? false,
                (value) => _logic.updateNotificationPreference('attendanceAlerts', value),
              ),
              _buildSwitchTile(
                'Assignment Reminders',
                'Reminders for upcoming assignments',
                preferences['assignmentReminders'] ?? false,
                (value) => _logic.updateNotificationPreference('assignmentReminders', value),
              ),
              _buildSwitchTile(
                'School Announcements',
                'Important school-wide announcements',
                preferences['schoolAnnouncements'] ?? false,
                (value) => _logic.updateNotificationPreference('schoolAnnouncements', value),
              ),
              _buildSwitchTile(
                'Behavior Reports',
                'Notifications about behavior incidents',
                preferences['behaviorReports'] ?? false,
                (value) => _logic.updateNotificationPreference('behaviorReports', value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Delivery Methods',
            Icons.send,
            [
              _buildSwitchTile(
                'Email Notifications',
                'Receive notifications via email',
                preferences['emailNotifications'] ?? false,
                (value) => _logic.updateNotificationPreference('emailNotifications', value),
              ),
              _buildSwitchTile(
                'SMS Notifications',
                'Receive notifications via SMS',
                preferences['smsNotifications'] ?? false,
                (value) => _logic.updateNotificationPreference('smsNotifications', value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Security',
            Icons.security,
            [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.orange),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'About',
            Icons.info,
            [
              _buildInfoRow('App Version', '1.0.0'),
              _buildInfoRow('Last Updated', 'January 2024'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    // Mock children data
    final children = [
      {'name': 'Juan Dela Cruz', 'grade': 7, 'section': 'Diamond'},
      {'name': 'Maria Dela Cruz', 'grade': 9, 'section': 'Sapphire'},
    ];
    
    return Column(
      children: children.map((child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange,
                child: Text(
                  child['name'].toString().split(' ')[0][0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child['name'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Grade ${child['grade']} - ${child['section']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.orange,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showEditProfileDialog() {
    final profile = _logic.profileData;
    final firstNameController = TextEditingController(text: profile['firstName']);
    final lastNameController = TextEditingController(text: profile['lastName']);
    final phoneController = TextEditingController(text: profile['phone']);
    final addressController = TextEditingController(text: profile['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _logic.updateProfile({
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'phone': phoneController.text,
                'address': addressController.text,
              }).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _logic.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              ).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
