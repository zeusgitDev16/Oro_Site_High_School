import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Phase 5 Task 9: Assignment Analytics Widget
/// 
/// Displays comprehensive analytics for an assignment including:
/// - Submission rate
/// - Average score
/// - Score distribution chart
/// - Late submissions count
/// - Missing submissions list
/// 
/// Small text UI matching gradebook style
class AssignmentAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic>? assignment;
  final List<Map<String, dynamic>> submissions;
  final List<Map<String, dynamic>> students;

  const AssignmentAnalyticsWidget({
    super.key,
    required this.assignment,
    required this.submissions,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    if (assignment == null) {
      return const Center(
        child: Text(
          'No assignment data available',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final submitted = submissions.where((s) => s['status'] == 'submitted').toList();
    final graded = submitted.where((s) => s['score'] != null).toList();
    final late = submitted.where((s) => (s['is_late'] ?? false) == true).toList();
    final totalStudents = students.length;
    final submissionRate = totalStudents > 0 ? (submitted.length / totalStudents * 100) : 0.0;
    
    // Calculate average score (only graded submissions)
    double avgScore = 0.0;
    if (graded.isNotEmpty) {
      final totalScore = graded.fold<double>(0.0, (sum, s) {
        final score = (s['score'] ?? 0).toDouble();
        final maxScore = (s['max_score'] ?? 1).toDouble();
        return sum + (maxScore > 0 ? (score / maxScore * 100) : 0);
      });
      avgScore = totalScore / graded.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Assignment Analytics',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Submission Rate',
                  '${submissionRate.toStringAsFixed(0)}%',
                  '${submitted.length}/${totalStudents}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Average Score',
                  graded.isEmpty ? 'N/A' : '${avgScore.toStringAsFixed(1)}%',
                  '${graded.length} graded',
                  Icons.grade,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Late & Missing Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Late Submissions',
                  '${late.length}',
                  '${(late.length / math.max(submitted.length, 1) * 100).toStringAsFixed(0)}% of submitted',
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Missing',
                  '${totalStudents - submitted.length}',
                  'Not submitted',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score Distribution Chart
          if (graded.isNotEmpty) ...[
            _buildScoreDistribution(graded),
            const SizedBox(height: 16),
          ],

          // Missing Submissions List
          if (totalStudents - submitted.length > 0) ...[
            _buildMissingList(submitted),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(List<Map<String, dynamic>> graded) {
    // Calculate score ranges: 0-59, 60-74, 75-84, 85-94, 95-100
    final ranges = {
      'Failed (0-59)': 0,
      'Passed (60-74)': 0,
      'Good (75-84)': 0,
      'Very Good (85-94)': 0,
      'Excellent (95-100)': 0,
    };

    for (final s in graded) {
      final score = (s['score'] ?? 0).toDouble();
      final maxScore = (s['max_score'] ?? 1).toDouble();
      final percentage = maxScore > 0 ? (score / maxScore * 100) : 0;

      if (percentage < 60) {
        ranges['Failed (0-59)'] = ranges['Failed (0-59)']! + 1;
      } else if (percentage < 75) {
        ranges['Passed (60-74)'] = ranges['Passed (60-74)']! + 1;
      } else if (percentage < 85) {
        ranges['Good (75-84)'] = ranges['Good (75-84)']! + 1;
      } else if (percentage < 95) {
        ranges['Very Good (85-94)'] = ranges['Very Good (85-94)']! + 1;
      } else {
        ranges['Excellent (95-100)'] = ranges['Excellent (95-100)']! + 1;
      }
    }

    final maxCount = ranges.values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              const Text(
                'Score Distribution',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ranges.entries.map((entry) {
            final percentage = maxCount > 0 ? (entry.value / maxCount) : 0.0;
            Color barColor;
            if (entry.key.startsWith('Failed')) {
              barColor = Colors.red;
            } else if (entry.key.startsWith('Passed')) {
              barColor = Colors.orange;
            } else if (entry.key.startsWith('Good')) {
              barColor = Colors.blue;
            } else if (entry.key.startsWith('Very Good')) {
              barColor = Colors.green;
            } else {
              barColor = Colors.purple;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissingList(List<Map<String, dynamic>> submitted) {
    final submittedIds = submitted.map((s) => s['student_id'].toString()).toSet();
    final missing = students
        .where((st) => !submittedIds.contains((st['student_id'] ?? st['id']).toString()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Text(
                'Missing Submissions (${missing.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...missing.take(10).map((st) {
            final name = st['full_name'] ?? 'Unknown Student';
            final email = st['email'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (missing.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... and ${missing.length - 10} more',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
