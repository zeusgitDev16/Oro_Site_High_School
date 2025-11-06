import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/screens/student/dashboard/student_dashboard_screen.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/teacher_course_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/models/course_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/widgets/announcement_tab.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_read_screen.dart';

/// Student Classroom Screen (Unified Layout)
/// Mirrors the teacher's 3-panel layout but with student permissions (read-only)
class StudentClassroomScreen extends StatefulWidget {
  const StudentClassroomScreen({super.key});

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen>
    with TickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final TeacherCourseService _teacherCourseService = TeacherCourseService();
  final AssignmentService _assignmentService = AssignmentService();
  final TextEditingController _accessCodeController = TextEditingController();

  String? _studentId;
  RealtimeChannel? _assignmentsChannel;

  // Left panel
  List<Classroom> _classrooms = [];
  Map<String, int> _enrollmentCounts = {};
  Classroom? _selectedClassroom;

  // Middle panel
  List<Course> _classroomCourses = [];
  Course? _selectedCourse;

  // Right panel state
  late TabController
  _tabController; // modules, assignments, announcements, projects

  // Modules
  List<CourseFile> _moduleFiles = [];

  // Assignments (published only for students)
  List<Map<String, dynamic>> _assignments = [];
  // Quarter sub-tabs for assignments
  int _selectedQuarter = 1; // 1..4
  late TabController _quarterTabController;

