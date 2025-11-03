import 'package:flutter/material.dart';

class AttendanceReportsScreen extends StatelessWidget {
  const AttendanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildReportCard(
            context,
            icon: Icons.calendar_today,
            title: 'Daily Attendance Report',
            description: 'View attendance for a specific day',
            color: Colors.blue,
          ),
          _buildReportCard(
            context,
            icon: Icons.date_range,
            title: 'Weekly Attendance Report',
            description: 'View attendance for the current week',
            color: Colors.green,
          ),
          _buildReportCard(
            context,
            icon: Icons.calendar_month,
            title: 'Monthly Attendance Report',
            description: 'View attendance for the current month',
            color: Colors.orange,
          ),
          _buildReportCard(
            context,
            icon: Icons.person,
            title: 'Student Attendance Summary',
            description: 'View individual student attendance statistics',
            color: Colors.purple,
          ),
          _buildReportCard(
            context,
            icon: Icons.class_,
            title: 'Section Attendance Summary',
            description: 'View attendance statistics by section',
            color: Colors.teal,
          ),
          _buildReportCard(
            context,
            icon: Icons.download,
            title: 'Export to Excel',
            description: 'Download attendance data in Excel format',
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generating $title...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
