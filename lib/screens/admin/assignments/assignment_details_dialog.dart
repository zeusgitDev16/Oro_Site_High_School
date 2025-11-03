import 'package:flutter/material.dart';

class AssignmentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const AssignmentDetailsDialog({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final submissionRate = (assignment['submitted'] / assignment['totalStudents'] * 100).toStringAsFixed(1);

    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment['course'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Submitted',
                            '${assignment['submitted']}/${assignment['totalStudents']}',
                            '$submissionRate%',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            assignment['pending'].toString(),
                            'Not submitted',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Late',
                            assignment['late'].toString(),
                            'After deadline',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Assignment Details
                    _buildDetailSection('Assignment Information', [
                      _buildDetailRow('Type', assignment['type']),
                      _buildDetailRow('Due Date', assignment['dueDate']),
                      _buildDetailRow('Status', assignment['status']),
                    ]),
                    const SizedBox(height: 24),
                    // Submission List
                    _buildSubmissionList(),
                  ],
                ),
              ),
            ),
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Export submissions
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Send reminder
                    },
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Send Reminder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionList() {
    // Mock submission data
    final submissions = [
      {
        'student': 'Juan Dela Cruz',
        'lrn': '123456789012',
        'submittedDate': '2024-02-18 10:30 AM',
        'status': 'On Time',
        'grade': '95',
      },
      {
        'student': 'Maria Santos',
        'lrn': '123456789013',
        'submittedDate': '2024-02-19 02:15 PM',
        'status': 'On Time',
        'grade': '98',
      },
      {
        'student': 'Pedro Garcia',
        'lrn': '123456789014',
        'submittedDate': '2024-02-21 08:00 AM',
        'status': 'Late',
        'grade': '85',
      },
      {
        'student': 'Ana Reyes',
        'lrn': '123456789015',
        'submittedDate': null,
        'status': 'Pending',
        'grade': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submissions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...submissions.map((submission) {
          Color statusColor;
          Color statusTextColor;
          
          if (submission['status'] == 'On Time') {
            statusColor = Colors.green.shade100;
            statusTextColor = Colors.green.shade900;
          } else if (submission['status'] == 'Late') {
            statusColor = Colors.orange.shade100;
            statusTextColor = Colors.orange.shade900;
          } else {
            statusColor = Colors.grey.shade200;
            statusTextColor = Colors.grey.shade900;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue.shade700),
              ),
              title: Text(submission['student'] as String),
              subtitle: Text('LRN: ${submission['lrn']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (submission['grade'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        submission['grade'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      submission['status'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  if (submission['submittedDate'] != null)
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        // TODO: View submission
                      },
                      tooltip: 'View Submission',
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
