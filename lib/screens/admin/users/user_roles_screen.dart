import 'package:flutter/material.dart';

class UserRolesScreen extends StatefulWidget {
  const UserRolesScreen({super.key});

  @override
  State<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends State<UserRolesScreen> {
  // Mock data - ready for backend connection
  final List<Map<String, dynamic>> _roles = [
    {
      'name': 'Student',
      'userCount': 980,
      'permissions': [
        'View courses',
        'Submit assignments',
        'Join groups',
        'View grades',
      ],
    },
    {
      'name': 'Teacher',
      'userCount': 45,
      'permissions': [
        'Create courses',
        'Grade assignments',
        'Manage groups',
        'View analytics',
        'Message students',
      ],
    },
    {
      'name': 'Admin',
      'userCount': 12,
      'permissions': [
        'Full system access',
        'Manage users',
        'System settings',
        'View all analytics',
        'Manage courses',
      ],
    },
    {
      'name': 'Parent',
      'userCount': 208,
      'permissions': [
        'View child progress',
        'Message teachers',
        'View grades',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final role = _roles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Icon(
                _getRoleIcon(role['name']),
                color: _getRoleColor(role['name']),
              ),
              title: Text(
                role['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${role['userCount']} users'),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(role['permissions'] as List<String>).map((permission) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(permission),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditPermissionsDialog(role),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Permissions'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Role'),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Student':
        return Icons.school;
      case 'Teacher':
        return Icons.person;
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Parent':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student':
        return Colors.blue;
      case 'Teacher':
        return Colors.green;
      case 'Admin':
        return Colors.purple;
      case 'Parent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showEditPermissionsDialog(Map<String, dynamic> role) {
    final List<String> allPermissions = [
      'View courses',
      'Create courses',
      'Edit courses',
      'Delete courses',
      'View users',
      'Manage users',
      'View analytics',
      'System settings',
      'Grade assignments',
      'Submit assignments',
      'Join groups',
      'Manage groups',
      'Message students',
      'Message teachers',
      'View grades',
      'View child progress',
    ];

    final selectedPermissions = List<String>.from(role['permissions']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${role['name']} Permissions'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allPermissions.length,
              itemBuilder: (context, index) {
                final permission = allPermissions[index];
                final isSelected = selectedPermissions.contains(permission);
                return CheckboxListTile(
                  title: Text(permission),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedPermissions.add(permission);
                      } else {
                        selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement backend update
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Permissions updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoleDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can configure permissions after creating the role.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement backend save
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom role created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
