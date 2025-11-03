import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';
import 'package:oro_site_high_school/screens/admin/attendance/create_attendance_session_screen.dart';
import 'package:oro_site_high_school/screens/admin/attendance/attendance_records_screen.dart';
import 'package:oro_site_high_school/screens/admin/attendance/scanning_permissions_screen.dart';
import 'package:oro_site_high_school/screens/admin/attendance/attendance_reports_screen.dart';
import 'package:oro_site_high_school/screens/admin/attendance/active_sessions_screen.dart';

class AttendancePopup extends StatelessWidget {
  const AttendancePopup({super.key});

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
              'Attendance Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildAttendanceItem(
            Icons.add_circle_outline,
            'Create Attendance Session',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const CreateAttendanceSessionScreen(),
            ),
          ),
          _buildAttendanceItem(
            Icons.access_time,
            'Active Sessions',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ActiveSessionsScreen(),
            ),
          ),
          _buildAttendanceItem(
            Icons.fact_check,
            'View Attendance Records',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const AttendanceRecordsScreen(),
            ),
          ),
          _buildAttendanceItem(
            Icons.qr_code_scanner,
            'Manage Scanning Permissions',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const ScanningPermissionsScreen(),
            ),
          ),
          _buildAttendanceItem(
            Icons.assessment,
            'Attendance Reports',
            () => PopupHelper.navigateAndClosePopup(
              context,
              const AttendanceReportsScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(IconData icon, String label, VoidCallback? onTap) {
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
