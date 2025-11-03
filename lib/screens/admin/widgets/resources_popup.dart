import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';
import 'package:oro_site_high_school/screens/admin/resources/manage_resources_screen.dart';
import 'package:oro_site_high_school/screens/admin/resources/upload_resource_screen.dart';
import 'package:oro_site_high_school/screens/admin/resources/resource_categories_screen.dart';
import 'package:oro_site_high_school/screens/admin/resources/resource_library_screen.dart';
import 'package:oro_site_high_school/screens/admin/resources/resource_analytics_screen.dart';
import 'package:oro_site_high_school/screens/admin/assignments/assignment_management_screen.dart';

class ResourcesPopup extends StatelessWidget {
  const ResourcesPopup({super.key});

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
              'Resource Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildResourceItem(
            Icons.library_books,
            'Manage All Resources',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ManageResourcesScreen(),
            ),
          ),
          _buildResourceItem(
            Icons.upload_file,
            'Upload Resource',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const UploadResourceScreen(),
            ),
          ),
          _buildResourceItem(
            Icons.category,
            'Resource Categories',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ResourceCategoriesScreen(),
            ),
          ),
          _buildResourceItem(
            Icons.folder,
            'Resource Library',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ResourceLibraryScreen(),
            ),
          ),
          _buildResourceItem(
            Icons.analytics,
            'Resource Analytics',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ResourceAnalyticsScreen(),
            ),
          ),
          const Divider(height: 1),
          _buildResourceItem(
            Icons.assignment,
            'Assignment Management',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const AssignmentManagementScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(IconData icon, String label, VoidCallback? onTap) {
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
