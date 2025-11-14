import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/screens/student/grades/student_report_card_screen.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';

class StudentGradeViewerScreen extends StatefulWidget {
  const StudentGradeViewerScreen({super.key});
  @override
  State<StudentGradeViewerScreen> createState() =>
      _StudentGradeViewerScreenState();
}

class _StudentGradeViewerScreenState extends State<StudentGradeViewerScreen> {
  final ClassroomService _classroomService = ClassroomService();
  String? _uid;
  RealtimeChannel? _gradesChannel;

  // Left panel
  List<Classroom> _classrooms = [];
  bool _loadingClassrooms = true;
  Map<String, String> _teacherNames = {}; // teacherId -> full_name
  Classroom? _selectedClassroom;

  // Middle panel
  List<Course> _courses = [];
  bool _loadingCourses = false;
  Course? _selectedCourse;

  // Right panel
  Map<int, Map<String, dynamic>> _quarterGrades = {}; // quarter -> row
  // Top-controls selections and explanation data
  final DepEdGradeService _depEd = DepEdGradeService();
  int _selectedQuarter = 1; // Q1 by default
  bool _loadingExplanation = false;
  Map<String, dynamic>? _explain; // holds weights, aggregates, and item lists

  bool _loadingGrades = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _uid = user?.id;
    _subscribeGradesRealtime();
    _loadStudentClassrooms();
  }

  @override
  void dispose() {
    _gradesChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeGradesRealtime() {
    _gradesChannel?.unsubscribe();
    final uid = _uid;
    if (uid == null) return;
    final supa = Supabase.instance.client;
    _gradesChannel = supa
        .channel('student-grades:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_grades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _refreshQuarterGradesIfSelected(),
        )
        .subscribe();
  }

  Future<void> _loadStudentClassrooms() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _loadingClassrooms = true);
    try {
      final classes = await _classroomService.getStudentClassrooms(uid);
      _classrooms = classes;
      _selectedClassroom = classes.isNotEmpty ? classes.first : null;
      await _loadTeacherNames(classes.map((c) => c.teacherId).toSet().toList());
      if (_selectedClassroom != null) {
        await _loadClassroomCourses(_selectedClassroom!.id);
      }
    } catch (_) {
      setState(() {
        _classrooms = [];
        _selectedClassroom = null;
      });
    } finally {
      if (mounted) setState(() => _loadingClassrooms = false);
    }
  }

  Future<void> _loadTeacherNames(List<String> teacherIds) async {
    if (teacherIds.isEmpty) return;
    final supa = Supabase.instance.client;
    try {
      final rows = await supa
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', teacherIds);
      _teacherNames = {
        for (final r in rows)
          (r['id'] as String): (r['full_name'] as String? ?? ''),
      };
      if (mounted) setState(() {});
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _loadClassroomCourses(String classroomId) async {
    setState(() {
      _loadingCourses = true;
      _courses = [];
      _selectedCourse = null;
    });
    try {
      final courses = await _classroomService.getClassroomCourses(classroomId);
      _courses = courses;
      _selectedCourse = courses.isNotEmpty ? courses.first : null;
      if (_selectedCourse != null) await _loadQuarterGrades();
    } catch (_) {
      setState(() {
        _courses = [];
        _selectedCourse = null;
        _quarterGrades = {};
      });
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadQuarterGrades() async {
    final uid = _uid;
    final c = _selectedClassroom;
    final course = _selectedCourse;
    if (uid == null || c == null || course == null) return;
    setState(() {
      _loadingGrades = true;
      _quarterGrades = {};
    });
    try {
      final supa = Supabase.instance.client;
      final rows = await supa
          .from('student_grades')
          .select()
          .eq('student_id', uid)
          .eq('classroom_id', c.id)
          .eq('course_id', course.id);
      final map = <int, Map<String, dynamic>>{};
      for (final r in rows) {
        final q = (r['quarter'] as num?)?.toInt();
        if (q != null) map[q] = Map<String, dynamic>.from(r);
      }
      // Debug: log fetched rows' weight overrides
      // for (final e in map.entries) {
      //   final row = e.value;
      //   debugPrint('[StudentFetch] Q${e.key} ww=${row['ww_weight_override']} pt=${row['pt_weight_override']} qa=${row['qa_weight_override']}');
      // }
      if (mounted) setState(() => _quarterGrades = map);
      await _loadExplanation();
    } catch (_) {
      if (mounted) setState(() => _quarterGrades = {});
    } finally {
      if (mounted) setState(() => _loadingGrades = false);
    }
  }

  void _refreshQuarterGradesIfSelected() {
    if (_selectedClassroom != null && _selectedCourse != null) {
      _loadQuarterGrades();
    }
  }

  void _onSelectClassroom(Classroom c) async {
    setState(() {
      _selectedClassroom = c;
    });
    await _loadClassroomCourses(c.id);
  }

  void _onSelectCourse(Course c) async {
    setState(() {
      _selectedCourse = c;
      _selectedQuarter = 1; // reset to Q1 when switching courses
    });
    await _loadQuarterGrades();
    await _loadExplanation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentReportCardScreen(),
              ),
            ),
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('View Report Card'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopControls(),
          const Divider(height: 1),
          Expanded(child: _buildGradeArea()),
        ],
      ),
    );
  }

  // Top controls matching Teacher Grading Workspace style
  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Classroom selector
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<Classroom>(
                  isExpanded: true,
                  value: _selectedClassroom,
                  hint: const Text('Select classroom'),
                  items: _classrooms
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    _onSelectClassroom(v);
                  },
                ),
                if (_selectedClassroom != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4),
                    child: Text(
                      'Teacher: ${_teacherNames[_selectedClassroom!.teacherId] ?? '\u2014'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_loadingClassrooms)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          // Course selector
          SizedBox(
            width: 240,
            child: DropdownButton<Course>(
              isExpanded: true,
              value: _selectedCourse,
              hint: const Text('Select course'),
              items: _courses
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                _onSelectCourse(v);
              },
            ),
          ),
          // Quarter chips
          Wrap(
            spacing: 6,
            children: List.generate(4, (i) {
              final q = i + 1;
              final selected = _selectedQuarter == q;
              return ChoiceChip(
                label: Text('Q$q'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedQuarter = q);
                  _loadExplanation();
                },
              );
            }),
          ),
          if (_loadingCourses || _loadingGrades) const SizedBox(width: 8),
          if (_loadingCourses || _loadingGrades)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> row) {
    final weights = List<double>.from(
      _depEd.getWeights(profile: 'auto', courseTitle: _selectedCourse?.title),
    );
    // Prefer weights persisted with the grade row (fractions 0.0-1.0)
    final wwOv = (row['ww_weight_override'] as num?)?.toDouble();
    final ptOv = (row['pt_weight_override'] as num?)?.toDouble();
    final qaOv = (row['qa_weight_override'] as num?)?.toDouble();
    if (wwOv != null) weights[0] = wwOv;
    if (ptOv != null) weights[1] = ptOv;
    if (qaOv != null) weights[2] = qaOv;
    // Debug
    // debugPrint('[StudentSummary] weights used => ww=${weights[0]} pt=${weights[1]} qa=${weights[2]}');
    String fmtNum(dynamic n) {
      final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0.0;
      return d.toStringAsFixed(0);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quarter $_selectedQuarter',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtNum(row['transmuted_grade']),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('Final Grade', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Initial: ${fmtNum(row['initial_grade'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if ((row['plus_points'] ?? 0) != 0)
                      Text(
                        'Plus: ${fmtNum(row['plus_points'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if ((row['extra_points'] ?? 0) != 0)
                      Text(
                        'Extra: ${fmtNum(row['extra_points'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('WW ${(weights[0] * 100).toStringAsFixed(0)}%'),
                ),
                Chip(
                  label: Text('PT ${(weights[1] * 100).toStringAsFixed(0)}%'),
                ),
                Chip(
                  label: Text('QA ${(weights[2] * 100).toStringAsFixed(0)}%'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Computed ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  _fmtDate(
                    row['computed_at'] ??
                        row['updated_at'] ??
                        row['created_at'],
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    if (_loadingExplanation) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      );
    }
    final data = _explain;
    if (data == null) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Grade Breakdown & Explanation\nNo graded assignments found for this quarter.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      );
    }

    List<Widget> compTile(String label, String key, Color color) {
      final items = List<Map<String, dynamic>>.from(
        (data['items']?[key] as List?)?.map(
              (e) => Map<String, dynamic>.from(e),
            ) ??
            const [],
      );
      final weights = Map<String, dynamic>.from(
        data['computed']['weights'] as Map,
      );
      final double w = ((weights[key] as num?)?.toDouble() ?? 0.0) * 100.0;
      final double ps =
          ((data['computed']['${key}_ps'] as num?)?.toDouble() ?? 0.0);
      final double ws =
          ((data['computed']['${key}_ws'] as num?)?.toDouble() ?? 0.0);

      return [
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          title: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${w.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'PS ${ps.toStringAsFixed(1)}  •  WS ${ws.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      'No ${label.toLowerCase()} yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ]
              : items
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              e['missing'] == true
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle,
                              color: e['missing'] == true
                                  ? Colors.orange
                                  : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                (e['title'] ?? 'Untitled').toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (_) {
                                final sc =
                                    ((e['score'] as num?)?.toDouble() ?? 0.0);
                                final mx =
                                    ((e['max'] as num?)?.toDouble() ?? 0.0);
                                final pct = mx > 0 ? (sc / mx) * 100.0 : 0.0;
                                final style = TextStyle(
                                  fontSize: 12,
                                  color: (e['missing'] == true)
                                      ? Colors.orange
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                );
                                return Text(
                                  '${sc.toStringAsFixed(0)}/${mx.toStringAsFixed(0)}  (${pct.toStringAsFixed(0)}%)',
                                  style: style,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
        ),
      ];
    }

    final compWidgets = <Widget>[
      ...compTile('Written Works', 'ww', Colors.indigo),
      ...compTile('Performance Tasks', 'pt', Colors.blue),
      ...compTile('Quarterly Assessment', 'qa', Colors.teal),
    ];

    final plus = ((data['plus'] as num?)?.toDouble() ?? 0.0);
    final extra = ((data['extra'] as num?)?.toDouble() ?? 0.0);
    final ig = ((data['computed']['initial_grade'] as num?)?.toDouble() ?? 0.0);
    final fg =
        ((data['computed']['transmuted_grade'] as num?)?.toDouble() ?? 0.0);
    final w = Map<String, dynamic>.from(data['computed']['weights'] as Map);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade Breakdown & Explanation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...compWidgets,
            const SizedBox(height: 8),
            Text(
              '(WW_PS × ${((w['ww'] ?? 0.0) * 100).toStringAsFixed(0)}%) + (PT_PS × ${((w['pt'] ?? 0.0) * 100).toStringAsFixed(0)}%) + (QA_PS × ${((w['qa'] ?? 0.0) * 100).toStringAsFixed(0)}%) + Plus + Extra = Initial Grade',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Plus: ${plus.toStringAsFixed(0)}   Extra: ${extra.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Initial Grade = ${ig.toStringAsFixed(1)}   →   Final (Transmuted) = ${fg.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExplanation() async {
    final uid = _uid;
    final c = _selectedClassroom;
    final course = _selectedCourse;
    final q = _selectedQuarter;
    if (uid == null || c == null || course == null) return;

    setState(() {
      _loadingExplanation = true;
      _explain = null;
    });

    try {
      final supa = Supabase.instance.client;
      final quarterOr =
          'quarter_no.eq.$q,content->meta->>quarter.eq.$q,content->meta->>quarter_no.eq.$q';

      // A) Published assignments (regular assignments students can access)
      final published = List<Map<String, dynamic>>.from(
        await supa
            .from('assignments')
            .select(
              'id, title, assignment_type, component, content, total_points',
            )
            .eq('classroom_id', c.id)
            .eq('course_id', course.id)
            .eq('is_active', true)
            .eq('is_published', true)
            .or(quarterOr),
      );

      // B) Assignments for which the student has a graded submission
      final gradedSubs = List<Map<String, dynamic>>.from(
        await supa
            .from('assignment_submissions')
            .select(
              'assignment_id, score, max_score, status, submitted_at, graded_at',
            )
            .eq('student_id', uid)
            .eq('classroom_id', c.id)
            .not('score', 'is', null),
      );
      final gradedIds = gradedSubs
          .map((s) => (s['assignment_id']).toString())
          .toSet()
          .toList();

      final gradedAssigns = gradedIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await supa
                  .from('assignments')
                  .select(
                    'id, title, assignment_type, component, content, total_points',
                  )
                  .eq('classroom_id', c.id)
                  .eq('course_id', course.id)
                  .eq('is_active', true)
                  .inFilter('id', gradedIds)
                  .or(quarterOr),
            );

      // Merge and dedupe by assignment id
      final byId = <String, Map<String, dynamic>>{};
      for (final a in published) {
        byId[(a['id']).toString()] = a;
      }
      for (final a in gradedAssigns) {
        byId[(a['id']).toString()] = a;
      }
      final assigns = byId.values.toList();

      // DEBUG: Log fetched assignments to diagnose PT issue
      debugPrint(
        '[StudentExplain] Fetched ${assigns.length} total assignments',
      );
      debugPrint(
        '[StudentExplain] Published: ${published.length}, Graded: ${gradedAssigns.length}',
      );
      for (final a in assigns) {
        debugPrint(
          '[StudentExplain] Assignment ${a['id']}: '
          'title="${a['title']}", '
          'component="${a['component']}", '
          'assignment_type="${a['assignment_type']}"',
        );
      }

      // Load submissions for the combined set so the UI can show score/max/missing
      final ids = assigns.map((a) => (a['id']).toString()).toList();
      final subs = ids.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await supa
                  .from('assignment_submissions')
                  .select(
                    'assignment_id, score, max_score, status, submitted_at, graded_at',
                  )
                  .eq('student_id', uid)
                  .eq('classroom_id', c.id)
                  .inFilter('assignment_id', ids),
            );
      final subMap = {for (final s in subs) (s['assignment_id']).toString(): s};

      List<Map<String, dynamic>> ww = [], pt = [], qa = [];
      for (final a in assigns) {
        final id = (a['id']).toString();
        String? comp = (a['component'] as String?);
        comp ??= (a['component_type'] as String?);
        comp = comp?.toLowerCase();
        final String? aType = (a['assignment_type'] as String?)?.toLowerCase();
        if (comp == null || comp.isEmpty) {
          try {
            final m = (a['content'] as Map?)?['meta'] as Map?;
            comp = (m?['component'] as String?)?.toLowerCase();
          } catch (_) {
            // ignore
          }
        }
        // Normalize component variants (e.g., "Performance Task", "performance-task", "PT")
        if (comp != null && comp.isNotEmpty) {
          var norm = comp.replaceAll(RegExp(r'[^a-z]'), '_');
          if (norm == 'performance_tasks') norm = 'performance_task';
          if (norm == 'written_work') norm = 'written_works';
          if (norm == 'quarterly_assessment' ||
              norm == 'quarterly_assessments') {
            norm = 'quarterly_assessment';
          }
          // Heuristic if still not canonical
          if (norm != 'written_works' &&
              norm != 'performance_task' &&
              norm != 'quarterly_assessment') {
            if (norm.contains('perform')) {
              norm = 'performance_task';
            } else if (norm.contains('assess') ||
                norm.contains('quarter') ||
                norm.contains('exam')) {
              norm = 'quarterly_assessment';
            } else if (norm.contains('written') ||
                norm.contains('work') ||
                norm.contains('quiz')) {
              norm = 'written_works';
            }
          }
          comp = norm;
        }

        if (comp == null || comp.isEmpty) {
          // infer from assignment_type
          switch (aType) {
            case 'quiz':
            case 'seatwork':
            case 'worksheet':
            case 'short_answer':
            case 'multiple_choice':
            case 'identification':
            case 'true_false':
            case 'written_work':
            case 'written_works':
              comp = 'written_works';
              break;
            case 'performance_task':
            case 'project':
            case 'presentation':
            case 'essay':
            case 'file_upload':
            // debugPrint('[StudentExplain] id=' + id + ' comp_raw=' + (a['component']?.toString() ?? '') + ' type=' + (a['assignment_type']?.toString() ?? '') + ' -> comp=' + (comp ?? 'null'));
            case 'performance':
              comp = 'performance_task';
              break;
            case 'exam':
            case 'quarterly_assessment':
            case 'qa':
              comp = 'quarterly_assessment';
              break;
            default:
              if (aType != null) {
                if (aType.contains('perform') ||
                    aType.contains('project') ||
                    aType.contains('present')) {
                  comp = 'performance_task';
                } else if (aType.contains('exam') ||
                    aType.contains('quarter')) {
                  comp = 'quarterly_assessment';
                } else if (aType.contains('quiz') ||
                    aType.contains('written') ||
                    aType.contains('work')) {
                  comp = 'written_works';
                }
              }
          }
        }
        if (comp == 'ww') comp = 'written_works';
        if (comp == 'pt') comp = 'performance_task';
        if (comp == 'qa') comp = 'quarterly_assessment';

        // DEBUG: Log final component classification
        debugPrint(
          '[StudentExplain] Assignment $id "${a['title']}" -> component: "$comp"',
        );

        final s = subMap[id];
        final hasScore = s != null && s['score'] != null;
        final sc = hasScore ? ((s['score'] as num).toDouble()) : 0.0;
        final mx = hasScore
            ? ((s['max_score'] as num?)?.toDouble() ??
                  ((a['total_points'] as num?)?.toDouble() ?? 0.0))
            : ((a['total_points'] as num?)?.toDouble() ?? 0.0);
        final item = {
          'id': id,
          'title': a['title'] ?? 'Untitled',
          'score': sc,
          'max': mx,
          // Mark as missing when there is no graded/recorded score
          'missing': !hasScore,
          'status': s?['status'],
        };
        switch (comp) {
          case 'written_works':
            ww.add(item);
            debugPrint('[StudentExplain] -> Added to WW list');
            break;
          case 'performance_task':
            pt.add(item);
            debugPrint('[StudentExplain] -> Added to PT list');
            break;
          case 'quarterly_assessment':
            qa.add(item);
            debugPrint('[StudentExplain] -> Added to QA list');
            break;
          default:
            debugPrint('[StudentExplain] -> NOT CATEGORIZED (comp="$comp")');
            break;
        }
      }

      // DEBUG: Log final categorization summary
      debugPrint('[StudentExplain] Categorization complete:');
      debugPrint('[StudentExplain]   WW: ${ww.length} items');
      debugPrint('[StudentExplain]   PT: ${pt.length} items');
      debugPrint('[StudentExplain]   QA: ${qa.length} items');

      final plus =
          ((_quarterGrades[q]?['plus_points'] as num?)?.toDouble() ?? 0.0);
      final extra =
          ((_quarterGrades[q]?['extra_points'] as num?)?.toDouble() ?? 0.0);
      final qaScoreOv =
          ((_quarterGrades[q]?['qa_score_override'] as num?)?.toDouble() ??
          0.0);
      final qaMaxOv =
          ((_quarterGrades[q]?['qa_max_override'] as num?)?.toDouble() ?? 0.0);
      // If teacher provided a manual QA score, display it instead of aggregating QA assignments
      if (qaMaxOv > 0.0) {
        qa = [
          {
            'id': 'qa_override',
            'title': 'Quarterly Assessment (Manual)',
            'score': qaScoreOv,
            'max': qaMaxOv,
            'missing': false,
            'status': 'recorded',
          },
        ];
      }

      // Weight overrides saved in student_grades are fractions (0.0-1.0)
      final wwW = ((_quarterGrades[q]?['ww_weight_override'] as num?)
          ?.toDouble());
      final ptW = ((_quarterGrades[q]?['pt_weight_override'] as num?)
          ?.toDouble());
      final qaW = ((_quarterGrades[q]?['qa_weight_override'] as num?)
          ?.toDouble());

      // Debug
      // debugPrint('[StudentExplain] q=$q overrides -> ww=$wwW pt=$ptW qa=$qaW');

      final computed = await _depEd.computeQuarterlyBreakdown(
        classroomId: c.id,
        courseId: course.id,
        studentId: uid,
        quarter: q,
        courseTitle: course.title,
        qaScoreOverride: qaScoreOv,
        qaMaxOverride: qaMaxOv,
        plusPoints: plus,
        extraPoints: extra,
        wwWeightOverride: wwW,
        ptWeightOverride: ptW,
        qaWeightOverride: qaW,
      );

      if (!mounted) return;
      setState(() {
        _explain = {
          'items': {'ww': ww, 'pt': pt, 'qa': qa},
          'computed': computed,
          'plus': plus,
          'extra': extra,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _explain = null);
    } finally {
      if (mounted) setState(() => _loadingExplanation = false);
    }
  }

  Widget _buildGradeArea() {
    if (_selectedClassroom == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a classroom to view grades',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }
    if (_selectedCourse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a course to view grades',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    final row = _quarterGrades[_selectedQuarter];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (row == null)
            Card(
              elevation: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Quarter $_selectedQuarter • Not yet graded',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildSummaryCard(row),
            const SizedBox(height: 12),
            _buildExplanationCard(),
          ],
        ],
      ),
    );
  }

  String _fmtDate(dynamic iso) {
    try {
      return DateTime.parse(
        iso.toString(),
      ).toLocal().toString().substring(0, 16);
    } catch (_) {
      return '—';
    }
  }
}
