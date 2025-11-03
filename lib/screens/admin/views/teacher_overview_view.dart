import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/course_assignment_service.dart';
import 'package:oro_site_high_school/services/teacher_request_service.dart';
import 'package:oro_site_high_school/screens/admin/teachers/teacher_detail_screen.dart';

/// Teacher Overview View for Admin Dashboard
/// Shows teacher activities, workload, and performance
/// UI-only component following OSHS architecture
class TeacherOverviewView extends StatefulWidget {
  const TeacherOverviewView({super.key});

  @override
  State<TeacherOverviewView> createState() => _TeacherOverviewViewState();
}

class _TeacherOverviewViewState extends State<TeacherOverviewView> {
  final CourseAssignmentService _assignmentService = CourseAssignmentService();
  final TeacherRequestService _requestService = TeacherRequestService();
  bool _isLoading = true;
  Map<String, int> _teacherWorkload = {};
  int _pendingRequests = 0;

  // Mock teacher data (will be replaced with actual teacher service)
  final List<Map<String, dynamic>> _teachers = [
    {
      'id': 'teacher-1',
      'name': 'Maria Santos',
      'role': 'Grade Level Coordinator',
      'gradeLevel': 7,
      'courses': 2,
      'students': 70,
      'sections': 6,
      'status': 'active',
      'lastActive': DateTime.now().subtract(const Duration(minutes: 15)),
      'performance': {
        'grading': 95,
        'attendance': 100,
        'resources': 85,
        'communication': 90,
      },
    },
    {
      'id': 'teacher-2',
      'name': 'Juan Reyes',
      'role': 'Teacher',
      'gradeLevel': 8,
      'courses': 2,
      'students': 70,
      'sections': 1,
      'status': 'active',
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      'performance': {
        'grading': 88,
        'attendance': 95,
        'resources': 78,
        'communication': 85,
      },
    },
    {
      'id': 'teacher-3',
      'name': 'Ana Cruz',
      'role': 'Teacher',
      'gradeLevel': 9,
      'courses': 3,
      'students': 105,
      'sections': 1,
      'status': 'active',
      'lastActive': DateTime.now().subtract(const Duration(hours: 5)),
      'performance': {
        'grading': 92,
        'attendance': 88,
        'resources': 90,
        'communication': 87,
      },
    },
    {
      'id': 'teacher-4',
      'name': 'Pedro Garcia',
      'role': 'Teacher',
      'gradeLevel': 10,
      'courses': 1,
      'students': 35,
      'sections': 1,
      'status': 'active',
      'lastActive': DateTime.now().subtract(const Duration(days: 1)),
      'performance': {
        'grading': 85,
        'attendance': 92,
        'resources': 75,
        'communication': 80,
      },
    },
    {
      'id': 'teacher-5',
      'name': 'Rosa Mendoza',
      'role': 'Teacher',
      'gradeLevel': 11,
      'courses': 2,
      'students': 70,
      'sections': 1,
      'status': 'active',
      'lastActive': DateTime.now().subtract(const Duration(hours: 8)),
      'performance': {
        'grading': 90,
        'attendance': 94,
        'resources': 88,
        'communication': 92,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workload = await _assignmentService.getTeacherWorkload();
      final requests = await _requestService.getPendingRequests();

      setState(() {
        _teacherWorkload = workload;
        _pendingRequests = requests.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 32),
          _buildTeacherWorkloadSection(),
          const SizedBox(height: 32),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
              Icons.people,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher Overview',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_teachers.length} active teachers • $_pendingRequests pending requests',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalCourses = _teachers.fold<int>(0, (sum, t) => sum + (t['courses'] as int));
    final totalStudents = _teachers.fold<int>(0, (sum, t) => sum + (t['students'] as int));
    final avgPerformance = _teachers.fold<double>(
          0,
          (sum, t) {
            final perf = t['performance'] as Map<String, dynamic>;
            final avg = (perf['grading'] + perf['attendance'] + perf['resources'] + perf['communication']) / 4;
            return sum + avg;
          },
        ) /
        _teachers.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Teachers',
            '${_teachers.length}',
            Icons.people,
            Colors.blue,
            'Active in system',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Courses',
            '$totalCourses',
            Icons.school,
            Colors.green,
            'Being taught',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Students',
            '$totalStudents',
            Icons.groups,
            Colors.orange,
            'Under supervision',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg Performance',
            '${avgPerformance.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.purple,
            'Overall rating',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherWorkloadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Teacher Workload',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'overloaded', label: Text('Overloaded')),
                ButtonSegment(value: 'available', label: Text('Available')),
              ],
              selected: {'all'},
              onSelectionChanged: (Set<String> newSelection) {
                // Filter logic here
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: _teachers.length,
          itemBuilder: (context, index) {
            return _buildTeacherCard(_teachers[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final isOverloaded = teacher['courses'] >= 3;
    final performance = teacher['performance'] as Map<String, dynamic>;
    final avgPerf = (performance['grading'] + performance['attendance'] + 
                     performance['resources'] + performance['communication']) / 4;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDetailScreen(teacher: teacher),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    teacher['name'].split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher['role'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'HIGH LOAD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTeacherStat(Icons.school, '${teacher['courses']}', 'Courses'),
                const SizedBox(width: 16),
                _buildTeacherStat(Icons.people, '${teacher['students']}', 'Students'),
                const SizedBox(width: 16),
                _buildTeacherStat(Icons.class_, '${teacher['sections']}', 'Sections'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Performance: ${avgPerf.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatLastActive(teacher['lastActive']),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTeacherStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Teacher Activity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildActivityItem(
                'Maria Santos',
                'Created attendance session for Grade 7 - Diamond',
                '15 minutes ago',
                Icons.fact_check,
                Colors.green,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Juan Reyes',
                'Entered grades for Mathematics 8 Quiz 3',
                '2 hours ago',
                Icons.grade,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Ana Cruz',
                'Uploaded resource: Science 9 Module 4',
                '5 hours ago',
                Icons.upload_file,
                Colors.purple,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Rosa Mendoza',
                'Submitted request: Need projector for Room 301',
                '8 hours ago',
                Icons.inbox,
                Colors.orange,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Pedro Garcia',
                'Created assignment: Filipino 10 Essay',
                '1 day ago',
                Icons.assignment,
                Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String teacher,
    String activity,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        teacher,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        activity,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  String _formatLastActive(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
