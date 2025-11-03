import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/admin/assignments/create_assignment_dialog.dart';
import 'package:oro_site_high_school/screens/admin/assignments/assignment_details_dialog.dart';

class AssignmentManagementScreen extends StatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  State<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  String? _selectedCourse;
  String? _selectedStatus;
  String _searchQuery = '';
  bool _isLoading = false;

  // Mock data
  final List<String> _courses = [
    'All Courses',
    'Mathematics 7',
    'Science 8',
    'English 9',
    'Filipino 10',
  ];

  final List<Map<String, dynamic>> _allAssignments = [
    {
      'id': 1,
      'title': 'Algebra Problem Set 1',
      'course': 'Mathematics 7',
      'dueDate': '2024-02-20',
      'totalStudents': 70,
      'submitted': 65,
      'pending': 5,
      'late': 3,
      'status': 'Active',
      'type': 'Problem Set',
    },
    {
      'id': 2,
      'title': 'Essay: My Hero',
      'course': 'English 9',
      'dueDate': '2024-02-18',
      'totalStudents': 68,
      'submitted': 68,
      'pending': 0,
      'late': 5,
      'status': 'Closed',
      'type': 'Essay',
    },
    {
      'id': 3,
      'title': 'Science Lab Report',
      'course': 'Science 8',
      'dueDate': '2024-02-25',
      'totalStudents': 35,
      'submitted': 20,
      'pending': 15,
      'late': 0,
      'status': 'Active',
      'type': 'Lab Report',
    },
    {
      'id': 4,
      'title': 'Filipino Poetry Analysis',
      'course': 'Filipino 10',
      'dueDate': '2024-02-15',
      'totalStudents': 38,
      'submitted': 30,
      'pending': 8,
      'late': 10,
      'status': 'Overdue',
      'type': 'Analysis',
    },
  ];

  List<Map<String, dynamic>> get _filteredAssignments {
    var assignments = List<Map<String, dynamic>>.from(_allAssignments);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      assignments = assignments.where((assignment) {
        final title = assignment['title'].toString().toLowerCase();
        final course = assignment['course'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || course.contains(query);
      }).toList();
    }

    // Apply course filter
    if (_selectedCourse != null && _selectedCourse != 'All Courses') {
      assignments = assignments.where((a) => a['course'] == _selectedCourse).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      assignments = assignments.where((a) => a['status'] == _selectedStatus).toList();
    }

    return assignments;
  }

  Map<String, dynamic> get _statistics {
    final assignments = _filteredAssignments;
    if (assignments.isEmpty) {
      return {
        'total': 0,
        'active': 0,
        'overdue': 0,
        'submissionRate': 0.0,
      };
    }

    final total = assignments.length;
    final active = assignments.where((a) => a['status'] == 'Active').length;
    final overdue = assignments.where((a) => a['status'] == 'Overdue').length;
    
    final totalStudents = assignments.fold<int>(0, (sum, a) => sum + (a['totalStudents'] as int));
    final totalSubmitted = assignments.fold<int>(0, (sum, a) => sum + (a['submitted'] as int));
    final submissionRate = totalStudents > 0 ? (totalSubmitted / totalStudents * 100) : 0.0;

    return {
      'total': total,
      'active': active,
      'overdue': overdue,
      'submissionRate': submissionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAssignments,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildStatisticsSection(),
          Expanded(child: _buildAssignmentsTable()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAssignment,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
        backgroundColor: Colors.blue,
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
              hintText: 'Search assignments...',
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
                  value: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
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
              'Total Assignments',
              stats['total'].toString(),
              Icons.assignment,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Active',
              stats['active'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Overdue',
              stats['overdue'].toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Submission Rate',
              '${stats['submissionRate'].toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.orange,
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

  Widget _buildAssignmentsTable() {
    final assignments = _filteredAssignments;

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No assignments found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new assignment',
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
            DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Course', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Submitted', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Late', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: assignments.map((assignment) => _buildAssignmentRow(assignment)).toList(),
        ),
      ),
    );
  }

  DataRow _buildAssignmentRow(Map<String, dynamic> assignment) {
    Color statusColor;
    Color statusTextColor;
    
    if (assignment['status'] == 'Active') {
      statusColor = Colors.green.shade100;
      statusTextColor = Colors.green.shade900;
    } else if (assignment['status'] == 'Closed') {
      statusColor = Colors.grey.shade200;
      statusTextColor = Colors.grey.shade900;
    } else {
      statusColor = Colors.red.shade100;
      statusTextColor = Colors.red.shade900;
    }

    final submissionRate = (assignment['submitted'] / assignment['totalStudents'] * 100).toStringAsFixed(0);

    return DataRow(
      cells: [
        DataCell(
          Text(
            assignment['title'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(assignment['course'])),
        DataCell(
          Chip(
            label: Text(assignment['type'], style: const TextStyle(fontSize: 11)),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        DataCell(Text(assignment['dueDate'])),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${assignment['submitted']}/${assignment['totalStudents']}'),
              const SizedBox(width: 4),
              Text(
                '($submissionRate%)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              assignment['pending'].toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ),
        DataCell(
          assignment['late'] > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignment['late'].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                )
              : const Text('0'),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              assignment['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewAssignment(assignment),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editAssignment(assignment),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteAssignment(assignment),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _createAssignment() {
    showDialog(
      context: context,
      builder: (context) => CreateAssignmentDialog(
        onSave: () {
          // TODO: Call AssignmentService().createAssignment()
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _viewAssignment(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AssignmentDetailsDialog(assignment: assignment),
    );
  }

  void _editAssignment(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => CreateAssignmentDialog(
        assignment: assignment,
        onSave: () {
          // TODO: Call AssignmentService().updateAssignment()
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _deleteAssignment(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call AssignmentService().deleteAssignment()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Assignment deleted'),
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

  void _exportAssignments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting assignments report...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Export assignments to Excel
  }
}
