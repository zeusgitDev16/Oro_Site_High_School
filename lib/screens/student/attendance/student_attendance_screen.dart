import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/screens/student/dashboard/student_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/services/profile_service.dart';

/// Student Attendance Overview Screen
/// Displays attendance records and statistics - UI only
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final ClassroomService _classroomService = ClassroomService();
  final _supabase = Supabase.instance.client;
  // Teacher info services (for showing course owner on Today)
  final TeacherService _teacherService = TeacherService();
  final ProfileService _profileService = ProfileService();
  final Map<String, String> _teacherNameCache = {};
  String? _teacherName;
  bool _isLoadingTeacherName = false;

  String? _studentId;

  // Left panel
  List<Classroom> _classrooms = [];
  bool _isLoadingClassrooms = false;
  Classroom? _selectedClassroom;

  // Courses
  List<Course> _courses = [];
  bool _isLoadingCourses = false;
  Course? _selectedCourse;

  // Filters
  int? _selectedQuarter; // 1-4
  DateTime? _selectedDate;
  late DateTime _visibleMonth;

  // Month data
  final Set<String> _markedDateKeys = {};
  final Map<String, String> _statusByDate = {}; // 'yyyy-MM-dd' -> status
  final Map<String, Map<String, dynamic>> _detailsByDate = {};
  bool _isLoadingMonth = false;

  RealtimeChannel? _rtAttendance;
  // Active quarter lock (teacher-controlled)
  RealtimeChannel? _rtActiveQuarter;
  int? _activeQuarterForCourse;

  @override
  void initState() {
    super.initState();
    _visibleMonth = _normalizeDate(DateTime.now());
    _init();
  }

  Future<void> _init() async {
    _studentId = _supabase.auth.currentUser?.id;
    await _restoreQuarter();
    await _loadClassrooms();
  }

  @override
  void dispose() {
    _teardownRealtime();
    _teardownActiveQuarterRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildLeftPanel(),
          const VerticalDivider(width: 1),
          Expanded(child: _buildWorkspace()),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 240,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back and title
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to Dashboard',
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
                    'MY ATTENDANCE',
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
          Expanded(
            child: _isLoadingClassrooms
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Your classrooms will appear here',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
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
                          borderRadius: BorderRadius.circular(12),
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
                            'Grade ${classroom.gradeLevel}',
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

  String _monthYearLabel(DateTime dt) => DateFormat('MMMM yyyy').format(dt);

  Future<void> _loadClassrooms() async {
    if (_studentId == null) return;
    setState(() => _isLoadingClassrooms = true);
    try {
      final rooms = await _classroomService.getStudentClassrooms(_studentId!);
      setState(() {
        _classrooms = rooms;
        _selectedClassroom = rooms.isNotEmpty ? rooms.first : null;
      });
      if (_selectedClassroom != null) {
        await _loadCoursesForSelectedClassroom();
      }
    } catch (_) {
      // swallow errors for UI
    } finally {
      if (mounted) setState(() => _isLoadingClassrooms = false);
    }
  }

  Future<void> _onSelectClassroom(Classroom room) async {
    setState(() {
      _selectedClassroom = room;
      _selectedCourse = null;
      _statusByDate.clear();
      _detailsByDate.clear();
      _markedDateKeys.clear();
    });
    await _loadCoursesForSelectedClassroom();
  }

  Future<void> _loadCoursesForSelectedClassroom() async {
    if (_selectedClassroom == null) return;
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _classroomService.getClassroomCourses(
        _selectedClassroom!.id,
      );
      setState(() {
        _courses = courses;
        _selectedCourse = courses.isNotEmpty ? courses.first : null;
      });
      await _loadActiveQuarterForCurrentCourse();
      _setupActiveQuarterRealtime();
      await _loadAttendanceForVisibleMonth();
      _setupRealtime();
      await _maybeLoadTeacherNameForToday();
    } catch (_) {
      // ignore for UI
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String _dateKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(_normalizeDate(d));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _maybeLoadTeacherNameForToday() async {
    final DateTime? sel = _selectedDate;
    final today = _normalizeDate(DateTime.now());
    if (sel == null || !_isSameDate(sel, today)) {
      if (mounted) setState(() => _teacherName = null);
      return;
    }
    final tid = _selectedCourse?.teacherId;
    if (tid == null || tid.isEmpty) {
      if (mounted) setState(() => _teacherName = null);
      return;
    }
    final cached = _teacherNameCache[tid];
    if (cached != null) {
      if (mounted) setState(() => _teacherName = cached);
      return;
    }
    if (mounted) setState(() => _isLoadingTeacherName = true);
    try {
      final t = await _teacherService.getTeacherById(tid);
      String? name = t?.fullName ?? t?.displayName;
      if (name == null || name.trim().isEmpty) {
        final prof = await _profileService.getProfile(tid);
        name = prof?.fullName;
      }
      if (mounted) {
        setState(() {
          _teacherName = (name != null && name.trim().isNotEmpty) ? name : null;
          if (_teacherName != null) {
            _teacherNameCache[tid] = _teacherName!;
          }
        });
      }
    } catch (_) {
      // ignore fetch errors
    } finally {
      if (mounted) setState(() => _isLoadingTeacherName = false);
    }
  }

  int _currentQuarterForMonth(int month) => ((month - 1) ~/ 3) + 1; // 1..4

  String _quarterPrefKeyFor(String studentId) =>
      'attendance_selected_quarter_student_$studentId';

  Future<void> _restoreQuarter() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = _studentId ?? _supabase.auth.currentUser?.id;
    if (sid != null) {
      final q = prefs.getInt(_quarterPrefKeyFor(sid));
      if (q != null && q >= 1 && q <= 4) {
        if (mounted) {
          setState(() => _selectedQuarter = q);
        } else {
          _selectedQuarter = q;
        }
        return;
      }
    }
    if (mounted) {
      setState(
        () => _selectedQuarter = _currentQuarterForMonth(DateTime.now().month),
      );
    } else {
      _selectedQuarter = _currentQuarterForMonth(DateTime.now().month);
    }
  }

  Future<void> _persistQuarter(int q) async {
    final prefs = await SharedPreferences.getInstance();
    final sid = _studentId ?? _supabase.auth.currentUser?.id;
    if (sid == null) return;
    await prefs.setInt(_quarterPrefKeyFor(sid), q);
  }

  void _setupRealtime() {
    _teardownRealtime();
    if (_studentId == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
      // ignore: avoid_print
      print(
        '[STU_ATT][RT] SKIP setup: studentId=${_studentId} course=${_selectedCourse?.id} quarter=${_selectedQuarter}',
      );
      return;
    }
    final cid = int.tryParse(_selectedCourse!.id);
    if (cid == null) {
      // ignore: avoid_print
      print(
        '[STU_ATT][RT] SKIP setup invalid course id: ${_selectedCourse!.id}',
      );
      return;
    }
    final chName =
        'student_att_${_studentId}_${_selectedCourse!.id}_${_selectedQuarter}';
    // ignore: avoid_print
    print('[STU_ATT][RT] setup channel=$chName');
    _rtAttendance = _supabase
        .channel(chName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: _studentId!,
          ),
          callback: (payload) {
            final data = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final sid = data['student_id']?.toString();
            final courseIdStr = data['course_id']?.toString();
            final q = int.tryParse(data['quarter']?.toString() ?? '');
            final dStr = data['date']?.toString();
            // ignore: avoid_print
            print(
              '[STU_ATT][RT] evt=${payload.eventType.name} sid=$sid course=$courseIdStr q=$q date=$dStr',
            );
            if (sid != _studentId) return;
            if (courseIdStr != cid.toString()) return;
            if (q != _selectedQuarter) return;
            final dt = dStr != null ? DateTime.tryParse(dStr)?.toLocal() : null;
            if (dt == null) {
              return;
            }
            if (dt.year != _visibleMonth.year ||
                dt.month != _visibleMonth.month) {
              return;
            }
            final key = _dateKey(dt);
            final status = (data['status'] ?? '').toString();
            setState(() {
              if (payload.eventType == PostgresChangeEvent.delete) {
                _statusByDate.remove(key);
                _detailsByDate.remove(key);
                _markedDateKeys.remove(key);
              } else {
                _statusByDate[key] = status;
                _detailsByDate[key] = {
                  'status': status,
                  'time_in': data['time_in'] ?? data['timeIn'],
                  'time_out': data['time_out'] ?? data['timeOut'],
                  'remarks': data['remarks'],
                };
                _markedDateKeys.add(key);
              }
            });
            // ignore: avoid_print
            print(
              '[STU_ATT][RT] updated key=$key status=$status totalDays=${_statusByDate.length}',
            );
          },
        )
        .subscribe();
  }

  void _teardownRealtime() {
    if (_rtAttendance != null) {
      // ignore: avoid_print
      print('[STU_ATT][RT] teardown');
      _supabase.removeChannel(_rtAttendance!);
      _rtAttendance = null;
    }
  }

  void _teardownActiveQuarterRealtime() {
    if (_rtActiveQuarter != null) {
      _supabase.removeChannel(_rtActiveQuarter!);
      _rtActiveQuarter = null;
    }
  }

  Future<void> _loadActiveQuarterForCurrentCourse() async {
    if (_selectedCourse == null) return;
    final cid = int.tryParse(_selectedCourse!.id);
    if (cid == null) return;
    try {
      final row = await _supabase
          .from('course_active_quarters')
          .select('active_quarter')
          .eq('course_id', cid)
          .maybeSingle();
      final aq = row == null ? null : int.tryParse('${row['active_quarter']}');
      // ignore: avoid_print
      print('[STU_ATT] activeQuarter load course=$cid -> $aq');
      if (!mounted) return;
      setState(() => _activeQuarterForCourse = aq);
      if (aq != null && _selectedQuarter != aq) {
        setState(() => _selectedQuarter = aq);
        await _persistQuarter(aq);
        await _loadAttendanceForVisibleMonth();
        _setupRealtime();
        await _maybeLoadTeacherNameForToday();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[STU_ATT] activeQuarter load error: $e');
    }
  }

  void _setupActiveQuarterRealtime() {
    _teardownActiveQuarterRealtime();
    if (_selectedCourse == null) return;
    final cid = int.tryParse(_selectedCourse!.id);
    if (cid == null) return;
    _rtActiveQuarter = _supabase
        .channel('course_active_quarter_${_selectedCourse!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_active_quarters',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'course_id',
            value: cid,
          ),
          callback: (payload) async {
            final data = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final courseIdStr = data['course_id']?.toString();
            if (courseIdStr != cid.toString()) return;
            final aq = int.tryParse('${data['active_quarter']}');
            // ignore: avoid_print
            print('[STU_ATT][RT] activeQuarter changed -> $aq for course=$cid');
            if (!mounted) return;
            setState(() => _activeQuarterForCourse = aq);
            if (aq != null && _selectedQuarter != aq) {
              setState(() => _selectedQuarter = aq);
              await _persistQuarter(aq);
              await _loadAttendanceForVisibleMonth();
              _setupRealtime();
              await _maybeLoadTeacherNameForToday();
            }
          },
        )
        .subscribe();
  }

  Widget _buildActiveQuarterBanner() {
    if (_activeQuarterForCourse == null) return const SizedBox.shrink();
    final isActive = _selectedQuarter == _activeQuarterForCourse;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green.shade300 : Colors.amber.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.lock,
              size: 16,
              color: isActive ? Colors.green : Colors.amber.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isActive
                    ? 'Active Quarter (Q${_activeQuarterForCourse}) set by your teacher'
                    : 'Viewing Q${_selectedQuarter ?? '-'} (Read-only) — Q${_activeQuarterForCourse} is the active quarter set by your teacher',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? Colors.green.shade800
                      : Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAttendanceForVisibleMonth() async {
    // Early guards with explicit debug output
    if (_studentId == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
      // ignore: avoid_print
      print(
        '[STU_ATT] SKIP loadMonth because: studentId=${_studentId}, course=${_selectedCourse?.id}, quarter=${_selectedQuarter}',
      );
      setState(() {
        _statusByDate.clear();
        _markedDateKeys.clear();
        _detailsByDate.clear();
      });
      return;
    }

    setState(() => _isLoadingMonth = true);
    try {
      final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final cid = int.tryParse(_selectedCourse!.id);
      if (cid == null) {
        // ignore: avoid_print
        print(
          '[STU_ATT] SKIP loadMonth invalid course id: ${_selectedCourse!.id}',
        );
        return;
      }

      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      final startIso = start.toIso8601String();
      final endIso = end.toIso8601String();

      // Debug: query params
      // ignore: avoid_print
      print(
        '[STU_ATT] loadMonth params student=$_studentId course=$cid q=$_selectedQuarter range(date-only)=$startStr..$endStr range(iso)=$startIso..$endIso',
      );

      // Main query (date-only range)
      final respMain = await _supabase
          .from('attendance')
          .select('student_id,course_id,quarter,date,status')
          .eq('student_id', _studentId!)
          .eq('course_id', cid)
          .eq('quarter', _selectedQuarter!)
          .gte('date', startStr)
          .lte('date', endStr);

      List respUsed = (respMain as List);
      // ignore: avoid_print
      print(
        '[STU_ATT] loadMonth main rows=${respUsed.length} sample=${respUsed.isNotEmpty ? respUsed.first : {}}',
      );

      // Fallback diagnostics if main returned 0 rows
      if (respUsed.isEmpty) {
        // Alt A: ISO range
        final respIso = await _supabase
            .from('attendance')
            .select('student_id,course_id,quarter,date,status')
            .eq('student_id', _studentId!)
            .eq('course_id', cid)
            .eq('quarter', _selectedQuarter!)
            .gte('date', startIso)
            .lte('date', endIso);
        final listIso = (respIso as List);
        // ignore: avoid_print
        print(
          '[STU_ATT][DBG] altA iso-range rows=${listIso.length} sample=${listIso.isNotEmpty ? listIso.first : {}}',
        );
        if (listIso.isNotEmpty) {
          // ignore: avoid_print
          print('[STU_ATT][DBG] Using ISO-range fallback for mapping');
          respUsed = listIso;
        } else {
          // Alt B: Drop quarter filter
          final respNoQ = await _supabase
              .from('attendance')
              .select('student_id,course_id,quarter,date,status')
              .eq('student_id', _studentId!)
              .eq('course_id', cid)
              .gte('date', startStr)
              .lte('date', endStr);
          final listNoQ = (respNoQ as List);
          // ignore: avoid_print
          print(
            '[STU_ATT][DBG] altB no-quarter rows=${listNoQ.length} sample=${listNoQ.isNotEmpty ? listNoQ.first : {}}',
          );
          if (listNoQ.isNotEmpty) {
            // ignore: avoid_print
            print('[STU_ATT][DBG] no-quarter shows rows: ${listNoQ.length}');
            // Try filtering to the selected quarter client-side in case of type mismatch
            final filtered = listNoQ.where((r) {
              final rq = int.tryParse(r['quarter']?.toString() ?? '');
              return rq == _selectedQuarter;
            }).toList();
            // ignore: avoid_print
            print(
              '[STU_ATT][DBG] no-quarter filtered to q=$_selectedQuarter -> ${filtered.length}',
            );
            if (filtered.isNotEmpty) {
              // ignore: avoid_print
              print(
                '[STU_ATT][DBG] Using no-quarter FILTERED fallback for mapping (type-mismatch suspected)',
              );
              respUsed = filtered;
            }
          } else {
            // Alt C: Drop course filter
            final respNoCourse = await _supabase
                .from('attendance')
                .select('student_id,course_id,quarter,date,status')
                .eq('student_id', _studentId!)
                .gte('date', startStr)
                .lte('date', endStr);
            final listNoCourse = (respNoCourse as List);
            // ignore: avoid_print
            print(
              '[STU_ATT][DBG] altC no-course rows=${listNoCourse.length} sample=${listNoCourse.isNotEmpty ? listNoCourse.first : {}}',
            );

            // Alt D: Probe a specific day (10th) with both eq-date formats
            try {
              final probeDay = DateTime(
                _visibleMonth.year,
                _visibleMonth.month,
                10,
              );
              final probeIso = probeDay.toIso8601String();
              final probeStr = DateFormat('yyyy-MM-dd').format(probeDay);
              final onDayIso = await _supabase
                  .from('attendance')
                  .select('student_id,course_id,quarter,date,status')
                  .eq('student_id', _studentId!)
                  .eq('course_id', cid)
                  .eq('date', probeIso);
              final onDayStr = await _supabase
                  .from('attendance')
                  .select('student_id,course_id,quarter,date,status')
                  .eq('student_id', _studentId!)
                  .eq('course_id', cid)
                  .eq('date', probeStr);
              // ignore: avoid_print
              print(
                '[STU_ATT][DBG] altD probe 10th iso=${(onDayIso as List).length} str=${(onDayStr as List).length}',
              );
            } catch (_) {}

            if (listNoCourse.isNotEmpty) {
              // ignore: avoid_print
              print(
                '[STU_ATT][DBG] no-course shows rows: ${listNoCourse.length}',
              );
              // Try filtering for course and quarter client-side in case of type mismatch
              final filtered = listNoCourse.where((r) {
                final rcid = r['course_id']?.toString();
                final rq = int.tryParse(r['quarter']?.toString() ?? '');
                return rcid == cid.toString() && rq == _selectedQuarter;
              }).toList();
              // ignore: avoid_print
              print(
                '[STU_ATT][DBG] no-course filtered by course=$cid & q=$_selectedQuarter -> ${filtered.length}',
              );
              if (filtered.isNotEmpty) {
                // ignore: avoid_print
                print(
                  '[STU_ATT][DBG] Using no-course FILTERED fallback for mapping (type-mismatch suspected)',
                );
                respUsed = filtered;
              }
            }
          }
        }
      }

      final Map<String, String> status = {};
      final Map<String, Map<String, dynamic>> details = {};
      final Set<String> keys = {};

      int i = 0;
      for (final row in respUsed) {
        final dStr = row['date']?.toString();
        final dt = dStr != null ? DateTime.tryParse(dStr)?.toLocal() : null;
        if (i < 10) {
          // ignore: avoid_print
          print('[STU_ATT] row[$i] rawDate=$dStr parsedLocal=$dt');
          i++;
        }
        if (dt == null) continue;
        final key = _dateKey(dt);
        final st = (row['status'] ?? '').toString();
        status[key] = st;
        details[key] = {
          'status': st,
          'time_in': row['time_in'] ?? row['timeIn'],
          'time_out': row['time_out'] ?? row['timeOut'],
          'remarks': row['remarks'],
        };
        keys.add(key);
      }

      // Debug: processed maps
      // ignore: avoid_print
      print(
        '[STU_ATT] mapped keys=${keys.length} e.g. ${keys.isNotEmpty ? keys.first : '-'} statuses=${status.toString()}',
      );

      if (mounted) {
        setState(() {
          _statusByDate
            ..clear()
            ..addAll(status);
          _detailsByDate
            ..clear()
            ..addAll(details);
          _markedDateKeys
            ..clear()
            ..addAll(keys);
        });
        // ignore: avoid_print
        print(
          '[STU_ATT] state set: statusByDate=${_statusByDate.length} marked=${_markedDateKeys.length}',
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[STU_ATT] loadMonth ERROR: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoadingMonth = false);
    }
  }

  Widget _buildWorkspace() {
    if (_selectedClassroom == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _isLoadingClassrooms
                ? 'Loading your classrooms...'
                : 'Select a classroom on the left to view your attendance.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final bool isTodaySelected =
        _selectedDate != null &&
        _isSameDate(_selectedDate!, _normalizeDate(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pearl 10 style classroom title pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _selectedClassroom?.title ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        const Divider(height: 1),
        // Filters row: course + quarter + month navigation
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<Course>(
                  isExpanded: true,
                  initialValue: _selectedCourse,
                  items: _courses
                      .map(
                        (c) => DropdownMenuItem<Course>(
                          value: c,
                          child: Text(c.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) async {
                    setState(() => _selectedCourse = val);
                    await _loadActiveQuarterForCurrentCourse();
                    _setupActiveQuarterRealtime();
                    await _loadAttendanceForVisibleMonth();
                    _setupRealtime();
                    await _maybeLoadTeacherNameForToday();
                  },
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                children: List.generate(4, (i) => i + 1).map((q) {
                  final selected = _selectedQuarter == q;
                  final lockSet = _activeQuarterForCourse != null;
                  final isActive = _activeQuarterForCourse == q;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (lockSet)
                          Icon(
                            isActive ? Icons.check_circle : Icons.lock,
                            size: 14,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        if (lockSet) const SizedBox(width: 4),
                        Text(
                          'Q$q${!isActive && lockSet ? ' (Read-only)' : ''}',
                        ),
                      ],
                    ),
                    selected: selected,
                    onSelected: (v) async {
                      if (!v) return;
                      setState(() => _selectedQuarter = q);
                      await _persistQuarter(q);
                      await _loadAttendanceForVisibleMonth();
                      _setupRealtime();
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () async => _onMonthNavigate(-1),
              ),
              Text(
                _monthYearLabel(_visibleMonth),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () async => _onMonthNavigate(1),
              ),
            ],
          ),
        ),
        // Teacher name row when viewing today (shows loader while fetching)
        if (isTodaySelected && _isLoadingTeacherName)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          )
        else if (isTodaySelected && _teacherName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  'Teacher: ${_teacherName!}',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        _buildActiveQuarterBanner(),

        // Summary row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _buildSummaryRow(),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        // Calendar workspace
        _buildWeekdayHeader(),
        Expanded(
          child: _isLoadingMonth
              ? const Center(child: CircularProgressIndicator())
              : _buildMonthGridWorkspace(),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    int p = 0, a = 0, l = 0, e = 0;
    _statusByDate.forEach((_, st) {
      final s = st.toString().toLowerCase();
      if (s == 'present') {
        p++;
      } else if (s == 'absent') {
        a++;
      } else if (s == 'late') {
        l++;
      } else if (s == 'excused') {
        e++;
      }
    });
    final int schoolDays = _countWeekdaysInMonth(_visibleMonth);
    final double rate = schoolDays == 0 ? 0 : (p / schoolDays) * 100;

    Widget box(String label, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );

    return Row(
      children: [
        box('P', '$p', Colors.green),
        const SizedBox(width: 8),
        box('A', '$a', Colors.red),
        const SizedBox(width: 8),
        box('L', '$l', Colors.grey),
        const SizedBox(width: 8),
        box('E', '$e', Colors.blue),
        const Spacer(),
        box('School Days', '$schoolDays', Colors.black87),
        const SizedBox(width: 8),
        box('Rate', '${rate.toStringAsFixed(1)}%', Colors.teal),
      ],
    );
  }

  int _countWeekdaysInMonth(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int count = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final wd = DateTime(month.year, month.month, d).weekday;
      if (wd >= DateTime.monday && wd <= DateTime.friday) {
        count++;
      }
    }
    return count;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.grey; // Match teacher screen color for Late
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'present') return 'Present';
    if (s == 'absent') return 'Absent';
    if (s == 'late') return 'Late';
    if (s == 'excused') return 'Excused';
    return '\u2014';
  }

  Widget _buildWeekdayHeader() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Calendar grid for the main workspace (teacher-style day cells with status)
  Widget _buildMonthGridWorkspace() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final int leading = first.weekday - 1; // Monday-based grid
    final int totalCells = leading + daysInMonth;
    final int trailing = totalCells % 7 == 0 ? 0 : 7 - (totalCells % 7);
    final int itemCount = totalCells + trailing;

    final today = _normalizeDate(DateTime.now());
    final DateTime? selected = _selectedDate != null
        ? _normalizeDate(_selectedDate!)
        : null;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.05,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < leading || index >= leading + daysInMonth) {
          return const SizedBox.shrink();
        }
        final int day = index - leading + 1;
        final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
        final bool isToday = _isSameDate(date, today);
        final bool isSelected = selected != null && _isSameDate(date, selected);
        final bool isWeekend =
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;

        final bool isFuture = date.isAfter(today);

        final key = _dateKey(date);
        final st = _statusByDate[key];
        final Color accent = st != null
            ? _statusColor(st)
            : Colors.grey.shade300;
        final Color dayText = (isSelected)
            ? Colors.deepOrange
            : (isToday
                  ? Colors.blueAccent
                  : (isWeekend ? Colors.redAccent : Colors.black87));

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            _onDateSelected(date);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.deepOrange : accent,
                width: isSelected ? 2 : 1,
              ),
              color: st != null ? accent.withValues(alpha: 0.06) : Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? Colors.blueAccent : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : dayText,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_markedDateKeys.contains(key))
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (st != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _statusLabel(st),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (!isFuture)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade400.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'No record',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMonthNavigate(int delta) async {
    final y = _visibleMonth.year;
    final m = _visibleMonth.month + delta;
    final newMonth = DateTime(y, m, 1);
    setState(() {
      _visibleMonth = _normalizeDate(newMonth);
      _selectedDate = null;
    });
    await _loadAttendanceForVisibleMonth();
  }

  void _onDateSelected(DateTime date) async {
    setState(() => _selectedDate = _normalizeDate(date));
    await _maybeLoadTeacherNameForToday();
  }
}
