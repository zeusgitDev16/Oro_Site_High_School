import 'package:flutter/material.dart';

class GradeLevelAnalyticsScreen extends StatelessWidget {
  const GradeLevelAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade 7 Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export Analytics - Coming Soon'),
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
            _buildOverallMetrics(),
            const SizedBox(height: 24),
            _buildSectionComparison(),
            const SizedBox(height: 24),
            _buildPerformanceTrends(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Grade',
                '87.0',
                Icons.grade,
                Colors.blue,
                '+2.5 from last quarter',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Attendance',
                '92%',
                Icons.fact_check,
                Colors.green,
                '+3% from last month',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Passing Rate',
                '96%',
                Icons.check_circle,
                Colors.purple,
                '202 of 210 students',
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(24),
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

  Widget _buildSectionComparison() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Section Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSectionBar('7-Amethyst', 87.5, 92, Colors.purple),
            const SizedBox(height: 16),
            _buildSectionBar('7-Bronze', 85.2, 90, Colors.brown),
            const SizedBox(height: 16),
            _buildSectionBar('7-Copper', 88.1, 93, Colors.orange),
            const SizedBox(height: 16),
            _buildSectionBar('7-Diamond', 89.3, 94, Colors.blue),
            const SizedBox(height: 16),
            _buildSectionBar('7-Emerald', 86.7, 91, Colors.green),
            const SizedBox(height: 16),
            _buildSectionBar('7-Feldspar', 84.9, 89, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBar(
      String section, double grade, int attendance, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Grade: ',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              grade.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: grade / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Attendance: ',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              '$attendance%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: attendance / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceTrends() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTrendItem('Q1', 84.5, Colors.blue),
            const SizedBox(height: 16),
            _buildTrendItem('Q2', 87.0, Colors.green),
            const SizedBox(height: 16),
            _buildTrendItem('Q3 (Projected)', 88.5, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String quarter, double grade, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            quarter,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    grade.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (quarter != 'Q1')
                    Icon(Icons.trending_up, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: grade / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
