import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/screens/teacher/profile/teacher_profile_screen.dart';
import 'package:oro_site_high_school/services/teacher_course_service.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Teacher My Courses Screen
/// Shows courses assigned to the teacher by admin
class MyCoursesScreen extends StatefulWidget {
  final String origin; // 'dashboard' or 'profile'
  
  const MyCoursesScreen({super.key, this.origin = 'dashboard'});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final TeacherCourseService _teacherCourseService = TeacherCourseService();
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _teacherId;
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _initializeTeacher();
  }

  Future<void> _initializeTeacher() async {
    try {
      // Get current user's teacher ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _teacherId = user.id;
        });
        await _loadCourses();
      }
    } catch (e) {
      print('❌ Error initializing teacher: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    if (_teacherId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _teacherCourseService.getTeacherCourses(_teacherId!);
      
      setState(() {
        _courses = courses;
        _isLoading = false;
        // Auto-select first course if available
        if (_courses.isNotEmpty) {
          _selectedCourse = _courses.first;
        }
      });
    } catch (e) {
      print('❌ Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // Left Sidebar
            _buildSidebar(),
            
            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'COURSE MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Course Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _isLoading 
                  ? 'Loading...' 
                  : 'you have ${_courses.length} course${_courses.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Course List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _courses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'your courses will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          final isSelected = _selectedCourse?.id == course.id;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                course.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCourse = course;
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'you are not added to any courses yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your admin to be assigned to courses',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedCourse == null) {
      return Center(
        child: Text(
          'Select a course from the sidebar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // Show selected course details
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          Text(
            _selectedCourse!.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCourse!.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // Course Info Cards
          Row(
            children: [
              _buildInfoCard(
                'Created',
                _formatDate(_selectedCourse!.createdAt),
                Icons.calendar_today,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                'Last Updated',
                _formatDate(_selectedCourse!.updatedAt),
                Icons.update,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                'Status',
                _selectedCourse!.isActive ? 'Active' : 'Inactive',
                Icons.check_circle,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Placeholder for future features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'Course Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Course modules, assignments, and student management features will be available here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _navigateBack() {
    if (widget.origin == 'profile') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TeacherProfileScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TeacherDashboardScreen(),
        ),
      );
    }
  }
}
