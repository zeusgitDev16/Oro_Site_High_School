import 'package:flutter/material.dart';

/// Small card showing attendance statistics
///
/// **Features:**
/// - Total students count
/// - Present, Absent, Late, Excused counts
/// - Percentage display
/// - Color-coded indicators
///
/// **Usage:**
/// ```dart
/// AttendanceSummaryCard(
///   totalStudents: 35,
///   presentCount: 30,
///   absentCount: 3,
///   lateCount: 2,
///   excusedCount: 0,
/// )
/// ```
class AttendanceSummaryCard extends StatelessWidget {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;

  const AttendanceSummaryCard({
    super.key,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
  });

  /// Calculate percentage
  String _getPercentage(int count) {
    if (totalStudents == 0) return '0%';
    return '${((count / totalStudents) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    if (totalStudents == 0) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Total Students
          _buildStatItem(
            icon: Icons.people,
            label: 'Total',
            count: totalStudents,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 24),

          // Present
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Present',
            count: presentCount,
            percentage: _getPercentage(presentCount),
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 24),

          // Absent
          _buildStatItem(
            icon: Icons.cancel,
            label: 'Absent',
            count: absentCount,
            percentage: _getPercentage(absentCount),
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 24),

          // Late
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Late',
            count: lateCount,
            percentage: _getPercentage(lateCount),
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 24),

          // Excused
          _buildStatItem(
            icon: Icons.event_busy,
            label: 'Excused',
            count: excusedCount,
            percentage: _getPercentage(excusedCount),
            color: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int count,
    String? percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (percentage != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($percentage)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'No attendance data available',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

