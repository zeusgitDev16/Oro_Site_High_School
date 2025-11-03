import 'package:flutter/material.dart';

class SystemAccessTab extends StatelessWidget {
  const SystemAccessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Access',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildRolesCard(),
          const SizedBox(height: 16),
          _buildPermissionsCard(),
          const SizedBox(height: 16),
          _buildAccessLevelsCard(),
        ],
      ),
    );
  }

  Widget _buildRolesCard() {
    final roles = [
      {'name': 'Administrator', 'description': 'Full system access and control', 'active': true},
      {'name': 'User Manager', 'description': 'Can create and manage user accounts', 'active': true},
      {'name': 'Grade Manager', 'description': 'Can view and edit student grades', 'active': true},
      {'name': 'Report Viewer', 'description': 'Can generate and view reports', 'active': true},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Assigned Roles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...roles.map((role) => _buildRoleItem(role)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleItem(Map<String, dynamic> role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(
          Icons.verified_user,
          color: role['active'] ? Colors.blue : Colors.grey,
        ),
        title: Text(
          role['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(role['description'] as String),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final permissions = [
      {'module': 'User Management', 'permissions': ['Create', 'Read', 'Update', 'Delete']},
      {'module': 'Course Management', 'permissions': ['Create', 'Read', 'Update', 'Delete']},
      {'module': 'Grade Management', 'permissions': ['Create', 'Read', 'Update', 'Delete']},
      {'module': 'Attendance', 'permissions': ['Create', 'Read', 'Update', 'Delete']},
      {'module': 'Reports', 'permissions': ['Read', 'Export']},
      {'module': 'System Settings', 'permissions': ['Read', 'Update']},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...permissions.map((perm) => _buildPermissionItem(perm)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(Map<String, dynamic> permission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  permission['module'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (permission['permissions'] as List<String>).map((perm) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPermissionColor(perm),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    perm,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPermissionColor(String permission) {
    switch (permission) {
      case 'Create':
        return Colors.green;
      case 'Read':
        return Colors.blue;
      case 'Update':
        return Colors.orange;
      case 'Delete':
        return Colors.red;
      case 'Export':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAccessLevelsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Access Levels',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAccessLevelItem(
              'System Administration',
              'Full access to all system features and settings',
              Icons.admin_panel_settings,
              Colors.red,
            ),
            _buildAccessLevelItem(
              'Data Management',
              'Can manage all student and course data',
              Icons.storage,
              Colors.blue,
            ),
            _buildAccessLevelItem(
              'User Management',
              'Can create and manage user accounts',
              Icons.people,
              Colors.green,
            ),
            _buildAccessLevelItem(
              'Reporting',
              'Can generate and export system reports',
              Icons.assessment,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessLevelItem(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(description),
        trailing: Icon(Icons.check_circle, color: Colors.green.shade700),
      ),
    );
  }
}
