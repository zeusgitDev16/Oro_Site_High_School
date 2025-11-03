import 'package:flutter/material.dart';

class GradeLevelStudentsScreen extends StatefulWidget {
  const GradeLevelStudentsScreen({super.key});

  @override
  State<GradeLevelStudentsScreen> createState() =>
      _GradeLevelStudentsScreenState();
}

class _GradeLevelStudentsScreenState extends State<GradeLevelStudentsScreen> {
  String _selectedSection = 'All Sections';
  String _searchQuery = '';

  final List<String> _sections = [
    'All Sections',
    '7-Amethyst',
    '7-Bronze',
    '7-Copper',
    '7-Diamond',
    '7-Emerald',
    '7-Feldspar',
  ];

  // Mock students data (210 students across 6 sections)
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _students = List.generate(
      210,
      (index) {
        final sectionIndex = index ~/ 35;
        final sections = [
          '7-Amethyst',
          '7-Bronze',
          '7-Copper',
          '7-Diamond',
          '7-Emerald',
          '7-Feldspar'
        ];
        return {
          'id': 'student-${index + 1}',
          'lrn': '${123456789000 + index}',
          'name': 'Student ${index + 1}',
          'section': sections[sectionIndex],
          'avgGrade': 75 + (index % 25),
          'attendance': 85 + (index % 15),
          'status': index % 20 == 0 ? 'At Risk' : 'Good Standing',
        };
      },
    );
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((student) {
      final matchesSection = _selectedSection == 'All Sections' ||
          student['section'] == _selectedSection;
      final matchesSearch = student['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          student['lrn'].toString().contains(_searchQuery);
      return matchesSection && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Grade 7 Students'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export to Excel - Coming Soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStatistics(),
          Expanded(child: _buildStudentsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or LRN...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSection,
            decoration: InputDecoration(
              labelText: 'Section',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.class_),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _sections
                .map((section) => DropdownMenuItem(
                      value: section,
                      child: Text(section),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSection = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final totalStudents = _filteredStudents.length;
    final avgGrade = totalStudents > 0
        ? _filteredStudents.fold(0, (sum, s) => sum + (s['avgGrade'] as int)) /
            totalStudents
        : 0;
    final atRisk =
        _filteredStudents.where((s) => s['status'] == 'At Risk').length;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students',
              totalStudents.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Grade',
              avgGrade.toStringAsFixed(1),
              Icons.grade,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'At Risk',
              atRisk.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(_filteredStudents[index]);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final status = student['status'] as String;
    final statusColor = status == 'At Risk' ? Colors.red : Colors.green;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Text(
            student['name'].toString().substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        title: Text(
          student['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('LRN: ${student['lrn']} • ${student['section']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, size: 18),
                      SizedBox(width: 8),
                      Text('Reset Password'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'grades',
                  child: Row(
                    children: [
                      Icon(Icons.grade, size: 18),
                      SizedBox(width: 8),
                      Text('View Grades'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'attendance',
                  child: Row(
                    children: [
                      Icon(Icons.fact_check, size: 18),
                      SizedBox(width: 8),
                      Text('View Attendance'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'reset') {
                  _showResetPasswordDialog(student['name']);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$value - Coming Soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password for $studentName?'),
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
                  content: Text('Password reset for $studentName'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
