import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';
import 'package:oro_site_high_school/screens/admin/users/manage_users_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/enhanced_add_user_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/user_roles_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/bulk_operations_screen.dart';
import 'package:oro_site_high_school/screens/admin/users/user_analytics_screen.dart';
import 'package:oro_site_high_school/screens/admin/progress/student_progress_dashboard.dart';
import 'package:oro_site_high_school/screens/admin/progress/section_progress_dashboard.dart';

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
            Icons.person_add,
            'Add New User',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const EnhancedAddUserScreen(),
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
            Icons.upload_file,
            'Bulk Operations',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const BulkOperationsScreen(),
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
          const Divider(height: 1),
          _buildUserItem(
            Icons.trending_up,
            'Student Progress',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const StudentProgressDashboard(),
            ),
          ),
          _buildUserItem(
            Icons.class_,
            'Section Progress',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const SectionProgressDashboard(),
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
