import 'package:flutter/material.dart';

class ScheduledReportsScreen extends StatefulWidget {
  const ScheduledReportsScreen({super.key});

  @override
  State<ScheduledReportsScreen> createState() => _ScheduledReportsScreenState();
}

class _ScheduledReportsScreenState extends State<ScheduledReportsScreen> {
  final List<Map<String, dynamic>> _scheduledReports = [
    {'id': 1, 'title': 'Weekly Performance Report', 'frequency': 'Weekly', 'nextRun': '2024-01-27', 'active': true, 'recipients': 3},
    {'id': 2, 'title': 'Monthly Enrollment Summary', 'frequency': 'Monthly', 'nextRun': '2024-02-01', 'active': true, 'recipients': 5},
    {'id': 3, 'title': 'Daily Activity Log', 'frequency': 'Daily', 'nextRun': '2024-01-21', 'active': false, 'recipients': 2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Reports')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduledReports.length,
        itemBuilder: (context, index) {
          final report = _scheduledReports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: report['active'] ? Colors.green : Colors.grey,
                child: Icon(Icons.schedule, color: Colors.white),
              ),
              title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Frequency: ${report['frequency']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Next run: ${report['nextRun']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('${report['recipients']} recipients', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: report['active'],
                    onChanged: (value) => setState(() => report['active'] = value),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'run', child: Row(children: [Icon(Icons.play_arrow, size: 18), SizedBox(width: 8), Text('Run Now')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(report['title']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value ${report['title']}')));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Report'),
      ),
    );
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule New Report'),
        content: const Text('Schedule report dialog will be implemented here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Report scheduled successfully')));
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheduled Report'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Scheduled report deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
