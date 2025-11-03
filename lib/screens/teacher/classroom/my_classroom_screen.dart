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
  StreamSubscription? _repliesStream;
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
  // Announcements (UI-only, local state)
  final List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = false;
  String? _selectedAnnouncementId;
  final Map<String, List<Map<String, dynamic>>> _announcementReplies = {};
  final TextEditingController _replyCtrl = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  final Map<String, String> _lastSelectedAnnouncement = <String, String>{};
  final Map<String, String> _replyAuthorNames = <String, String>{};
  // Join as co-teacher input state
  final TextEditingController _joinCodeCtrl = TextEditingController();
  bool _isJoiningAsTeacher = false;

  Future<void> _primeCurrentUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        final name = (row['full_name'] ?? '').toString();
        _replyAuthorNames[user.id] = name.isEmpty ? 'You' : name;
      } else {
        _replyAuthorNames[user.id] = 'You';
      }
    } catch (_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _replyAuthorNames[user.id] = 'You';
      }
    }
  }

  String _selectionKey() {
    final String c = _selectedClassroom?.id ?? '';
    final String s = _selectedCourse?.id ?? '';
    return '$c|$s';
  }

  void _rememberSelectedAnnouncement(String announcementId) {
    final String k = _selectionKey();
    if (k.isEmpty) return;
    // Explicit typed map literal used above prevents JS ddc Symbol(dartx._set) issues.
    _lastSelectedAnnouncement[k] = announcementId;
  }

  String? _restoreSelectedAnnouncement() {
    final String k = _selectionKey();
    if (k.isEmpty) return null;
    return _lastSelectedAnnouncement[k];
  }

  Future<void> _ensureReplyAuthorNames(Iterable<dynamic> authorIds) async {
    final setIds = <String>{};
    for (final a in authorIds) {
      final id = a?.toString();
      if (id != null && id.isNotEmpty && !_replyAuthorNames.containsKey(id)) {
        setIds.add(id);
      }
    }
    if (setIds.isEmpty) return;

    // First attempt: batch fetch via IN filter (fast path)
    final fetchedIds = <String>{};
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', setIds.toList());
      for (final row in (rows as List)) {
        final id = row['id']?.toString();
        if (id != null) {
          final name = (row['full_name'] ?? '').toString();
          _replyAuthorNames[id] = name.isEmpty ? 'User' : name;
          fetchedIds.add(id);
        }
      }
    } catch (_) {
      // ignore and fallback to per-id
    }

    // Fallback: fetch any missing IDs individually (robust against uuid/text mismatch)
    final missing = setIds.difference(fetchedIds);
    for (final id in missing) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .eq('id', id)
            .maybeSingle();
        if (row != null) {
          final name = (row['full_name'] ?? '').toString();
          _replyAuthorNames[id] = name.isEmpty ? 'User' : name;
        }
      } catch (_) {
        // ignore; fallback will be used by UI
      }
    }

    // Ensure current user has a name cached as a last resort
    if (_teacherId != null && !_replyAuthorNames.containsKey(_teacherId)) {
      await _primeCurrentUserName();
    }
  }

  Future<void> _reloadRepliesFromView(String idStr, int annId) async {
    try {
      final rows = await Supabase.instance.client.rpc(
        'get_replies_with_author',
        params: {'p_announcement_id': annId},
      );
      final list = <Map<String, dynamic>>[];
      for (final row in (rows as List)) {
        DateTime created = DateTime.now();
        final s = row['created_at']?.toString();
        if (s != null && s.isNotEmpty) {
          try {
            created = DateTime.parse(s).toLocal();
          } catch (_) {}
        }
        final bool deleted = row['is_deleted'] == true;
        final authorIdStr = row['author_id']?.toString();
        final String? me =
            _teacherId ?? Supabase.instance.client.auth.currentUser?.id;
        final authorName =
            (row['author_name'] ??
                    ((me != null && authorIdStr == me) ? 'You' : 'User'))
                .toString();
        list.add({
          'id': row['id'],
          'authorId': authorIdStr,
          'authorName': authorName,
          'content': deleted ? '' : row['content'],
          'isDeleted': deleted,
          'createdAt': created,
        });
      }
      if (!mounted) return;
      setState(() {
        _announcementReplies[idStr] = list;
      });
    } catch (_) {}
  }

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
      if (_tabController.index == 2 && _selectedCourse != null) {
        _loadAnnouncementsForSelectedCourse();
      }
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
    _studentsSearchCtrl.addListener(() {
      setState(() {
        _studentsQuery = _studentsSearchCtrl.text.trim();
      });
    });
    _initializeTeacher();
    _subscribeClassroomsRealtime();
  }

  @override
  void dispose() {
    _classroomStream?.cancel();
    _repliesStream?.cancel();
    _tabController.dispose();
    _quarterTabController.dispose();
    _studentsSearchCtrl.dispose();
    _replyCtrl.dispose();
    _replyFocus.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeTeacher() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _teacherId = user.id;
        });
        await _primeCurrentUserName();
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
          if (_tabController.index == 2) {
            // If currently on announcements tab, refresh announcements for new classroom+course
            _loadAnnouncementsForSelectedCourse();
          }
        } else {
          _selectedCourse = null;
          _moduleFiles = [];
          // Clear announcements when there are no courses for this classroom
          _announcements.clear();
          _selectedAnnouncementId = null;
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
          _announcements.clear();
          _selectedAnnouncementId = null;
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
            child: Text(
              _isLoading
                  ? 'Loading...'
                  : 'you have ${_classrooms.length} classroom${_classrooms.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                              _selectedAnnouncementId = null;
                              _announcementReplies.clear();
                            });
                            _repliesStream?.cancel();
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
                              _selectedAnnouncementId = null;
                              _announcementReplies.clear();
                            });
                            _repliesStream?.cancel();
                            _loadCourseModules(course.id);
                            if (_tabController.index == 1 &&
                                _selectedClassroom != null &&
                                _canAccessAssignments()) {
                              _loadClassroomAssignments(_selectedClassroom!.id);
                            }
                            if (_tabController.index == 2) {
                              _loadAnnouncementsForSelectedCourse();
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
                            'my students',
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
                            child: Text(
                              '${_enrollmentCounts[_selectedClassroom!.id] ?? _selectedClassroom!.currentStudents}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
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
            child: _buildStudentsTab(setLocal: setLocal),
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

              List<Map<String, dynamic>> students =
                  List<Map<String, dynamic>>.from(snapshot.data ?? const []);
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
                                      onPressed: () => Navigator.pop(ctx, true),
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
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Removed $fullName from classroom',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                  setState(
                                    () {},
                                  ); // trigger FutureBuilder refresh
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
              onTap: _selectedClassroom == null ? null : _showAddStudentDialog,
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

  void _showAddStudentDialog() async {
    if (_selectedClassroom == null) return;
    final TextEditingController searchCtrl = TextEditingController();
    List<Profile> results = [];
    bool isLoading = false;
    final enrolledIds = <String>{};

    try {
      final enrolled = await _classroomService.getClassroomStudents(
        _selectedClassroom!.id,
      );
      for (final s in enrolled) {
        final sid = s['student_id'] as String?;
        if (sid != null) enrolledIds.add(sid);
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> runSearch(String q) async {
            setDialogState(() {
              isLoading = true;
            });
            try {
              final list = await _profileService.getAllUsers(
                roleFilter: 'student',
                searchQuery: q.isEmpty ? null : q,
                limit: 50,
                page: 1,
              );
              setDialogState(() {
                results = list;
              });
            } catch (e) {
              // ignore
            } finally {
              setDialogState(() {
                isLoading = false;
              });
            }
          }

          if (results.isEmpty && !isLoading) {
            runSearch('');
          }

          Future<void> addStudent(Profile p) async {
            setDialogState(() {
              isLoading = true;
            });
            final res = await _classroomService.joinClassroom(
              accessCode: _selectedClassroom!.id,
              studentId: p.id,
            );
            setDialogState(() {
              isLoading = false;
            });
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
              enrolledIds.add(p.id);
              await _refreshEnrollmentCount(_selectedClassroom!.id);
              setState(() {});
            }
          }

          return AlertDialog(
            title: const Text('Add student to classroom'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search students by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                runSearch('');
                              },
                            ),
                    ),
                    onChanged: (q) => runSearch(q),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    width: double.infinity,
                    child: results.isEmpty && !isLoading
                        ? Center(
                            child: Text(
                              'No students found',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          )
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final p = results[i];
                              final already = enrolledIds.contains(p.id);
                              return ListTile(
                                leading: CircleAvatar(child: Text(p.initials)),
                                title: Text(p.displayName),
                                subtitle: Text(p.email ?? ''),
                                trailing: TextButton.icon(
                                  onPressed: already || isLoading
                                      ? null
                                      : () => addStudent(p),
                                  icon: const Icon(Icons.add),
                                  label: Text(already ? 'Added' : 'Add'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: already
                                        ? Colors.grey
                                        : Colors.blue,
                                  ),
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
    );
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

        return Container(
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
                            (a['is_published'] == true) ? 'published' : 'draft',
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

  void _subscribeRepliesForSelectedAnnouncement() {
    _repliesStream?.cancel();
    final idStr = _selectedAnnouncementId;
    if (idStr == null) return;
    final annId = int.tryParse(idStr);
    if (annId == null) return;

    try {
      // Preload existing replies
      _loadRepliesForSelectedAnnouncement();
      _repliesStream = Supabase.instance.client
          .from('announcement_replies')
          .stream(primaryKey: ['id'])
          .eq('announcement_id', annId)
          .listen((_) async {
            await _reloadRepliesFromView(idStr, annId);
          });
    } catch (e) {
      // silent fail, UI will handle empty list
    }
  }

  Future<void> _softDeleteReply(int replyId) async {
    try {
      final client = Supabase.instance.client;

      // Fetch existing reply to preserve author and timestamp
      final fetched = await client
          .from('announcement_replies')
          .select('id, author_id, created_at, announcement_id')
          .eq('id', replyId)
          .limit(1);

      Map<String, dynamic>? old;
      if (fetched is List && fetched.isNotEmpty) {
        old = Map<String, dynamic>.from(fetched.first as Map);
      }
      if (old == null) {
        return;
      }

      final annId = old['announcement_id'];

      // Delete the original message row
      await client.from('announcement_replies').delete().eq('id', replyId);

      // Insert a placeholder row to keep the bubble constant
      final insertData = <String, dynamic>{
        'announcement_id': annId,
        'author_id': Supabase.instance.client.auth.currentUser?.id,
        'author_id': old['author_id'],
        'content': '',
        'is_deleted': true,
      };
      if (old['created_at'] != null) {
        insertData['created_at'] = old['created_at'];
      }
      await client.from('announcement_replies').insert(insertData);

      // Optimistic local state update: mark as deleted placeholder
      final k = _selectedAnnouncementId;
      if (k != null) {
        setState(() {
          final current = List<Map<String, dynamic>>.from(
            _announcementReplies[k] ?? const [],
          );
          final idx = current.indexWhere((e) => (e['id'] == replyId));
          if (idx != -1) {
            final updated = Map<String, dynamic>.from(current[idx]);
            updated['isDeleted'] = true;
            updated['content'] = '';
            current[idx] = updated;
            _announcementReplies[k] = current;
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRepliesForSelectedAnnouncement() async {
    final idStr = _selectedAnnouncementId;
    if (idStr == null) return;
    final annId = int.tryParse(idStr);
    if (annId == null) return;
    try {
      final rows = await Supabase.instance.client.rpc(
        'get_replies_with_author',
        params: {'p_announcement_id': annId},
      );
      final list = <Map<String, dynamic>>[];
      for (final row in (rows as List)) {
        DateTime created = DateTime.now();
        final s = row['created_at']?.toString();
        if (s != null && s.isNotEmpty) {
          try {
            created = DateTime.parse(s).toLocal();
          } catch (_) {}
        }
        final bool deleted = row['is_deleted'] == true;
        final authorIdStr = row['author_id']?.toString();
        final authorName =
            (row['author_name'] ??
                    (_teacherId != null && authorIdStr == _teacherId
                        ? 'You'
                        : 'User'))
                .toString();
        list.add({
          'id': row['id'],
          'authorId': authorIdStr,
          'authorName': authorName,
          'content': deleted ? '' : row['content'],
          'isDeleted': deleted, // show deleted placeholder
          'createdAt': created,
        });
      }
      if (!mounted) return;
      setState(() {
        _announcementReplies[idStr] = list;
      });
    } catch (_) {}
  }

  Future<void> _loadAnnouncementsForSelectedCourse() async {
    if (_selectedCourse == null) return;
    setState(() {
      _isLoadingAnnouncements = true;
    });
    try {
      final courseId = int.tryParse(_selectedCourse!.id) ?? 0;
      final rows = await Supabase.instance.client
          .from('announcements')
          .select()
          .eq('course_id', courseId)
          .eq('classroom_id', _selectedClassroom!.id)
          .order('created_at', ascending: false);
      final list = <Map<String, dynamic>>[];
      for (final row in (rows as List)) {
        list.add({
          'id': row['id'].toString(),
          'title': row['title'],
          'body': row['content'],
          'createdAt': (() {
            final s = row['created_at']?.toString();
            if (s != null && s.isNotEmpty) {
              try {
                return DateTime.parse(s).toLocal();
              } catch (_) {}
            }
            return DateTime.now();
          })(),
        });
      }
      setState(() {
        _announcements
          ..clear()
          ..addAll(list);
        try {
          if (_tabController.index == 2 && _announcements.isNotEmpty) {
            // Prefer remembered selection; fallback to current or first
            final remembered = _restoreSelectedAnnouncement();
            String? effective;
            if (remembered != null &&
                _announcements.any((a) => a['id'].toString() == remembered)) {
              effective = remembered;
            } else if (_selectedAnnouncementId != null &&
                _announcements.any(
                  (a) => a['id'].toString() == _selectedAnnouncementId,
                )) {
              effective = _selectedAnnouncementId;
            } else {
              effective = _announcements.first['id'].toString();
            }

            final changed = effective != _selectedAnnouncementId;
            _selectedAnnouncementId = effective;
            _rememberSelectedAnnouncement(effective!);
            if (changed ||
                (_announcementReplies[effective] == null ||
                    _announcementReplies[effective]!.isEmpty)) {
              _subscribeRepliesForSelectedAnnouncement();
            }
          }
        } catch (_) {}
        _isLoadingAnnouncements = false;
        if (_announcements.isEmpty) {
          _selectedAnnouncementId = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingAnnouncements = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAnnouncementsTab() {
    // Two-pane layout: Announcements list (left) + Replies (right)
    return Row(
      children: [
        // Left: Announcements list
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with label and add button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'announcements',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'New announcement',
                      child: InkWell(
                        onTap: _showCreateAnnouncementDialog,
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
                              Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingAnnouncements
                    ? const Center(child: CircularProgressIndicator())
                    : _announcements.isEmpty
                    ? Center(
                        child: Text(
                          'No announcements yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _announcements.length,
                        itemBuilder: (ctx, i) {
                          final a = _announcements[i];
                          final isSelected = _selectedAnnouncementId == a['id'];
                          return Card(
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            child: ListTile(
                              title: Text(
                                a['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    a['body'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a['createdAt'] != null
                                        ? 'posted at: ${_formatLongDate(a['createdAt'] as DateTime)}'
                                        : '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedAnnouncementId = a['id']
                                              .toString();
                                          _rememberSelectedAnnouncement(
                                            _selectedAnnouncementId!,
                                          );
                                        });
                                        _subscribeRepliesForSelectedAnnouncement();
                                        Future.microtask(
                                          () => _replyFocus.requestFocus(),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.reply_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Reply'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    _showEditAnnouncementDialog(a);
                                  } else if (val == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Delete announcement',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete this announcement?',
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
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        final id = int.parse(
                                          a['id'].toString(),
                                        );
                                        await Supabase.instance.client
                                            .from('announcements')
                                            .delete()
                                            .eq('id', id);
                                        await _loadAnnouncementsForSelectedCourse();
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Announcement deleted',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error deleting: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedAnnouncementId = a['id'].toString();
                                });
                                _subscribeRepliesForSelectedAnnouncement();
                                _showAnnouncementFullDialog(a);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Divider
        Container(width: 1, color: Colors.grey.shade300),
        // Right: Replies panel
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'replies',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: (_selectedAnnouncementId == null)
                    ? Center(
                        child: Text(
                          'Select an announcement to view replies',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            ((_announcementReplies[_selectedAnnouncementId!] ??
                                    const [])
                                .length) +
                            1,
                        itemBuilder: (ctx, i) {
                          final list =
                              _announcementReplies[_selectedAnnouncementId!] ??
                              const [];

                          // 🧩 Reply header ("replying to <announcement>")
                          if (i == 0) {
                            String title = '';
                            try {
                              final match = _announcements.firstWhere(
                                (a) =>
                                    a['id'].toString() ==
                                    _selectedAnnouncementId,
                              );
                              title = (match['title'] ?? '').toString();
                            } catch (_) {}
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.reply_outlined,
                                        size: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'replying to',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        title.isEmpty ? 'announcement' : title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // 🗨️ Replies
                          final r = list[i - 1];
                          final String? me =
                              _teacherId ??
                              Supabase.instance.client.auth.currentUser?.id;
                          final bool isMine =
                              (me != null && r['authorId']?.toString() == me);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMine)
                                  const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.person, size: 14),
                                  ),
                                if (!isMine) const SizedBox(width: 8),

                                // 💬 Message + name + time
                                Flexible(
                                  child: GestureDetector(
                                    onLongPress: () async {
                                      final bool isDeleted =
                                          (r['isDeleted'] == true);
                                      if (!isMine || isDeleted) return;
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete message'),
                                          content: const Text(
                                            'This message will be marked as deleted.',
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
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _softDeleteReply(r['id'] as int);
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment: isMine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        // 🧠 Author name (above message)
                                        Text(
                                          r['authorName'] ?? 'Unknown Author',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // 💬 Message bubble
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMine
                                                ? Colors.blue.shade100
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                12,
                                              ),
                                              topRight: const Radius.circular(
                                                12,
                                              ),
                                              bottomLeft: isMine
                                                  ? const Radius.circular(12)
                                                  : const Radius.circular(4),
                                              bottomRight: isMine
                                                  ? const Radius.circular(4)
                                                  : const Radius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            (r['isDeleted'] == true)
                                                ? 'deleted message'
                                                : (r['content'] ?? ''),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontStyle:
                                                  (r['isDeleted'] == true)
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              color: (r['isDeleted'] == true)
                                                  ? Colors.grey.shade600
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // 🕒 Date + Time below message
                                        Text(
                                          r['createdAt'] != null
                                              ? _formatLongDate(
                                                  r['createdAt'] as DateTime,
                                                )
                                              : '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMine) const SizedBox(width: 8),
                                if (isMine)
                                  const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.person, size: 14),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Reply composer (always visible; disabled effect when none selected)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _replyCtrl,
                          focusNode: _replyFocus,
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: _selectedAnnouncementId == null
                                ? 'Select an announcement first'
                                : 'Aa',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final text = _replyCtrl.text.trim();
                        if (_selectedAnnouncementId == null || text.isEmpty)
                          return;
                        try {
                          final userId =
                              Supabase.instance.client.auth.currentUser?.id;
                          if (userId == null) return;
                          final annId = int.parse(_selectedAnnouncementId!);
                          await Supabase.instance.client
                              .from('announcement_replies')
                              .insert({
                                'announcement_id': annId,
                                'author_id': userId,
                                'content': text,
                                'is_deleted': false,
                              });
                          // Ensure local cache has the sender's name for immediate render
                          await _ensureReplyAuthorNames([userId]);
                          // Optimistic update so it appears immediately
                          setState(() {
                            final k = _selectedAnnouncementId!;
                            final current = List<Map<String, dynamic>>.from(
                              _announcementReplies[k] ?? const [],
                            );
                            current.add({
                              'authorId': userId,
                              'content': text,
                              'createdAt': DateTime.now(),
                            });
                            _announcementReplies[k] = current;
                          });
                          _replyCtrl.clear();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sending reply: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isPosting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('New announcement'),
          content: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: bodyCtrl,
                    minLines: 8,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      hintText: 'Write your announcement here... ',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isPosting) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: isPosting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            InkWell(
              onTap: isPosting
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final body = bodyCtrl.text.trim();
                      if (title.isEmpty ||
                          body.isEmpty ||
                          _selectedCourse == null)
                        return;
                      setDlg(() {
                        isPosting = true;
                      });
                      try {
                        final courseId = int.tryParse(_selectedCourse!.id) ?? 0;
                        final row = await Supabase.instance.client
                            .from('announcements')
                            .insert({
                              'course_id': courseId,
                              'classroom_id': _selectedClassroom!.id,
                              'title': title,
                              'content': body,
                            })
                            .select()
                            .single();
                        _selectedAnnouncementId = row['id'].toString();
                        if (mounted) {
                          await _loadAnnouncementsForSelectedCourse();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Announcement posted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error posting: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setDlg(() {
                          isPosting = false;
                        });
                      }
                    },
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
                      'post',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAnnouncementDialog(Map<String, dynamic> a) {
    final titleCtrl = TextEditingController(text: a['title'] ?? '');
    final bodyCtrl = TextEditingController(text: a['body'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit announcement'),
          content: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: bodyCtrl,
                    minLines: 8,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      hintText: 'Update your announcement...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isSaving) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final body = bodyCtrl.text.trim();
                      if (title.isEmpty || body.isEmpty) return;
                      setDlg(() {
                        isSaving = true;
                      });
                      try {
                        final id = int.parse(a['id'].toString());
                        await Supabase.instance.client
                            .from('announcements')
                            .update({'title': title, 'content': body})
                            .eq('id', id);
                        if (mounted) {
                          await _loadAnnouncementsForSelectedCourse();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Announcement updated'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setDlg(() {
                          isSaving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementFullDialog(Map<String, dynamic> a) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final double screenW = MediaQuery.of(ctx).size.width;
        // Fixed-but-adjustable width: 55% of screen, clamped between 420 and 720
        double dialogW = screenW * 0.55;
        if (dialogW < 420) dialogW = 420;
        if (dialogW > 720) dialogW = 720;

        final title = (a['title'] ?? '').toString();
        final body = (a['body'] ?? '').toString();
        final created = a['createdAt'] as DateTime?;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogW),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title.isEmpty ? 'Untitled' : title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    created != null
                        ? 'posted at: ${_formatLongDate(created)}'
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // White content box with min height and scroll for overflow
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 160,
                      minWidth: double.infinity,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('close'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedAnnouncementId = a['id'].toString();
                          });
                          _rememberSelectedAnnouncement(
                            _selectedAnnouncementId!,
                          );
                          _subscribeRepliesForSelectedAnnouncement();
                          Navigator.pop(ctx);
                          Future.microtask(() => _replyFocus.requestFocus());
                        },
                        child: const Text('reply'),
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
                    '• All courses will be removed from this classroom\n'
                    '• Classroom data will be permanently deleted\n'
                    '• Courses will remain in "My Courses"',
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

      // Delete the classroom (this will cascade delete classroom_courses due to ON DELETE CASCADE)
      await _classroomService.deleteClassroom(classroom.id);

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