  // Loading flags
  bool _isLoading = true;
  bool _isLoadingCourses = false;
  bool _isLoadingModules = false;
  bool _isLoadingAssignments = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_selectedClassroom == null || _selectedCourse == null) return;
      if (_tabController.index == 0) {
        _loadCourseModules(_selectedCourse!.id);
      } else if (_tabController.index == 1) {
        _loadAssignmentsPublished(
          classroomId: _selectedClassroom!.id,
          courseId: _selectedCourse!.id,
        );
      } else {
        // projects tab – placeholder
      }
    });
    _quarterTabController = TabController(length: 4, vsync: this);
    _quarterTabController.addListener(() {
      final q = _quarterTabController.index + 1;
      if (q != _selectedQuarter) {
        setState(() {
          _selectedQuarter = q;
        });
      }
    });
    _subscribeAssignmentsRealtime();
    _initializeStudent();
  }

  @override
  void dispose() {
    _assignmentsChannel?.unsubscribe();
    _accessCodeController.dispose();
    _quarterTabController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeAssignmentsRealtime() {
    _assignmentsChannel?.unsubscribe();
    final supa = Supabase.instance.client;
    _assignmentsChannel = supa
        .channel('student-assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          callback: (payload) {
            final map = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final row = Map<String, dynamic>.from(map);
            final clsId = (row['classroom_id'] ?? '').toString();
            final courseId = (row['course_id'] ?? '').toString();
            if (_selectedClassroom != null &&
                _selectedCourse != null &&
                clsId == _selectedClassroom!.id &&
                courseId == _selectedCourse!.id) {
              if (mounted && _tabController.index == 1) {
                _loadAssignmentsPublished(
                  classroomId: _selectedClassroom!.id,
                  courseId: _selectedCourse!.id,
                );
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _initializeStudent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _studentId = user.id;
        await _loadStudentClassrooms();
      }
    } catch (e) {
      debugPrint('❌ Error initializing student: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudentClassrooms() async {
    if (_studentId == null) return;
    setState(() => _isLoading = true);
    try {
      final classrooms = await _classroomService.getStudentClassrooms(
        _studentId!,
      );
      // Fetch live counts and override
      final counts = await _classroomService.getEnrollmentCountsForClassrooms(
        classrooms.map((c) => c.id).toList(),
      );
      final updated = classrooms
          .map(
            (c) =>
                c.copyWith(currentStudents: counts[c.id] ?? c.currentStudents),
          )
          .toList();
      setState(() {
        _classrooms = updated;
        _enrollmentCounts = counts;
      });
      if (_classrooms.isNotEmpty && _selectedClassroom == null) {
        _onSelectClassroom(_classrooms.first);
      }
    } catch (e) {
      debugPrint('❌ Error loading student classrooms: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassroomCourses(String classroomId) async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _classroomService.getClassroomCourses(classroomId);
      setState(() {
        _classroomCourses = courses;
      });
      if (_classroomCourses.isNotEmpty) {
        _onSelectCourse(_classroomCourses.first);
      } else {
        setState(() {
          _selectedCourse = null;
          _moduleFiles = [];
          _assignments = [];
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading classroom courses: $e');
      setState(() {
        _classroomCourses = [];
        _selectedCourse = null;
        _moduleFiles = [];
        _assignments = [];
      });
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadCourseModules(String courseId) async {
    setState(() => _isLoadingModules = true);
    try {
      final modules = await _teacherCourseService.getCourseModules(courseId);
      // Filter to only those visible to students if the flag exists on the raw json
      final filtered = modules.where((m) {
        try {
          if (m is Map && m.containsKey('is_visible_to_students')) {
            final v = m['is_visible_to_students'];
            if (v is bool) return v;
            if (v is String) return v.toLowerCase() == 'true';
          }
        } catch (_) {}
        // Default to visible if flag is absent
        return true;
      }).toList();

      setState(
        () => _moduleFiles = filtered
            .map((json) => CourseFile.fromJson(json, 'module'))
            .toList(),
      );
    } catch (e) {
      debugPrint('❌ Error loading modules: $e');
      setState(() => _moduleFiles = []);
    } finally {
      if (mounted) setState(() => _isLoadingModules = false);
    }
  }

  Future<void> _loadAssignmentsPublished({
    required String classroomId,
    required String courseId,
  }) async {
    setState(() => _isLoadingAssignments = true);
    try {
      final rows = await _assignmentService.getAssignmentsByClassroomAndCourse(
        classroomId: classroomId,
        courseId: courseId,
      );
      setState(() => _assignments = rows);
    } catch (e) {
      debugPrint('❌ Error loading assignments: $e');
      setState(() => _assignments = []);
    } finally {
      if (mounted) setState(() => _isLoadingAssignments = false);
    }
  }

  void _onSelectClassroom(Classroom c) {
    setState(() {
      _selectedClassroom = c;
      _selectedCourse = null;
      _classroomCourses = [];
      _moduleFiles = [];
      _assignments = [];
    });
    _loadClassroomCourses(c.id);
  }

  void _onSelectCourse(Course c) {
    setState(() {
      _selectedCourse = c;
      _moduleFiles = [];
      _assignments = [];
    });
    // Trigger load for the active tab
    if (_tabController.index == 0) {
      _loadCourseModules(c.id);
    } else if (_tabController.index == 1) {
      _loadAssignmentsPublished(
        classroomId: _selectedClassroom!.id,
        courseId: c.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildClassroomSidebar(),
          if (_selectedClassroom != null) _buildCoursesPanel(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildClassroomSidebar() {
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
          // Header row (Back + Title)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLASSROOMS',
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

          const Divider(height: 1),

          // Join by Access Code (top right of sidebar header alternative)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _accessCodeController,
                            decoration: InputDecoration(
                              hintText: 'enter access code',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(8),
                            ],
                            onSubmitted: (_) =>
                                _isJoining ? null : _joinClassroom(),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isJoining ? null : _joinClassroom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Classroom list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'you have 0 classrooms',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _classrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = _classrooms[index];
                      final isSelected = _selectedClassroom?.id == classroom.id;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            classroom.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Grade ${classroom.gradeLevel} • ${(_enrollmentCounts[classroom.id] ?? classroom.currentStudents)}/${classroom.maxStudents} students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onTap: () => _onSelectClassroom(classroom),
                        ),
                      );
                    },
                  ),
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
          Expanded(
            child: _isLoadingCourses
                ? const Center(child: CircularProgressIndicator())
                : _classroomCourses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No courses yet',
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            course.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onTap: () => _onSelectCourse(course),
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
    if (_selectedClassroom == null) {
      return const Center(
        child: Text('Select a classroom from the left panel'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Classroom + Course header
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
                      _selectedClassroom!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedClassroom!.description ??
                          'classroom description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                  _selectedCourse!.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

        if (_selectedCourse != null)
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
              isScrollable: true,
              tabs: const [
                Tab(text: 'modules'),
                Tab(text: 'assignments'),
                Tab(text: 'announcements'),
                Tab(text: 'projects'),
              ],
            ),
          ),

        if (_selectedCourse != null)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModulesTab(),
                _buildAssignmentsTab(),
                AnnouncementTab(
                  classroomId: _selectedClassroom!.id,
                  courseId: _selectedCourse!.id,
                ),
                _buildProjectsTab(),
              ],
            ),
          ),

        if (_selectedCourse == null)
          const Expanded(
            child: Center(child: Text('Select a course to view content')),
          ),
      ],
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
              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No modules available',
                style: TextStyle(color: Colors.grey.shade600),
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
              child: Text(file.fileIcon, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Text(
              '${file.fileSizeFormatted} • ${file.uploadedAt.toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // Students: read-only; viewing handled externally (teacher side uses launcher)
                Icon(Icons.visibility, size: 20, color: Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    // Quarter header tabs
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
        Expanded(child: _buildAssignmentsQuarterList()),
      ],
    );
  }

  Widget _buildAssignmentsQuarterList() {
    final filtered = _assignments.where((a) {
      int? qInt;
      // Primary: use quarter_no column when present
      final q = a['quarter_no'];
      if (q != null) {
        qInt = int.tryParse(q.toString());
      }
      // Fallback: derive from content.meta.quarter_no to support older rows
      if (qInt == null) {
        try {
          final content = a['content'];
          if (content is Map) {
            final meta = content['meta'];
            if (meta is Map && meta['quarter_no'] != null) {
              qInt = int.tryParse(meta['quarter_no'].toString());
            }
          }
        } catch (_) {}
      }
      return qInt != null && qInt == _selectedQuarter;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No published assignments for Q$_selectedQuarter',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final String courseName = (_selectedCourse?.title ?? '');
        final String type = (a['assignment_type'] ?? a['type'] ?? 'Task')
            .toString();
        final String points = (a['total_points'] ?? a['points'] ?? 0)
            .toString();
        String dueStr = '-';
        try {
          final raw = a['due_date'];
          if (raw != null) {
            final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
            dueStr = '${dt.month}/${dt.day}/${dt.year}';
          }
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.grey.shade100,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => StudentAssignmentReadScreen(
                    assignmentId: a['id'].toString(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                (a['title'] ?? 'Untitled Assignment')
                                    .toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$courseName • $type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          'Published',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$points pts • $dueStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Projects coming soon',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClassroom() async {
    final accessCode = _accessCodeController.text.trim();

    if (accessCode.isEmpty) {
      _showError('Please enter an access code');
      return;
    }

    if (accessCode.length != 8) {
      _showError('Access code must be 8 characters');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('You must be signed in.');
      return;
    }

    setState(() => _isJoining = true);
    try {
      final res = await _classroomService.joinClassroom(
        studentId: user.id,
        accessCode: accessCode,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        _accessCodeController.clear();
        await _loadStudentClassrooms();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Joined classroom successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showError((res['message'] ?? 'Failed to join classroom').toString());
      }
    } catch (e) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
