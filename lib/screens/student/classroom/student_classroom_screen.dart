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
import 'package:oro_site_high_school/services/submission_service.dart';

import 'package:oro_site_high_school/widgets/announcement_tab.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_read_screen.dart';

import 'package:oro_site_high_school/services/profile_service.dart';
import 'package:oro_site_high_school/models/profile.dart';

import 'package:url_launcher/url_launcher.dart';

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
  final SubmissionService _submissionService = SubmissionService();

  final TeacherCourseService _teacherCourseService = TeacherCourseService();
  final AssignmentService _assignmentService = AssignmentService();
  String? _studentId;
  RealtimeChannel? _assignmentsChannel;
  RealtimeChannel? _submissionsChannel;

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
  // Student submission lookup keyed by assignment_id
  Map<String, Map<String, dynamic>> _submissionsByAssignment = {};
  // Quarter sub-tabs for assignments
  int _selectedQuarter = 1; // 1..4
  late TabController _quarterTabController;

  // Loading flags
  bool _isLoading = true;
  bool _isLoadingCourses = false;
  bool _isLoadingModules = false;
  bool _isLoadingAssignments = false;
  bool _isJoining = false;

  final TextEditingController _accessCodeController = TextEditingController();

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
    _submissionsChannel?.unsubscribe();
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

  void _subscribeSubmissionsRealtime() {
    _submissionsChannel?.unsubscribe();
    final uid = _studentId;
    if (uid == null) return;
    final supa = Supabase.instance.client;
    _submissionsChannel = supa
        .channel('student-submissions:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignment_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (payload) {
            if (!mounted) return;
            if (_selectedClassroom != null &&
                _selectedCourse != null &&
                _tabController.index == 1 &&
                _assignments.isNotEmpty) {
              _loadSubmissionStatuses();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadSubmissionStatuses() async {
    final uid = _studentId;
    if (uid == null) return;
    final ids = _assignments
        .map((a) => (a['id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    if (ids.isEmpty) {
      if (mounted) setState(() => _submissionsByAssignment = {});
      return;
    }
    try {
      final rows = await _submissionService.getStudentSubmissionsForAssignments(
        studentId: uid,
        assignmentIds: ids,
      );
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final aid = (r['assignment_id'] ?? '').toString();
        if (aid.isNotEmpty) {
          map[aid] = Map<String, dynamic>.from(r);
        }
      }
      if (mounted) setState(() => _submissionsByAssignment = map);
    } catch (e) {
      debugPrint('❌ Error fetching submission statuses: $e');
    }
  }

  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v.toLocal();
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _deriveSubmissionStatus(
    Map<String, dynamic> assignment,
    Map<String, dynamic>? submission,
  ) {
    // graded/submitted or late
    if (submission != null) {
      final statusStr = (submission['status'] ?? '').toString();
      // Explicit teacher-graded takes precedence
      if (statusStr == 'graded') {
        return 'graded';
      }
      if (statusStr == 'submitted') {
        final due = _parseDateTime(assignment['due_date']);
        final submittedAt = _parseDateTime(submission['submitted_at']);
        final allowLate =
            (assignment['allow_late_submissions'] ?? false) == true;
        // Preserve existing late handling
        if (allowLate &&
            due != null &&
            submittedAt != null &&
            submittedAt.isAfter(due)) {
          return 'late';
        }
        // For objective types with an immediate score, reflect as graded
        final type = (assignment['assignment_type'] ?? '').toString();
        final isObjective =
            type == 'quiz' ||
            type == 'multiple_choice' ||
            type == 'identification' ||
            type == 'matching_type';
        final hasScore = (submission['score'] as num?) != null;
        if (isObjective && hasScore) {
          return 'graded';
        }
        return 'submitted';
      }
    }
    // pending or missed
    final due = _parseDateTime(assignment['due_date']);
    if (due != null && DateTime.now().isAfter(due)) {
      return 'missed';
    }
    return 'pending';
  }

  // NEW: Get assignment timeline status
  String _getAssignmentTimelineStatus(Map<String, dynamic> assignment) {
    final now = DateTime.now();
    final startTime = assignment['start_time'] != null
        ? DateTime.tryParse(assignment['start_time'].toString())
        : null;
    final dueDate = assignment['due_date'] != null
        ? DateTime.tryParse(assignment['due_date'].toString())
        : null;
    final endTime = assignment['end_time'] != null
        ? DateTime.tryParse(assignment['end_time'].toString())
        : null;
    final allowLate = assignment['allow_late_submissions'] ?? true;

    // Scheduled: not yet visible
    if (startTime != null && now.isBefore(startTime)) {
      return 'scheduled';
    }

    // Ended: past end time
    if (endTime != null && now.isAfter(endTime)) {
      return 'ended';
    }

    // Late: past due date but before end time (if late submissions allowed)
    if (dueDate != null && now.isAfter(dueDate)) {
      return allowLate ? 'late' : 'ended';
    }

    // Active: between start and due
    return 'active';
  }

  // NEW: Build timeline status badge for students
  Widget _buildTimelineStatusBadge(Map<String, dynamic> assignment) {
    final status = _getAssignmentTimelineStatus(assignment);

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'scheduled':
        icon = Icons.schedule;
        color = Colors.blue;
        label = 'Scheduled';
        break;
      case 'active':
        icon = Icons.play_circle;
        color = Colors.green;
        label = 'Active';
        break;
      case 'late':
        icon = Icons.warning;
        color = Colors.orange;
        label = 'Late';
        break;
      case 'ended':
        icon = Icons.stop_circle;
        color = Colors.red;
        label = 'Ended';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeStudent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _studentId = user.id;
        _subscribeSubmissionsRealtime();
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
      if (!mounted) return;
      setState(() => _assignments = rows);
      await _loadSubmissionStatuses();
    } catch (e) {
      debugPrint('❌ Error loading assignments: $e');
      setState(() => _assignments = []);
    } finally {
      if (mounted) setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _onSelectClassroom(Classroom c) async {
    setState(() {
      _selectedClassroom = c;
      _selectedCourse = null;
      _classroomCourses = [];
      _moduleFiles = [];
      _assignments = [];
    });
    // Apply teacher's active quarter (default) for this classroom on initial selection
    try {
      final row = await Supabase.instance.client
          .from('classroom_active_quarters')
          .select('active_quarter')
          .eq('classroom_id', c.id)
          .maybeSingle();
      final aqVal = row == null ? null : row['active_quarter'];
      final aq = aqVal == null ? null : int.tryParse('$aqVal');
      if (aq != null && aq >= 1 && aq <= 4 && mounted) {
        setState(() {
          _selectedQuarter = aq;
        });
        // Reflect in quarter tab controller (assignments sub-tabs)
        final idx = (aq - 1).clamp(0, 3);
        if (_quarterTabController.index != idx) {
          _quarterTabController.index = idx;
        }
      }
    } catch (_) {}
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
                          trailing: IconButton(
                            tooltip: 'Leave classroom',
                            icon: const Icon(
                              Icons.logout,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              if (_studentId == null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You must be signed in.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Leave classroom'),
                                  content: Text(
                                    'Are you sure you want to leave "${classroom.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Leave'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              try {
                                await _classroomService.leaveClassroom(
                                  studentId: _studentId!,
                                  classroomId: classroom.id,
                                );
                                await _loadStudentClassrooms();
                                if (!mounted) return;
                                if (_selectedClassroom?.id == classroom.id) {
                                  setState(() {
                                    _selectedClassroom = _classrooms.isNotEmpty
                                        ? _classrooms.first
                                        : null;
                                    _classroomCourses = [];
                                    _selectedCourse = null;
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Left "${classroom.title}"'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error leaving classroom: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
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
              const SizedBox(width: 8),
              Tooltip(
                message: 'View members',
                child: InkWell(
                  onTap: _selectedClassroom == null ? null : _showMembersDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_2,
                          size: 16,
                          color: Colors.blueGrey.shade700,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'members',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
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

  void _showMembersDialog() {
    if (_selectedClassroom == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Joined'),
          content: SizedBox(
            width: 720,
            height: 480,
            child: FutureBuilder<Map<String, dynamic>>(
              future: (() async {
                final cid = _selectedClassroom!.id;
                final students = await _classroomService.getClassroomStudents(
                  cid,
                );
                final teachers = await _classroomService.getClassroomTeachers(
                  cid,
                );
                Profile? owner;
                try {
                  owner = await ProfileService().getProfile(
                    _selectedClassroom!.teacherId,
                  );
                } catch (_) {}
                return {
                  'students': students,
                  'teachers': teachers,
                  'owner': owner,
                };
              })(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load members',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  );
                }
                final students =
                    (snap.data?['students'] as List<dynamic>? ?? [])
                        .cast<Map<String, dynamic>>();
                final teachers =
                    (snap.data?['teachers'] as List<dynamic>? ?? [])
                        .cast<Map<String, dynamic>>();
                final owner = snap.data?['owner'] as Profile?;
                final sCount = students.length;
                final tCount = teachers.length; // excludes owner

                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Students ($sCount)'),
                          Tab(text: 'Teachers ($tCount)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Students list (read-only)
                            ListView.separated(
                              itemCount: students.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (ctx, i) {
                                final s = students[i];
                                final name =
                                    (s['profiles']?['full_name'] ??
                                            s['full_name'] ??
                                            'Unknown Student')
                                        .toString();
                                final email =
                                    (s['profiles']?['email'] ??
                                            s['email'] ??
                                            '')
                                        .toString();
                                final initials = name.isNotEmpty
                                    ? name
                                          .trim()
                                          .split(' ')
                                          .where((e) => e.isNotEmpty)
                                          .map((e) => e[0])
                                          .take(2)
                                          .join()
                                    : 'S';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Teachers list (read-only)
                            ListView.separated(
                              itemCount:
                                  (owner != null ? 1 : 0) + teachers.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (ctx, i) {
                                String name = '';
                                String email = '';
                                String role = '';
                                if (owner != null && i == 0) {
                                  name = owner.displayName;
                                  email = owner.email ?? '';
                                  role = 'Owner';
                                } else {
                                  final t =
                                      teachers[i - (owner != null ? 1 : 0)];
                                  name =
                                      (t['profiles']?['full_name'] ??
                                              t['full_name'] ??
                                              'Unknown')
                                          .toString();
                                  email =
                                      (t['profiles']?['email'] ??
                                              t['email'] ??
                                              '')
                                          .toString();
                                  role = 'Co-teacher';
                                }
                                final initials = name.isNotEmpty
                                    ? name
                                          .trim()
                                          .split(' ')
                                          .where((e) => e.isNotEmpty)
                                          .map((e) => e[0])
                                          .take(2)
                                          .join()
                                    : 'T';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.shade100,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Text(email),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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
            onTap: () => _viewFile(file),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${file.fileName}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch ${file.fileUrl}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewFile(CourseFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${file.fileName}...'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch ${file.fileUrl}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final now = DateTime.now();

    // Filter by quarter
    final quarterFiltered = _assignments.where((a) {
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

    // NEW: Filter by timeline (only show active assignments, not ended)
    final filtered = quarterFiltered.where((a) {
      // Check start_time: assignment must have started (or no start_time = visible immediately)
      final startTime = a['start_time'] != null
          ? DateTime.tryParse(a['start_time'].toString())
          : null;
      if (startTime != null && now.isBefore(startTime)) {
        return false; // Not yet visible
      }

      // Check end_time: assignment must not have ended (or no end_time = never expires)
      final endTime = a['end_time'] != null
          ? DateTime.tryParse(a['end_time'].toString())
          : null;
      if (endTime != null && now.isAfter(endTime)) {
        return false; // Already ended
      }

      return true; // Active assignment
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
        final Map<String, dynamic>? submission =
            _submissionsByAssignment[(a['id'] ?? '').toString()];
        final String status = _deriveSubmissionStatus(a, submission);
        String submittedStr = '';
        final submittedAt = _parseDateTime(submission?['submitted_at']);
        if (submittedAt != null) {
          final hh = submittedAt.hour.toString().padLeft(2, '0');
          final mm = submittedAt.minute.toString().padLeft(2, '0');
          submittedStr =
              '${submittedAt.month}/${submittedAt.day}/${submittedAt.year} $hh:$mm';
        }
        // Status display colors and label
        Color bg;
        Color border;
        Color txt;
        String label;
        if (status == 'graded') {
          label = 'Graded';
          bg = Colors.blue.shade100;
          border = Colors.blue.shade300;
          txt = Colors.blue.shade800;
        } else if (status == 'submitted') {
          label = 'Submitted';
          bg = Colors.green.shade100;
          border = Colors.green.shade300;
          txt = Colors.green.shade800;
        } else if (status == 'late') {
          label = 'Submitted Late';
          bg = Colors.orange.shade100;
          border = Colors.orange.shade300;
          txt = Colors.orange.shade800;
        } else if (status == 'missed') {
          label = 'Missed';
          bg = Colors.red.shade100;
          border = Colors.red.shade300;
          txt = Colors.red.shade800;
        } else {
          label = 'Pending';
          bg = Colors.yellow.shade100;
          border = Colors.yellow.shade300;
          txt = Colors.yellow.shade800;
        }

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
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // NEW: Timeline status badge
                            _buildTimelineStatusBadge(a),
                            if ((((a['component'] ??
                                        (a['content']?['meta']?['component'] ??
                                            ''))
                                    .toString())
                                .isNotEmpty))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.brown.shade200,
                                  ),
                                ),
                                child: Text(
                                  ((a['component'] ??
                                          (a['content']?['meta']?['component'] ??
                                              ''))
                                      .toString()
                                      .replaceAll('_', ' ')),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.brown.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blueGrey.shade200,
                                ),
                              ),
                              child: Text(
                                'Q$_selectedQuarter',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: txt,
                          ),
                        ),
                      ),
                      if ((status == 'submitted' || status == 'late') &&
                          submittedStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Submitted on: $submittedStr',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
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
