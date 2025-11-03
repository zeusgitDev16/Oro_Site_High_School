import 'package:flutter/material.dart';

class EnrollmentReportsScreen extends StatefulWidget {
  const EnrollmentReportsScreen({super.key});

  @override
  State<EnrollmentReportsScreen> createState() => _EnrollmentReportsScreenState();
}

class _EnrollmentReportsScreenState extends State<EnrollmentReportsScreen> {
  String _selectedSchoolYear = 'S.Y. 2024-2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Reports'),
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
              value: _selectedSchoolYear,
              decoration: const InputDecoration(
                labelText: 'School Year',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                'S.Y. 2024-2025',
                'S.Y. 2023-2024',
                'S.Y. 2022-2023',
              ].map((sy) {
                return DropdownMenuItem(value: sy, child: Text(sy));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSchoolYear = value!;
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
        _buildEnrollmentByGrade(),
        const SizedBox(height: 16),
        _buildEnrollmentByGender(),
        const SizedBox(height: 16),
        _buildEnrollmentTrend(),
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
              'Enrollment Summary - S.Y. 2024-2025',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Enrolled',
                    '850',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Male',
                    '425',
                    Icons.male,
                    Colors.indigo,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Female',
                    '425',
                    Icons.female,
                    Colors.pink,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'New Students',
                    '142',
                    Icons.person_add,
                    Colors.green,
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

  Widget _buildEnrollmentByGrade() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enrollment by Grade Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGradeBar('Grade 7', 145, 2, Colors.blue),
            _buildGradeBar('Grade 8', 142, 2, Colors.green),
            _buildGradeBar('Grade 9', 140, 2, Colors.orange),
            _buildGradeBar('Grade 10', 138, 2, Colors.purple),
            _buildGradeBar('Grade 11', 145, 2, Colors.teal),
            _buildGradeBar('Grade 12', 140, 2, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBar(String grade, int students, int sections, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(grade, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(
                '$students students • $sections sections',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: students / 150,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentByGender() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender Distribution by Grade',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Grade Level')),
                  DataColumn(label: Text('Male')),
                  DataColumn(label: Text('Female')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Ratio')),
                ],
                rows: [
                  _buildGenderRow('Grade 7', 73, 72, 145),
                  _buildGenderRow('Grade 8', 71, 71, 142),
                  _buildGenderRow('Grade 9', 70, 70, 140),
                  _buildGenderRow('Grade 10', 69, 69, 138),
                  _buildGenderRow('Grade 11', 72, 73, 145),
                  _buildGenderRow('Grade 12', 70, 70, 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildGenderRow(String grade, int male, int female, int total) {
    return DataRow(
      cells: [
        DataCell(Text(grade)),
        DataCell(Text(male.toString(), style: const TextStyle(color: Colors.indigo))),
        DataCell(Text(female.toString(), style: const TextStyle(color: Colors.pink))),
        DataCell(Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text('${(male / total * 100).toStringAsFixed(0)}:${(female / total * 100).toStringAsFixed(0)}')),
      ],
    );
  }

  Widget _buildEnrollmentTrend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enrollment Trend (Last 5 Years)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('School Year')),
                  DataColumn(label: Text('Total Enrolled')),
                  DataColumn(label: Text('New Students')),
                  DataColumn(label: Text('Transferees')),
                  DataColumn(label: Text('Dropouts')),
                ],
                rows: [
                  _buildTrendRow('S.Y. 2024-2025', 850, 142, 8, 5),
                  _buildTrendRow('S.Y. 2023-2024', 835, 138, 6, 7),
                  _buildTrendRow('S.Y. 2022-2023', 820, 135, 5, 8),
                  _buildTrendRow('S.Y. 2021-2022', 810, 130, 4, 6),
                  _buildTrendRow('S.Y. 2020-2021', 795, 125, 3, 9),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enrollment has increased by 6.9% over the past 5 years',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildTrendRow(String sy, int total, int newStudents, int transferees, int dropouts) {
    return DataRow(
      cells: [
        DataCell(Text(sy)),
        DataCell(Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(newStudents.toString())),
        DataCell(Text(transferees.toString())),
        DataCell(Text(dropouts.toString(), style: const TextStyle(color: Colors.red))),
      ],
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating enrollment report for $_selectedSchoolYear...'),
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
