import 'package:flutter/material.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_status_selector.dart';

/// Compact attendance grid panel displaying students with status selectors
///
/// **Features:**
/// - Scrollable student list
/// - Columns: Avatar | Name | LRN | Status | Remarks
/// - Compact row height (36px)
/// - Alternating row colors
/// - Hover effects
///
/// **Usage:**
/// ```dart
/// AttendanceGridPanel(
///   students: _students,
///   attendanceStatus: _attendanceStatus,
///   onStatusChanged: (studentId, status) {
///     setState(() => _attendanceStatus[studentId] = status);
///   },
///   isReadOnly: false,
/// )
/// ```
class AttendanceGridPanel extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final Map<String, String> attendanceStatus;
  final Function(String studentId, String status) onStatusChanged;
  final bool isReadOnly;

  const AttendanceGridPanel({
    super.key,
    required this.students,
    required this.attendanceStatus,
    required this.onStatusChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  /// Build header row
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // Avatar column
          const SizedBox(width: 40),
          const SizedBox(width: 12),

          // Name column
          const Expanded(
            flex: 3,
            child: Text(
              'Student Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // LRN column
          const Expanded(
            flex: 2,
            child: Text(
              'LRN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Status column
          SizedBox(
            width: 140,
            child: Text(
              'Status',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Remarks column
          const Expanded(
            flex: 2,
            child: Text(
              'Remarks',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build student list
  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['id'] as String;
        final status = attendanceStatus[studentId];
        final isEvenRow = index % 2 == 0;

        return _buildStudentRow(
          student: student,
          studentId: studentId,
          status: status,
          isEvenRow: isEvenRow,
        );
      },
    );
  }

  /// Build individual student row
  Widget _buildStudentRow({
    required Map<String, dynamic> student,
    required String studentId,
    String? status,
    required bool isEvenRow,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isEvenRow ? Colors.white : Colors.grey.shade50,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              _getInitials(student['full_name'] ?? 'Unknown'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            flex: 3,
            child: Text(
              student['full_name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // LRN
          Expanded(
            flex: 2,
            child: Text(
              student['lrn'] ?? 'N/A',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status Selector
          SizedBox(
            width: 140,
            child: AttendanceStatusSelector(
              status: status,
              onStatusChanged: (newStatus) {
                if (!isReadOnly) {
                  onStatusChanged(studentId, newStatus);
                }
              },
              isEnabled: !isReadOnly,
            ),
          ),

          // Remarks (placeholder for now)
          Expanded(
            flex: 2,
            child: Text(
              student['remarks'] ?? '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No students to display',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get initials from full name
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

