
import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/admin/settings/system_settings_screen.dart';
import 'package:oro_site_high_school/screens/admin/requests/teacher_requests_screen.dart';
import 'package:oro_site_high_school/screens/admin/permissions/permission_management_screen.dart';

void showAdminMenuDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Admin Menu'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Teacher Requests'),
                subtitle: const Text('Review and respond to requests'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherRequestsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Permission Management'),
                subtitle: const Text('Manage user permissions and roles'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PermissionManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('System Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SystemSettingsScreen()),
                  );
                },
              ),
              const ListTile(leading: Icon(Icons.people), title: Text('User Management')),
              const ListTile(leading: Icon(Icons.school), title: Text('Course Management')),
              const ListTile(leading: Icon(Icons.bar_chart), title: Text('Reporting Tools')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
