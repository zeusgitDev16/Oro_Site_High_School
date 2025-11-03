import 'package:flutter/material.dart';

class ArchiveManagementScreen extends StatefulWidget {
  const ArchiveManagementScreen({super.key});

  @override
  State<ArchiveManagementScreen> createState() => _ArchiveManagementScreenState();
}

class _ArchiveManagementScreenState extends State<ArchiveManagementScreen> {
  final List<Map<String, dynamic>> _archives = [
    {
      'schoolYear': 'S.Y. 2024-2025',
      'status': 'Active',
      'students': 850,
      'teachers': 45,
      'courses': 48,
      'archived': false,
      'archiveDate': null,
    },
    {
      'schoolYear': 'S.Y. 2023-2024',
      'status': 'Archived',
      'students': 835,
      'teachers': 43,
      'courses': 46,
      'archived': true,
      'archiveDate': 'June 15, 2024',
    },
    {
      'schoolYear': 'S.Y. 2022-2023',
      'status': 'Archived',
      'students': 820,
      'teachers': 42,
      'courses': 45,
      'archived': true,
      'archiveDate': 'June 10, 2023',
    },
    {
      'schoolYear': 'S.Y. 2021-2022',
      'status': 'Archived',
      'students': 810,
      'teachers': 40,
      'courses': 44,
      'archived': true,
      'archiveDate': 'June 12, 2022',
    },
    {
      'schoolYear': 'S.Y. 2020-2021',
      'status': 'Archived',
      'students': 795,
      'teachers': 39,
      'courses': 43,
      'archived': true,
      'archiveDate': 'June 8, 2021',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(child: _buildArchiveList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showArchiveDialog,
        icon: const Icon(Icons.archive),
        label: const Text('Archive Current S.Y.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Archives preserve historical data for each school year. '
              'Archived data is read-only and can be exported for records.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _archives.length,
      itemBuilder: (context, index) {
        final archive = _archives[index];
        return _buildArchiveCard(archive);
      },
    );
  }

  Widget _buildArchiveCard(Map<String, dynamic> archive) {
    final isActive = archive['status'] == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.folder_open : Icons.archive,
            color: isActive ? Colors.green : Colors.grey.shade700,
          ),
        ),
        title: Text(
          archive['schoolYear'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isActive
              ? 'Current School Year'
              : 'Archived on ${archive['archiveDate']}',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green : Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            archive['status'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archive Statistics',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        Icons.people,
                        'Students',
                        archive['students'].toString(),
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatChip(
                        Icons.school,
                        'Teachers',
                        archive['teachers'].toString(),
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatChip(
                        Icons.book,
                        'Courses',
                        archive['courses'].toString(),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      'View Details',
                      Icons.visibility,
                      () => _viewArchiveDetails(archive),
                    ),
                    _buildActionButton(
                      'Export Data',
                      Icons.download,
                      () => _exportArchive(archive),
                    ),
                    _buildActionButton(
                      'Generate Reports',
                      Icons.assessment,
                      () => _generateArchiveReports(archive),
                    ),
                    if (!isActive)
                      _buildActionButton(
                        'Delete Archive',
                        Icons.delete,
                        () => _deleteArchive(archive),
                        color: Colors.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color ?? Colors.blue),
      ),
    );
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Current School Year'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive S.Y. 2024-2025?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This will:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('• Make all data read-only', style: TextStyle(fontSize: 13)),
            Text('• Preserve records for historical reference', style: TextStyle(fontSize: 13)),
            Text('• Allow you to start a new school year', style: TextStyle(fontSize: 13)),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _archiveCurrentYear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _archiveCurrentYear() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archiving S.Y. 2024-2025... This may take a few minutes.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _viewArchiveDetails(Map<String, dynamic> archive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(archive['schoolYear']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', archive['status']),
            _buildDetailRow('Students', archive['students'].toString()),
            _buildDetailRow('Teachers', archive['teachers'].toString()),
            _buildDetailRow('Courses', archive['courses'].toString()),
            if (archive['archiveDate'] != null)
              _buildDetailRow('Archived On', archive['archiveDate']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _exportArchive(Map<String, dynamic> archive) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${archive['schoolYear']} data to Excel...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateArchiveReports(Map<String, dynamic> archive) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating reports for ${archive['schoolYear']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteArchive(Map<String, dynamic> archive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Archive'),
        content: Text(
          'Are you sure you want to permanently delete ${archive['schoolYear']} archive? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting ${archive['schoolYear']} archive...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
