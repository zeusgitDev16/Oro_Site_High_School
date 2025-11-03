import 'package:flutter/material.dart';

class CourseGradesTab extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseGradesTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildGradeStatistics(),
          const SizedBox(height: 24),
          _buildGradeDistribution(),
          const SizedBox(height: 24),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Grade Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        DropdownButton<String>(
          value: 'Q2',
          items: ['Q1', 'Q2', 'Q3', 'Q4']
              .map((quarter) => DropdownMenuItem(
                    value: quarter,
                    child: Text(quarter),
                  ))
              .toList(),
          onChanged: (value) {},
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Grade Entry - Coming Soon'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Enter Grades'),
          style: ElevatedButton.styleFrom(
            backgroundColor: course['color'],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Class Average',
            '${course['averageGrade']}',
            Icons.grade,
            Colors.blue,
            'DepEd Scale',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Passing Rate',
            '94%',
            Icons.check_circle,
            Colors.green,
            '33 of 35 students',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Highest Grade',
            '98.5',
            Icons.trending_up,
            Colors.purple,
            'Outstanding',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Lowest Grade',
            '72.0',
            Icons.trending_down,
            Colors.orange,
            'Needs Improvement',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistribution() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDistributionBar('Outstanding (90-100)', 12, 35, Colors.green),
            const SizedBox(height: 16),
            _buildDistributionBar('Very Satisfactory (85-89)', 15, 35, Colors.blue),
            const SizedBox(height: 16),
            _buildDistributionBar('Satisfactory (80-84)', 6, 35, Colors.orange),
            const SizedBox(height: 16),
            _buildDistributionBar('Fairly Satisfactory (75-79)', 2, 35, Colors.amber),
            const SizedBox(height: 16),
            _buildDistributionBar('Did Not Meet (Below 75)', 0, 35, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '$count students',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($percentage%)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: count / total,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Enter Grades',
                Icons.edit,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'View Grade Book',
                Icons.book,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Export Grades',
                Icons.download,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Grade Reports',
                Icons.assessment,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label - Coming Soon'),
            backgroundColor: Colors.blue,
          ),
        );
      },
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
