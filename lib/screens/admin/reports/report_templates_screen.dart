import 'package:flutter/material.dart';

class ReportTemplatesScreen extends StatelessWidget {
  const ReportTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = [
      {'name': 'Student Performance', 'description': 'Comprehensive student academic performance', 'category': 'Academic'},
      {'name': 'Course Enrollment', 'description': 'Course enrollment statistics and trends', 'category': 'Enrollment'},
      {'name': 'User Activity', 'description': 'System usage and user engagement metrics', 'category': 'System'},
      {'name': 'Financial Summary', 'description': 'Financial transactions and revenue reports', 'category': 'Financial'},
      {'name': 'Attendance Report', 'description': 'Student and staff attendance tracking', 'category': 'Academic'},
      {'name': 'Grade Distribution', 'description': 'Grade statistics across courses', 'category': 'Academic'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Report Templates')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Card(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Using template: ${template['name']}')));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            template['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      template['description'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(template['category'] as String, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.shade50,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
