import 'package:flutter/material.dart';

class AttendanceRecordsScreen extends StatelessWidget {
  const AttendanceRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement export to Excel
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting to Excel...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRecordCard(
            studentName: 'Juan Dela Cruz',
            lrn: '123456789012',
            date: 'Dec 18, 2024',
            timeIn: '7:05 AM',
            status: 'Present',
            statusColor: Colors.green,
          ),
          _buildRecordCard(
            studentName: 'Maria Santos',
            lrn: '123456789013',
            date: 'Dec 18, 2024',
            timeIn: '7:18 AM',
            status: 'Late',
            statusColor: Colors.orange,
          ),
          _buildRecordCard(
            studentName: 'Pedro Garcia',
            lrn: '123456789014',
            date: 'Dec 18, 2024',
            timeIn: '-',
            status: 'Absent',
            statusColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard({
    required String studentName,
    required String lrn,
    required String date,
    required String timeIn,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            status == 'Present'
                ? Icons.check_circle
                : status == 'Late'
                    ? Icons.access_time
                    : Icons.cancel,
            color: statusColor,
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LRN: $lrn'),
            Text('$date • Time In: $timeIn'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
