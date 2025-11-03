import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/admin/progress/student_progress_dashboard.dart';

class SectionProgressDashboard extends StatefulWidget {
  const SectionProgressDashboard({super.key});

  @override
  State<SectionProgressDashboard> createState() => _SectionProgressDashboardState();
}

class _SectionProgressDashboardState extends State<SectionProgressDashboard> {
  String? _selectedGradeLevel;
  String? _selectedSection;
  bool _isLoading = false;
  Map<String, dynamic>? _sectionData;

  final Map<String, List<String>> _sectionsByGrade = {
    '7': ['Grade 7 - Diamond', 'Grade 7 - Amethyst', 'Grade 7 - Bronze'],
    '8': ['Grade 8 - Sapphire', 'Grade 8 - Ruby', 'Grade 8 - Copper'],
    '9': ['Grade 9 - Emerald', 'Grade 9 - Pearl', 'Grade 9 - Silver'],
    '10': ['Grade 10 - Jade', 'Grade 10 - Topaz', 'Grade 10 - Gold'],
  };

  Future<void> _loadSectionData() async {
    if (_selectedSection == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Call service to get section progress
    setState(() {
      _sectionData = {
        'totalStudents': 35,
        'averageAttendance': 91.5,
        'averageGrade': 87.8,
        'assignmentCompletion': 85.0,
        'atRiskCount': 3,
        'students': [
          {
            'id': 1,
            'rank': 1,
            'name': 'Maria Santos',
            'lrn': '123456789013',
            'attendance': 98.0,
            'average': 92.9,
            'status': 'Excellent',
          },
          {
            'id': 2,
            'rank': 2,
            'name': 'Juan Dela Cruz',
            'lrn': '123456789012',
            'attendance': 92.5,
            'average': 89.4,
            'status': 'Very Good',
          },
          {
            'id': 3,
            'rank': 3,
            'name': 'Pedro Garcia',
            'lrn': '123456789014',
            'attendance': 88.0,
            'average': 78.4,
            'status': 'Good',
          },
          {
            'id': 4,
            'rank': 4,
            'name': 'Ana Reyes',
            'lrn': '123456789015',
            'attendance': 75.0,
            'average': 73.3,
            'status': 'At Risk',
          },
        ],
        'topPerformers': [
          {'name': 'Maria Santos', 'average': 92.9},
          {'name': 'Juan Dela Cruz', 'average': 89.4},
          {'name': 'Carlos Lopez', 'average': 88.7},
        ],
        'atRiskStudents': [
          {'name': 'Ana Reyes', 'average': 73.3, 'attendance': 75.0},
          {'name': 'Jose Cruz', 'average': 74.5, 'attendance': 78.0},
          {'name': 'Linda Garcia', 'average': 72.8, 'attendance': 80.0},
        ],
        'gradeDistribution': [
          {'range': '90-100', 'count': 8},
          {'range': '85-89', 'count': 12},
          {'range': '80-84', 'count': 10},
          {'range': '75-79', 'count': 3},
          {'range': '<75', 'count': 2},
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Progress Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_sectionData != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportReport,
              tooltip: 'Export Report',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printReport,
              tooltip: 'Print Report',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSectionSelector(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_sectionData == null)
            _buildEmptyState()
          else
            Expanded(child: _buildSectionContent()),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGradeLevel,
              decoration: const InputDecoration(
                labelText: 'Grade Level',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _sectionsByGrade.keys.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text('Grade $grade'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGradeLevel = value;
                  _selectedSection = null;
                  _sectionData = null;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(
                labelText: 'Section',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _selectedGradeLevel != null
                  ? _sectionsByGrade[_selectedGradeLevel!]!.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList()
                  : [],
              onChanged: _selectedGradeLevel != null
                  ? (value) {
                      setState(() {
                        _selectedSection = value;
                      });
                      _loadSectionData();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select a section to view progress',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose grade level and section above',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStatisticsCards(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildStudentComparisonTable(),
                  const SizedBox(height: 16),
                  _buildGradeDistribution(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildTopPerformers(),
                  const SizedBox(height: 16),
                  _buildAtRiskStudents(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Students',
            _sectionData!['totalStudents'].toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'Avg Attendance',
            '${_sectionData!['averageAttendance'].toStringAsFixed(1)}%',
            Icons.fact_check,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'Avg Grade',
            _sectionData!['averageGrade'].toStringAsFixed(1),
            Icons.grade,
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'At-Risk Students',
            _sectionData!['atRiskCount'].toString(),
            Icons.warning,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildStudentComparisonTable() {
    final students = _sectionData!['students'] as List;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Student Comparison',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('LRN', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: students.map((student) {
                Color statusBackgroundColor;
                Color statusTextColor;
                
                if (student['status'] == 'Excellent') {
                  statusBackgroundColor = Colors.green.shade100;
                  statusTextColor = Colors.green.shade900;
                } else if (student['status'] == 'Very Good') {
                  statusBackgroundColor = Colors.blue.shade100;
                  statusTextColor = Colors.blue.shade900;
                } else if (student['status'] == 'Good') {
                  statusBackgroundColor = Colors.orange.shade100;
                  statusTextColor = Colors.orange.shade900;
                } else {
                  statusBackgroundColor = Colors.red.shade100;
                  statusTextColor = Colors.red.shade900;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: student['rank'] <= 3 ? Colors.amber : Colors.grey.shade300,
                        child: Text(
                          student['rank'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: student['rank'] <= 3 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(student['name'])),
                    DataCell(Text(student['lrn'])),
                    DataCell(Text('${student['attendance'].toStringAsFixed(1)}%')),
                    DataCell(Text(student['average'].toStringAsFixed(1))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _viewStudentProgress(student['id']),
                        tooltip: 'View Details',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    final distribution = _sectionData!['gradeDistribution'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.map((data) {
              final count = data['count'] as int;
              final percentage = count / _sectionData!['totalStudents'];
              Color color;
              if (data['range'] == '90-100') {
                color = Colors.green;
              } else if (data['range'] == '85-89') {
                color = Colors.blue;
              } else if (data['range'] == '80-84') {
                color = Colors.orange;
              } else if (data['range'] == '75-79') {
                color = Colors.amber;
              } else {
                color = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['range'], style: const TextStyle(fontSize: 13)),
                        Text('$count students', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    final topPerformers = _sectionData!['topPerformers'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.amber
                      : index == 1
                          ? Colors.grey.shade400
                          : Colors.brown.shade300,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(student['name']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student['average'].toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAtRiskStudents() {
    final atRisk = _sectionData!['atRiskStudents'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'At-Risk Students',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...atRisk.map((student) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.red.shade50,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.person, color: Colors.red.shade700),
                  title: Text(student['name']),
                  subtitle: Text(
                    'Grade: ${student['average'].toStringAsFixed(1)} • Attendance: ${student['attendance'].toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.message, size: 18, color: Colors.red.shade700),
                    onPressed: () => _contactStudent(student['name']),
                    tooltip: 'Contact',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _viewStudentProgress(int studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProgressDashboard(initialStudentId: studentId),
      ),
    );
  }

  void _contactStudent(String studentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening message to $studentName...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting section report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing section report for printing...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
