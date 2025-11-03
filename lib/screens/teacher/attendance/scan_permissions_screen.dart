import 'package:flutter/material.dart';

class ScanPermissionsScreen extends StatefulWidget {
  const ScanPermissionsScreen({super.key});

  @override
  State<ScanPermissionsScreen> createState() => _ScanPermissionsScreenState();
}

class _ScanPermissionsScreenState extends State<ScanPermissionsScreen> {
  String _selectedCourse = 'Mathematics 7';
  String _searchQuery = '';
  bool _selectAll = false;

  final List<String> _courses = ['Mathematics 7', 'Science 7'];

  // Mock student data with permissions
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _students = List.generate(
      35,
      (index) => {
        'id': 'student-${index + 1}',
        'lrn': '${123456789000 + index}',
        'name': [
          'Juan Dela Cruz',
          'Maria Clara',
          'Pedro Santos',
          'Ana Garcia',
          'Jose Rizal',
          'Gabriela Silang',
          'Andres Bonifacio',
          'Melchora Aquino',
          'Emilio Aguinaldo',
          'Apolinario Mabini',
        ][index % 10],
        'hasPermission': index % 3 != 0, // Most students have permission
        'lastGranted': index % 3 != 0
            ? DateTime.now().subtract(Duration(days: index % 7))
            : null,
      },
    );
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((student) {
      return student['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          student['lrn'].toString().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentsWithPermission =
        _students.where((s) => s['hasPermission'] == true).length;
    final studentsWithoutPermission = _students.length - studentsWithPermission;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Permissions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildStatistics(studentsWithPermission, studentsWithoutPermission),
          Expanded(child: _buildStudentList()),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Scan Permissions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant or revoke student scanning permissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
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
            value: _selectedCourse,
            decoration: InputDecoration(
              labelText: 'Course',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.school),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _courses
                .map((course) => DropdownMenuItem(
                      value: course,
                      child: Text(course),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourse = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(int withPermission, int withoutPermission) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'With Permission',
              withPermission.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Without Permission',
              withoutPermission.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Students',
              _students.length.toString(),
              Icons.people,
              Colors.blue,
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
                fontSize: 24,
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

  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (value) {
                  setState(() {
                    _selectAll = value!;
                    for (var student in _filteredStudents) {
                      student['hasPermission'] = _selectAll;
                    }
                  });
                },
              ),
              const Text(
                'Select All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _filteredStudents.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(_filteredStudents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final hasPermission = student['hasPermission'] as bool;
    final lastGranted = student['lastGranted'] as DateTime?;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: hasPermission
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Text(
                student['name'].toString().substring(0, 1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hasPermission ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LRN: ${student['lrn']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (lastGranted != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last granted: ${lastGranted.day}/${lastGranted.month}/${lastGranted.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: hasPermission,
              onChanged: (value) {
                setState(() {
                  student['hasPermission'] = value;
                  if (value) {
                    student['lastGranted'] = DateTime.now();
                  }
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _grantAllPermissions,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Grant All'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _revokeAllPermissions,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Revoke All'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _grantAllPermissions() {
    setState(() {
      for (var student in _students) {
        student['hasPermission'] = true;
        student['lastGranted'] = DateTime.now();
      }
      _selectAll = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Granted permissions to all students'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _revokeAllPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Permissions'),
        content: const Text(
          'Are you sure you want to revoke scan permissions for all students?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (var student in _students) {
                  student['hasPermission'] = false;
                }
                _selectAll = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Revoked permissions from all students'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );
  }

  void _savePermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
