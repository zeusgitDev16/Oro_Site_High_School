import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/screens/teacher/profile/teacher_profile_screen.dart';
import 'package:oro_site_high_school/screens/teacher/classroom/my_classroom_screen.dart';
import 'package:oro_site_high_school/services/teacher_course_service.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/models/course_file.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Teacher My Courses Screen
/// Shows courses assigned to the teacher by admin
class MyCoursesScreen extends StatefulWidget {
  final String origin; // 'dashboard' or 'profile'
  
  const MyCoursesScreen({super.key, this.origin = 'dashboard'});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  final TeacherCourseService _teacherCourseService = TeacherCourseService();
  late TabController _tabController;
  List<Course> _courses = [];
  bool _isLoading = true;
  RealtimeChannel? _courseTeachersChannel;
  String? _teacherId;
  Course? _selectedCourse;
  List<CourseFile> _moduleFiles = [];
  List<CourseFile> _assignmentFiles = [];
  bool _isLoadingFiles = false;
  
    
  // Course selection state
  Set<String> _selectedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeTeacher();
  }

  @override
  void dispose() {
    _courseTeachersChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeTeacher() async {
    try {
      // Get current user's teacher ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _teacherId = user.id;
        });
        _subscribeToCourseTeachers();
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
          _loadCourseFiles(_courses.first.id);
        }
      });
    } catch (e) {
      print('❌ Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToCourseTeachers() {
    try {
      if (_teacherId == null) return;
      final client = Supabase.instance.client;
      _courseTeachersChannel?.unsubscribe();

      _courseTeachersChannel = client.channel('watch-course_teachers-${_teacherId}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'course_teachers',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow != null && newRow['teacher_id'] == _teacherId) {
              _loadCourses();
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'course_teachers',
          callback: (payload) {
            final oldRow = payload.oldRecord;
            if (oldRow != null && oldRow['teacher_id'] == _teacherId) {
              _loadCourses();
            }
          },
        )
        ..subscribe();
    } catch (e) {
      print('⚠️ Realtime subscription error: $e');
    }
  }

  Future<void> _loadCourseFiles(String courseId) async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final modules = await _teacherCourseService.getCourseModules(courseId);
      final assignments = await _teacherCourseService.getCourseAssignments(courseId);
      
      setState(() {
        _moduleFiles = modules.map((json) => CourseFile.fromJson(json, 'module')).toList();
        _assignmentFiles = assignments.map((json) => CourseFile.fromJson(json, 'assignment')).toList();
        _isLoadingFiles = false;
      });
    } catch (e) {
      print('❌ Error loading course files: $e');
      setState(() {
        _isLoadingFiles = false;
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
          
          // Select All Courses
          if (_courses.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedCourseIds.length == _courses.length && _courses.isNotEmpty,
                    tristate: _selectedCourseIds.isNotEmpty && _selectedCourseIds.length < _courses.length,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCourseIds = _courses.map((c) => c.id).toSet();
                        } else {
                          _selectedCourseIds.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _selectedCourseIds.isEmpty
                          ? 'Select All Courses'
                          : _selectedCourseIds.length == _courses.length
                              ? 'All Courses Selected'
                              : '${_selectedCourseIds.length} Selected',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
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
                          final isCourseChecked = _selectedCourseIds.contains(course.id);
                          
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
                              leading: Checkbox(
                                value: isCourseChecked,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedCourseIds.add(course.id);
                                    } else {
                                      _selectedCourseIds.remove(course.id);
                                    }
                                  });
                                },
                              ),
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
                                _loadCourseFiles(course.id);
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

    // Show selected course with tabs
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCourse!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedCourse!.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'module resource'),
              Tab(text: 'assignment resource'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: _isLoadingFiles
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileList(_moduleFiles, 'module'),
                    _buildFileList(_assignmentFiles, 'assignment'),
                  ],
                ),
        ),
        
        // Share Button (appears when courses are selected)
        if (_selectedCourseIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  _buildSelectionSummary(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showShareDialog,
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Share To'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFileList(List<CourseFile> files, String type) {
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'the files from the admin can access by the teachers\nthat is added in the course.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                file.fileIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${file.fileSizeFormatted} • ${file.uploadedAt.toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: () => _downloadFile(file),
                  tooltip: 'Download',
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _viewFile(file),
                  tooltip: 'View',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  
  String _buildSelectionSummary() {
    final courseCount = _selectedCourseIds.length;
    return '$courseCount course${courseCount > 1 ? 's' : ''} selected';
  }

  void _clearSelection() {
    setState(() {
      _selectedCourseIds.clear();
    });
  }

  void _showShareDialog() {
    final selectedCourses = <Course>[];
    for (var course in _courses) {
      if (_selectedCourseIds.contains(course.id)) {
        selectedCourses.add(course);
      }
    }

    showDialog(
      context: context,
      builder: (context) => _ShareFilesDialog(
        files: const [],
        courses: selectedCourses,
        courseTitle: _selectedCourse?.title ?? '',
        onShared: () {
          _clearSelection();
        },
      ),
    );
  }

  Future<void> _downloadFile(CourseFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${file.fileName}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch ${file.fileUrl}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewFile(CourseFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not open ${file.fileUrl}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

/// Share Files Dialog
/// Allows teacher to share selected files with students
class _ShareFilesDialog extends StatefulWidget {
  final List<CourseFile> files;
  final List<Course> courses;
  final String courseTitle;
  final VoidCallback onShared;

  const _ShareFilesDialog({
    required this.files,
    required this.courses,
    required this.courseTitle,
    required this.onShared,
  });

  @override
  State<_ShareFilesDialog> createState() => _ShareFilesDialogState();
}

class _ShareFilesDialogState extends State<_ShareFilesDialog> {
  final ClassroomService _classroomService = ClassroomService();
  List<Classroom> _classrooms = [];
  Set<String> _selectedClassroomIds = {};
  bool _isSharing = false;
  bool _isLoadingClassrooms = true;
  String? _teacherId;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _teacherId = user.id;
        final classrooms = await _classroomService.getTeacherClassrooms(user.id);
        // Fetch live enrollment counts and merge into classroom objects
        final ids = classrooms.map((c) => c.id).toList();
        final counts = await _classroomService.getEnrollmentCountsForClassrooms(ids);
        final merged = classrooms.map((c) => c.copyWith(
          currentStudents: counts[c.id] ?? c.currentStudents,
        )).toList();
        setState(() {
          _classrooms = merged;
          _isLoadingClassrooms = false;
        });
      }
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _isLoadingClassrooms = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share To Classrooms',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildDialogSubtitle(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Selection Summary
            Column(
              children: [
                if (widget.files.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.files.length} ${widget.files.length == 1 ? 'file' : 'files'} ${widget.files.length == 1 ? 'is' : 'are'} about to be shared',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.files.isNotEmpty && widget.courses.isNotEmpty)
                  const SizedBox(height: 12),
                if (widget.courses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${widget.courses.length} ${widget.courses.length == 1 ? 'course' : 'courses'} ${widget.courses.length == 1 ? 'is' : 'are'} about to be shared',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade900, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Only module resources will be shared. Assignment resources are kept confidential for teachers only.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber.shade900,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Classrooms List or Empty State
            _isLoadingClassrooms
                ? Container(
                    padding: const EdgeInsets.all(32),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _classrooms.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.class_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'you have no classrooms, create one to link your courses!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyClassroomScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Create Classroom'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Select All Checkbox
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selectedClassroomIds.length == _classrooms.length && _classrooms.isNotEmpty,
                                  tristate: _selectedClassroomIds.isNotEmpty && _selectedClassroomIds.length < _classrooms.length,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedClassroomIds = _classrooms.map((c) => c.id).toSet();
                                      } else {
                                        _selectedClassroomIds.clear();
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedClassroomIds.isEmpty
                                      ? 'Select All Classrooms'
                                      : _selectedClassroomIds.length == _classrooms.length
                                          ? 'All Classrooms Selected'
                                          : '${_selectedClassroomIds.length} Selected',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Classrooms List
                          ...widget.courses.isNotEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Select classrooms to share ${widget.courses.length} course${widget.courses.length > 1 ? 's' : ''} to:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                          
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _classrooms.length,
                              itemBuilder: (context, index) {
                                final classroom = _classrooms[index];
                                final isSelected = _selectedClassroomIds.contains(classroom.id);
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedClassroomIds.add(classroom.id);
                                        } else {
                                          _selectedClassroomIds.remove(classroom.id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      classroom.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Grade ${classroom.gradeLevel} • ${classroom.currentStudents}/${classroom.maxStudents} students',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSharing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                if (_classrooms.isNotEmpty && _selectedClassroomIds.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareToClassrooms,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share, size: 20),
                    label: Text(_isSharing ? 'Sharing...' : 'Share Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildDialogSubtitle() {
    return 'Share ${widget.courses.length} course${widget.courses.length > 1 ? 's' : ''}';
  }

  Future<void> _shareToClassrooms() async {
    if (_selectedClassroomIds.isEmpty || _teacherId == null) return;

    setState(() {
      _isSharing = true;
    });

    try {
      int successCount = 0;
      int errorCount = 0;

      // Share courses to selected classrooms
      for (final courseId in widget.courses.map((c) => c.id)) {
        for (final classroomId in _selectedClassroomIds) {
          try {
            await _classroomService.addCourseToClassroom(
              classroomId: classroomId,
              courseId: courseId,
              addedBy: _teacherId!,
            );
            successCount++;
          } catch (e) {
            // Check if it's a duplicate error (already linked)
            if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
              // Silently skip duplicates
              successCount++;
            } else {
              errorCount++;
              print('❌ Error sharing course $courseId to classroom $classroomId: $e');
            }
          }
        }
      }

      Navigator.of(context).pop();
      widget.onShared();

      if (mounted) {
        final message = errorCount == 0
            ? 'Successfully shared ${widget.courses.length} course${widget.courses.length > 1 ? 's' : ''} to ${_selectedClassroomIds.length} classroom${_selectedClassroomIds.length > 1 ? 's' : ''}!'
            : 'Shared with $successCount success(es) and $errorCount error(s)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSharing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
