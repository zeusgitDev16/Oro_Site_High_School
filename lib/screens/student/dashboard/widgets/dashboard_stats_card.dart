import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_dashboard_logic.dart';

/// Dashboard Stats Card Widget
/// Displays recent grades and attendance summary - UI only
class DashboardStatsCard extends StatelessWidget {
  final StudentDashboardLogic logic;

  const DashboardStatsCard({
    super.key,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final recentGrades = logic.dashboardData['recentGrades'] as List;
    final attendanceSummary = logic.dashboardData['attendanceSummary'] as Map<String, dynamic>;

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
                Icon(Icons.analytics, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Recent Grades Section
            const Text(
              'Recent Grades',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (recentGrades.isEmpty)
              _buildEmptyGrades()
            else
              ...recentGrades.map((grade) => _buildGradeItem(grade)),
            
            const SizedBox(height: 20),
            
            // Attendance Summary Section
            const Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAttendanceSummary(attendanceSummary),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to grades screen
                },
                child: const Text('View All Grades'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGrades() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No grades yet',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildGradeItem(Map<String, dynamic> grade) {
    final percentage = grade['percentage'] as num;
    Color gradeColor = Colors.green;
    
    if (percentage < 75) {
      gradeColor = Colors.red;
    } else if (percentage < 85) {
      gradeColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade['assignmentTitle'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  grade['course'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${grade['pointsEarned']}/${grade['pointsPossible']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(Map<String, dynamic> summary) {
    final percentage = summary['percentage'] as num;
    Color percentageColor = Colors.green;
    
    if (percentage < 75) {
      percentageColor = Colors.red;
    } else if (percentage < 90) {
      percentageColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttendanceItem(
                'Present',
                '${summary['present']}',
                Colors.green,
              ),
              _buildAttendanceItem(
                'Late',
                '${summary['late']}',
                Colors.orange,
              ),
              _buildAttendanceItem(
                'Absent',
                '${summary['absent']}',
                Colors.red,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Rate',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: percentageColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
