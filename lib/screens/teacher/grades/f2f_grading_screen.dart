import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/services/submission_service.dart';

class F2FGradingScreen extends StatefulWidget {
  final Classroom classroom;
  final int? initialQuarter; // 1-4, optional preselection from Grade Entry
  const F2FGradingScreen({
    super.key,
    required this.classroom,
    this.initialQuarter,
  });

  @override
  State<F2FGradingScreen> createState() => _F2FGradingScreenState();
}

class _F2FGradingScreenState extends State<F2FGradingScreen> {
  // Phase 1: UI only (mock data)
  bool _created = false;

  // Activity form controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '10');
  // Course data
  final ClassroomService _classroomService = ClassroomService();
  List<Course> _courses = [];
  Course? _selectedCourse;
  String? _teacherId;
  bool _loadingCourses = true;

  // Persisted details after "Create Activity"
  String _activityTitle = '';
  String _activityDesc = '';
  int _maxPoints = 10;
  String _courseName = '';

  // Real students fetched for the classroom
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = false;
  // Phase 2 state
  final AssignmentService _assignmentService = AssignmentService();
  final SubmissionService _submissionService = SubmissionService();
  String? _selectedComponent; // 'written_works' | 'performance_task'
  String? _activityComponent; // frozen after creation for display
  String? _activityId; // saved assignment id
  bool _savingActivity = false;
  bool _savingScores = false;

  // Quarter selection (optional prefill from Grade Entry)
  int? _selectedQuarter; // 1-4
  int? _activityQuarter; // frozen after creation for display

  // Recent F2F activities
  List<Map<String, dynamic>> _recentActivities = [];
  bool _loadingRecent = false;

  String _componentDisplay(String? v) {
    switch (v) {
      case 'written_works':
        return 'Written Works';
      case 'performance_task':
        return 'Performance Task';
      default:
        return v ?? '';
    }
  }

