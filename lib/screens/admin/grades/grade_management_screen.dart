import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/admin/grades/grade_entry_dialog.dart';
import 'package:oro_site_high_school/screens/admin/grades/grade_override_dialog.dart';
import 'package:oro_site_high_school/screens/admin/grades/bulk_grade_import_dialog.dart';
import 'package:oro_site_high_school/screens/admin/grades/grade_audit_trail_screen.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  String _selectedQuarter = 'Q1';
  String? _selectedGradeLevel;
  String? _selectedSection;
  String? _selectedSubject;
  String _searchQuery = '';
  bool _isLoading = false;

  // Mock data - will be replaced with service call
  final List<Map<String, dynamic>> _allStudentGrades = [
    {
      'id': 1,
      'studentName': 'Juan Dela Cruz',
      'lrn': '123456789012',
      'section': 'Grade 7 - Diamond',
      'mathematics': 88,
      'science': 90,
      'english': 85,
      'filipino': 92,
      'socialStudies': 87,
      'mapeh': 91,
      'tle': 89,
      'values': 93,
      'average': 89.4,
      'status': 'Passed',
    },
    {
      'id': 2,
      'studentName': 'Maria Santos',
      'lrn': '123456789013',
      'section': 'Grade 7 - Diamond',
      'mathematics': 92,
      'science': 94,
      'english': 90,
      'filipino': 95,
      'socialStudies': 91,
      'mapeh': 93,
      'tle': 92,
      'values': 96,
      'average': 92.9,
      'status': 'Passed',
    },
    {
      'id': 3,
      'studentName': 'Pedro Garcia',
      'lrn': '123456789014',
      'section': 'Grade 7 - Diamond',
      'mathematics': 72,
      'science': 75,
      'english': 78,
      'filipino': 80,
      'socialStudies': 76,
      'mapeh': 82,
      'tle': 79,
      'values': 85,
      'average': 78.4,
      'status': 'Passed',
    },
    {
      'id': 4,
      'studentName': 'Ana Reyes',
      'lrn': '123456789015',
      'section': 'Grade 7 - Diamond',
      'mathematics': 70,
      'science': 72,
      'english': 68,
      'filipino': 74,
      'socialStudies': 71,
      'mapeh': 78,
      'tle': 73,
      'values': 80,
      'average': 73.3,
      'status': 'Failed',
    },
  ];

  List<Map<String, dynamic>> get _filteredGrades {
    var grades = List<Map<String, dynamic>>.from(_allStudentGrades);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      grades = grades.where((grade) {
        final name = grade['studentName'].toString().toLowerCase();
        final lrn = grade['lrn'].toString();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || lrn.contains(query);
      }).toList();
    }

    // Apply grade level filter
    if (_selectedGradeLevel != null) {
      grades = grades.where((grade) {
        final section = grade['section'].toString();
        return section.contains('Grade $_selectedGradeLevel');
      }).toList();
    }

    // Apply section filter
    if (_selectedSection != null) {
      grades = grades.where((grade) => grade['section'] == _selectedSection).toList();
    }

    return grades;
  }

  Map<String, dynamic> get _statistics {
    final grades = _filteredGrades;
    if (grades.isEmpty) {
      return {
        'average': 0.0,
        'passingRate': 0.0,
        'failingCount': 0,
        'honorRoll': 0,
      };
    }

    final totalAverage = grades.fold<double>(0, (sum, g) => sum + g['average']) / grades.length;
    final passing = grades.where((g) => g['status'] == 'Passed').length;
    final failing = grades.where((g) => g['status'] == 'Failed').length;
    final honorRoll = grades.where((g) => g['average'] >= 90).length;

    return {
      'average': totalAverage,
      'passingRate': (passing / grades.length * 100),
      'failingCount': failing,
      'honorRoll': honorRoll,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showBulkImportDialog,
            tooltip: 'Bulk Import',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportGrades,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReportCards,
            tooltip: 'Print Report Cards',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildStatisticsSection(),
          Expanded(child: _buildGradesTable()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or LRN...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filters row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedQuarter,
                  decoration: const InputDecoration(
                    labelText: 'Quarter',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Q1', child: Text('Quarter 1')),
                    DropdownMenuItem(value: 'Q2', child: Text('Quarter 2')),
                    DropdownMenuItem(value: 'Q3', child: Text('Quarter 3')),
                    DropdownMenuItem(value: 'Q4', child: Text('Quarter 4')),
                    DropdownMenuItem(value: 'Final', child: Text('Final Grade')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedQuarter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGradeLevel,
                  decoration: const InputDecoration(
                    labelText: 'Grade Level',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Grades')),
                    ...List.generate(6, (i) => i + 7).map((grade) {
                      return DropdownMenuItem(
                        value: grade.toString(),
                        child: Text('Grade $grade'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGradeLevel = value;
                      _selectedSection = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Sections')),
                    DropdownMenuItem(value: 'Grade 7 - Diamond', child: Text('Grade 7 - Diamond')),
                    DropdownMenuItem(value: 'Grade 7 - Amethyst', child: Text('Grade 7 - Amethyst')),
                    DropdownMenuItem(value: 'Grade 8 - Sapphire', child: Text('Grade 8 - Sapphire')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSection = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Subjects')),
                    DropdownMenuItem(value: 'mathematics', child: Text('Mathematics')),
                    DropdownMenuItem(value: 'science', child: Text('Science')),
                    DropdownMenuItem(value: 'english', child: Text('English')),
                    DropdownMenuItem(value: 'filipino', child: Text('Filipino')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = _statistics;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Average Grade',
              stats['average'].toStringAsFixed(1),
              Icons.trending_up,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Passing Rate',
              '${stats['passingRate'].toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Failing Students',
              stats['failingCount'].toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Honor Roll',
              stats['honorRoll'].toString(),
              Icons.star,
              Colors.amber,
            ),
          ),
        ],
      ),
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

  Widget _buildGradesTable() {
    final grades = _filteredGrades;

    if (grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No grades found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('LRN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Math', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Science', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Filipino', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Soc. Stud.', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('MAPEH', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('TLE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Values', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: grades.map((grade) => _buildGradeRow(grade)).toList(),
        ),
      ),
    );
  }

  DataRow _buildGradeRow(Map<String, dynamic> grade) {
    final isPassed = grade['status'] == 'Passed';

    return DataRow(
      cells: [
        DataCell(Text(grade['lrn'])),
        DataCell(Text(grade['studentName'], style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(grade['section'])),
        DataCell(_buildGradeCell(grade['mathematics'])),
        DataCell(_buildGradeCell(grade['science'])),
        DataCell(_buildGradeCell(grade['english'])),
        DataCell(_buildGradeCell(grade['filipino'])),
        DataCell(_buildGradeCell(grade['socialStudies'])),
        DataCell(_buildGradeCell(grade['mapeh'])),
        DataCell(_buildGradeCell(grade['tle'])),
        DataCell(_buildGradeCell(grade['values'])),
        DataCell(
          Text(
            grade['average'].toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              grade['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editGrade(grade),
                tooltip: 'Edit Grade',
              ),
              IconButton(
                icon: const Icon(Icons.history, size: 20),
                onPressed: () => _viewHistory(grade),
                tooltip: 'View History',
              ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, size: 20, color: Colors.orange),
                onPressed: () => _overrideGrade(grade),
                tooltip: 'Override Grade',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeCell(int grade) {
    Color backgroundColor;
    Color textColor;
    
    if (grade >= 90) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else if (grade >= 85) {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
    } else if (grade >= 80) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    } else if (grade >= 75) {
      backgroundColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        grade.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _editGrade(Map<String, dynamic> grade) {
    showDialog(
      context: context,
      builder: (context) => GradeEntryDialog(
        studentName: grade['studentName'],
        studentLrn: grade['lrn'],
        currentGrades: {
          'mathematics': grade['mathematics'],
          'science': grade['science'],
          'english': grade['english'],
          'filipino': grade['filipino'],
        },
        onSave: (grades) {
          // TODO: Call GradeService().updateGrades()
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grades updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _viewHistory(Map<String, dynamic> grade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradeAuditTrailScreen(
          studentId: grade['id'],
          studentName: grade['studentName'],
        ),
      ),
    );
  }

  void _overrideGrade(Map<String, dynamic> grade) {
    showDialog(
      context: context,
      builder: (context) => GradeOverrideDialog(
        studentName: grade['studentName'],
        studentLrn: grade['lrn'],
        subject: 'Mathematics',
        currentGrade: grade['mathematics'],
        onOverride: (newGrade, reason) {
          // TODO: Call GradeService().overrideGrade()
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grade overridden successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  void _showBulkImportDialog() {
    showDialog(
      context: context,
      builder: (context) => const BulkGradeImportDialog(),
    );
  }

  void _exportGrades() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting grades to Excel...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Call GradeService().exportGrades()
  }

  void _printReportCards() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating report cards...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Generate and print report cards
  }
}
