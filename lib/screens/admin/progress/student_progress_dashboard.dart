import 'package:flutter/material.dart';

class StudentProgressDashboard extends StatefulWidget {
  final int? initialStudentId;

  const StudentProgressDashboard({super.key, this.initialStudentId});

  @override
  State<StudentProgressDashboard> createState() => _StudentProgressDashboardState();
}

class _StudentProgressDashboardState extends State<StudentProgressDashboard> {
  int? _selectedStudentId;
  bool _isLoading = false;
  Map<String, dynamic>? _progressData;

  // Mock student list
  final List<Map<String, dynamic>> _students = [
    {'id': 1, 'name': 'Juan Dela Cruz', 'lrn': '123456789012', 'section': 'Grade 7 - Diamond'},
    {'id': 2, 'name': 'Maria Santos', 'lrn': '123456789013', 'section': 'Grade 7 - Diamond'},
    {'id': 3, 'name': 'Pedro Garcia', 'lrn': '123456789014', 'section': 'Grade 7 - Diamond'},
    {'id': 4, 'name': 'Ana Reyes', 'lrn': '123456789015', 'section': 'Grade 7 - Diamond'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStudentId != null) {
      _selectedStudentId = widget.initialStudentId;
      _loadProgressData();
    }
  }

  Future<void> _loadProgressData() async {
    if (_selectedStudentId == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Call ProfileService().getStudentProgress(_selectedStudentId)
    // Mock data
    setState(() {
      _progressData = {
        'attendanceRate': 92.5,
        'averageGrade': 89.4,
        'assignmentCompletion': 87.0,
        'lastLogin': '2024-02-15 10:30 AM',
        'lastSubmission': '2024-02-14 03:45 PM',
        'gradesByQuarter': [
          {'quarter': 'Q1', 'average': 88.5},
          {'quarter': 'Q2', 'average': 89.2},
          {'quarter': 'Q3', 'average': 90.1},
          {'quarter': 'Q4', 'average': 89.8},
        ],
        'attendanceByMonth': [
          {'month': 'Jan', 'rate': 95.0},
          {'month': 'Feb', 'rate': 92.0},
          {'month': 'Mar', 'rate': 90.0},
          {'month': 'Apr', 'rate': 93.0},
        ],
        'subjectPerformance': [
          {'subject': 'Mathematics', 'grade': 88},
          {'subject': 'Science', 'grade': 90},
          {'subject': 'English', 'grade': 85},
          {'subject': 'Filipino', 'grade': 92},
          {'subject': 'Social Studies', 'grade': 87},
          {'subject': 'MAPEH', 'grade': 91},
        ],
        'recentActivity': [
          {'date': '2024-02-15', 'activity': 'Submitted Math Assignment 5', 'type': 'submission'},
          {'date': '2024-02-14', 'activity': 'Attended Science Class', 'type': 'attendance'},
          {'date': '2024-02-13', 'activity': 'Completed English Quiz', 'type': 'assessment'},
          {'date': '2024-02-12', 'activity': 'Submitted Filipino Essay', 'type': 'submission'},
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_progressData != null) ...[
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: _messageStudent,
              tooltip: 'Message Student',
            ),
            IconButton(
              icon: const Icon(Icons.family_restroom),
              onPressed: _messageParent,
              tooltip: 'Message Parent',
            ),
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
          _buildStudentSelector(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_progressData == null)
            _buildEmptyState()
          else
            Expanded(child: _buildProgressContent()),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _students;
                }
                return _students.where((student) {
                  final name = student['name'].toString().toLowerCase();
                  final lrn = student['lrn'].toString();
                  final query = textEditingValue.text.toLowerCase();
                  return name.contains(query) || lrn.contains(query);
                });
              },
              displayStringForOption: (student) => student['name'],
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search Student',
                    hintText: 'Enter student name or LRN...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: Container(
                      width: 400,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final student = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, color: Colors.blue.shade700),
                            ),
                            title: Text(student['name']),
                            subtitle: Text('LRN: ${student['lrn']} • ${student['section']}'),
                            onTap: () {
                              onSelected(student);
                              setState(() {
                                _selectedStudentId = student['id'];
                              });
                              _loadProgressData();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select a student to view progress',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the search bar above to find a student',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOverviewCards(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildGradeTrendChart(),
                  const SizedBox(height: 16),
                  _buildAttendanceChart(),
                  const SizedBox(height: 16),
                  _buildSubjectPerformanceChart(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRecentActivity(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Attendance Rate',
            '${_progressData!['attendanceRate'].toStringAsFixed(1)}%',
            Icons.fact_check,
            Colors.blue,
            _progressData!['attendanceRate'] >= 90 ? 'Excellent' : 'Good',
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'Average Grade',
            _progressData!['averageGrade'].toStringAsFixed(1),
            Icons.grade,
            Colors.green,
            _progressData!['averageGrade'] >= 90 ? 'Outstanding' : 'Very Good',
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'Assignment Completion',
            '${_progressData!['assignmentCompletion'].toStringAsFixed(0)}%',
            Icons.assignment_turned_in,
            Colors.orange,
            _progressData!['assignmentCompletion'] >= 85 ? 'On Track' : 'Needs Attention',
          ),
        ),
        Expanded(
          child: _buildStatCard(
            'Last Activity',
            _progressData!['lastLogin'],
            Icons.access_time,
            Colors.purple,
            'Recent',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: _getTextColorForBackground(color),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeTrendChart() {
    final grades = _progressData!['gradesByQuarter'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade Trend by Quarter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: grades.map((data) {
                  final average = data['average'] as double;
                  final height = (average / 100) * 180;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['quarter'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final attendance = _progressData!['attendanceByMonth'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Pattern (Monthly)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: attendance.map((data) {
                  final rate = data['rate'] as double;
                  final height = (rate / 100) * 130;
                  Color color;
                  if (rate >= 95) {
                    color = Colors.green;
                  } else if (rate >= 90) {
                    color = Colors.blue;
                  } else {
                    color = Colors.orange;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${rate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['month'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformanceChart() {
    final subjects = _progressData!['subjectPerformance'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...subjects.map((data) {
              final grade = data['grade'] as int;
              final percentage = grade / 100;
              Color color;
              if (grade >= 90) {
                color = Colors.green;
              } else if (grade >= 85) {
                color = Colors.blue;
              } else if (grade >= 80) {
                color = Colors.orange;
              } else {
                color = Colors.amber;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['subject'],
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          grade.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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

  Widget _buildRecentActivity() {
    final activities = _progressData!['recentActivity'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) {
              IconData icon;
              Color color;
              switch (activity['type']) {
                case 'submission':
                  icon = Icons.assignment_turned_in;
                  color = Colors.green;
                  break;
                case 'attendance':
                  icon = Icons.check_circle;
                  color = Colors.blue;
                  break;
                case 'assessment':
                  icon = Icons.quiz;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.info;
                  color = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['activity'],
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['date'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
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

  void _messageStudent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening message to student...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _messageParent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening message to parent...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting progress report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing progress report for printing...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    if (backgroundColor == Colors.blue) {
      return Colors.blue.shade900;
    } else if (backgroundColor == Colors.green) {
      return Colors.green.shade900;
    } else if (backgroundColor == Colors.orange) {
      return Colors.orange.shade900;
    } else if (backgroundColor == Colors.purple) {
      return Colors.purple.shade900;
    } else {
      return Colors.grey.shade900;
    }
  }
}
