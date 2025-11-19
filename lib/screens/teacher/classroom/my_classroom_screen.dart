import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/teacher_course_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/models/course_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/assignment_submissions_screen.dart';
import 'package:oro_site_high_school/services/profile_service.dart';
import 'package:oro_site_high_school/models/profile.dart';

import 'package:oro_site_high_school/widgets/announcement_tab.dart';

/// My Classroom Screen
/// Allows teachers to create and manage classrooms
class MyClassroomScreen extends StatefulWidget {
  const MyClassroomScreen({super.key});

  @override
  State<MyClassroomScreen> createState() => _MyClassroomScreenState();
}

class _MyClassroomScreenState extends State<MyClassroomScreen>
    with TickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final TeacherCourseService _teacherCourseService = TeacherCourseService();
  final AssignmentService _assignmentService = AssignmentService();
  final ProfileService _profileService = ProfileService();
  List<Classroom> _classrooms = [];
  Map<String, int> _enrollmentCounts = {};
  Classroom? _selectedClassroom;
  List<Course> _classroomCourses = [];
  StreamSubscription? _classroomStream;

  RealtimeChannel? _assignmentsChannel;

  Course? _selectedCourse;
  List<CourseFile> _moduleFiles = [];
  // Assignments tab state
  List<Map<String, dynamic>> _classroomAssignments = [];
  bool _isLoadingClassroomAssignments = false;
  // Sub-tab for quarters in Assignments
  int _selectedQuarter = 1; // 1..4
  late TabController _quarterTabController;
  bool _isLoading = false;
  bool _isLoadingCourses = false;
  bool _isLoadingModules = false;
  String? _teacherId;
  late TabController _tabController;
  final TextEditingController _studentsSearchCtrl = TextEditingController();
  String _studentsQuery = '';
  final TextEditingController _teachersSearchCtrl = TextEditingController();
  String _teachersQuery = '';

  // Small reload key used to force the joined dialog FutureBuilders to refetch
  // after add/remove operations. Purely UI-side and idempotent.
  int _membersDialogReloadKey = 0;

  // Classroom-level Active Quarter (default) state
  int? _classroomActiveQuarter; // null when not set
  bool _isSettingClassroomActiveQuarter = false;

  // Join as co-teacher input state
  final TextEditingController _joinCodeCtrl = TextEditingController();
  bool _isJoiningAsTeacher = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 &&
          _selectedClassroom != null &&
          _canAccessAssignments()) {
        _loadClassroomAssignments(_selectedClassroom!.id);
      }
      // Announcement loading now handled by AnnouncementTab widget
      // if (_tabController.index == 2 && _selectedCourse != null) {
      //   _loadAnnouncementsForSelectedCourse();
      // }
    });
    _quarterTabController = TabController(length: 4, vsync: this);
    _quarterTabController.addListener(() {
      final newQuarter = _quarterTabController.index + 1;
      if (newQuarter != _selectedQuarter) {
        setState(() {
          _selectedQuarter = newQuarter;
        });
        if (_tabController.index == 1 &&
            _selectedClassroom != null &&
            _canAccessAssignments()) {
          _loadClassroomAssignments(_selectedClassroom!.id);
        }
      }
    });
    // Note: _studentsQuery is updated directly in the dialog's TextField onChanged
    // to avoid unnecessary full-screen rebuilds. No listener needed here.
    _initializeTeacher();
    _subscribeClassroomsRealtime();
    _subscribeAssignmentsRealtime();
  }

  void _subscribeAssignmentsRealtime() {
    _assignmentsChannel?.unsubscribe();
    final supa = Supabase.instance.client;
    _assignmentsChannel = supa
        .channel('teacher-assignments')
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
            final selectedId = _selectedClassroom?.id;
            if (selectedId != null && clsId == selectedId) {
              if (mounted &&
                  _tabController.index == 1 &&
                  _canAccessAssignments()) {
                _loadClassroomAssignments(selectedId);
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _classroomStream?.cancel();
    _assignmentsChannel?.unsubscribe();
    _tabController.dispose();
    _quarterTabController.dispose();
    _studentsSearchCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  // Load the teacher-set active quarter (default) for the currently selected classroom
  Future<void> _loadClassroomActiveQuarter() async {
    final cls = _selectedClassroom;
    if (cls == null) return;
    final expectedId = cls.id;
    try {
      final row = await Supabase.instance.client
          .from('classroom_active_quarters')
          .select('active_quarter')
          .eq('classroom_id', expectedId)
          .maybeSingle();
      final aqVal = row == null ? null : row['active_quarter'];
      final aq = aqVal == null ? null : int.tryParse('$aqVal');
      if (!mounted) return;
      if (_selectedClassroom?.id != expectedId) return; // stale
      setState(() => _classroomActiveQuarter = aq);
    } catch (e) {
      debugPrint('[CLASSROOM] load active quarter error: $e');
    }
  }

  Future<void> _setClassroomActiveQuarter(int q) async {
    final cls = _selectedClassroom;
    final tid = _teacherId;
    if (cls == null || tid == null) return;
    setState(() => _isSettingClassroomActiveQuarter = true);
    try {
      await Supabase.instance.client.from('classroom_active_quarters').upsert({
        'classroom_id': cls.id,
        'active_quarter': q,
        'set_by_teacher_id': tid,
        'set_at': DateTime.now().toIso8601String(),
      }, onConflict: 'classroom_id');
      if (!mounted) return;
      setState(() => _classroomActiveQuarter = q);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active quarter set for classroom')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set active quarter: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSettingClassroomActiveQuarter = false);
      }
    }
  }

  Future<void> _confirmAndSetClassroomActiveQuarter(int q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Active Quarter'),
          content: Text(
            'Set Q$q as the default quarter for this classroom?\nStudents can still switch, this only changes the default.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _setClassroomActiveQuarter(q);
    }
  }

  Widget _buildActiveQuarterDropdown() {
    final q = _classroomActiveQuarter;
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: q,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          hint: const Text('AQ', style: TextStyle(fontSize: 12)),
          items: List.generate(4, (i) {
            final v = i + 1;
            return DropdownMenuItem<int>(
              value: v,
              child: Text('Q$v', style: const TextStyle(fontSize: 12)),
            );
          }),
          onChanged: _isSettingClassroomActiveQuarter
              ? null
              : (val) {
                  if (val == null) return;
                  _confirmAndSetClassroomActiveQuarter(val);
                },
        ),
      ),
    );
  }

  Future<void> _initializeTeacher() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _teacherId = user.id;
        });
        await _loadClassrooms();
      }
    } catch (e) {
      print('❌ Error initializing teacher: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeClassroomsRealtime() {
    // Listen to changes in classrooms table and refresh when counts change
    try {
      _classroomStream = Supabase.instance.client
          .from('classrooms')
          .stream(primaryKey: ['id'])
          .listen((data) async {
            if (data.isEmpty) return;
            // Refresh counts for impacted classrooms
            final impactedIds = data.map((r) => r['id'] as String).toList();
            final freshCounts = await _classroomService
                .getEnrollmentCountsForClassrooms(impactedIds);
            setState(() {
              for (final row in data) {
                final id = row['id'] as String;
                final idx = _classrooms.indexWhere((c) => c.id == id);
                if (idx != -1) {
                  var updated = Classroom.fromJson(row);
                  // Override currentStudents with live count if available
                  final live = freshCounts[id];
                  if (live != null) {
                    updated = updated.copyWith(currentStudents: live);
                    _enrollmentCounts[id] = live;
                  }
                  _classrooms[idx] = updated;
                  if (_selectedClassroom?.id == id) {
                    _selectedClassroom = updated;
                  }
                }
              }
            });
          });
    } catch (e) {
      print('Realtime subscription error: $e');
    }
  }

  Future<void> _refreshEnrollmentCount(String classroomId) async {
    try {
      final counts = await _classroomService.getEnrollmentCountsForClassrooms([
        classroomId,
      ]);
      setState(() {
        final updated = counts[classroomId];
        if (updated != null) {
          _enrollmentCounts[classroomId] = updated;
          // Also patch selected classroom object if it matches
          if (_selectedClassroom?.id == classroomId) {
            _selectedClassroom = _selectedClassroom!.copyWith(
              currentStudents: updated,
            );
          }
        }
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _afterMemberMutationDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadClassrooms() async {
    if (_teacherId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final classrooms = await _classroomService.getTeacherClassrooms(
        _teacherId!,
      );
      final counts = await _classroomService.getEnrollmentCountsForClassrooms(
        classrooms.map((c) => c.id).toList(),
      );
      setState(() {
        _classrooms = classrooms
            .map(
              (c) => c.copyWith(
                currentStudents: counts[c.id] ?? c.currentStudents,
              ),
            )
            .toList();
        _enrollmentCounts = counts;
        _isLoading = false;
        // Auto-select first classroom
        if (_classrooms.isNotEmpty && _selectedClassroom == null) {
          _selectedClassroom = _classrooms.first;
          _loadClassroomCourses(_classrooms.first.id);
          _loadClassroomActiveQuarter();
        }
      });
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classrooms: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadClassroomCourses(String classroomId) async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courses = await _classroomService.getClassroomCourses(classroomId);
      setState(() {
        _classroomCourses = courses;
        _isLoadingCourses = false;
        // Auto-select first course
        if (_classroomCourses.isNotEmpty) {
          _selectedCourse = _classroomCourses.first;
          _loadCourseModules(_classroomCourses.first.id);
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
      final modules = await _teacherCourseService.getCourseModules(courseId);
      setState(() {
        _moduleFiles = modules
            .map((json) => CourseFile.fromJson(json, 'module'))
            .toList();
        _isLoadingModules = false;
      });
    } catch (e) {
      print('❌ Error loading course modules: $e');
      setState(() {
        _moduleFiles = [];
        _isLoadingModules = false;
      });
    }
  }

  bool _canAccessAssignments() {
    final uid = _teacherId ?? Supabase.instance.client.auth.currentUser?.id;
    final owner = _selectedCourse?.teacherId;
    return uid != null && owner != null && owner == uid;
  }

  Widget _buildAssignmentsLocked() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            'Assignments are available only to the course owner.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Allow teacher to join a classroom as co-teacher via access code (idempotent)
  Future<void> _joinAsCoTeacher() async {
    try {
      final code = _joinCodeCtrl.text.trim();
      if (code.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an access code.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_teacherId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in to join a classroom.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isJoiningAsTeacher = true;
      });

      final res = await _classroomService.joinClassroomAsTeacher(
        teacherId: _teacherId!,
        accessCode: code,
      );

      if (!mounted) return;
      setState(() {
        _isJoiningAsTeacher = false;
      });

      final success = res['success'] == true;
      final msg =
          (res['message'] ??
                  (success ? 'Joined successfully.' : 'Failed to join.'))
              .toString();

      // Refresh classroom list to reflect new co-teaching membership (idempotent)
      await _loadClassrooms();

      // Optionally select the classroom if returned
      final cls = res['classroom'];
      if (cls is Classroom) {
        setState(() {
          _selectedClassroom = cls;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      if (success) {
        _joinCodeCtrl.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoiningAsTeacher = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining classroom: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirm and handle leaving a shared classroom (co-teacher)
  Future<void> _confirmLeaveClassroom(Classroom classroom) async {
    final ctrl = TextEditingController();
    bool canConfirm = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            title: const Text('Leave classroom'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to leave "${classroom.title}". You will lose access to this classroom until you re-enter using its access code.',
                ),
                const SizedBox(height: 12),
                Text(
                  'To confirm, please type the classroom title exactly:',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Type classroom title to confirm',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDlg(
                    () => canConfirm = ctrl.text.trim() == classroom.title,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canConfirm
                    ? () async {
                        Navigator.pop(ctx);
                        await _leaveSharedClassroom(classroom);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Execute leave by removing membership; idempotent with dual table support
  Future<void> _leaveSharedClassroom(Classroom classroom) async {
    if (_teacherId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Promote nullable field to non-null local for flow analysis
    final String teacherId = _teacherId!;

    try {
      bool removed = false;
      // Prefer unified membership table
      try {
        await Supabase.instance.client
            .from('classroom_members')
            .delete()
            .eq('classroom_id', classroom.id)
            .eq('member_id', teacherId)
            .eq('role', 'co_teacher');
        removed = true;
      } catch (_) {
        // table may not exist or RLS denied
      }

      // Fallback to legacy mapping
      if (!removed) {
        try {
          await Supabase.instance.client
              .from('classroom_teachers')
              .delete()
              .eq('classroom_id', classroom.id)
              .eq('teacher_id', teacherId);
          removed = true;
        } catch (_) {}
      }

      if (!mounted) return;
      if (!removed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not leave classroom. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Refresh list and selection
      await _loadClassrooms();
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
          content: Text('You left "${classroom.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving classroom: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar - Classrooms
          _buildClassroomSidebar(),

          // Middle Panel - Courses
          if (_selectedClassroom != null) _buildCoursesPanel(),

          // Right Panel - Main Content
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
          // Header
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
                        builder: (context) => const TeacherDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLASSROOM MANAGEMENT',
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

          // Classroom Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : 'you have ${_classrooms.length} classroom${_classrooms.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                if (_selectedClassroom != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Set default quarter for this classroom',
                    child: _buildActiveQuarterDropdown(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Classroom List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'start creating classrooms!',
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
                      final bool isOwned =
                          _teacherId != null &&
                          classroom.teacherId == _teacherId;

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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  classroom.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwned
                                      ? Colors.blue.shade50
                                      : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOwned
                                        ? Colors.blue.shade200
                                        : Colors.purple.shade200,
                                  ),
                                ),
                                child: Text(
                                  isOwned ? 'owned' : 'shared',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Grade ${classroom.gradeLevel} • ${(_enrollmentCounts[classroom.id] ?? classroom.currentStudents)}/${classroom.maxStudents} students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: Colors.blue.shade600,
                                ),
                                onPressed: () =>
                                    _showEditClassroomDialog(classroom),
                                tooltip: 'Edit classroom',
                              ),
                              if (isOwned)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () =>
                                      _showDeleteClassroomDialog(classroom),
                                  tooltip: 'Delete classroom',
                                )
                              else
                                IconButton(
                                  icon: Icon(
                                    Icons.logout,
                                    size: 20,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () =>
                                      _confirmLeaveClassroom(classroom),
                                  tooltip: 'Leave classroom',
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedClassroom = classroom;
                            });
                            _loadClassroomActiveQuarter();
                            _loadClassroomCourses(classroom.id);
                            if (_tabController.index == 1) {
                              _loadClassroomAssignments(classroom.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Create Class Button (Always visible at bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCreateClassroomDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'create class',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // Bottom: join as co-teacher via access code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
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
                            controller: _joinCodeCtrl,
                            decoration: InputDecoration(
                              hintText: 'enter code to join as co-teacher',
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
                                _isJoiningAsTeacher ? null : _joinAsCoTeacher(),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isJoiningAsTeacher ? null : _joinAsCoTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                  child: _isJoiningAsTeacher
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
                      final bool isOwnedCourse =
                          _teacherId != null && course.teacherId == _teacherId;

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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwnedCourse
                                      ? Colors.blue.shade50
                                      : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOwnedCourse
                                        ? Colors.blue.shade200
                                        : Colors.purple.shade200,
                                  ),
                                ),
                                child: Text(
                                  isOwnedCourse ? 'owned' : 'shared',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            course.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: isOwnedCourse
                              ? IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () =>
                                      _showRemoveCourseDialog(course),
                                  tooltip: 'Remove course from classroom',
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCourse = course;
                            });
                            _loadCourseModules(course.id);
                            if (_tabController.index == 1 &&
                                _selectedClassroom != null &&
                                _canAccessAssignments()) {
                              _loadClassroomAssignments(_selectedClassroom!.id);
                            }
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

    if (_classrooms.isEmpty) {
      return Stack(
        children: [
          // Empty State
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'classroom not yet created!',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Create Class Button (Bottom Right)
          Positioned(
            right: 32,
            bottom: 32,
            child: ElevatedButton(
              onPressed: _showCreateClassroomDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: const Text(
                'create class',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      );
    }

    if (_selectedClassroom == null) {
      return const Center(child: Text('Select a classroom from the sidebar'));
    }

    // Main content with classroom details
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with classroom name and access code
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
              // Access Code + My Students (compact)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // My Students chip button (compact, subtle green)
                  InkWell(
                    onTap: _showMyStudentsDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'joined',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Counter badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: FutureBuilder<int>(
                              future: _classroomService
                                  .getClassroomTeacherCount(
                                    _selectedClassroom!.id,
                                  ),
                              builder: (ctx, snap) {
                                final sCount =
                                    _enrollmentCounts[_selectedClassroom!.id] ??
                                    _selectedClassroom!.currentStudents;
                                final tCount =
                                    (snap.data ?? 0) + 1; // include owner
                                return Text(
                                  '${sCount + tCount}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Access code container (reduced size)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.content_copy, size: 16),
                          onPressed: () => _copyAccessCodeToClipboard(),
                          tooltip: 'Copy access code',
                          color: Colors.grey.shade700,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedClassroom!.accessCode ?? 'a6Eqy3ml',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.25,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _regenerateAccessCode,
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('generate access code'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Course Title (if selected)
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

        // Tabs
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
                Expanded(
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
              ],
            ),
          ),

        // Tab Content
        if (_selectedCourse != null)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModulesTab(),
                _canAccessAssignments()
                    ? _buildAssignmentsTab()
                    : _buildAssignmentsLocked(),
                AnnouncementTab(
                  classroomId: _selectedClassroom!.id,
                  courseId: _selectedCourse!.id,
                  isTeacher: true,
                  canManageAnnouncements: true,
                  canSoftDeleteReply: true,
                  showDeletedPlaceholders: true,
                ),
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
                    'No courses added to this classroom yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Show add course dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add course feature coming soon!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showMyStudentsDialog() {
    if (_selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a classroom first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 900,
            height: 560,
            padding: const EdgeInsets.all(12),
            child: DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<int>(
                    future: _classroomService.getClassroomTeacherCount(
                      _selectedClassroom!.id,
                    ),
                    builder: (ctx, snap) {
                      final sCount =
                          _enrollmentCounts[_selectedClassroom!.id] ??
                          _selectedClassroom!.currentStudents;
                      final tCount = (snap.data ?? 0) + 1; // include owner
                      return TabBar(
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Students ($sCount)'),
                          Tab(text: 'Teachers ($tCount)'),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStudentsTab(setLocal: setLocal),
                        _buildTeachersTab(setLocal: setLocal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsTab({StateSetter? setLocal}) {
    if (_selectedClassroom == null) {
      return const Center(child: Text('No classroom selected'));
    }

    return Column(
      children: [
        _buildStudentsToolbar(setLocal: setLocal),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(
              'students-${_selectedClassroom!.id}-$_membersDialogReloadKey',
            ),
            future: _classroomService.getClassroomStudents(
              _selectedClassroom!.id,
            ),
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

              final rawStudents = List<Map<String, dynamic>>.from(
                snapshot.data ?? const [],
              );
              final totalEnrolled = rawStudents.length;

              // Keep enrollment counts in sync with the actual list we are showing.
              if (_selectedClassroom != null) {
                final selectedId = _selectedClassroom!.id;
                final existingCount = _enrollmentCounts[selectedId];
                if (existingCount != totalEnrolled ||
                    _selectedClassroom!.currentStudents != totalEnrolled) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _enrollmentCounts[selectedId] = totalEnrolled;
                      _selectedClassroom = _selectedClassroom!.copyWith(
                        currentStudents: totalEnrolled,
                      );
                      final idx = _classrooms.indexWhere(
                        (c) => c.id == selectedId,
                      );
                      if (idx != -1) {
                        _classrooms[idx] = _classrooms[idx].copyWith(
                          currentStudents: totalEnrolled,
                        );
                      }
                    });
                  });
                }
              }

              // Apply search filtering on top of the raw list (does not affect counts).
              List<Map<String, dynamic>> students = rawStudents;
              if (_studentsQuery.isNotEmpty) {
                final q = _studentsQuery.toLowerCase();
                students = students.where((s) {
                  final name = (s['full_name'] ?? '').toString().toLowerCase();
                  final email = (s['email'] ?? '').toString().toLowerCase();
                  return name.contains(q) || email.contains(q);
                }).toList();
              }

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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Message student',
                            icon: const Icon(Icons.message_outlined),
                            color: Colors.blueGrey,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Messaging coming soon'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          if (_teacherId != null &&
                              _selectedClassroom!.teacherId == _teacherId)
                            IconButton(
                              tooltip: 'Remove from classroom',
                              icon: const Icon(
                                Icons.person_remove_alt_1_outlined,
                              ),
                              color: Colors.red.shade400,
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove student'),
                                    content: Text(
                                      'Are you sure you want to remove "$fullName" from this classroom?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    await _classroomService.leaveClassroom(
                                      studentId: student['student_id'],
                                      classroomId: _selectedClassroom!.id,
                                    );
                                    await _refreshEnrollmentCount(
                                      _selectedClassroom!.id,
                                    );
                                    // Wait for Supabase replication before refetching
                                    await _afterMemberMutationDelay();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Removed $fullName from classroom',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _membersDialogReloadKey++;
                                    });
                                    setLocal?.call(() {});
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error removing student: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsToolbar({StateSetter? setLocal}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search (left, compact)
          Expanded(
            child: SizedBox(
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _studentsSearchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search students',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey,
                    ),
                    suffixIcon: _studentsQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _studentsSearchCtrl.clear();
                              setLocal?.call(() {});
                            },
                          ),
                  ),
                  onChanged: (v) {
                    print(
                      '🔍 Client-side filter: "$v" (no backend call)',
                    ); // DEBUG
                    _studentsQuery = v.trim();
                    setLocal?.call(() {});
                  },
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add student chip (right, compact subtle green)
          Tooltip(
            message: 'Add student',
            child: InkWell(
              onTap: _selectedClassroom == null
                  ? null
                  : () => _showAddMemberDialog(
                      initialType: 'student',
                      onMembersChanged: () => setLocal?.call(() {}),
                    ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    const Text(
                      'add student',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersToolbar({StateSetter? setLocal}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search (left)
          Expanded(
            child: SizedBox(
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _teachersSearchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search teachers',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (q) {
                    setLocal?.call(() {
                      _teachersQuery = q.trim();
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add teacher
          Tooltip(
            message: 'Add teacher',
            child: InkWell(
              onTap: _selectedClassroom == null
                  ? null
                  : () => _showAddMemberDialog(
                      initialType: 'teacher',
                      onMembersChanged: () => setLocal?.call(() {}),
                    ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 16,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'add teacher',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTab({StateSetter? setLocal}) {
    if (_selectedClassroom == null) {
      return const Center(child: Text('Select a classroom first'));
    }

    final cid = _selectedClassroom!.id;
    return Column(
      children: [
        _buildTeachersToolbar(setLocal: setLocal),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            key: ValueKey(
              'teachers-${_selectedClassroom!.id}-$_membersDialogReloadKey',
            ),
            future: (() async {
              // Fetch owner profile and co-teachers concurrently
              Profile? owner;
              try {
                owner = await _profileService.getProfile(
                  _selectedClassroom!.teacherId,
                );
              } catch (_) {}
              final coTeachers = await _classroomService.getClassroomTeachers(
                cid,
              );
              return {'owner': owner, 'coTeachers': coTeachers};
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
                    'Failed to load teachers',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                );
              }
              final owner = snap.data?['owner'] as Profile?;
              final co = (snap.data?['coTeachers'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

              final List<Map<String, String>> items = [];
              if (owner != null) {
                items.add({
                  'id': owner.id,
                  'name': owner.displayName,
                  'email': owner.email ?? '',
                  'role': 'Owner',
                });
              }
              for (final t in co) {
                items.add({
                  'id': (t['teacher_id'] ?? '').toString(),
                  'name': (t['full_name'] ?? '').toString(),
                  'email': (t['email'] ?? '').toString(),
                  'role': 'Co-teacher',
                });
              }

              final q = _teachersQuery.toLowerCase();
              final filtered = q.isEmpty
                  ? items
                  : items
                        .where(
                          (m) =>
                              (m['name'] ?? '').toLowerCase().contains(q) ||
                              (m['email'] ?? '').toLowerCase().contains(q),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No teachers found',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (ctx, i) {
                  final m = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        (m['name'] ?? 'T').isNotEmpty
                            ? m['name']!
                                  .trim()
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join()
                            : 'T',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    title: Text(m['name'] ?? ''),
                    subtitle: Text(m['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            m['role'] ?? 'Teacher',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ),
                        if (m['role'] == 'Co-teacher' &&
                            _teacherId != null &&
                            _selectedClassroom!.teacherId == _teacherId) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Remove co-teacher',
                            child: IconButton(
                              icon: Icon(
                                Icons.person_remove,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove co-teacher'),
                                    content: Text(
                                      'Are you sure you want to remove "${m['name'] ?? 'this co-teacher'}" from this classroom?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                final ok = await _classroomService
                                    .removeTeacherFromClassroom(
                                      classroomId: _selectedClassroom!.id,
                                      teacherId: m['id']!,
                                    );
                                // Wait for Supabase replication before refetching
                                if (ok) {
                                  await _afterMemberMutationDelay();
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Co-teacher removed'
                                          : 'Failed to remove co-teacher',
                                    ),
                                    backgroundColor: ok
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                                if (ok) {
                                  setState(() {
                                    _membersDialogReloadKey++;
                                  });
                                }
                                setLocal?.call(() {});
                              },
                            ),
                          ),
                        ],
                        if (m['role'] == 'Co-teacher' &&
                            _teacherId != null &&
                            m['id'] == _teacherId &&
                            _selectedClassroom!.teacherId != _teacherId) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Leave classroom',
                            child: IconButton(
                              icon: Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () async {
                                await _confirmLeaveClassroom(
                                  _selectedClassroom!,
                                );
                                if (mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddMemberDialog({
    String initialType = 'student',
    VoidCallback? onMembersChanged,
  }) async {
    if (_selectedClassroom == null) return;

    String type = initialType; // 'student' or 'teacher'
    final TextEditingController searchCtrl = TextEditingController();
    List<Profile> allUsers = [];
    List<Profile> filteredUsers = [];
    bool isLoading = false;
    bool dialogActive = true; // Track if dialog is still active

    // Preload membership sets to show status in the Add dialog and avoid duplicates
    final Set<String> enrolledIds = <String>{};
    final Set<String> teacherIds = <String>{};
    try {
      final enrolled = await _classroomService.getClassroomStudents(
        _selectedClassroom!.id,
      );
      for (final s in enrolled) {
        final sid = (s['student_id'] ?? '').toString();
        if (sid.isNotEmpty) enrolledIds.add(sid);
      }
    } catch (_) {}
    try {
      final co = await _classroomService.getClassroomTeachers(
        _selectedClassroom!.id,
      );
      for (final t in co) {
        final tid = (t['teacher_id'] ?? '').toString();
        if (tid.isNotEmpty) teacherIds.add(tid);
      }
    } catch (_) {}
    // Include the owner so we treat them as already in classroom for teacher type
    if (_selectedClassroom?.teacherId != null) {
      teacherIds.add(_selectedClassroom!.teacherId);
    }

    Future<void> loadUsers() async {
      print(
        '🔥 NEW loadUsers() called - type: $type',
      ); // DEBUG: Verify new code is running
      isLoading = true;
      try {
        final all = await _profileService.getAllUsers(limit: 200, page: 1);
        List<Profile> filtered;
        if (type == 'student') {
          filtered = all.where((p) {
            final isStudent =
                (p.roleName ?? '').toLowerCase() == 'student' || p.roleId == 3;
            final isEnrolled = enrolledIds.contains(p.id);
            final isAdmin =
                (p.roleName ?? '').toLowerCase() == 'admin' || p.roleId == 1;
            return isStudent && !isEnrolled && !isAdmin;
          }).toList();
        } else {
          filtered = all.where((p) {
            final rn = (p.roleName ?? '').toLowerCase();
            final isTeacherLike =
                rn == 'teacher' ||
                rn == 'grade_level_coordinator' ||
                rn == 'coordinator' ||
                rn == 'hybrid' ||
                p.roleId == 2 ||
                p.roleId == 5;
            final isAlreadyInClassroom = teacherIds.contains(p.id);
            final isAdmin = rn == 'admin' || p.roleId == 1;
            return isTeacherLike && !isAlreadyInClassroom && !isAdmin;
          }).toList();
        }
        allUsers = filtered;
        filteredUsers = filtered;
      } catch (e) {
        print('Error loading users: $e');
        allUsers = [];
        filteredUsers = [];
      } finally {
        isLoading = false;
      }
    }

    void filterUsers(String query) {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        final q = query.toLowerCase();
        filteredUsers = allUsers.where((p) {
          final name = (p.fullName ?? '').toLowerCase();
          final email = (p.email ?? '').toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load users on first render
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (allUsers.isEmpty && !isLoading && dialogActive) {
              // Set loading state before starting
              setDialogState(() {
                isLoading = true;
              });
              loadUsers().then((_) {
                // Rebuild after loading completes
                if (dialogActive) setDialogState(() {});
              });
            }
          });

          Future<void> addSelected(Profile p) async {
            // Prevent duplicates based on preloaded membership sets
            if (type == 'student' && enrolledIds.contains(p.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student is already in this classroom'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (type == 'teacher' && teacherIds.contains(p.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teacher is already in this classroom'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final code = _selectedClassroom!.accessCode;
            if (code == null || code.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Classroom has no access code. Please generate one.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            setDialogState(() => isLoading = true);
            Map<String, dynamic> res;
            try {
              if (type == 'student') {
                res = await _classroomService.joinClassroom(
                  studentId: p.id,
                  accessCode: code,
                );
              } else {
                res = await _classroomService.joinClassroomAsTeacher(
                  teacherId: p.id,
                  accessCode: code,
                );
              }
            } finally {
              setDialogState(() => isLoading = false);
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Operation complete'),
                backgroundColor: (res['success'] == true)
                    ? Colors.green
                    : Colors.orange,
              ),
            );
            if (res['success'] == true) {
              if (type == 'student') {
                enrolledIds.add(p.id);
                await _refreshEnrollmentCount(_selectedClassroom!.id);
              } else {
                teacherIds.add(p.id);
              }
              // Let parent dialog refresh its lists & counters
              onMembersChanged?.call();
              await _afterMemberMutationDelay();
              setState(() {
                _membersDialogReloadKey++;
              });
              // Remove from available lists
              allUsers.removeWhere((u) => u.id == p.id);
              filteredUsers.removeWhere((u) => u.id == p.id);
              if (dialogActive) setDialogState(() {});
            }
          }

          return AlertDialog(
            title: const Text('Add member to classroom'),
            content: SizedBox(
              width: 650,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Type:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Text('Teacher/Coordinator/Hybrid'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          type = v;
                          allUsers.clear();
                          filteredUsers.clear();
                          // Set loading state before starting
                          setDialogState(() {
                            isLoading = true;
                          });
                          loadUsers().then((_) {
                            if (dialogActive) setDialogState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: type == 'student'
                          ? 'Search students by name or email...'
                          : 'Search teachers by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                filterUsers('');
                                if (dialogActive) setDialogState(() {});
                              },
                            ),
                    ),
                    onChanged: (q) {
                      filterUsers(q);
                      if (dialogActive) setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isLoading) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    width: double.infinity,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              type == 'student'
                                  ? 'No students found'
                                  : 'No teachers found',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (ctx, i) {
                              final p = filteredUsers[i];
                              final bool isOwner =
                                  _selectedClassroom != null &&
                                  _selectedClassroom!.teacherId == _teacherId;
                              final bool isAlready = type == 'student'
                                  ? enrolledIds.contains(p.id)
                                  : teacherIds.contains(p.id);
                              return ListTile(
                                leading: CircleAvatar(child: Text(p.initials)),
                                title: Text(p.displayName),
                                subtitle: Text(p.email ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isAlready)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: type == 'student'
                                              ? Colors.green.shade50
                                              : Colors.purple.shade50,
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          border: Border.all(
                                            color: type == 'student'
                                                ? Colors.green.shade200
                                                : Colors.purple.shade200,
                                          ),
                                        ),
                                        child: const Text(
                                          'Already in classroom',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    if (isAlready) const SizedBox(width: 6),
                                    if (isAlready &&
                                        type == 'student' &&
                                        isOwner)
                                      IconButton(
                                        tooltip: 'Remove from classroom',
                                        icon: const Icon(
                                          Icons.person_remove_alt_1_outlined,
                                        ),
                                        color: Colors.red.shade400,
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: const Text(
                                                          'Remove student?',
                                                        ),
                                                        content: Text(
                                                          'Remove ${p.displayName} from this classroom?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Remove',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                if (confirm != true) return;
                                                setDialogState(
                                                  () => isLoading = true,
                                                );
                                                try {
                                                  await _classroomService
                                                      .leaveClassroom(
                                                        studentId: p.id,
                                                        classroomId:
                                                            _selectedClassroom!
                                                                .id,
                                                      );
                                                  enrolledIds.remove(p.id);
                                                  await _refreshEnrollmentCount(
                                                    _selectedClassroom!.id,
                                                  );
                                                  onMembersChanged?.call();
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Student removed',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                  setState(() {
                                                    _membersDialogReloadKey++;
                                                  });
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Failed to remove student',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  setDialogState(
                                                    () => isLoading = false,
                                                  );
                                                }
                                              },
                                      ),
                                    if (isAlready &&
                                        type == 'teacher' &&
                                        isOwner &&
                                        p.id != _selectedClassroom!.teacherId)
                                      IconButton(
                                        tooltip: 'Remove co-teacher',
                                        icon: const Icon(
                                          Icons.person_remove_alt_1_outlined,
                                        ),
                                        color: Colors.red.shade400,
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: const Text(
                                                          'Remove co-teacher?',
                                                        ),
                                                        content: Text(
                                                          'Remove ${p.displayName} as co-teacher?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Remove',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                if (confirm != true) return;
                                                setDialogState(
                                                  () => isLoading = true,
                                                );
                                                try {
                                                  final ok = await _classroomService
                                                      .removeTeacherFromClassroom(
                                                        classroomId:
                                                            _selectedClassroom!
                                                                .id,
                                                        teacherId: p.id,
                                                      );
                                                  if (ok) {
                                                    teacherIds.remove(p.id);
                                                    onMembersChanged?.call();
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Co-teacher removed',
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );
                                                    }
                                                    setState(() {
                                                      _membersDialogReloadKey++;
                                                    });
                                                  } else {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Failed to remove co-teacher',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } finally {
                                                  setDialogState(
                                                    () => isLoading = false,
                                                  );
                                                }
                                              },
                                      ),
                                    if (!isAlready && isOwner)
                                      IconButton(
                                        tooltip: type == 'student'
                                            ? 'Add student'
                                            : 'Add teacher',
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: type == 'student'
                                              ? Colors.green
                                              : Colors.purple,
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : () => addSelected(p),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
      ),
    ).then((_) => dialogActive = false);
  }

  Future<void> _loadClassroomAssignments(String classroomId) async {
    setState(() {
      _isLoadingClassroomAssignments = true;
    });
    try {
      List<Map<String, dynamic>> list;
      if (_selectedCourse != null) {
        list = await _assignmentService.getAssignmentsByClassroomAndCourse(
          classroomId: classroomId,
          courseId: _selectedCourse!.id,
        );
      } else {
        list = await _assignmentService.getClassroomAssignments(classroomId);
      }
      setState(() {
        _classroomAssignments = list;
        _isLoadingClassroomAssignments = false;
      });
    } catch (e) {
      setState(() {
        _classroomAssignments = [];
        _isLoadingClassroomAssignments = false;
      });
    }
  }

  Future<void> _togglePublishAssignment(
    String assignmentId,
    bool publish,
  ) async {
    try {
      await _assignmentService.togglePublishAssignment(assignmentId, publish);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish ? 'Assignment published' : 'Assignment unpublished',
            ),
            backgroundColor: publish ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      if (_selectedClassroom != null) {
        await _loadClassroomAssignments(_selectedClassroom!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating publish state: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAssignmentOverview(Map<String, dynamic> a) async {
    final String assignmentId = a['id'].toString();
    bool allowLate = (a['allow_late_submissions'] == true);
    final bool originalAllowLate = allowLate;

    String? currentComponent =
        (a['component'] ?? a['content']?['meta']?['component'])?.toString();
    final String? originalComponent = currentComponent;
    const List<String> allowedComponents = [
      'written_works',
      'performance_task',
    ];
    final bool canChangeComponent =
        currentComponent == null ||
        allowedComponents.contains(currentComponent);
    String selectedComponent = canChangeComponent
        ? (currentComponent ?? 'written_works')
        : (currentComponent ?? 'written_works');

    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return AlertDialog(
              title: const Text('Assignment overview'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (a['title'] ?? 'Untitled').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (((a['assignment_type'] ?? '').toString())
                              .isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
                              ),
                              child: Text(
                                (a['assignment_type'] ?? '')
                                    .toString()
                                    .replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (((currentComponent ?? '').toString()).isNotEmpty)
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
                                currentComponent!.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.brown.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allow late submissions'),
                        value: allowLate,
                        onChanged: (val) => setDlg(() => allowLate = val),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Component',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (canChangeComponent)
                        DropdownButtonFormField<String>(
                          value: selectedComponent,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: allowedComponents
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.replaceAll('_', ' ')),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDlg(
                            () => selectedComponent = val ?? selectedComponent,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (currentComponent ?? '').toString().replaceAll(
                                  '_',
                                  ' ',
                                ),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'To edit other fields, unpublish the assignment and edit it from My Assignments.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).maybePop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final bool lateChanged =
                              allowLate != originalAllowLate;
                          final bool compChanged =
                              canChangeComponent &&
                              (selectedComponent !=
                                  (originalComponent ?? 'written_works'));
                          if (!lateChanged && !compChanged) {
                            Navigator.of(ctx).maybePop();
                            return;
                          }
                          setDlg(() => saving = true);
                          try {
                            await _assignmentService.updateAssignment(
                              assignmentId: assignmentId,
                              allowLateSubmissions: lateChanged
                                  ? allowLate
                                  : null,
                              component: compChanged ? selectedComponent : null,
                            );
                            if (mounted && _selectedClassroom != null) {
                              await _loadClassroomAssignments(
                                _selectedClassroom!.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Assignment updated'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            setDlg(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
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
              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
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

  Widget _buildAssignmentsTab() {
    if (_selectedClassroom == null) {
      return const Center(child: Text('No classroom selected'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quarter sub-tabs
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
          child: _isLoadingClassroomAssignments
              ? const Center(child: CircularProgressIndicator())
              : _buildAssignmentsQuarterList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentsQuarterList() {
    final filtered = _classroomAssignments.where((a) {
      int? qInt;
      final q = a['quarter_no'];
      if (q != null) qInt = int.tryParse(q.toString());
      if (qInt == null) {
        final content = a['content'];
        if (content is Map) {
          final meta = content['meta'];
          if (meta is Map && meta['quarter_no'] != null) {
            qInt = int.tryParse(meta['quarter_no'].toString());
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
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No assignments for Q$_selectedQuarter',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final dueRaw = a['due_date'];
        DateTime? due;
        if (dueRaw != null && dueRaw.toString().isNotEmpty) {
          try {
            due = DateTime.parse(dueRaw.toString());
          } catch (_) {}
        }

        return GestureDetector(
          onTap: () => _showAssignmentOverview(a),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status chip
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (a['title'] ?? 'Untitled').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (a['is_published'] == true)
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (a['is_published'] == true)
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Text(
                              (a['is_published'] == true)
                                  ? 'published'
                                  : 'draft',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: (a['is_published'] == true)
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${a['total_points'] ?? 0} pts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (due != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${due.month}/${due.day}/${due.year} ${_formatAmPm(due)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (((a['assignment_type'] ?? '').toString())
                              .isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
                              ),
                              child: Text(
                                (a['assignment_type'] ?? '')
                                    .toString()
                                    .replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (((a['component'] ??
                                      (a['content']?['meta']?['component'] ??
                                          ''))
                                  .toString())
                              .isNotEmpty)
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

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View submissions',
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      color: Colors.blueGrey.shade600,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AssignmentSubmissionsScreen(
                              classroomId: _selectedClassroom!.id,
                              assignmentId: a['id'].toString(),
                              courseTitle: _selectedCourse?.title,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Publish',
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      color: Colors.green.shade700,
                      onPressed: (a['is_published'] == true)
                          ? null
                          : () async {
                              await _togglePublishAssignment(
                                a['id'].toString(),
                                true,
                              );
                            },
                    ),
                    IconButton(
                      tooltip: 'Unpublish',
                      icon: const Icon(Icons.visibility_off_outlined, size: 18),
                      color: Colors.orange.shade700,
                      onPressed: (a['is_published'] == true)
                          ? () async {
                              await _togglePublishAssignment(
                                a['id'].toString(),
                                false,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
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

  String _formatLongDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final time = _formatAmPm(dt);
    return '$month $day, $year, $time';
  }

  Widget _buildProjectsTab() {
    return Center(
      child: Text(
        'Projects tab - Coming soon',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Future<void> _regenerateAccessCode() async {
    if (_selectedClassroom == null) return;

    try {
      final newCode = await _classroomService.regenerateAccessCode(
        _selectedClassroom!.id,
      );

      setState(() {
        _selectedClassroom = _selectedClassroom!.copyWith(accessCode: newCode);
        // Update in list
        final index = _classrooms.indexWhere(
          (c) => c.id == _selectedClassroom!.id,
        );
        if (index != -1) {
          _classrooms[index] = _selectedClassroom!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access code regenerated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating access code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateClassroomDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxStudentsController = TextEditingController(text: '35');
    int? selectedGradeLevel;
    String? selectedSchoolLevel;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Classroom'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classroom Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Classroom Title',
                      hintText: 'e.g., Grade 7 - Diamond',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isCreating,
                  ),
                  const SizedBox(height: 16),

                  // Grade Level Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedGradeLevel,
                    decoration: const InputDecoration(
                      labelText: 'Grade Level',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select grade level'),
                    items: List.generate(6, (index) {
                      final grade = index + 7; // 7 to 12
                      return DropdownMenuItem(
                        value: grade,
                        child: Text('Grade $grade'),
                      );
                    }),
                    onChanged: isCreating
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedGradeLevel = value;

                              // Auto-select school level based on grade level
                              if (value != null) {
                                if (value >= 7 && value <= 10) {
                                  selectedSchoolLevel =
                                      Classroom.schoolLevelJhs;
                                } else if (value == 11 || value == 12) {
                                  selectedSchoolLevel =
                                      Classroom.schoolLevelShs;
                                }
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 16),

                  // School Level Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSchoolLevel,
                    decoration: const InputDecoration(
                      labelText: 'School Level',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select school level'),
                    items: const [
                      DropdownMenuItem(
                        value: Classroom.schoolLevelJhs,
                        child: Text('Junior High School (JHS)'),
                      ),
                      DropdownMenuItem(
                        value: Classroom.schoolLevelShs,
                        child: Text('Senior High School (SHS)'),
                      ),
                    ],
                    onChanged: isCreating
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedSchoolLevel = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),

                  // Classroom Description (Optional)
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Classroom Description (Optional)',
                      hintText: 'Brief description of the classroom',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !isCreating,
                  ),
                  const SizedBox(height: 16),

                  // Max Students
                  TextField(
                    controller: maxStudentsController,
                    decoration: const InputDecoration(
                      labelText: 'Number of People Who Can Join',
                      hintText: '1 - 100',
                      border: OutlineInputBorder(),
                      suffixText: 'students',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !isCreating,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the maximum number of students (1-100)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  if (isCreating) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      // Validation
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a classroom title'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (selectedGradeLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a grade level'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (selectedSchoolLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a school level'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final gradeLevel = selectedGradeLevel!;
                      final schoolLevel = selectedSchoolLevel!;
                      if (schoolLevel == Classroom.schoolLevelJhs &&
                          (gradeLevel < 7 || gradeLevel > 10)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Junior High School classrooms must use grade levels 7 to 10.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      if (schoolLevel == Classroom.schoolLevelShs &&
                          (gradeLevel < 11 || gradeLevel > 12)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Senior High School classrooms must use grade levels 11 to 12.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final maxStudents = int.tryParse(
                        maxStudentsController.text.trim(),
                      );
                      if (maxStudents == null ||
                          maxStudents < 1 ||
                          maxStudents > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Max students must be between 1 and 100',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (_teacherId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teacher ID not found'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      try {
                        await _classroomService.createClassroom(
                          teacherId: _teacherId!,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          gradeLevel: selectedGradeLevel!,
                          maxStudents: maxStudents,
                          schoolLevel: selectedSchoolLevel!,
                        );

                        Navigator.pop(context);

                        // Reload classrooms
                        await _loadClassrooms();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Classroom created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isCreating = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating classroom: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClassroomDialog(Classroom classroom) {
    final titleController = TextEditingController(text: classroom.title);
    final descriptionController = TextEditingController(
      text: classroom.description ?? '',
    );
    final maxStudentsController = TextEditingController(
      text: classroom.maxStudents.toString(),
    );
    int? selectedGradeLevel = classroom.gradeLevel;
    String? selectedSchoolLevel = classroom.schoolLevel;
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Classroom'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classroom Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Classroom Title',
                      hintText: 'e.g., Grade 7 - Diamond',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: 16),

                  // Grade Level Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedGradeLevel,
                    decoration: const InputDecoration(
                      labelText: 'Grade Level',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(6, (index) {
                      final grade = index + 7; // 7 to 12
                      return DropdownMenuItem(
                        value: grade,
                        child: Text('Grade $grade'),
                      );
                    }),
                    onChanged: isUpdating
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedGradeLevel = value;

                              // Auto-select school level based on grade level
                              if (value != null) {
                                if (value >= 7 && value <= 10) {
                                  selectedSchoolLevel =
                                      Classroom.schoolLevelJhs;
                                } else if (value == 11 || value == 12) {
                                  selectedSchoolLevel =
                                      Classroom.schoolLevelShs;
                                }
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 16),

                  // School Level Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSchoolLevel,
                    decoration: const InputDecoration(
                      labelText: 'School Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: Classroom.schoolLevelJhs,
                        child: Text('Junior High School (JHS)'),
                      ),
                      DropdownMenuItem(
                        value: Classroom.schoolLevelShs,
                        child: Text('Senior High School (SHS)'),
                      ),
                    ],
                    onChanged: isUpdating
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedSchoolLevel = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),

                  // Classroom Description (Optional)
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Classroom Description (Optional)',
                      hintText: 'Brief description of the classroom',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: 16),

                  // Max Students
                  TextField(
                    controller: maxStudentsController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Number of Students',
                      hintText: '1 - 100',
                      border: OutlineInputBorder(),
                      suffixText: 'students',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${classroom.currentStudents} students enrolled',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (classroom.currentStudents > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Note: Cannot set max below current enrollment (${classroom.currentStudents})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  if (isUpdating) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      // Validation
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a classroom title'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (selectedGradeLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a grade level'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (selectedSchoolLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a school level'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final gradeLevel = selectedGradeLevel!;
                      final schoolLevel = selectedSchoolLevel!;
                      if (schoolLevel == Classroom.schoolLevelJhs &&
                          (gradeLevel < 7 || gradeLevel > 10)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Junior High School classrooms must use grade levels 7 to 10.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      if (schoolLevel == Classroom.schoolLevelShs &&
                          (gradeLevel < 11 || gradeLevel > 12)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Senior High School classrooms must use grade levels 11 to 12.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final maxStudents = int.tryParse(
                        maxStudentsController.text.trim(),
                      );
                      if (maxStudents == null ||
                          maxStudents < 1 ||
                          maxStudents > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Max students must be between 1 and 100',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Check if max students is less than current enrollment
                      if (maxStudents < classroom.currentStudents) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cannot set max students to $maxStudents. '
                              'Current enrollment is ${classroom.currentStudents} students.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isUpdating = true;
                      });

                      try {
                        final updatedClassroom = await _classroomService
                            .updateClassroom(
                              classroomId: classroom.id,
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              gradeLevel: selectedGradeLevel,
                              maxStudents: maxStudents,
                              schoolLevel: selectedSchoolLevel,
                            );

                        Navigator.pop(context);

                        // Update the selected classroom and reload list
                        setState(() {
                          _selectedClassroom = updatedClassroom;
                          // Update in the list
                          final index = _classrooms.indexWhere(
                            (c) => c.id == updatedClassroom.id,
                          );
                          if (index != -1) {
                            _classrooms[index] = updatedClassroom;
                          }
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Classroom updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isUpdating = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating classroom: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveCourseDialog(Course course) {
    if (_teacherId == null || course.teacherId != _teacherId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You can only remove courses you own.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "${course.title}" from this classroom?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The course will be removed from this classroom but will still be available in "My Courses".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeCourseFromClassroom(course);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCourseFromClassroom(Course course) async {
    if (_selectedClassroom == null) return;
    if (_teacherId == null || course.teacherId != _teacherId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You can only remove courses you own.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _classroomService.removeCourseFromClassroom(
        classroomId: _selectedClassroom!.id,
        courseId: course.id,
      );

      // Reload courses for this classroom
      await _loadClassroomCourses(_selectedClassroom!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.title} removed from classroom'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteClassroomDialog(Classroom classroom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Delete Classroom'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${classroom.title}"?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• All assignments and their submissions will be permanently deleted\n'
                    '• All courses will be removed from this classroom (they remain in "My Courses")\n'
                    '• The classroom will be deactivated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (classroom.currentStudents > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This classroom has ${classroom.currentStudents} enrolled student${classroom.currentStudents > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteClassroom(classroom);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClassroom(Classroom classroom) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Deleting classroom...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Delete the classroom with cleanup: remove course mappings, delete assignments+submissions, then soft-deactivate
      await _classroomService.deleteClassroomAndCleanup(classroom.id);

      // Clear the selected classroom if it was the one deleted
      if (_selectedClassroom?.id == classroom.id) {
        setState(() {
          _selectedClassroom = null;
          _classroomCourses = [];
          _selectedCourse = null;
          _moduleFiles = [];
        });
      }

      // Reload classrooms
      await _loadClassrooms();

      // Hide loading and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${classroom.title} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting classroom: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _copyAccessCodeToClipboard() async {
    if (_selectedClassroom?.accessCode == null) return;

    try {
      await Clipboard.setData(
        ClipboardData(text: _selectedClassroom!.accessCode!),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Access code "${_selectedClassroom!.accessCode}" copied to clipboard!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying to clipboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

extension on SupabaseStreamBuilder {
  eq(String s, bool bool) {}
}
