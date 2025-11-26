import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dialog for managing classroom student enrollment
/// 
/// Features:
/// - View enrolled students
/// - Search and add new students
/// - Remove students from classroom
/// - Real-time student count updates
/// 
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ClassroomStudentsDialog(
///     classroomId: classroom.id,
///     onStudentsChanged: () {
///       // Refresh classroom data
///     },
///   ),
/// );
/// ```
class ClassroomStudentsDialog extends StatefulWidget {
  final String classroomId;
  final VoidCallback? onStudentsChanged;

  const ClassroomStudentsDialog({
    super.key,
    required this.classroomId,
    this.onStudentsChanged,
  });

  @override
  State<ClassroomStudentsDialog> createState() =>
      _ClassroomStudentsDialogState();
}

class _ClassroomStudentsDialogState extends State<ClassroomStudentsDialog>
    with SingleTickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _availableStudents = [];
  List<Map<String, dynamic>> _filteredAvailableStudents = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadEnrolledStudents(),
        _loadAvailableStudents(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrolledStudents() async {
    try {
      final students = await _classroomService.getClassroomStudents(
        widget.classroomId,
      );
      setState(() {
        _enrolledStudents = students;
      });
    } catch (e) {
      print('Error loading enrolled students: $e');
    }
  }

  Future<void> _loadAvailableStudents() async {
    try {
      // Get all students with their profile information
      final response = await _supabase
          .from('students')
          .select('id, lrn, first_name, last_name, grade_level, section, profiles!inner(email)')
          .eq('is_active', true)
          .order('last_name');

      final allStudents = (response as List).map((s) {
        return {
          'student_id': s['id'],
          'lrn': s['lrn'],
          'full_name': '${s['first_name']} ${s['last_name']}',
          'grade_level': s['grade_level'],
          'section': s['section'],
          'email': s['profiles']?['email'] ?? '',
        };
      }).toList();

      // Filter out already enrolled students
      final enrolledIds = _enrolledStudents.map((s) => s['student_id']).toSet();
      final available = allStudents
          .where((s) => !enrolledIds.contains(s['student_id']))
          .toList();

      setState(() {
        _availableStudents = available;
        _filteredAvailableStudents = available;
      });
    } catch (e) {
      print('Error loading available students: $e');
    }
  }

  void _filterAvailableStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredAvailableStudents = _availableStudents;
      } else {
        _filteredAvailableStudents = _availableStudents.where((student) {
          final name = student['full_name'].toString().toLowerCase();
          final lrn = student['lrn'].toString().toLowerCase();
          final email = student['email'].toString().toLowerCase();
          return name.contains(_searchQuery) ||
              lrn.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _addStudent(String studentId) async {
    try {
      setState(() => _isLoading = true);

      // Insert into classroom_students
      await _supabase.from('classroom_students').insert({
        'classroom_id': widget.classroomId,
        'student_id': studentId,
        'enrolled_at': DateTime.now().toIso8601String(),
      });

      // Update student count
      await _updateStudentCount();

      // Reload data
      await _loadData();

      // Notify parent
      widget.onStudentsChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeStudent(String studentId) async {
    try {
      setState(() => _isLoading = true);

      // Remove from classroom_students
      await _supabase
          .from('classroom_students')
          .delete()
          .eq('classroom_id', widget.classroomId)
          .eq('student_id', studentId);

      // Update student count
      await _updateStudentCount();

      // Reload data
      await _loadData();

      // Notify parent
      widget.onStudentsChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentCount() async {
    try {
      // Get current enrollment count
      final rows = await _supabase
          .from('classroom_students')
          .select('student_id')
          .eq('classroom_id', widget.classroomId);
      final count = (rows as List).length;

      // Update classroom current_students
      await _supabase
          .from('classrooms')
          .update({'current_students': count})
          .eq('id', widget.classroomId);
    } catch (e) {
      print('Error updating student count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.people, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Manage Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Text('Enrolled (${_enrolledStudents.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle, size: 16),
                      const SizedBox(width: 8),
                      Text('Add Students (${_filteredAvailableStudents.length})'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar (only for Add Students tab)
            if (_tabController.index == 1)
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, LRN, or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterAvailableStudents,
              ),
            if (_tabController.index == 1) const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEnrolledStudentsTab(),
                        _buildAddStudentsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledStudentsTab() {
    if (_enrolledStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No students enrolled yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _enrolledStudents.length,
      itemBuilder: (context, index) {
        final student = _enrolledStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                student['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student['full_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(student['email'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _confirmRemoveStudent(student['student_id']),
              tooltip: 'Remove student',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddStudentsTab() {
    if (_filteredAvailableStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.check_circle : Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'All students are already enrolled'
                  : 'No students found matching "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAvailableStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredAvailableStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                student['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student['full_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LRN: ${student['lrn']}'),
                Text('Grade ${student['grade_level']} - ${student['section']}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => _addStudent(student['student_id']),
              tooltip: 'Add student',
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveStudent(String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text(
          'Are you sure you want to remove this student from the classroom?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeStudent(studentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

