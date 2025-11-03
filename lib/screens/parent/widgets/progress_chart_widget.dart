import 'package:flutter/material.dart';

/// Progress Chart Widget - Displays progress charts and analytics
/// Reusable widget for progress visualization
class ProgressChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String type; // 'grade' or 'attendance'

  const ProgressChartWidget({
    super.key,
    required this.title,
    required this.data,
    this.type = 'grade',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        _buildSimpleChart(),
      ],
    );
  }

  Widget _buildSimpleChart() {
    if (data.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) => _buildBar(item)).toList(),
      ),
    );
  }

  Widget _buildBar(Map<String, dynamic> item) {
    final value = type == 'grade' 
        ? (item['grade'] as double) 
        : (item['percentage'] as double);
    final label = type == 'grade' 
        ? (item['quarter'] as String) 
        : (item['month'] as String);
    
    final color = _getColor(value);
    final height = (value / 100) * 100; // Max height 100px
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.length > 3 ? label.substring(0, 3) : label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(double value) {
    if (type == 'grade') {
      if (value >= 90) return Colors.green;
      if (value >= 75) return Colors.orange;
      return Colors.red;
    } else {
      // attendance
      if (value >= 95) return Colors.green;
      if (value >= 85) return Colors.orange;
      return Colors.red;
    }
  }
}
