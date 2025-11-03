import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';
import 'package:oro_site_high_school/screens/admin/reports/admin_reports_screen.dart';
import 'package:oro_site_high_school/screens/admin/reports/grade_reports_screen.dart';
import 'package:oro_site_high_school/screens/admin/reports/enrollment_reports_screen.dart';
import 'package:oro_site_high_school/screens/admin/reports/teacher_performance_screen.dart';
import 'package:oro_site_high_school/screens/admin/reports/archive_management_screen.dart';
import 'package:oro_site_high_school/screens/admin/grades/grade_management_screen.dart';

class ReportsPopup extends StatelessWidget {
  const ReportsPopup({super.key});

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
              'Reports & Archives',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildReportItem(
            Icons.analytics,
            'Reports & Analytics',
            'Comprehensive reporting dashboard',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const AdminReportsScreen(),
            ),
          ),
          const Divider(height: 1),
          _buildReportItem(
            Icons.grade,
            'Grade Reports',
            'Student grades and performance',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const GradeReportsScreen(),
            ),
          ),
          _buildReportItem(
            Icons.edit_note,
            'Grade Management',
            'View and edit student grades',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const GradeManagementScreen(),
            ),
          ),
          _buildReportItem(
            Icons.people,
            'Enrollment Reports',
            'Student enrollment statistics',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const EnrollmentReportsScreen(),
            ),
          ),
          _buildReportItem(
            Icons.school,
            'Teacher Performance',
            'Teaching load and performance',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const TeacherPerformanceScreen(),
            ),
          ),
          const Divider(height: 1),
          _buildReportItem(
            Icons.archive,
            'Archive Management',
            'School year archives (S.Y. 2024, 2025...)',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ArchiveManagementScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    IconData icon,
    String label,
    String description,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