  final Map<String, TextEditingController> _scoreCtrls = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  RoundedRectangleBorder get _cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: Colors.grey.shade200),
  );

  InputDecoration get _inputDecoration => const InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
  );

  TextStyle get _labelStyle =>
      TextStyle(fontSize: 12, color: Colors.grey.shade700);

  @override
  void initState() {
    super.initState();
    // Preselect quarter from Grade Entry if provided
    _selectedQuarter = widget.initialQuarter;
    _initCourses();
    _loadRecentActivities();
  }

  Future<void> _initCourses() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      setState(() {
        _teacherId = uid;
        _loadingCourses = true;
      });
      final all = await _classroomService.getClassroomCourses(
        widget.classroom.id,
      );
      final owned = uid == null
          ? all
          : all.where((c) => c.teacherId == uid).toList();
      setState(() {
        _courses = owned;
        _selectedCourse = owned.isNotEmpty ? owned.first : null;
        _loadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _courses = [];
        _selectedCourse = null;
        _loadingCourses = false;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() => _loadingRecent = true);
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('assignments')
          .select(
            'id, title, course_id, total_points, component, quarter_no, created_at, content, description',
          )
          .eq('classroom_id', widget.classroom.id)
          .eq('assignment_type', 'quiz')
          .order('created_at', ascending: false)
          .limit(15);
      final list = List<Map<String, dynamic>>.from(rows as List).where((r) {
        final c = r['content'];
        if (c is Map && c['meta'] is Map) {
          return (c['meta']['created_via'] ?? '') == 'f2f_grading';
        }
        return false;
      }).toList();
      if (!mounted) return;
      setState(() {
        _recentActivities = list;
        _loadingRecent = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRecent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recent activities: $e')),
        );
      }
    }
  }

  Future<void> _openExistingActivity(Map<String, dynamic> a) async {
    final id = a['id']?.toString();
    final title = (a['title'] ?? '').toString();
    final comp = (a['component'] ?? (a['content']?['meta']?['component']))
        ?.toString();
    final qRaw = a['quarter_no'] ?? a['content']?['meta']?['quarter'];
    final q = qRaw is int ? qRaw : int.tryParse('$qRaw');
    final points = (a['total_points'] ?? 0) as int;
    final courseId = (a['course_id'] ?? '').toString();
    String courseTitle = 'Course';
    for (final c in _courses) {
      if (c.id == courseId) {
        courseTitle = c.title;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _activityId = id;
      _activityTitle = title;
      _activityDesc = (a['description'] ?? '').toString();
      _maxPoints = points;
      _courseName = courseTitle;
      _activityComponent = comp;
      _activityQuarter = q;
      _created = true;
      _loadingStudents = true;
    });
    await _loadStudents();
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      elevation: 1,
      shape: _cardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Recent F2F Activities',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingRecent)
              const LinearProgressIndicator()
            else if (_recentActivities.isEmpty)
              Text(
                'No recent F2F activities. Create one below.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final a = _recentActivities[i];
                  final title = (a['title'] ?? 'Untitled').toString();
                  final comp =
                      (a['component'] ?? (a['content']?['meta']?['component']))
                          ?.toString();
                  final q =
                      a['quarter_no'] ?? a['content']?['meta']?['quarter'];
                  final points = a['total_points'];
                  final courseId = (a['course_id'] ?? '').toString();
                  String courseTitle = 'Course';
                  for (final c in _courses) {
                    if (c.id == courseId) {
                      courseTitle = c.title;
                      break;
                    }
                  }
                  final createdAt = (a['created_at'] ?? '').toString();
                  final createdShort = createdAt
                      .replaceFirst('T', ' ')
                      .split('.')
                      .first;

                  String meta = courseTitle;
                  if (comp != null && comp.toString().isNotEmpty) {
                    meta += ' • ${_componentDisplay(comp.toString())}';
                  }
                  if (q != null) meta += ' • Q$q';
                  if (points != null) meta += ' • Max: $points';
                  meta += ' • $createdShort';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meta,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openExistingActivity(a),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Scores'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('F2F Grading')),
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: _created ? _buildScoringStep() : _buildActivityForm(),
      ),
    );
  }

  // Step 1: Activity creation (UI only)
  Widget _buildActivityForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: SingleChildScrollView(child: _buildRecentActivitiesCard()),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 1,
            shape: _cardShape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Activity',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Subject / Course first
                    Text('Subject / Course', style: _labelStyle),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<Course>(
                      initialValue: _selectedCourse,
                      isExpanded: true,
                      items: _courses
                          .map(
                            (c) => DropdownMenuItem<Course>(
                              value: c,
                              child: Text(
                                c.title,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingCourses || _courses.isEmpty
                          ? null
                          : (v) => setState(() => _selectedCourse = v),
                      decoration: _inputDecoration.copyWith(
                        hintText: _loadingCourses
                            ? 'Loading courses...'
                            : (_courses.isEmpty ? 'No courses found' : null),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text('Component', style: _labelStyle),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedComponent,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'written_works',
                          child: Text(
                            'Written Works',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'performance_task',
                          child: Text(
                            'Performance Task',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedComponent = v),
                      decoration: _inputDecoration.copyWith(
                        hintText: 'Select component',
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text('Quarter', style: _labelStyle),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedQuarter,
                      isExpanded: true,
                      items: [1, 2, 3, 4]
                          .map(
                            (q) => DropdownMenuItem<int>(
                              value: q,
                              child: Text(
                                'Quarter $q',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedQuarter = v),
                      decoration: _inputDecoration.copyWith(
                        hintText: 'Select quarter',
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Title
                    Text('Activity Title', style: _labelStyle),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration.copyWith(
                        hintText: 'e.g., Quiz 1',
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text('Description (optional)', style: _labelStyle),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration.copyWith(
                        hintText: 'Notes or coverage',
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text('Max Score / Total Points', style: _labelStyle),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration.copyWith(
                        hintText: 'e.g., 10',
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savingActivity
                            ? null
                            : _saveActivityAndProceed,
                        icon: const Icon(Icons.playlist_add_check),
                        label: Text(
                          _savingActivity ? 'Saving…' : 'Create Activity',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _initScoreControllers() {
    // Clear any existing controllers
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    _scoreCtrls.clear();
    for (final s in _students) {
      final id = s['student_id']?.toString() ?? '';
      if (id.isNotEmpty) {
        _scoreCtrls[id] = TextEditingController();
      }
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final rows = await _classroomService.getClassroomStudents(
        widget.classroom.id,
      );

      setState(() {
        _students = rows;
        _loadingStudents = false;
      });
      _initScoreControllers();
      await _prefillExistingScores();
    } catch (e) {
      setState(() {
        _students = [];
        _loadingStudents = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _prefillExistingScores() async {
    final aid = _activityId;
    if (aid == null) return;
    try {
      final rows = await _submissionService.getSubmissionsForAssignment(aid);
      for (final r in rows) {
        final sid = (r['student_id'] ?? '').toString();
        final sc = r['score'];
        if (sid.isEmpty || sc == null) continue;
        final ctrl = _scoreCtrls[sid];
        if (ctrl != null) ctrl.text = (sc as num).toString();
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Ignore prefill errors to not block manual entry
    }
  }

  Future<void> _saveActivityAndProceed() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final max = int.tryParse(_maxCtrl.text.trim());
    final course = _selectedCourse;
    final comp = _selectedComponent;
    final q = _selectedQuarter;
    final uid = _teacherId ?? Supabase.instance.client.auth.currentUser?.id;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create an activity'),
        ),
      );
      return;
    }
    if (course == null || title.isEmpty || max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the required fields')),
      );
      return;
    }
    if (comp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a component')),
      );
      return;
    }
    if (q == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a quarter')));
      return;
    }

    setState(() => _savingActivity = true);
    try {
      final created = await _assignmentService.createAssignment(
        classroomId: widget.classroom.id,
        teacherId: uid,
        title: title,
        description: desc.isEmpty ? null : desc,
        assignmentType: 'quiz',
        totalPoints: max,
        dueDate: null,
        content: {
          'meta': {
            'created_via': 'f2f_grading',
            'component': comp,
            'quarter': q,
          },
        },
        courseId: course.id,
        component: comp,
        quarterNo: q,
      );
      final id = created['id']?.toString();
      if (!mounted) return;
      setState(() {
        _activityId = id;
        _activityTitle = title;
        _activityDesc = desc;
        _maxPoints = max;
        _courseName = course.title;
        _activityComponent = comp;
        _activityQuarter = q;
        _created = true;
        _loadingStudents = true;
      });
      await _loadStudents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingActivity = false);
    }
  }

  Future<void> _saveAllScores() async {
    if (_activityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create the activity first')),
      );
      return;
    }
    setState(() => _savingScores = true);
    int saved = 0;
    final errors = <String>[];

    for (final s in _students) {
      final id = (s['student_id'] ?? '').toString();
      final name = (s['full_name'] ?? 'Student').toString();
      final text = _scoreCtrls[id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final score = int.tryParse(text);
      if (score == null) {
        errors.add('$name: invalid number');
        continue;
      }
      if (score < 0 || score > _maxPoints) {
        errors.add('$name: out of range (0-$_maxPoints)');
        continue;
      }
      try {
        final existing = await _submissionService.getStudentSubmission(
          assignmentId: _activityId!,
          studentId: id,
        );
        if (existing == null) {
          await _submissionService.createSubmission(
            assignmentId: _activityId!,
            studentId: id,
            classroomId: widget.classroom.id,
          );
        }
        await _submissionService.updateSubmissionGrade(
          assignmentId: _activityId!,
          studentId: id,
          score: score,
          maxScore: _maxPoints,
        );
        saved++;
      } catch (e) {
        errors.add('$name: $e');
      }
    }

    if (!mounted) return;
    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scores saved successfully for $saved students'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final preview = errors.take(3).join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scores saved for $saved. ${errors.length} errors.\n$preview',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    setState(() => _savingScores = false);
  }

  // Step 2: Student score entry (UI only)
  Widget _buildScoringStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity summary
        Card(
          elevation: 1,
          shape: _cardShape,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Activity Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _created = false),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _chip('Title', _activityTitle),
                    _chip('Course', _courseName),
                    if (_activityComponent != null)
                      _chip('Component', _componentDisplay(_activityComponent)),
                    if (_activityQuarter != null)
                      _chip('Quarter', 'Q$_activityQuarter'),
                    _chip('Max', '$_maxPoints'),
                    if (_activityDesc.isNotEmpty) _chip('Notes', _activityDesc),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Scores entry list
        Expanded(
          child: Card(
            elevation: 1,
            shape: _cardShape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Enter Scores',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const Spacer(),
                      Text('0 - $_maxPoints', style: _labelStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        _tableHeaderCell('Student', flex: 3),
                        _tableHeaderCell('Score'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _loadingStudents
                        ? const Center(child: LinearProgressIndicator())
                        : (_students.isEmpty
                              ? Center(
                                  child: Text(
                                    'No students enrolled',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _students.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, i) {
                                    final s = _students[i];
                                    final id = (s['student_id'] ?? '')
                                        .toString();
                                    final name = (s['full_name'] ?? 'Student')
                                        .toString();
                                    final ctrl = _scoreCtrls[id] ??=
                                        TextEditingController();
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 96,
                                              child: TextField(
                                                controller: ctrl,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                decoration: _inputDecoration
                                                    .copyWith(
                                                      hintText: '0-$_maxPoints',
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savingScores ? null : _saveAllScores,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _savingScores ? 'Saving…' : 'Save All Scores',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _labelStyle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
      ),
    );
  }
}
