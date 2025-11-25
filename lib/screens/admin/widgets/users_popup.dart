import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';
import 'package:oro_site_high_school/screens/admin/users/manage_users_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/user_roles_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/user_analytics_screen.dart';

class UsersPopup extends StatelessWidget {
  const UsersPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'User Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _buildUserItem(
            Icons.people,
            'Manage All Users',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ManageUsersScreen(),
            ),
          ),
          _buildUserItem(
            Icons.admin_panel_settings,
            'Roles & Permissions',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const UserRolesScreen(),
            ),
          ),
          _buildUserItem(
            Icons.analytics,
            'User Analytics',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const UserAnalyticsScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
