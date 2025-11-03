import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/grade_service.dart';
import 'package:oro_site_high_school/services/notification_trigger_service.dart';

/// Bulk Grade Entry Screen for Grade Level Coordinators
/// Allows coordinators to enter grades for multiple students at once
/// UI-only component following OSHS architecture
class BulkGradeEntryScreen extends StatefulWidget {
  const BulkGradeEntryScreen({super.key});

  @override
  State<BulkGradeEntryScreen> createState() => _BulkGradeEntryScreenState();
}

class _BulkGradeEntryScreenState extends State<BulkGradeEntryScreen> {
  final GradeService _gradeService = GradeService();
  final NotificationTriggerService _notificationTrigger = NotificationTriggerService();
  String _selectedSection = 'Grade 7 - Diamond';
  String _selectedSubject = 'Mathematics 7';
  String _selectedQuarter = 'Q1';
  bool _isLoading = false;

  // Mock student data for Grade 7 - Diamond
  final List<Map<String, dynamic>> _students = [
    {
      'id': 'student-1',
      'lrn': '123456789012',
      'name': 'Juan Dela Cruz',
      'written': 85.0,
      'performance': 88.0,
      'quarterly': 90.0,
    },
    {
      'id': 'student-2',
      'lrn': '123456789013',
      'name': 'Maria Clara Santos',
      'written': 92.0,
      'performance': 90.0,
      'quarterly': 95.0,
    },
    {
      'id': 'student-3',
      'lrn': '123456789014',
      'name': 'Pedro Garcia',
      'written': 78.0,
      'performance': 82.0,
      'quarterly': 85.0,
    },
    {
      'id': 'student-4',
      'lrn': '123456789015',
      'name': 'Ana Reyes',
      'written': 88.0,
      'performance': 86.0,
      'quarterly': 90.0,
    },
    {
      'id': 'student-5',
      'lrn': '123456789016',
      'name': 'Jose Mendoza',
      'written': 75.0,
      'performance': 80.0,
      'quarterly': 82.0,
    },
  ];

  final List<String> _sections = [
    'Grade 7 - Diamond',
    'Grade 7 - Emerald',
    'Grade 7 - Ruby',
    'Grade 7 - Sapphire',
    'Grade 7 - Pearl',
    'Grade 7 - Jade',
  ];

  final List<String> _subjects = [
    'Mathematics 7',
    'Science 7',
    'English 7',
    'Filipino 7',
    'Araling Panlipunan 7',
    'MAPEH 7',
    'TLE 7',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Grade Entry'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: _handleSaveAll,
            icon: const Icon(Icons.save),
            label: const Text('Save All'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGradeTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Section and Subject',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _sections.map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Text(section),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSection = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _selectedQuarter,
                  decoration: InputDecoration(
                    labelText: 'Quarter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: ['Q1', 'Q2', 'Q3', 'Q4'].map((quarter) {
                    return DropdownMenuItem(
                      value: quarter,
                      child: Text(quarter),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedQuarter = value!;
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

  Widget _buildGradeTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Text(
                    '$_selectedSection - $_selectedSubject ($_selectedQuarter)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_students.length} students',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('LRN', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Written Work (40%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Performance Task (40%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Quarterly Exam (20%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Final Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _students.map((student) {
                  final finalGrade = _calculateFinalGrade(
                    student['written'],
                    student['performance'],
                    student['quarterly'],
                  );
                  final remarks = _getRemarks(finalGrade);
                  final remarksColor = _getRemarksColor(remarks);

                  return DataRow(
                    cells: [
                      DataCell(Text(student['lrn'])),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            student['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(
                              text: student['written'].toString(),
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                student['written'] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(
                              text: student['performance'].toString(),
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                student['performance'] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(
                              text: student['quarterly'].toString(),
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                student['quarterly'] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: remarksColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            finalGrade.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remarksColor,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: remarksColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            remarks,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remarksColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'DepEd Grading Formula: Written Work (40%) + Performance Task (40%) + Quarterly Exam (20%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Class Average: ${_calculateClassAverage().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  double _calculateFinalGrade(double written, double performance, double quarterly) {
    return (written * 0.4) + (performance * 0.4) + (quarterly * 0.2);
  }

  String _getRemarks(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  Color _getRemarksColor(String remarks) {
    switch (remarks) {
      case 'Outstanding':
        return Colors.green;
      case 'Very Satisfactory':
        return Colors.blue;
      case 'Satisfactory':
        return Colors.orange;
      case 'Fairly Satisfactory':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  double _calculateClassAverage() {
    if (_students.isEmpty) return 0.0;
    final total = _students.fold<double>(
      0.0,
      (sum, student) => sum + _calculateFinalGrade(
        student['written'],
        student['performance'],
        student['quarterly'],
      ),
    );
    return total / _students.length;
  }

  Future<void> _handleSaveAll() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save all grades to backend
      // await _gradeService.bulkSaveGrades(_students, _selectedSection, _selectedSubject, _selectedQuarter);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Trigger notification to admin
      await _notificationTrigger.triggerBulkGradeSubmission(
        adminId: 'admin-1',
        coordinatorName: 'Maria Santos',
        section: _selectedSection,
        subject: _selectedSubject,
        studentCount: _students.length,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved grades for ${_students.length} students'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
