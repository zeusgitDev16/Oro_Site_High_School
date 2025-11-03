import 'package:flutter/material.dart';

class GradeReportsScreen extends StatefulWidget {
  const GradeReportsScreen({super.key});

  @override
  State<GradeReportsScreen> createState() => _GradeReportsScreenState();
}

class _GradeReportsScreenState extends State<GradeReportsScreen> {
  String _selectedQuarter = 'Q1';
  String _selectedGradeLevel = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Reports'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quarter',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedQuarter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['Q1', 'Q2', 'Q3', 'Q4', 'Final'].map((quarter) {
                        return DropdownMenuItem(value: quarter, child: Text(quarter));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuarter = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grade Level',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGradeLevel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Grades')),
                        ...List.generate(6, (i) => i + 7).map((grade) {
                          return DropdownMenuItem(
                            value: 'grade$grade',
                            child: Text('Grade $grade'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGradeLevel = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateReport,
              child: const Text('Generate Report'),
            ),
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
        _buildPerformanceDistribution(),
        const SizedBox(height: 16),
        _buildTopPerformers(),
        const SizedBox(height: 16),
        _buildGradesBySubject(),
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
              'Grade Summary - Quarter 1',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average',
                    '87.5',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Passing',
                    '95%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Failing',
                    '5%',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Honor Roll',
                    '142',
                    Icons.star,
                    Colors.amber,
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
        ),
      ],
    );
  }

  Widget _buildPerformanceDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDistributionBar('Outstanding (90-100)', 245, Colors.green),
            _buildDistributionBar('Very Satisfactory (85-89)', 312, Colors.blue),
            _buildDistributionBar('Satisfactory (80-84)', 198, Colors.orange),
            _buildDistributionBar('Fairly Satisfactory (75-79)', 52, Colors.amber),
            _buildDistributionBar('Did Not Meet (Below 75)', 43, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('$count students', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: count / 850,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Top 10 Performers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: index < 3 ? Colors.amber : Colors.blue.shade100,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? Colors.white : Colors.blue.shade900,
                    ),
                  ),
                ),
                title: Text('Student Name ${index + 1}'),
                subtitle: Text('Grade ${7 + (index % 6)} - Section'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${95 - index}.${5 - (index % 10)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradesBySubject() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Average Grades by Subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Average')),
                DataColumn(label: Text('Highest')),
                DataColumn(label: Text('Lowest')),
                DataColumn(label: Text('Passing %')),
              ],
              rows: [
                _buildSubjectRow('Mathematics', 85.2, 98, 65, '92%'),
                _buildSubjectRow('Science', 87.5, 99, 70, '94%'),
                _buildSubjectRow('English', 88.1, 97, 72, '95%'),
                _buildSubjectRow('Filipino', 89.3, 98, 75, '96%'),
                _buildSubjectRow('Social Studies', 86.7, 96, 68, '93%'),
                _buildSubjectRow('MAPEH', 90.2, 99, 78, '98%'),
                _buildSubjectRow('TLE', 88.9, 97, 74, '96%'),
                _buildSubjectRow('Values Education', 91.5, 100, 80, '99%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildSubjectRow(String subject, double avg, int highest, int lowest, String passing) {
    return DataRow(
      cells: [
        DataCell(Text(subject)),
        DataCell(Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(highest.toString(), style: const TextStyle(color: Colors.green))),
        DataCell(Text(lowest.toString(), style: const TextStyle(color: Colors.red))),
        DataCell(Text(passing)),
      ],
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating grade report for $_selectedQuarter...'),
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
