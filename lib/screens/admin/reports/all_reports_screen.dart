import 'package:flutter/material.dart';

class AllReportsScreen extends StatefulWidget {
  const AllReportsScreen({super.key});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _reports = [
    {'id': 1, 'title': 'Student Performance Report', 'type': 'Academic', 'date': '2024-01-20', 'status': 'Completed', 'format': 'PDF'},
    {'id': 2, 'title': 'Course Enrollment Summary', 'type': 'Enrollment', 'date': '2024-01-18', 'status': 'Completed', 'format': 'Excel'},
    {'id': 3, 'title': 'User Activity Report', 'type': 'System', 'date': '2024-01-15', 'status': 'Processing', 'format': 'PDF'},
    {'id': 4, 'title': 'Financial Summary Q1', 'type': 'Financial', 'date': '2024-01-10', 'status': 'Completed', 'format': 'PDF'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [Tab(text: 'All'), Tab(text: 'Academic'), Tab(text: 'Enrollment'), Tab(text: 'System')],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportList(_reports),
          _buildReportList(_reports.where((r) => r['type'] == 'Academic').toList()),
          _buildReportList(_reports.where((r) => r['type'] == 'Enrollment').toList()),
          _buildReportList(_reports.where((r) => r['type'] == 'System').toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/generate-report'),
        icon: const Icon(Icons.add),
        label: const Text('Generate Report'),
      ),
    );
  }

  Widget _buildReportList(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return const Center(child: Text('No reports found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(report['status']),
              child: Icon(_getFormatIcon(report['format']), color: Colors.white, size: 20),
            ),
            title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(label: Text(report['type'], style: const TextStyle(fontSize: 11)), backgroundColor: Colors.blue.shade50, padding: EdgeInsets.zero),
                    const SizedBox(width: 8),
                    Text('Generated: ${report['date']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
                const PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download, size: 18), SizedBox(width: 8), Text('Download')])),
                const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
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
          ),
        );
      },
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Excel': return Icons.table_chart;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'Processing': return Colors.orange;
      case 'Failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showDeleteDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Report deleted successfully')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
