import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/create_assignment_screen_new.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';

/// Teacher Assignments Management Screen
/// 3-panel layout: Classrooms | Assignments | Assignment Details
class MyAssignmentsScreen extends StatefulWidget {
  const MyAssignmentsScreen({super.key});

  @override
  State<MyAssignmentsScreen> createState() => _MyAssignmentsScreenState();
}

class _MyAssignmentsScreenState extends State<MyAssignmentsScreen> {
  final _classroomService = ClassroomService();
  final _assignmentService = AssignmentService();
  final _supabase = Supabase.instance.client;

  List<Classroom> _classrooms = [];
  List<Map<String, dynamic>> _assignments = [];
  // Live enrollment counts fetched from classroom_students to avoid stale current_students
  Map<String, int> _enrollmentCounts = {};
  // Selection set for distribution of assignments to classrooms
  final Set<String> _selectedForDistribution = {};

  bool _isLoadingClassrooms = true;
  bool _isLoadingAssignments = false;
  String? _selectedClassroomId;
  String? _selectedAssignmentId;

  RealtimeChannel? _poolChannel;

  @override
  void initState() {
    super.initState();
    _setupPoolRealtime();

    _loadClassrooms();
  }

  void _setupPoolRealtime() {
    _poolChannel?.unsubscribe();
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _poolChannel = _supabase
        .channel('teacher-assignment-pool:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: uid,
          ),
          callback: (payload) {
            if (!mounted) return;
            _loadAssignments(_selectedClassroomId ?? '');
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _poolChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoadingClassrooms = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final classrooms = await _classroomService.getTeacherClassrooms(userId);

      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;

        // Auto-select first classroom if available
        if (_classrooms.isNotEmpty && _selectedClassroomId == null) {
          _selectedClassroomId = _classrooms.first.id;
          _loadAssignments(_classrooms.first.id);
        }
      });
      // Fetch live enrollment counts for accuracy
      final classroomIds = classrooms.map((c) => c.id).toList();
      _loadEnrollmentCounts(classroomIds);
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _isLoadingClassrooms = false;
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

