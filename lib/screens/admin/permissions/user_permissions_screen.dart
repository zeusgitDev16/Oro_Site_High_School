import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/enhanced_permission_service.dart';

/// User Permissions Screen
/// Manage permissions for a specific user
/// UI-only component following OSHS architecture
class UserPermissionsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const UserPermissionsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  final EnhancedPermissionService _permissionService = EnhancedPermissionService();
  Map<String, List<Map<String, String>>>? _categories;
  List<String>? _userPermissions;
  bool _isLoading = true;
  bool _isSaving = false;
  final Set<String> _modifiedPermissions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _permissionService.getPermissionCategories();
      final permissions = await _permissionService.getUserPermissions(widget.userId);

      setState(() {
        _categories = categories;
        _userPermissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} - Permissions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_modifiedPermissions.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(),
                  const SizedBox(height: 24),
                  _buildRoleTemplates(),
                  const SizedBox(height: 32),
                  _buildPermissionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
              widget.userName.split(' ').map((n) => n[0]).join(),
              style: const TextStyle(
              color: Color(0xFF512DA8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userRole,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.vpn_key, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${_userPermissions?.length ?? 0} permissions assigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_modifiedPermissions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_modifiedPermissions.length} unsaved changes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTemplates() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Apply Role Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Apply a predefined role template to quickly set permissions',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildRoleTemplateChip('Admin', 'admin', Colors.deepPurple),
                _buildRoleTemplateChip('Teacher', 'teacher', Colors.green),
                _buildRoleTemplateChip('Coordinator', 'coordinator', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTemplateChip(String label, String roleKey, Color color) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(Icons.badge, size: 18, color: color),
      onPressed: () => _applyRoleTemplate(roleKey, label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPermissionsList() {
    if (_categories == null || _userPermissions == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissions by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._categories!.entries.map((entry) => _buildCategoryCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCategoryCard(String category, List<Map<String, String>> permissions) {
    final categoryPermissions = permissions.map((p) => p['id']!).toList();
    final enabledCount = categoryPermissions.where((p) => _userPermissions!.contains(p)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$enabledCount of ${permissions.length} enabled',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          children: permissions.map((perm) {
            final permId = perm['id']!;
            final isEnabled = _userPermissions!.contains(permId);

            return CheckboxListTile(
              value: isEnabled,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _userPermissions!.add(permId);
                  } else {
                    _userPermissions!.remove(permId);
                  }
                  _modifiedPermissions.add(permId);
                });
              },
              title: Text(
                perm['name']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                perm['description']!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              secondary: Icon(
                isEnabled ? Icons.check_circle : Icons.circle_outlined,
                color: isEnabled ? Colors.green : Colors.grey.shade400,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _applyRoleTemplate(String roleKey, String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Role Template'),
        content: Text(
          'This will replace all current permissions with the $roleName template. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _permissionService.applyRoleTemplate(widget.userId, roleKey);
      await _loadData();
      _modifiedPermissions.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$roleName template applied successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _permissionService.setUserPermissions(widget.userId, _userPermissions!);
      _modifiedPermissions.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
