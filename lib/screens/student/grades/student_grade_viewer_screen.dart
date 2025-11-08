import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/screens/student/grades/student_report_card_screen.dart';

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
      if (mounted) setState(() => _quarterGrades = map);
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
    });
    await _loadQuarterGrades();
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
      body: Row(
        children: [
          SizedBox(width: 260, child: _buildClassrooms()),
          Container(width: 1, color: Colors.grey.shade200),
          SizedBox(width: 240, child: _buildCourses()),
          Container(width: 1, color: Colors.grey.shade200),
          Expanded(child: _buildQuarterPanel()),
        ],
      ),
    );
  }

  Widget _buildClassrooms() {
    if (_loadingClassrooms) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_classrooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No classrooms'),
        ),
      );
    }
    return ListView.builder(
      itemCount: _classrooms.length,
      itemBuilder: (ctx, i) {
        final c = _classrooms[i];
        final selected = _selectedClassroom?.id == c.id;
        final tname = _teacherNames[c.teacherId] ?? '';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: ListTile(
            title: Text(
              c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              tname.isEmpty ? 'Teacher: —' : 'Teacher: $tname',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () => _onSelectClassroom(c),
          ),
        );
      },
    );
  }

  Widget _buildCourses() {
    if (_selectedClassroom == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Select a classroom'),
        ),
      );
    }
    if (_loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No courses'),
        ),
      );
    }
    return ListView.builder(
      itemCount: _courses.length,
      itemBuilder: (ctx, i) {
        final course = _courses[i];
        final selected = _selectedCourse?.id == course.id;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            onTap: () => _onSelectCourse(course),
          ),
        );
      },
    );
  }

  Widget _buildQuarterPanel() {
    if (_selectedCourse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Select a course to view grades'),
        ),
      );
    }
    if (_loadingGrades) return const Center(child: LinearProgressIndicator());
    final tiles = <Widget>[];
    for (var q = 1; q <= 4; q++) {
      tiles.add(_quarterCard(q, _quarterGrades[q]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: tiles),
    );
  }

  Widget _quarterCard(int quarter, Map<String, dynamic>? row) {
    final title = 'Quarter $quarter';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: row == null
            ? Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '$title • Not yet graded',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _kv('Final Grade', _fmtNum(row['transmuted_grade'])),
                  _kv('Initial Grade', _fmtNum(row['initial_grade'])),
                  if ((row['plus_points'] ?? 0) != 0)
                    _kv('Plus Points', _fmtNum(row['plus_points'])),
                  if ((row['extra_points'] ?? 0) != 0)
                    _kv('Extra Points', _fmtNum(row['extra_points'])),
                  if ((row['remarks'] ?? '').toString().isNotEmpty)
                    _kv('Remarks', row['remarks']),
                  _kv(
                    'Computed',
                    _fmtDate(
                      row['computed_at'] ??
                          row['updated_at'] ??
                          row['created_at'],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  String _fmtNum(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0.0;
    return d.toStringAsFixed(0);
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
