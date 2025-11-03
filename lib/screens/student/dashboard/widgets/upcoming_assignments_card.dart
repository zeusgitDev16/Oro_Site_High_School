import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_dashboard_logic.dart';
import 'package:intl/intl.dart';

/// Upcoming Assignments Card Widget
/// Displays assignments due soon - UI only
class UpcomingAssignmentsCard extends StatelessWidget {
  final StudentDashboardLogic logic;

  const UpcomingAssignmentsCard({
    super.key,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final assignments = logic.dashboardData['upcomingAssignments'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Upcoming Assignments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to assignments screen
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 24),
            if (assignments.isEmpty)
              _buildEmptyState()
            else
              ...assignments.map((assignment) => _buildAssignmentItem(assignment)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No upcoming assignments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentItem(Map<String, dynamic> assignment) {
    final dueDate = DateTime.parse(assignment['dueDate']);
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final daysUntilDue = difference.inDays;
    
    Color statusColor = Colors.green;
    String statusText = 'Not Started';
    
    if (assignment['status'] == 'in_progress') {
      statusColor = Colors.blue;
      statusText = 'In Progress';
    } else if (assignment['status'] == 'submitted') {
      statusColor = Colors.purple;
      statusText = 'Submitted';
    }

    Color dueDateColor = Colors.grey.shade700;
    if (daysUntilDue <= 1) {
      dueDateColor = Colors.red;
    } else if (daysUntilDue <= 3) {
      dueDateColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.book, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                assignment['course'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: dueDateColor),
              const SizedBox(width: 4),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: dueDateColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              if (daysUntilDue >= 0)
                Text(
                  '(${daysUntilDue == 0 ? 'Today' : daysUntilDue == 1 ? 'Tomorrow' : '$daysUntilDue days'})',
                  style: TextStyle(
                    fontSize: 12,
                    color: dueDateColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${assignment['pointsPossible']} points',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
