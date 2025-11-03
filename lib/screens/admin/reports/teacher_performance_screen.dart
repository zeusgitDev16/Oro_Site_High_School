import 'package:flutter/material.dart';

class TeacherPerformanceScreen extends StatefulWidget {
  const TeacherPerformanceScreen({super.key});

  @override
  State<TeacherPerformanceScreen> createState() => _TeacherPerformanceScreenState();
}

class _TeacherPerformanceScreenState extends State<TeacherPerformanceScreen> {
  String _selectedQuarter = 'Q1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Performance'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildReportContent()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedQuarter,
              decoration: const InputDecoration(
                labelText: 'Quarter',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ['Q1', 'Q2', 'Q3', 'Q4', 'Annual'].map((quarter) {
                return DropdownMenuItem(value: quarter, child: Text(quarter));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuarter = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _generateReport,
            child: const Text('Generate Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildTeachingLoadCard(),
        const SizedBox(height: 16),
        _buildTeacherListCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teaching Staff Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Teachers',
                    '45',
                    Icons.school,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Full-time',
                    '38',
                    Icons.work,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Part-time',
                    '7',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg. Load',
                    '24 hrs',
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTeachingLoadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teaching Load Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Teachers')),
                  DataColumn(label: Text('Sections')),
                  DataColumn(label: Text('Avg. Hours')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  _buildLoadRow('Mathematics', 8, 24, 25, 'Optimal'),
                  _buildLoadRow('Science', 7, 21, 24, 'Optimal'),
                  _buildLoadRow('English', 8, 24, 26, 'High'),
                  _buildLoadRow('Filipino', 6, 18, 23, 'Optimal'),
                  _buildLoadRow('Social Studies', 5, 15, 22, 'Optimal'),
                  _buildLoadRow('MAPEH', 6, 18, 21, 'Low'),
                  _buildLoadRow('TLE', 5, 15, 20, 'Low'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildLoadRow(String dept, int teachers, int sections, int hours, String status) {
    Color statusColor = status == 'Optimal'
        ? Colors.green
        : status == 'High'
            ? Colors.orange
            : Colors.blue;

    return DataRow(
      cells: [
        DataCell(Text(dept)),
        DataCell(Text(teachers.toString())),
        DataCell(Text(sections.toString())),
        DataCell(Text('$hours hrs')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherListCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Teacher Performance Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildTeacherTile(
                name: 'Teacher Name ${index + 1}',
                department: ['Mathematics', 'Science', 'English', 'Filipino'][index % 4],
                sections: 3 + (index % 2),
                hours: 22 + (index % 6),
                performance: 85 + (index % 15),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherTile({
    required String name,
    required String department,
    required int sections,
    required int hours,
    required int performance,
  }) {
    Color performanceColor = performance >= 90
        ? Colors.green
        : performance >= 80
            ? Colors.blue
            : Colors.orange;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: performanceColor.withOpacity(0.2),
        child: Icon(Icons.person, color: performanceColor),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('$department • $sections sections • $hours hrs/week'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: performanceColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$performance%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: performanceColor,
              ),
            ),
            Text(
              'Rating',
              style: TextStyle(
                fontSize: 10,
                color: performanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating teacher performance report for $_selectedQuarter...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report to Excel...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing report for printing...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
