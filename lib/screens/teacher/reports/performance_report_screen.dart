import 'package:flutter/material.dart';

class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({super.key});

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  String _selectedCourse = 'Mathematics 7';

  final List<String> _courses = ['Mathematics 7', 'Science 7'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export to Excel - Coming Soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilter(),
            const SizedBox(height: 24),
            _buildOverallMetrics(),
            const SizedBox(height: 24),
            _buildPerformanceByCategory(),
            const SizedBox(height: 24),
            _buildStudentPerformance(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      decoration: const InputDecoration(
        labelText: 'Course',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.school),
      ),
      items: _courses
          .map((course) => DropdownMenuItem(
                value: course,
                child: Text(course),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCourse = value!;
        });
      },
    );
  }

  Widget _buildOverallMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Overall Performance',
            '87.5',
            Icons.trending_up,
            Colors.blue,
            'Class Average',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Improvement Rate',
            '+5.2%',
            Icons.arrow_upward,
            Colors.green,
            'From last quarter',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Completion Rate',
            '85%',
            Icons.assignment_turned_in,
            Colors.purple,
            'Assignments',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceByCategory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildCategoryBar('Written Works (30%)', 86, Colors.blue),
            const SizedBox(height: 16),
            _buildCategoryBar('Performance Tasks (50%)', 89, Colors.green),
            const SizedBox(height: 16),
            _buildCategoryBar('Quarterly Assessment (20%)', 85, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
        ),
      ],
    );
  }

  Widget _buildStudentPerformance() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceCard('Excellent (90-100)', 12, Colors.green),
            _buildPerformanceCard('Very Good (85-89)', 15, Colors.blue),
            _buildPerformanceCard('Good (80-84)', 6, Colors.orange),
            _buildPerformanceCard('Satisfactory (75-79)', 2, Colors.amber),
            _buildPerformanceCard('Needs Improvement (<75)', 0, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${(count / 35 * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
