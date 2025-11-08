import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_read_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/submission_service.dart';
import 'package:oro_site_high_school/services/profile_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';

import 'package:oro_site_high_school/models/course.dart';

/// Student Assignment Workspace (UI only - mock data)
/// 2-layer pool: left classrooms → right assignments with quarter + 5 tabs
class StudentAssignmentWorkspaceScreen extends StatefulWidget {
  const StudentAssignmentWorkspaceScreen({super.key});

  @override
  State<StudentAssignmentWorkspaceScreen> createState() =>
      _StudentAssignmentWorkspaceScreenState();
}

class _StudentAssignmentWorkspaceScreenState
    extends State<StudentAssignmentWorkspaceScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _selectedClassroomIndex = 0;
  int _selectedQuarter = _currentQuarter();

  static int _currentQuarter() {
    final m = DateTime.now().month;
    return ((m - 1) ~/ 3) + 1; // 1..4
  }

  // Phase 2 data sources
  final _supabase = Supabase.instance.client;
  final ClassroomService _classroomService = ClassroomService();
  final SubmissionService _submissionService = SubmissionService();
  final ProfileService _profileService = ProfileService();

  // State
  List<Classroom> _classrooms = [];
  List<Map<String, dynamic>> _assignments = [];

  bool _isLoadingClassrooms = true;
  // Course filter state
  static const String _kAllCourses = 'ALL';
  List<Course> _courses = [];
  String _selectedCourseId = _kAllCourses;

  bool _isLoadingAssignments = false;

  // Cache for teacher names
  final Map<String, String> _teacherNames = {};

  // Realtime
  RealtimeChannel? _rtAssignments;
  RealtimeChannel? _rtSubmissions;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted && !_tabCtrl.indexIsChanging) {
        setState(() {});
      }
    });
    _loadClassrooms();
  }

  @override
  void dispose() {
    _teardownRealtime();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Workspace'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoadingClassrooms
          ? const Center(child: CircularProgressIndicator())
          : (_classrooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.class_outlined,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No classrooms found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      _buildLeftClassroomPanel(),
                      Expanded(
                        child: _buildRightAssignmentsPanel(_assignments),
                      ),
                    ],
                  )),
    );
  }

  Widget _buildLeftClassroomPanel() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'You have ${_classrooms.length} classrooms',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _classrooms.length,
              itemBuilder: (context, i) {
                final c = _classrooms[i];
                final selected = i == _selectedClassroomIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Teacher: ${_teacherNames[c.teacherId] ?? '—'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: _badge(
                      '${c.currentStudents} students',
                      Colors.indigo,
                    ),
                    onTap: () async {
                      await _onSelectClassroom(i);
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

  Widget _buildRightAssignmentsPanel(List<Map<String, dynamic>> all) {
    return Column(
      children: [
        _buildFiltersRow(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Submitted'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Due Today'),
              Tab(text: 'Missing'),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingAssignments
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildAssignmentList(all),
                    _buildAssignmentList(
                      all
                          .where(
                            (a) => [
                              'submitted',
                              'graded',
                              'late',
                            ].contains(a['status']),
                          )
                          .toList(),
                    ),
                    _buildAssignmentList(
                      all
                          .where(
                            (a) =>
                                a['status'] == 'pending' &&
                                (a['due'] as DateTime).isAfter(
                                  DateTime.now(),
                                ) &&
                                !_isToday(a['due']),
                          )
                          .toList(),
                    ),
                    _buildAssignmentList(
                      all
                          .where(
                            (a) =>
                                a['status'] == 'pending' && _isToday(a['due']),
                          )
                          .toList(),
                    ),
                    _buildAssignmentList(
                      all.where((a) => a['status'] == 'missed').toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // Top filter row: Course dropdown + Quarter chips (left-aligned)
  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: DropdownButton<String>(
              value: _selectedCourseId,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: _kAllCourses,
                  child: Text('All Courses'),
                ),
                ..._courses.map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() {
                  _selectedCourseId = v;
                  _isLoadingAssignments = true;
                });
                await _loadAssignmentsForSelected();
              },
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: List.generate(4, (i) {
              final q = i + 1;
              final selected = _selectedQuarter == q;
              return ChoiceChip(
                label: Text('Q$q'),
                selected: selected,
                onSelected: (_) async {
                  setState(() {
                    _selectedQuarter = q;
                    _isLoadingAssignments = true;
                  });
                  await _loadAssignmentsForSelected();
                },
                selectedColor: Colors.blue.shade100,
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectClassroom(int index) async {
    setState(() {
      _selectedClassroomIndex = index;
      _isLoadingAssignments = true;
      _selectedCourseId = _kAllCourses; // reset to All when classroom changes
      _courses = [];
    });
    await _loadCoursesForSelectedClassroom();
    await _loadAssignmentsForSelected();
    _setupRealtime();
  }

  Future<void> _loadCoursesForSelectedClassroom() async {
    if (_classrooms.isEmpty) {
      if (mounted) {
        setState(() {
          _courses = [];
          _selectedCourseId = _kAllCourses;
        });
      }
      return;
    }
    try {
      final classroomId = _classrooms[_selectedClassroomIndex].id;
      final courses = await _classroomService.getClassroomCourses(classroomId);
      if (!mounted) return;
      setState(() {
        _courses = courses;
        // Keep selection if still valid; else reset to All
        if (!_courses.any((c) => c.id == _selectedCourseId)) {
          _selectedCourseId = _kAllCourses;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _courses = [];
        _selectedCourseId = _kAllCourses;
      });
    }
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClassrooms = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _classrooms = [];
          _isLoadingClassrooms = false;
        });
        return;
      }
      final cls = await _classroomService.getStudentClassrooms(uid);
      if (!mounted) return;
      setState(() {
        _classrooms = cls;
        _selectedClassroomIndex = _classrooms.isNotEmpty ? 0 : 0;
        _isLoadingClassrooms = false;
      });
      // Preload teacher names (best-effort)
      await _preloadTeacherNames(cls.map((c) => c.teacherId).toSet());
      if (_classrooms.isNotEmpty) {
        setState(() => _isLoadingAssignments = true);
        await _loadCoursesForSelectedClassroom();
        await _loadAssignmentsForSelected();
        _setupRealtime();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classrooms = [];
        _isLoadingClassrooms = false;
        _isLoadingAssignments = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading classrooms: $e')));
    }
  }

  Future<void> _preloadTeacherNames(Iterable<String> teacherIds) async {
    for (final tid in teacherIds) {
      if (_teacherNames.containsKey(tid)) continue;
      try {
        final p = await _profileService.getProfile(tid);
        if (p != null) {
          _teacherNames[tid] = p.fullName ?? 'Teacher';
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadAssignmentsForSelected() async {
    if (_classrooms.isEmpty) {
      if (mounted) setState(() => _isLoadingAssignments = false);
      return;
    }
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');
      final classroomId = _classrooms[_selectedClassroomIndex].id;

      var query = _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('quarter_no', _selectedQuarter)
          .eq('is_active', true)
          .eq('is_published', true);
      if (_selectedCourseId != _kAllCourses) {
        final maybeInt = int.tryParse(_selectedCourseId);
        if (maybeInt != null) {
          query = query.eq('course_id', maybeInt);
        } else {
          query = query.eq('course_id', _selectedCourseId);
        }
      }
      final response = await query.order('due_date', ascending: true);

      final raw = List<Map<String, dynamic>>.from(response as List);
      final assignmentIds = raw.map((a) => a['id'].toString()).toList();
      final subs = await _submissionService.getStudentSubmissionsForAssignments(
        studentId: uid,
        assignmentIds: assignmentIds,
      );
      final subMap = <String, Map<String, dynamic>>{};
      for (final s in subs) {
        subMap[s['assignment_id'].toString()] = s;
      }

      final items = <Map<String, dynamic>>[];
      for (final a in raw) {
        final due = _parseDateTime(a['due_date']) ?? DateTime.now();
        final sub = subMap[a['id'].toString()];
        final status = _deriveSubmissionStatus(a, sub);
        final scoreVal = sub?['score'];
        final maxPts = a['total_points'];
        items.add({
          'id': a['id'],
          'title': (a['title'] ?? '').toString(),
          'type': (a['assignment_type'] ?? '').toString(),
          'component': (a['component'] ?? '').toString(),
          'quarter': a['quarter_no'] ?? 0,
          'due': due,
          'status': status,
          'score': scoreVal is num ? scoreVal.toInt() : null,
          'max': maxPts is num
              ? maxPts.toInt()
              : (maxPts is String ? int.tryParse(maxPts) : null),
        });
      }
      items.sort(
        (a, b) => (a['due'] as DateTime).compareTo(b['due'] as DateTime),
      );

      if (!mounted) return;
      setState(() {
        _assignments = items;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAssignments = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading assignments: $e')));
    }
  }

  void _setupRealtime() {
    _teardownRealtime();
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || _classrooms.isEmpty) return;
    final classroomId = _classrooms[_selectedClassroomIndex].id;

    _rtAssignments = _supabase
        .channel('student-assignments:$classroomId:Q$_selectedQuarter')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'classroom_id',
            value: classroomId,
          ),
          callback: (payload) {
            _loadAssignmentsForSelected();
          },
        )
        .subscribe();

    _rtSubmissions = _supabase
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
            _loadAssignmentsForSelected();
          },
        )
        .subscribe();
  }

  void _teardownRealtime() {
    _rtAssignments?.unsubscribe();
    _rtAssignments = null;
    _rtSubmissions?.unsubscribe();
    _rtSubmissions = null;
  }

  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }

  String _deriveSubmissionStatus(
    Map<String, dynamic> assignment,
    Map<String, dynamic>? submission,
  ) {
    if (submission != null) {
      final statusStr = (submission['status'] ?? '').toString();
      if (statusStr == 'graded') {
        return 'graded';
      }
      if (statusStr == 'submitted') {
        final due = _parseDateTime(assignment['due_date']);
        final submittedAt = _parseDateTime(submission['submitted_at']);
        final allowLate =
            (assignment['allow_late_submissions'] ?? false) == true;
        if (allowLate &&
            due != null &&
            submittedAt != null &&
            submittedAt.isAfter(due)) {
          return 'late';
        }
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
    final due = _parseDateTime(assignment['due_date']);
    if (due != null && DateTime.now().isAfter(due)) {
      return 'missed';
    }
    return 'pending';
  }

  Widget _buildAssignmentList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              'No assignments',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) => _assignmentCard(list[i]),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> a) {
    final due = a['due'] as DateTime;
    final fmt = DateFormat('MMM d, h:mm a');
    final status = (a['status'] as String);
    final score = a['score'] as int?;
    final max = a['max'] as int?;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Phase 1: mock navigation – safe to keep as preview placeholder
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) =>
                  StudentAssignmentReadScreen(assignmentId: a['id'].toString()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.assignment_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: [
                        _badge(_typeLabel(a['type']), Colors.purple),
                        _badge(_componentLabel(a['component']), Colors.teal),
                        _badge('Due ${fmt.format(due)}', Colors.orange),
                        _statusBadge(status),
                        if (status == 'graded' && score != null && max != null)
                          _badge('Score $score/$max', Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(dynamic d) {
    final date = d as DateTime;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _statusBadge(String status) {
    switch (status) {
      case 'graded':
        return _badge('Graded', Colors.blue);
      case 'submitted':
        return _badge('Submitted', Colors.green);
      case 'late':
        return _badge('Submitted Late', Colors.orange);
      case 'missed':
        return _badge('Missed', Colors.red);
      default:
        return _badge('Pending', Colors.amber);
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'identification':
        return 'Identification';
      case 'matching_type':
        return 'Matching Type';
      case 'file_upload':
        return 'File Upload';
      default:
        return t[0].toUpperCase() + t.substring(1);
    }
  }

  String _componentLabel(String c) {
    switch (c) {
      case 'written_works':
        return 'Written Works';
      case 'performance_task':
        return 'Performance Task';
      case 'quarterly_assessment':
        return 'Quarterly Assessment';
      default:
        return c;
    }
  }
}
