import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/submission_detail_screen.dart';

/// Grades Management (Template)
/// 3-layer layout mirroring Assignment Management, with placeholders.
class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassroomService _classroomService = ClassroomService();
  List<Classroom> _classrooms = [];
  Map<String, int> _enrollmentCounts = {};
  Classroom? _selectedClassroom;
  bool _isLoadingClassrooms = true;
  String? _teacherId;

  // Course/quarter selection for computation
  List<Course> _courses = [];
  Course? _selectedCourse;
  int? _selectedQuarter; // 1-4

  Map<String, dynamic>? _selectedStudent; // {id, full_name, email}
  bool _loadingStudentData = false;
  List<Map<String, dynamic>> _studentGraded = [];
  List<Map<String, dynamic>> _studentPending = [];
  List<Map<String, dynamic>> _studentScores = [];
  // Compute tab editable state (mock, in-memory)
  final Map<String, double> _scoreOverrides = {};
  double _plusPoints = 0.0;
  double _extraPoints = 0.0;
  // Quarterly Exam is manual (no QA assignments). Teachers input raw score and max.
  double _qaScore = 0.0;
  double _qaMax = 0.0;

  // Optional remarks when saving computed grade
  final TextEditingController _remarksCtrl = TextEditingController();

  // DepEd computation
  final DepEdGradeService _depEd = DepEdGradeService();
  Map<String, dynamic>? _computed;
  bool _computing = false;
  Map<String, dynamic>? _savedGrade;
  RealtimeChannel? _gradeRtChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeTeacher();
  }

  @override
  void dispose() {
    _teardownRealtime();
    _tabController.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeTeacher() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() => _teacherId = user.id);
        await _loadClassrooms();
      } else {
        setState(() => _isLoadingClassrooms = false);
      }
    } catch (e) {
      setState(() => _isLoadingClassrooms = false);
    }
  }

  Future<void> _loadClassrooms() async {
    if (_teacherId == null) return;
    setState(() => _isLoadingClassrooms = true);
    try {
      final classrooms = await _classroomService.getTeacherClassrooms(
        _teacherId!,
      );
      final ids = classrooms.map((c) => c.id).toList();
      final counts = await _classroomService.getEnrollmentCountsForClassrooms(
        ids,
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
        _isLoadingClassrooms = false;
      });
    } catch (e) {
      setState(() {
        _classrooms = [];
        _isLoadingClassrooms = false;
      });
    }
  }

  Future<void> _showViewStudentsPopup() async {
    if (_selectedClassroom == null) return;
    try {
      final students = await _classroomService.getClassroomStudents(
        _selectedClassroom!.id,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${_selectedClassroom!.title}')),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${students.length} students',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              height: 420,
              child: students.isEmpty
                  ? Center(
                      child: Text(
                        'No students enrolled',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final name = (s['full_name'] ?? 'Student').toString();
                        final email = (s['email'] ?? '').toString();
                        final initials = name.isNotEmpty
                            ? name
                                  .split(' ')
                                  .map((p) => p.isNotEmpty ? p[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                            : 'S';
                        return ListTile(
                          leading: CircleAvatar(child: Text(initials)),
                          title: Text(name, overflow: TextOverflow.ellipsis),
                          subtitle: email.isNotEmpty
                              ? Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedStudent = {
                                  'id':
                                      (s['student_id'] ??
                                              s['user_id'] ??
                                              s['id'])
                                          .toString(),
                                  'full_name': name,
                                  'email': email,
                                };
                              });
                              _setupRealtime();
                              await _loadStudentOverview();
                            },
                            child: const Text('Select'),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedStudent = {
                                'id':
                                    (s['student_id'] ?? s['user_id'] ?? s['id'])
                                        .toString(),
                                'full_name': name,
                                'email': email,
                              };
                            });
                            _setupRealtime();
                            await _loadStudentOverview();
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadStudentOverview() async {
    final classroom = _selectedClassroom;
    final student = _selectedStudent;
    final course = _selectedCourse;
    if (classroom == null || student == null || course == null) return;
    setState(() {
      _loadingStudentData = true;
      _studentGraded = [];
      _studentPending = [];
      _studentScores = [];
    });
    // Require a quarter selection to show history and pending lists
    if (_selectedQuarter == null) {
      setState(() {
        _loadingStudentData = false;
      });
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      final subs = await supabase
          .from('assignment_submissions')
          .select(
            'assignment_id, status, score, max_score, submitted_at, graded_at',
          )
          .eq('classroom_id', classroom.id)
          .eq('student_id', student['id'].toString());

      final list = List<Map<String, dynamic>>.from(subs as List? ?? const []);
      if (list.isEmpty) {
        setState(() {
          _loadingStudentData = false;
        });
        return;
      }

      final ids = list
          .map((e) => (e['assignment_id']).toString())
          .toSet()
          .toList();
      final assignQuery = supabase
          .from('assignments')
          .select(
            'id, title, assignment_type, total_points, quarter_no, course_id',
          )
          .inFilter('id', ids)
          .eq('course_id', course.id);
      final assigns = await (_selectedQuarter != null
          ? assignQuery.eq('quarter_no', _selectedQuarter!)
          : assignQuery);
      final aMap = {for (final a in (assigns as List)) (a['id'].toString()): a};
      // Filter submissions to the selected quarter by keeping only assignments that matched
      final validIds = aMap.keys.toSet();
      final filteredSubs = list
          .where((s) => validIds.contains((s['assignment_id']).toString()))
          .toList();

      final combined = filteredSubs.map((s) {
        final a = aMap[(s['assignment_id']).toString()];
        return {
          'assignment_id': s['assignment_id'],
          'title': a?['title'] ?? 'Untitled',
          'type': a?['assignment_type'] ?? 'unknown',
          'total_points': a?['total_points'] ?? s['max_score'] ?? 0,
          'status': s['status'],
          'score': s['score'],
          'max_score': s['max_score'] ?? a?['total_points'],
          'submitted_at': s['submitted_at'],
          'graded_at': s['graded_at'],
        };
      }).toList();

      // Reclassify: completed vs to grade (use graded_at/status; keep objective auto-case)
      final graded = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];
      for (final e in combined) {
        final status = (e['status'] ?? '').toString().toLowerCase();
        final type = (e['type'] ?? '').toString();
        final gradedAt = e['graded_at'];
        final hasScore = (e['score'] as num?) != null;
        final isObjective =
            type == 'quiz' ||
            type == 'multiple_choice' ||
            type == 'identification' ||
            type == 'matching_type';

        if (gradedAt != null || status == 'graded') {
          graded.add(e);
        } else if (status == 'submitted' || status == 'late') {
          if (isObjective && hasScore) {
            // Auto-scored objective type with score → treat as completed
            graded.add(e);
          } else {
            // Essay/File upload or no score yet → requires teacher grading
            pending.add(e);
          }
        }
      }

      setState(() {
        _studentGraded = graded
          ..sort(
            (a, b) => (a['submitted_at'] ?? '').toString().compareTo(
              (b['submitted_at'] ?? '').toString(),
            ),
          );
        _studentPending = pending
          ..sort(
            (a, b) => (a['submitted_at'] ?? '').toString().compareTo(
              (b['submitted_at'] ?? '').toString(),
            ),
          );
        _studentScores = graded;
        _loadingStudentData = false;
      });
    } catch (e) {
      setState(() {
        _loadingStudentData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading student overview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _teardownRealtime() {
    _gradeRtChannel?.unsubscribe();
    _gradeRtChannel = null;
  }

  void _setupRealtime() {
    // Subscribe to submission changes for the selected student in this classroom.
    // Quarter is respected by reloading and filtering inside _loadStudentOverview().
    final classroom = _selectedClassroom;
    final student = _selectedStudent;
    if (classroom == null || student == null) return;

    final supa = Supabase.instance.client;
    _teardownRealtime();
    _gradeRtChannel = supa
        .channel('grade-entry:${classroom.id}:${student['id']}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignment_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: student['id'].toString(),
          ),
          callback: (payload) {
            final map = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final row = Map<String, dynamic>.from(map);
            // Only refresh for events in the currently selected classroom
            if ((row['classroom_id'] ?? '').toString() ==
                classroom.id.toString()) {
              if (mounted) {
                _loadStudentOverview();
              }
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildLeftSidebar(context),
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext ctx) {
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
                  tooltip: 'Back',
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
                    'GRADES',
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

          // Classroom Count (placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _isLoadingClassrooms
                  ? 'Loading...'
                  : 'you have ${_classrooms.length} classroom${_classrooms.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(height: 1),

          // Classroom list
          Expanded(
            child: _isLoadingClassrooms
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'classrooms will appear here',
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
                      final count =
                          _enrollmentCounts[classroom.id] ??
                          classroom.currentStudents;
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Grade ${classroom.gradeLevel} • $count/${classroom.maxStudents} students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onTap: () => _selectClassroom(classroom),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom action bar: view students (appears when a classroom is selected)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              color: Colors.white,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedClassroom == null
                    ? null
                    : _showViewStudentsPopup,
                icon: const Icon(Icons.people_alt),
                label: const Text('view students'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectClassroom(Classroom classroom) async {
    _teardownRealtime();

    setState(() {
      _selectedClassroom = classroom;
      _selectedStudent = null;
      _studentGraded.clear();
      _studentPending.clear();
      _studentScores.clear();
      _courses = [];
      _selectedCourse = null;
      _selectedQuarter = null;
      _computed = null;
      _plusPoints = 0.0;
      _extraPoints = 0.0;
      _qaScore = 0.0;
      _savedGrade = null;

      _qaMax = 0.0;
      _remarksCtrl.clear();
    });
    await _loadCoursesForClassroom();
  }

  Future<void> _loadCoursesForClassroom() async {
    final c = _selectedClassroom;
    if (c == null) return;
    try {
      final all = await _classroomService.getClassroomCourses(c.id);
      final uid = _teacherId;
      final owned = uid == null
          ? all
          : all.where((co) => co.teacherId == uid).toList();
      setState(() {
        _courses = owned;
        _selectedCourse = owned.isNotEmpty ? owned.first : null;
      });
    } catch (_) {}
  }

  Future<void> _computeDepEd() async {
    if (_selectedClassroom == null ||
        _selectedStudent == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a course, quarter and student first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() {
      _computing = true;
      _computed = null;
    });
    try {
      final result = await _depEd.computeQuarterlyBreakdown(
        classroomId: _selectedClassroom!.id,
        courseId: _selectedCourse!.id,
        studentId: _selectedStudent!['id'].toString(),
        quarter: _selectedQuarter!,
        courseTitle: _selectedCourse!.title,
        qaScoreOverride: _qaScore,
        qaMaxOverride: _qaMax,
        plusPoints: _plusPoints,
        extraPoints: _extraPoints,
      );
      if (mounted) {
        setState(() {
          _computed = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compute failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _computing = false;
        });
      }
    }
  }

  Future<void> _saveComputedGrade() async {
    if (_selectedClassroom == null ||
        _selectedStudent == null ||
        _selectedCourse == null ||
        _selectedQuarter == null ||
        _computed == null)
      return;
    try {
      await _depEd.saveOrUpdateStudentQuarterGrade(
        studentId: _selectedStudent!['id'].toString(),
        classroomId: _selectedClassroom!.id,
        courseId: _selectedCourse!.id,
        quarter: _selectedQuarter!,
        initialGrade: (_computed!['initial_grade'] as num).toDouble(),
        transmutedGrade: (_computed!['transmuted_grade'] as num).toDouble(),
        plusPoints: _plusPoints,
        extraPoints: _extraPoints,
        remarks: _remarksCtrl.text.trim().isEmpty
            ? null
            : _remarksCtrl.text.trim(),
      );
      await _loadExistingQuarterGrade();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadExistingQuarterGrade() async {
    if (_selectedClassroom == null ||
        _selectedStudent == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
      return;
    }
    try {
      final supa = Supabase.instance.client;
      final row = await supa
          .from('student_grades')
          .select()
          .eq('student_id', _selectedStudent!['id'].toString())
          .eq('classroom_id', _selectedClassroom!.id)
          .eq('course_id', _selectedCourse!.id)
          .eq('quarter', _selectedQuarter!)
          .maybeSingle();
      if (!mounted) return;
      if (row != null) {
        setState(() {
          _savedGrade = row;
          _plusPoints = ((row['plus_points'] as num?)?.toDouble() ?? 0.0);
          _extraPoints = ((row['extra_points'] as num?)?.toDouble() ?? 0.0);
          _remarksCtrl.text = (row['remarks'] as String?) ?? '';
        });
      } else {
        setState(() {
          _savedGrade = null;
          _plusPoints = 0.0;
          _extraPoints = 0.0;
          _remarksCtrl.text = '';
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
                    const Text(
                      'grading workspace',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_selectedStudent == null)
                      Text(
                        'Select a classroom • View students • Choose a student',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      )
                    else
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (_selectedStudent?['full_name'] ?? 'Student')
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Course selector
                          if (_courses.isNotEmpty)
                            DropdownButton<Course>(
                              value: _selectedCourse,
                              hint: const Text('Select course'),
                              items: _courses
                                  .map(
                                    (c) => DropdownMenuItem<Course>(
                                      value: c,
                                      child: Text(
                                        c.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedCourse = v;
                                  _computed = null;
                                });
                                _loadExistingQuarterGrade();
                              },
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
                                onSelected: (_) async {
                                  setState(() {
                                    _selectedQuarter = q;
                                    _computed = null;
                                  });
                                  // Refresh saved grade (compute tab) and re-query lists for the selected quarter
                                  await _loadExistingQuarterGrade();
                                  await _loadStudentOverview();
                                },
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: _computing ? null : _computeDepEd,
                            icon: const Icon(Icons.calculate, size: 16),
                            label: Text(
                              _computing ? 'computing...' : 'Compute Grades',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              _teardownRealtime();
                              setState(() {
                                _selectedStudent = null;
                                _studentGraded.clear();
                                _studentPending.clear();
                                _studentScores.clear();
                              });
                            },
                            child: const Text('clear'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Final grades • Coming soon'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.summarize, size: 18),
                label: const Text('final grades'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
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
              Tab(text: 'completed'),
              Tab(text: 'to grade'),
              Tab(text: 'compute scores'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentHistoryTab(),
              _buildStudentPendingTab(),
              _buildStudentComputeTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallEmpty(String text, {IconData icon = Icons.info_outline}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildStudentHistoryTab() {
    if (_selectedStudent == null) {
      return _smallEmpty(
        'Select a student to view history',
        icon: Icons.person,
      );
    }
    if (_selectedQuarter == null) {
      return _smallEmpty(
        'Select a quarter to view assignments',
        icon: Icons.filter_list,
      );
    }
    if (_loadingStudentData) {
      return const Center(child: LinearProgressIndicator());
    }
    if (_studentGraded.isEmpty) {
      return _smallEmpty(
        'No assignments for Quarter ${_selectedQuarter}',
        icon: Icons.history,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _studentGraded.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _studentGraded[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.check_circle, color: Colors.green.shade600),
          title: Text(
            item['title'] ?? 'Untitled',
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${(item['type'] ?? '').toString().replaceAll('_', ' ')} • submitted ${(item['submitted_at'] ?? '').toString().replaceFirst('T', ' ').split('.').first}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          onTap: () async {
            final assignmentId = (item['assignment_id']).toString();
            final studentId = _selectedStudent!['id'].toString();
            final name = _selectedStudent!['full_name']?.toString();
            final email = _selectedStudent!['email']?.toString();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SubmissionDetailScreen(
                  assignmentId: assignmentId,
                  studentId: studentId,
                  studentName: name,
                  studentEmail: email,
                ),
              ),
            );
            if (_selectedStudent != null && _selectedQuarter != null) {
              await _loadStudentOverview();
            }
          },
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '${item['score'] ?? 0}/${item['max_score'] ?? item['total_points'] ?? 0}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentPendingTab() {
    if (_selectedStudent == null) {
      return _smallEmpty(
        'Select a student to view submissions',
        icon: Icons.person,
      );
    }
    if (_selectedQuarter == null) {
      return _smallEmpty(
        'Select a quarter to view assignments',
        icon: Icons.filter_list,
      );
    }
    if (_loadingStudentData) {
      return const Center(child: LinearProgressIndicator());
    }
    if (_studentPending.isEmpty) {
      return _smallEmpty(
        'No assignments for Quarter ${_selectedQuarter}',
        icon: Icons.inbox,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _studentPending.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _studentPending[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.pending_actions, color: Colors.orange.shade700),
          title: Text(
            item['title'] ?? 'Untitled',
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${(item['type'] ?? '').toString().replaceAll('_', ' ')} • submitted ${(item['submitted_at'] ?? '').toString().replaceFirst('T', ' ').split('.').first}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          onTap: () async {
            final assignmentId = (item['assignment_id']).toString();
            final studentId = _selectedStudent!['id'].toString();
            final name = _selectedStudent!['full_name']?.toString();
            final email = _selectedStudent!['email']?.toString();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SubmissionDetailScreen(
                  assignmentId: assignmentId,
                  studentId: studentId,
                  studentName: name,
                  studentEmail: email,
                ),
              ),
            );
            if (_selectedStudent != null && _selectedQuarter != null) {
              await _loadStudentOverview();
            }
          },
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'not graded',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        );
      },
    );
  }

  String _k(String section, int idx) => '$section#$idx';
  double _ov(String section, int idx, double original) =>
      _scoreOverrides[_k(section, idx)] ?? original;

  Future<void> _editScore(String section, int idx, double current) async {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit score'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Score',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _scoreOverrides[_k(section, idx)] = result;
      });
    }
  }

  Widget _buildStudentComputeTab() {
    if (_selectedStudent == null)
      return _smallEmpty(
        'Select a student to compute grades',
        icon: Icons.person,
      );
    if (_loadingStudentData)
      return const Center(child: LinearProgressIndicator());
    if (_studentScores.isEmpty)
      return _smallEmpty('No graded scores to compute', icon: Icons.calculate);

    // DepEd-style weights (auto; from compute service when available)
    double wwWeight = 0.40; // Written Works
    double ptWeight = 0.40; // Performance Tasks
    double qaWeight = 0.20; // Quarterly Assessment
    if (_computed != null) {
      final w = Map<String, dynamic>.from(_computed!['weights'] as Map);
      wwWeight = ((w['ww'] as num?)?.toDouble() ?? wwWeight);
      ptWeight = ((w['pt'] as num?)?.toDouble() ?? ptWeight);
      qaWeight = ((w['qa'] as num?)?.toDouble() ?? qaWeight);
    }

    // Partition items by type (no QA assignments; QA will be manual input)
    bool isWW(String t) =>
        t == 'quiz' ||
        t == 'multiple_choice' ||
        t == 'identification' ||
        t == 'matching_type';
    bool isPT(String t) => t == 'essay' || t == 'file_upload';

    final ww = <Map<String, dynamic>>[];
    final pt = <Map<String, dynamic>>[];

    for (final e in _studentScores) {
      final t = (e['type'] ?? '').toString();
      if (isWW(t))
        ww.add(e);
      else if (isPT(t))
        pt.add(e);
    }

    double sumScore(List<Map<String, dynamic>> xs) =>
        xs.fold(0.0, (a, e) => a + ((e['score'] as num?)?.toDouble() ?? 0.0));
    double sumMax(List<Map<String, dynamic>> xs) => xs.fold(
      0.0,
      (a, e) =>
          a +
          ((e['max_score'] as num?)?.toDouble() ??
              ((e['total_points'] as num?)?.toDouble() ?? 0.0)),
    );

    double wwScore = sumScore(ww);
    double wwMax = sumMax(ww);
    double wwPS = wwMax > 0 ? (wwScore / wwMax) * 100.0 : 0.0;
    double wwWS = wwPS * wwWeight; // e.g., 85 * 0.40 = 34.0

    double ptScore = sumScore(pt);
    double ptMax = sumMax(pt);
    double ptPS = ptMax > 0 ? (ptScore / ptMax) * 100.0 : 0.0;
    double ptWS = ptPS * ptWeight;

    double qaScore = _qaScore;
    double qaMax = _qaMax;
    double qaPS = qaMax > 0 ? (qaScore / qaMax) * 100.0 : 0.0;
    double qaWS = qaPS * qaWeight;
    final qaItems = <Map<String, dynamic>>[]; // manual QA has no items

    // If computed via service, prefer its canonical numbers to ensure consistency
    if (_computed != null) {
      wwScore = ((_computed!['ww_score'] as num?)?.toDouble() ?? wwScore);
      wwMax = ((_computed!['ww_max'] as num?)?.toDouble() ?? wwMax);
      wwPS = ((_computed!['ww_ps'] as num?)?.toDouble() ?? wwPS);
      wwWS = ((_computed!['ww_ws'] as num?)?.toDouble() ?? wwWS);

      ptScore = ((_computed!['pt_score'] as num?)?.toDouble() ?? ptScore);
      ptMax = ((_computed!['pt_max'] as num?)?.toDouble() ?? ptMax);
      ptPS = ((_computed!['pt_ps'] as num?)?.toDouble() ?? ptPS);
      ptWS = ((_computed!['pt_ws'] as num?)?.toDouble() ?? ptWS);

      qaScore = ((_computed!['qa_score'] as num?)?.toDouble() ?? qaScore);
      qaMax = ((_computed!['qa_max'] as num?)?.toDouble() ?? qaMax);
      qaPS = ((_computed!['qa_ps'] as num?)?.toDouble() ?? qaPS);
      qaWS = ((_computed!['qa_ws'] as num?)?.toDouble() ?? qaWS);
    }

    double initialGrade = (wwWS + ptWS + qaWS); // already on 0-100 scale
    initialGrade = (initialGrade + _plusPoints + _extraPoints).clamp(
      0.0,
      100.0,
    );

    // Build an Excel-like compact grid but visually pleasant
    Widget cell(
      String text, {
      bool bold = false,
      Color? bg,
      double w = 96,
      Alignment align = Alignment.center,
    }) => Container(
      alignment: align,
      width: w,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: Colors.grey.shade900,
        ),
      ),
    );

    List<Widget> buildSection(
      String title,
      double weightPct,
      List<Map<String, dynamic>> items,
      double score,
      double max,
      double ps,
      double ws,
      String sectionKey,
    ) {
      // Show up to 6 items for the mock
      final show = items.take(6).toList();
      final header = [
        cell(
          title,
          bold: true,
          bg: Colors.grey.shade100,
          w: 220,
          align: Alignment.centerLeft,
        ),
        ...List.generate(
          show.length,
          (i) => cell('${i + 1}', bold: true, bg: Colors.grey.shade100),
        ),
        cell('total', bold: true, bg: Colors.grey.shade100),
        cell('p.s', bold: true, bg: Colors.grey.shade100),
        cell(
          'w.s (${(weightPct * 100).toStringAsFixed(0)}%)',
          bold: true,
          bg: Colors.grey.shade100,
          w: 110,
        ),
      ];
      // Editable score row
      final scoreRowCells = <Widget>[];
      scoreRowCells.add(
        cell('score', bold: true, w: 220, align: Alignment.centerLeft),
      );
      for (var i = 0; i < show.length; i++) {
        final original = ((show[i]['score'] as num?)?.toDouble() ?? 0.0);
        final value = _ov(sectionKey, i, original);
        scoreRowCells.add(
          InkWell(
            onTap: () => _editScore(sectionKey, i, value),
            child: cell(value.toStringAsFixed(0)),
          ),
        );
      }
      scoreRowCells.add(cell(max > 0 ? score.toStringAsFixed(0) : '-'));
      scoreRowCells.add(cell(ps.toStringAsFixed(2)));
      scoreRowCells.add(cell(ws.toStringAsFixed(2), w: 110));

      final rowMax = [
        cell('total score', bold: true, w: 220, align: Alignment.centerLeft),
        ...show.map(
          (e) => cell(
            ((e['max_score'] as num?)?.toStringAsFixed(0) ??
                ((e['total_points'] as num?)?.toStringAsFixed(0) ?? '0')),
          ),
        ),
        cell(max.toStringAsFixed(0)),
        cell('100'),
        cell((weightPct * 100).toStringAsFixed(0), w: 110),
      ];
      return [
        Row(children: header),
        Row(children: scoreRowCells),
        Row(children: rowMax),
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Table Card
          Expanded(
            flex: 3,
            child: Center(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...buildSection(
                          'written works',
                          wwWeight,
                          ww,
                          wwScore,
                          wwMax,
                          wwPS,
                          wwWS,
                          'ww',
                        ),
                        const SizedBox(height: 12),
                        ...buildSection(
                          'performance task',
                          ptWeight,
                          pt,
                          ptScore,
                          ptMax,
                          ptPS,
                          ptWS,
                          'pt',
                        ),
                        const SizedBox(height: 12),
                        ...buildSection(
                          'quarterly exam',
                          qaWeight,
                          qaItems,
                          qaScore,
                          qaMax,
                          qaPS,
                          qaWS,
                          'qa',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            cell(
                              'Initial Grade',
                              bold: true,
                              bg: Colors.blue.shade50,
                              w: 220,
                              align: Alignment.centerLeft,
                            ),
                            cell(
                              initialGrade.toStringAsFixed(2),
                              bold: true,
                              bg: Colors.blue.shade50,
                              w: 110,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            cell(
                              'Final Grade (transmuted)',
                              bold: true,
                              bg: Colors.green.shade50,
                              w: 220,
                              align: Alignment.centerLeft,
                            ),
                            cell(
                              _computed != null
                                  ? ((_computed!['transmuted_grade'] as num)
                                            .toDouble())
                                        .toStringAsFixed(0)
                                  : '—',
                              bold: true,
                              bg: Colors.green.shade50,
                              w: 110,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: Adjustments panel
          SizedBox(
            width: 300,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Adjustments',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Plus Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g., 2',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        setState(() {
                          _plusPoints = double.tryParse(v) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Extra-Curricular',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g., 1.5',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        setState(() {
                          _extraPoints = double.tryParse(v) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quarterly Exam (manual)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Score',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _qaScore = double.tryParse(v) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _qaMax = double.tryParse(v) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Initial: ${((wwWS + ptWS + qaWS)).toStringAsFixed(2)}',
                          ),
                          Text(
                            'Plus: ${_plusPoints.toStringAsFixed(2)}  •  Extra: ${_extraPoints.toStringAsFixed(2)}',
                          ),
                          Text('Adjusted: ${initialGrade.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _remarksCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Optional notes (visible to co-teachers)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_savedGrade != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Saved: ${((_savedGrade!['transmuted_grade'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_computed == null || _computing)
                            ? null
                            : _saveComputedGrade,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save grade'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
}
