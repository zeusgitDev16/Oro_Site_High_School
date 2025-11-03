import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/screens/student/classroom/student_classroom_screen.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/teacher_course_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/models/course_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_read_screen.dart';

/// Student Classroom Detail Screen
/// Shows classroom content exactly like teacher view but read-only
class StudentClassroomDetailScreen extends StatefulWidget {
  final Classroom classroom;

  const StudentClassroomDetailScreen({
    super.key,
    required this.classroom,
  });

  @override
  State<StudentClassroomDetailScreen> createState() => _StudentClassroomDetailScreenState();
}

class _StudentClassroomDetailScreenState extends State<StudentClassroomDetailScreen>
    with TickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final TeacherCourseService _courseService = TeacherCourseService();
  
  List<Course> _classroomCourses = [];
  Course? _selectedCourse;
  List<CourseFile> _moduleFiles = [];
  bool _isLoadingCourses = false;
  bool _isLoadingModules = false;
  bool _isLoadingTeacher = false;
  late TabController _tabController;
  Map<String, dynamic>? _teacherInfo;
  // Assignments state for students
  bool _isLoadingAssignments = false;
  List<Map<String, dynamic>> _assignments = [];
  // Quarter sub-tabs
  int _selectedQuarter = 1;
  late TabController _quarterTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _quarterTabController = TabController(length: 4, vsync: this);
    _quarterTabController.addListener(() {
      final q = _quarterTabController.index + 1;
      if (q != _selectedQuarter) {
        setState(() { _selectedQuarter = q; });
      }
    });
    _loadTeacherInfo();
    _loadClassroomCourses();
  }

  Future<void> _loadTeacherInfo() async {
    setState(() {
      _isLoadingTeacher = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('email')
          .eq('id', widget.classroom.teacherId)
          .single();

      setState(() {
        _teacherInfo = response;
        _isLoadingTeacher = false;
      });
    } catch (e) {
      print('❌ Error loading teacher info: $e');
      setState(() {
        _isLoadingTeacher = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quarterTabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroomCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courses = await _classroomService.getClassroomCourses(widget.classroom.id);
      setState(() {
        _classroomCourses = courses;
        _isLoadingCourses = false;
        // Auto-select first course
        if (_classroomCourses.isNotEmpty) {
          _selectedCourse = _classroomCourses.first;
          _loadCourseModules(_classroomCourses.first.id);
          // Load assignments once there is at least one course selected
          _loadAssignments();
        } else {
          _selectedCourse = null;
          _moduleFiles = [];
        }
      });
    } catch (e) {
      print('❌ Error loading classroom courses: $e');
      setState(() {
        _classroomCourses = [];
        _selectedCourse = null;
        _moduleFiles = [];
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadCourseModules(String courseId) async {
    setState(() {
      _isLoadingModules = true;
    });

    try {
      final modules = await _courseService.getCourseModules(courseId);
      setState(() {
        _moduleFiles = modules.map((json) => CourseFile.fromJson(json, 'module')).toList();
        _isLoadingModules = false;
      });
    } catch (e) {
      print('❌ Error loading modules: $e');
      setState(() {
        _moduleFiles = [];
        _isLoadingModules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar - Back button
          _buildBackButton(),
          
          // Middle Panel - Courses
          _buildCoursesPanel(),
          
          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentClassroomScreen(),
                ),
              );
            },
            tooltip: 'Back to classrooms',
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesPanel() {
    return Container(
      width: 200,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'courses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Courses List
          Expanded(
            child: _isLoadingCourses
                ? const Center(child: CircularProgressIndicator())
                : _classroomCourses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No courses added yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _classroomCourses.length,
                        itemBuilder: (context, index) {
                          final course = _classroomCourses[index];
                          final isSelected = _selectedCourse?.id == course.id;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'algebra',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCourse = course;
                                });
                                _loadCourseModules(course.id);
                                _loadAssignments();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Classroom Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classroom.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.classroom.description ?? 'classroom description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Teacher Information Display
              _isLoadingTeacher
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Teacher: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _teacherInfo?['email'] ?? 'Loading...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        
        // Course Title
        if (_selectedCourse != null)
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'algebra',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        
        // Tabs with filter button
        if (_selectedCourse != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filter options - Coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  tooltip: 'Filter options',
                  color: Colors.grey.shade700,
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'students'),
                      Tab(text: 'modules'),
                      Tab(text: 'assignments'),
                      Tab(text: 'announcements'),
                      Tab(text: 'projects'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        // Tab Content
        if (_selectedCourse != null)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsTab(),
                _buildModulesTab(),
                _buildAssignmentsTab(),
                _buildAnnouncementsTab(),
                _buildProjectsTab(),
              ],
            ),
          ),
        
        // Empty state when no course selected
        if (_selectedCourse == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _classroomCourses.isEmpty
                        ? 'No courses added to this classroom yet'
                        : 'Select a course to view content',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _classroomService.getClassroomStudents(widget.classroom.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading students: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students enrolled yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final fullName = student['full_name'] ?? '';
            final initials = fullName.isNotEmpty 
                ? fullName.split(' ').map((n) => n[0]).take(2).join()
                : 'S';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  student['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModulesTab() {
    if (_isLoadingModules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_moduleFiles.isEmpty) {
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
                'No module files available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Module resources will appear here when added to the course',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _moduleFiles.length,
      itemBuilder: (context, index) {
        final file = _moduleFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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

  Widget _buildAssignmentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _quarterTabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Q1'),
              Tab(text: 'Q2'),
              Tab(text: 'Q3'),
              Tab(text: 'Q4'),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingAssignments
              ? const Center(child: CircularProgressIndicator())
              : _buildAssignmentsQuarterList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentsQuarterList() {
    // Filter using quarter_no column; fallback to content.meta.quarter_no
    final filtered = _assignments.where((a) {
      int? qInt;
      final q = a['quarter_no'];
      if (q != null) qInt = int.tryParse(q.toString());
      if (qInt == null) {
        final content = a['content'];
        if (content is Map) {
          final meta = content['meta'];
          if (meta is Map) {
            final mq = meta['quarter_no'];
            if (mq != null) qInt = int.tryParse(mq.toString());
          }
        }
      }
      return qInt == _selectedQuarter;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No assignments for Q$_selectedQuarter', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final dueRaw = a['due_date'];
        DateTime? due;
        if (dueRaw != null && dueRaw.toString().isNotEmpty) {
          try { due = DateTime.parse(dueRaw.toString()); } catch (_) {}
        }
        return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
        leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(Icons.assignment, color: Colors.blue.shade700),
        ),
        title: Text(a['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const SizedBox(height: 4),
        Text('${a['total_points'] ?? 0} pts', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        if (due != null) ...[
        const SizedBox(height: 2),
        Row(
        children: [
        Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text('${due.month}/${due.day}/${due.year} ${_formatAmPm(due)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
        ),
        ],
        ],
        ),
        trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        tooltip: 'Open',
        onPressed: () {
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => StudentAssignmentReadScreen(assignmentId: a['id'].toString()),
        ),
        );
        },
        ),
        onTap: () {
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => StudentAssignmentReadScreen(assignmentId: a['id'].toString()),
        ),
        );
        },
        ),
        );
      },
    );
  }

  String _formatAmPm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ap';
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoadingAssignments = true;
    });
    try {
      var builder = Supabase.instance.client
          .from('assignments')
          .select()
          .eq('classroom_id', widget.classroom.id)
          .eq('is_active', true)
          .eq('is_published', true);
      if (_selectedCourse != null) {
        builder = builder.eq('course_id', _selectedCourse!.id);
      }
      final list = await builder.order('created_at', ascending: false);
      setState(() {
        _assignments = List<Map<String, dynamic>>.from(list as List);
        _isLoadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        _assignments = [];
        _isLoadingAssignments = false;
      });
    }
  }

  Widget _buildAnnouncementsTab() {
    return Center(
      child: Text(
        'Announcements tab - Coming soon',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildProjectsTab() {
    return Center(
      child: Text(
        'Projects tab - Coming soon',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}
