import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';

class SectionsPopup extends StatelessWidget {
  const SectionsPopup({super.key});

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
              'Sections Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSectionItem(
            Icons.class_,
            'Manage All Sections',
            () {
              // TODO: Navigate to sections management screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sections management coming soon')),
              );
            },
          ),
          _buildSectionItem(
            Icons.add_circle_outline,
            'Create New Section',
            () {
              // TODO: Navigate to create section screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create section coming soon')),
              );
            },
          ),
          _buildSectionItem(
            Icons.supervisor_account,
            'Adviser Assignments',
            () {
              // TODO: Navigate to adviser assignments screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adviser assignments coming soon')),
              );
            },
          ),
          _buildSectionItem(
            Icons.grade,
            'Grade Levels',
            () {
              // TODO: Navigate to grade levels screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grade levels coming soon')),
              );
            },
          ),
          _buildSectionItem(
            Icons.settings,
            'Section Settings',
            () {
              // TODO: Navigate to section settings screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Section settings coming soon')),
              );
            },
          ),
          _buildSectionItem(
            Icons.analytics,
            'View Analytics',
            () {
              // TODO: Navigate to analytics screen
              PopupHelper.closePopup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(IconData icon, String label, VoidCallback? onTap) {
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