  Future<void> _loadAssignments(String classroomId) async {
    // Note: classroomId is ignored here by design. The Assignment Management screen
    // shows the teacher's unpublished (draft) assignments pool across classrooms.
    setState(() {
      _isLoadingAssignments = true;
      _selectedAssignmentId = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final response = await _supabase
          .from('assignments')
          .select()
          .eq('teacher_id', userId)
          .eq('is_published', false)
          .order('created_at', ascending: false);
      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        response as List,
      );

      setState(() {
        _assignments = list;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      print('❌ Error loading assignments: $e');
      setState(() {
        _isLoadingAssignments = false;
      });
    }
  }

  Future<void> _loadEnrollmentCounts(List<String> classroomIds) async {
    if (classroomIds.isEmpty) return;
    try {
      final counts = await _classroomService.getEnrollmentCountsForClassrooms(
        classroomIds,
      );
      if (!mounted) return;
      setState(() {
        _enrollmentCounts = counts;
      });
    } catch (e) {
      print('❌ Error loading enrollment counts: $e');
    }
  }

  Classroom? get _selectedClassroom {
    if (_selectedClassroomId == null) return null;
    try {
      return _classrooms.firstWhere((c) => c.id == _selectedClassroomId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? get _selectedAssignment {
    if (_selectedAssignmentId == null) return null;
    try {
      return _assignments.firstWhere(
        (a) => a['id'].toString() == _selectedAssignmentId,
      );
    } catch (e) {
      return null;
    }
  }

  // Helpers: parse and format due date from backend
  DateTime? _parseDueDate(dynamic raw) {
    try {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      final s = raw.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDueDate(DateTime? dt) {
    if (dt == null) return '';
    // Format as MMM d, yyyy h:mm a
    final two = (int n) => n.toString().padLeft(2, '0');
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = monthNames[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    int h = dt.hour;
    final am = h < 12;
    h = h % 12;
    if (h == 0) h = 12;
    final min = two(dt.minute);
    final ampm = am ? 'AM' : 'PM';
    return '$m $day, $year $h:$min $ampm';
  }

  bool _isOwnedAssignment(Map<String, dynamic> a) {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final owner = (a['teacher_id'] ?? a['created_by'] ?? a['owner_id'])
        ?.toString();
    return owner != null && owner == uid;
  }

  // Read-only preview builder for selected assignment (type-aware)
  Widget _buildAssignmentPreview() {
    final a = _selectedAssignment!;
    final type = (a['assignment_type'] ?? '').toString();
    final totalPoints = (a['total_points'] ?? a['points'] ?? 0).toString();
    final allowLate = (a['allow_late_submissions'] ?? true) == true;
    final dueStr = _formatDueDate(_parseDueDate(a['due_date']));
    final comp = (a['component'] ?? (a['content']?['meta']?['component'] ?? ''))
        .toString();
    final quarter =
        (a['quarter_no'] ?? (a['content']?['meta']?['quarter_no'] ?? ''))
            .toString();

    Map<String, dynamic> content = {};
    try {
      final raw = a['content'];
      if (raw is Map) {
        content = Map<String, dynamic>.from(raw as Map);
      }
    } catch (_) {}

    Widget _chip(String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    Widget _kv(String k, String v) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      );
    }

    List<Map<String, dynamic>> _listMap(List? l) {
      if (l == null) return const [];
      return l.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    Widget body;
    switch (type) {
      case 'multiple_choice':
        final qs = _listMap(content['questions'] as List?);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (qs.isEmpty)
              Text(
                'No questions',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...qs.asMap().entries.map((e) {
                final i = e.key;
                final q = e.value;
                final choices = List<String>.from(
                  (q['choices'] as List? ?? const []).map((x) => x.toString()),
                );
                final correctIndex = q['correctIndex'];
                return _qCard([
                  Row(
                    children: [
                      _chip('Q${i + 1}', Colors.blue),
                      const SizedBox(width: 8),
                      _chip('${q['points'] ?? 1} pts', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question']?.toString() ?? 'Question ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...choices.asMap().entries.map((c) {
                    final idx = c.key;
                    final text = c.value;
                    final isCorrect =
                        (correctIndex is int) && (idx == correctIndex);
                    return Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: isCorrect ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(text)),
                      ],
                    );
                  }).toList(),
                ]);
              }),
          ],
        );
        break;
      case 'quiz':
      case 'identification':
        final qs = _listMap(content['questions'] as List?);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (qs.isEmpty)
              Text(
                'No questions',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...qs.asMap().entries.map((e) {
                final i = e.key;
                final q = e.value;
                return _qCard([
                  Row(
                    children: [
                      _chip('Q${i + 1}', Colors.blue),
                      const SizedBox(width: 8),
                      _chip('${q['points'] ?? 1} pts', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question']?.toString() ?? 'Question ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if ((q['answer'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _kv('Answer', (q['answer'] ?? '').toString()),
                  ],
                ]);
              }),
          ],
        );
        break;
      case 'matching_type':
        final pairs = _listMap(content['pairs'] as List?);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pairs.isEmpty)
              Text('No pairs', style: TextStyle(color: Colors.grey.shade600))
            else
              ...pairs.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                return _qCard([
                  Row(
                    children: [
                      _chip('Pair ${i + 1}', Colors.purple),
                      const SizedBox(width: 8),
                      _chip('${p['points'] ?? 1} pts', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _kv('Column A', (p['columnA'] ?? '').toString()),
                  _kv('Column B', (p['columnB'] ?? '').toString()),
                ]);
              }),
          ],
        );
        break;
      case 'essay':
        final qs = _listMap(content['questions'] as List?);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (qs.isEmpty)
              Text(
                'No questions',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...qs.asMap().entries.map((e) {
                final i = e.key;
                final q = e.value;
                return _qCard([
                  Row(
                    children: [
                      _chip('Essay ${i + 1}', Colors.teal),
                      const SizedBox(width: 8),
                      _chip('${q['points'] ?? 10} pts', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question']?.toString() ?? 'Essay ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if ((q['guidelines'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _kv('Guidelines', (q['guidelines'] ?? '').toString()),
                  ],
                ]);
              }),
          ],
        );
        break;
      case 'file_upload':
        final instr = (content['instructions'] ?? '').toString();
        final maxSize = (content['max_file_size'] ?? '').toString();
        final maxFiles = (content['max_files'] ?? '').toString();
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Instructions', instr),
            const SizedBox(height: 4),
            _kv('Max file size (MB)', maxSize),
            _kv('Max number of files', maxFiles),
          ],
        );
        break;
      default:
        body = Text(
          'No preview available for this assignment type or content is missing.',
          style: TextStyle(color: Colors.grey.shade600),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(
                type.isEmpty ? 'unknown' : type.replaceAll('_', ' '),
                Colors.indigo,
              ),
              const SizedBox(width: 8),
              _chip('$totalPoints pts', Colors.amber),
              if (dueStr.isNotEmpty) ...[
                const SizedBox(width: 8),
                _chip(dueStr, Colors.deepPurple),
              ],
              const SizedBox(width: 8),
              _chip(
                allowLate ? 'late allowed' : 'late not allowed',
                allowLate ? Colors.green : Colors.red,
              ),
              if (comp.isNotEmpty) ...[
                const SizedBox(width: 8),
                _chip(comp.replaceAll('_', ' '), Colors.brown),
              ],
              if (quarter.isNotEmpty) ...[
                const SizedBox(width: 8),
                _chip('Q$quarter', Colors.blueGrey),
              ],
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _qCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherDashboardScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // Left Panel - Classrooms
            _buildClassroomPanel(),

            // Middle Panel - Assignments
            _buildAssignmentsPanel(),

            // Right Panel - Assignment Details
            Expanded(child: _buildAssignmentDetailsPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomPanel() {
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
                    'ASSIGNMENT MANAGEMENT',
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
              'you have ${_classrooms.length} classroom${_classrooms.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),

          const Divider(height: 1),

          // Classrooms List
          Expanded(
            child: _isLoadingClassrooms
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No classrooms yet',
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
                      final isSelected = _selectedClassroomId == classroom.id;
                      final bool isOwned =
                          _supabase.auth.currentUser?.id != null &&
                          classroom.teacherId == _supabase.auth.currentUser!.id;

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
                            'Grade ${classroom.gradeLevel} • ${_enrollmentCounts[classroom.id] ?? classroom.currentStudents}/${classroom.maxStudents} students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedClassroomId = classroom.id;
                              _selectedAssignmentId = null;
                              _selectedForDistribution.clear();
                            });
                            _loadAssignments(classroom.id);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Create Assignment Button
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
                onPressed: _showCreateAssignmentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'create assignment',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDistributeSelectedAssignments() async {
    // 1) Validate selection and classroom context
    if (_selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a classroom first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final classroom = _selectedClassroom!;

    final List<String> assignmentIds = _selectedForDistribution.toList();
    if (assignmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one assignment to distribute'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 2) Fetch available courses in classroom and filter to owned
      List<Course> courses = await _classroomService.getClassroomCourses(
        classroom.id,
      );
      final ownedCourses = courses.where((c) => c.teacherId == uid).toList();

      if (ownedCourses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No owned courses available in this classroom.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 3) Show modal multi-select for owned courses
      final selectedCourseIds = <String>{};
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDlg) {
              return AlertDialog(
                title: const Text('Distribute to Courses'),
                content: SizedBox(
                  width: 480,
                  height: 360,
                  child: ListView.builder(
                    itemCount: ownedCourses.length,
                    itemBuilder: (ctx, i) {
                      final c = ownedCourses[i];
                      final checked = selectedCourseIds.contains(c.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setDlg(() {
                            if (v == true) {
                              selectedCourseIds.add(c.id);
                            } else {
                              selectedCourseIds.remove(c.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Text(
                                'owned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('Grade ${classroom.gradeLevel}'),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selectedCourseIds.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Distribute Now'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || selectedCourseIds.isEmpty) {
        return; // User canceled or no courses chosen
      }

      // 4) Distribute assignments: update first course, clone for additional courses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Distributing to ${selectedCourseIds.length} course${selectedCourseIds.length == 1 ? '' : 's'}...',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      // Helper to get assignment map by id from local list
      Map<String, dynamic>? _getAssignment(String id) {
        try {
          return _assignments.firstWhere((a) => a['id'].toString() == id);
        } catch (_) {
          return null;
        }
      }

      for (final assignmentId in assignmentIds) {
        final a = _getAssignment(assignmentId);
        if (a == null) continue;

        // Extract reusable fields safely
        final String title = (a['title'] ?? '').toString();
        final String? description = a['description']?.toString();
        final String type = (a['assignment_type'] ?? a['type'] ?? 'quiz')
            .toString();
        final int totalPoints =
            int.tryParse((a['total_points'] ?? a['points'] ?? 0).toString()) ??
            0;
        final bool allowLate = (a['allow_late_submissions'] ?? true) == true;
        final DateTime? dueDate = _parseDueDate(a['due_date']);
        Map<String, dynamic>? content;
        try {
          if (a['content'] is Map) {
            content = Map<String, dynamic>.from(a['content'] as Map);
          }
        } catch (_) {}
        // Normalize grading tags: prefer DB columns, then fall back to meta
        final String? component =
            a['component']?.toString() ??
            content?['meta']?['component']?.toString();
        final int? quarterNo = a['quarter_no'] != null
            ? int.tryParse(a['quarter_no'].toString())
            : int.tryParse((content?['meta']?['quarter_no'])?.toString() ?? '');

        // Always create assignments bound to the current classroom + selected courses.
        for (final courseId in selectedCourseIds) {
          await _assignmentService.createAssignment(
            classroomId: classroom.id,
            teacherId: uid,
            title: title,
            description: description,
            assignmentType: type,
            totalPoints: totalPoints,
            dueDate: dueDate,
            allowLateSubmissions: allowLate,
            content: content,
            courseId: courseId,
            isPublished: true,
            component: component,
            quarterNo: quarterNo,
          );
        }

        // Remove the original draft from the unpublished pool locally and in DB
        try {
          await _supabase
              .from('assignments')
              .update({'is_published': true})
              .eq('id', assignmentId);
        } catch (_) {}
        setState(() {
          _assignments.removeWhere((x) => x['id'].toString() == assignmentId);
          _selectedForDistribution.remove(assignmentId);
          if (_selectedAssignmentId == assignmentId) {
            _selectedAssignmentId = null;
          }
        });
      }

      // 6) Refresh and confirm
      await _loadAssignments(classroom.id);
      setState(() {
        _selectedForDistribution.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment successfully distributed to selected courses.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during distribution: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAssignmentsPanel() {
    if (_selectedClassroom == null) {
      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
      );
    }

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
              'assignments',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Divider(height: 1),

          // Assignments List
          Expanded(
            child: _assignments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No assignments yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      final isSelected =
                          _selectedAssignmentId == assignment['id'].toString();
                      final bool isOwned = _isOwnedAssignment(assignment);

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
                                  assignment['title'],
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
                            '${assignment['total_points'] ?? assignment['points'] ?? 0} pts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Checkbox(
                            value: _selectedForDistribution.contains(
                              assignment['id'].toString(),
                            ),
                            onChanged: (checked) {
                              setState(() {
                                final id = assignment['id'].toString();
                                if (checked == true) {
                                  _selectedForDistribution.add(id);
                                } else {
                                  _selectedForDistribution.remove(id);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAssignmentId = assignment['id']
                                  .toString();
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedForDistribution.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Distribute'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _onDistributeSelectedAssignments,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDetailsPanel() {
    if (_selectedClassroom == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a classroom to manage assignments',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_selectedAssignment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No assignment selected',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an assignment or create a new one',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAssignment!['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedClassroom!.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isOwnedAssignment(_selectedAssignment!)) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final assignment = _selectedAssignment!;
                    final classroom = _selectedClassroom!;
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAssignmentScreen(
                          classroom: classroom,
                          existingAssignment: assignment,
                        ),
                      ),
                    );
                    if (updated == true && mounted) {
                      _loadAssignments(classroom.id);
                    }
                  },
                  tooltip: 'Edit assignment',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final assignment = _selectedAssignment!;
                    final assignmentId = assignment['id'].toString();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete assignment'),
                        content: const Text(
                          'Are you sure you want to delete this assignment? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deleting assignment...')),
                      );
                      try {
                        // Best-effort storage cleanup; errors here should not block DB delete
                        await _assignmentService.deleteAssignmentStorageFiles(
                          assignmentId,
                        );
                      } catch (_) {}
                      try {
                        await _assignmentService.deleteAssignment(assignmentId);
                        if (!mounted) return;
                        setState(() {
                          _assignments.removeWhere(
                            (a) => a['id'].toString() == assignmentId,
                          );
                          if (_selectedAssignmentId == assignmentId) {
                            _selectedAssignmentId = null;
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Assignment deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting assignment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: 'Delete assignment',
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Assignment Preview (read-only)
          _buildAssignmentPreview(),

          const SizedBox(height: 24),

          // Assignment Details Form
          _buildDetailSection(
            'Assignment Title',
            Icons.title,
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter assignment title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              controller: TextEditingController(
                text: _selectedAssignment!['title'],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildDetailSection(
            'Description',
            Icons.description,
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter assignment description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
              controller: TextEditingController(
                text: _selectedAssignment!['description'],
              ),
            ),
          ),

          const SizedBox(height: 20),

          (((_selectedAssignment!['assignment_type'] ?? '').toString() ==
                  'file_upload')
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Instructions',
                      Icons.list_alt,
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter detailed instructions for students',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : const SizedBox.shrink()),

          Row(
            children: [
              Expanded(
                child: _buildDetailSection(
                  'Points',
                  Icons.star,
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Points',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text:
                          (_selectedAssignment!['total_points'] ??
                                  _selectedAssignment!['points'] ??
                                  0)
                              .toString(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailSection(
                  'Due Date',
                  Icons.calendar_today,
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Select due date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _formatDueDate(
                        _parseDueDate(_selectedAssignment!['due_date']),
                      ),
                    ),
                    readOnly: true,
                    onTap: () {
                      // TODO: Show date picker
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          (((_selectedAssignment!['assignment_type'] ?? '').toString() ==
                  'file_upload')
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Attachments',
                      Icons.attach_file,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Upload file
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload File'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No files uploaded yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                )
              : const SizedBox(height: 16)),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAssignmentId = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Save assignment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assignment saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _showCreateAssignmentDialog() {
    if (_selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a classroom first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to full-screen create assignment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateAssignmentScreen(classroom: _selectedClassroom!),
      ),
    ).then((result) {
      if (result == true && _selectedClassroom != null) {
        _loadAssignments(_selectedClassroom!.id);
      }
    });
  }
}

/// Create Assignment Dialog Widget
class _CreateAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> classroom;
  final VoidCallback onAssignmentCreated;

  const _CreateAssignmentDialog({
    required this.classroom,
    required this.onAssignmentCreated,
  });

  @override
  State<_CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');

  String _selectedType = 'quiz';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _assignmentTypes = [
    {'id': 'quiz', 'label': 'quiz', 'icon': Icons.quiz},
    {
      'id': 'multiple_choice',
      'label': 'multiple choice',
      'icon': Icons.checklist,
    },
    {
      'id': 'identification',
      'label': 'identification',
      'icon': Icons.text_fields,
    },
    {
      'id': 'matching_type',
      'label': 'matching type',
      'icon': Icons.compare_arrows,
    },
    {'id': 'file_upload', 'label': 'file upload', 'icon': Icons.upload_file},
    {'id': 'essay', 'label': 'essay', 'icon': Icons.article},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Assignment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.classroom['title'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isCreating
                        ? null
                        : () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assignment Title
                      _buildSectionLabel(
                        'Assignment Title',
                        Icons.title,
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter assignment title',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an assignment title';
                          }
                          return null;
                        },
                        enabled: !_isCreating,
                      ),

                      const SizedBox(height: 24),

                      // Assignment Description
                      _buildSectionLabel(
                        'Assignment Description',
                        Icons.description,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Enter assignment description',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 3,
                        enabled: !_isCreating,
                      ),

                      const SizedBox(height: 24),

                      // Assignment Type
                      _buildSectionLabel(
                        'Assignment Type',
                        Icons.category,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _assignmentTypes.map((type) {
                          final isSelected = _selectedType == type['id'];
                          return InkWell(
                            onTap: _isCreating
                                ? null
                                : () {
                                    setState(() {
                                      _selectedType = type['id'];
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type['icon'],
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Points and Due Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Points
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  'Points',
                                  Icons.star,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _pointsController,
                                  decoration: InputDecoration(
                                    hintText: '100',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final points = int.tryParse(value);
                                    if (points == null || points <= 0) {
                                      return 'Invalid points';
                                    }
                                    return null;
                                  },
                                  enabled: !_isCreating,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Due Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  'Due Date',
                                  Icons.calendar_today,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _isCreating ? null : _selectDueDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dueDate != null
                                                ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                                                : 'Select date',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _dueDate != null
                                                  ? Colors.black87
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Due Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  'Due Time',
                                  Icons.access_time,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _isCreating ? null : _selectDueTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dueTime != null
                                                ? _dueTime!.format(context)
                                                : 'Select time',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _dueTime != null
                                                  ? Colors.black87
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'After creating the assignment, you can add detailed instructions, attachments, and configure additional settings.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isCreating
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create Assignment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon, {
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // TODO: Implement actual backend call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        Navigator.pop(context);
        widget.onAssignmentCreated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Assignment "${_titleController.text}" created successfully!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error creating assignment: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
