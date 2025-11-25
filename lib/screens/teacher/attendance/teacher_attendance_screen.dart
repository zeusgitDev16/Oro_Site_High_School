import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as xls;
import 'package:oro_site_high_school/utils/excel_download.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Teacher Attendance (Structure Only)
/// 2-layer workspace layout mirroring GradeEntry screen.
/// No data loading/saving yet; placeholders and empty states only.
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  // Services
  final ClassroomService _classroomService = ClassroomService();

  // Layer 1: Classroom selection (real data)
  List<Classroom> _classrooms = [];
  Map<String, int> _enrollmentCounts = {};
  Classroom? _selectedClassroom;
  bool _isLoadingClassrooms = true;
  String? _teacherId;

  // Layer 2 controls (real data)
  List<Course> _courses = [];
  Course? _selectedCourse;
  bool _isLoadingCourses = false;

  int? _selectedQuarter; // 1-4
  DateTime? _selectedDate; // selected via calendar in right sidebar
  late DateTime _visibleMonth; // month visible in calendar

  // Students + attendance status (real roster)
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;
  final Map<String, String> _statusByStudent = {};

  static const double _statusColWidth = 36.0;
  bool _isSaving = false;
  bool _isExporting = false;

  // SF2 export manual overrides (from dialog)
  String? _sf2OverrideSchoolYear;
  String? _sf2OverrideGradeLevel;
  String? _sf2OverrideSection;

  final Set<String> _markedDateKeys = {};

  // Active quarter lock (teacher-controlled)
  RealtimeChannel? _rtActiveQuarter;
  int? _activeQuarterForCourse;
  bool _isSettingActiveQuarter = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
    _initializeTeacher();
  }

  @override
  void dispose() {
    _teardownActiveQuarterRealtime();
    super.dispose();
  }

  // Date helpers
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _monthYearLabel(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatShortDate(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _quarterPrefKeyFor(String teacherId) =>
      'attendance_selected_quarter_$teacherId';

  Future<void> _loadPersistedQuarter() async {
    final tid = _teacherId;
    if (tid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = prefs.getInt(_quarterPrefKeyFor(tid));
      if (q != null && q >= 1 && q <= 4) {
        if (mounted) {
          setState(() => _selectedQuarter = q);
        } else {
          _selectedQuarter = q;
        }
      }
    } catch (_) {
      // ignore preference errors
    }
  }

  Future<void> _persistQuarter(int q) async {
    final tid = _teacherId;
    if (tid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_quarterPrefKeyFor(tid), q);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    if (_statusByStudent.isEmpty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Quarter?'),
        content: const Text(
          'Changing quarters will discard unsaved attendance marks. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _onQuarterSelected(int q) async {
    if (_selectedQuarter == q) return;
    final proceed = await _confirmDiscardUnsavedChanges();
    if (!proceed) return;
    setState(() {
      _selectedQuarter = q;
      _statusByStudent.clear();
      _markedDateKeys.clear();
    });
    await _persistQuarter(q);
    await _loadMarkedDatesForVisibleMonth();
    await _loadAttendanceForSelectedDate();
  }

  // Initialization and data loading (real data)
  Future<void> _initializeTeacher() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() => _teacherId = user.id);
        await _loadPersistedQuarter();
        await _loadClassrooms();
      } else {
        setState(() => _isLoadingClassrooms = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClassrooms = false);
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _classrooms = [];
        _enrollmentCounts = {};
        _isLoadingClassrooms = false;
      });
    }
  }

  Future<void> _selectClassroom(Classroom room) async {
    setState(() {
      _selectedClassroom = room;
      _selectedCourse = null;
      _statusByStudent.clear();
      _students = [];
    });
    await Future.wait([
      _loadCoursesForClassroom(),
      _loadStudentsForClassroom(),
    ]);
  }

  Future<void> _loadCoursesForClassroom() async {
    final c = _selectedClassroom;
    if (c == null) return;
    setState(() => _isLoadingCourses = true);
    try {
      final all = await _classroomService.getClassroomCourses(c.id);
      final uid = _teacherId;
      final owned = uid == null
          ? all
          : all.where((co) => co.teacherId == uid).toList();
      if (!mounted) return;
      setState(() {
        _courses = owned;
        // Keep course unselected until user chooses (clear if previously selected and now missing)
        if (_selectedCourse != null &&
            !_courses.any((co) => co.id == _selectedCourse!.id)) {
          _selectedCourse = null;
        }
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadStudentsForClassroom() async {
    final c = _selectedClassroom;
    if (c == null) return;
    setState(() => _isLoadingStudents = true);
    try {
      final rows = await _classroomService.getClassroomStudents(c.id);

      // Enrich with LRN from students table (idempotent: only adds if available)
      Map<String, String> lrnById = {};
      try {
        final ids = rows
            .map((r) => (r['student_id'] ?? r['id'])?.toString())
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) {
          final resp = await Supabase.instance.client
              .from('students')
              .select('id, lrn')
              .inFilter('id', ids);
          final list = (resp as List).cast<Map<String, dynamic>>();
          for (final m in list) {
            final sid = m['id']?.toString();
            final lrn = m['lrn']?.toString();
            if (sid != null && lrn != null && lrn.isNotEmpty) {
              lrnById[sid] = lrn;
            }
          }
          debugPrint(
            'SF2: fetched LRN for ${lrnById.length}/${ids.length} students',
          );
        }
      } catch (e) {
        debugPrint('SF2: LRN enrichment skipped (error): $e');
      }

      // Apply enrichment
      final enriched = rows.map<Map<String, dynamic>>((r) {
        final sid = (r['student_id'] ?? r['id'])?.toString();
        final lrn = sid != null ? (lrnById[sid] ?? r['lrn']) : r['lrn'];
        if (lrn != null) {
          return {...r, 'lrn': lrn};
        }
        return r;
      }).toList();

      if (!mounted) return;
      setState(() {
        _students = enriched;
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _students = [];
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _loadMarkedDatesForVisibleMonth() async {
    if (_selectedCourse == null || _selectedQuarter == null) {
      setState(() => _markedDateKeys.clear());
      return;
    }
    // Snapshot to avoid stale updates when switching quarters rapidly
    final String? expectedCourseIdStr = _selectedCourse?.id;
    final int? expectedQuarter = _selectedQuarter;
    try {
      final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final courseId = int.tryParse(_selectedCourse!.id);
      if (courseId == null) return;
      // Classroom-scoped / course-scoped query:
      // - Fetches all attendance rows for this course and quarter to mark
      //   the calendar.
      // - Visibility and write access are enforced by the
      //   "Teachers can manage course attendance" RLS policy on public.attendance.
      // - There is intentionally no teacher_id filter so co-teachers share
      //   the same attendance records.
      final resp = await Supabase.instance.client
          .from('attendance')
          .select('date')
          .eq('course_id', courseId)
          .eq('quarter', _selectedQuarter!)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());
      final Set<String> keys = {};
      for (final row in (resp as List)) {
        final dStr = row['date']?.toString();
        if (dStr == null) continue;
        final d = DateTime.tryParse(dStr);
        if (d != null) keys.add(_dateKey(_normalizeDate(d)));
      }
      if (!mounted) return;
      if (expectedCourseIdStr != _selectedCourse?.id ||
          expectedQuarter != _selectedQuarter) {
        // Drop stale result
        return;
      }
      setState(() {
        _markedDateKeys
          ..clear()
          ..addAll(keys);
      });
    } catch (_) {
      // ignore indicator load errors
    }
  }

  Future<void> _loadAttendanceForSelectedDate() async {
    if (_selectedDate == null || _selectedCourse == null || _students.isEmpty) {
      setState(() => _statusByStudent.clear());
      return;
    }
    if (_selectedQuarter == null) {
      setState(() => _statusByStudent.clear());
      return;
    }
    final selected = _normalizeDate(_selectedDate!);
    final today = _normalizeDate(DateTime.now());
    if (selected.isAfter(today)) {
      setState(() => _statusByStudent.clear());
      return;
    }

    // Snapshot to prevent stale updates when toggling quickly
    final String? expectedCourseIdStr = _selectedCourse?.id;
    final int? expectedQuarter = _selectedQuarter;
    final String expectedDateIso = selected.toIso8601String();

    try {
      final courseId = int.tryParse(_selectedCourse!.id);
      if (courseId == null) return;
      final ids = _students
          .map((s) => (s['student_id'] ?? s['id']).toString())
          .toList();
      if (ids.isEmpty) return;

      // Classroom-scoped / course-scoped query:
      // - Loads each student's status for the selected date in this course.
      // - All teachers for the course see the same statuses, enforced by the
      //   "Teachers can manage course attendance" RLS policy on public.attendance.
      // - No teacher_id filter by design; do not add one here.
      final resp = await Supabase.instance.client
          .from('attendance')
          .select('student_id,status')
          .eq('course_id', courseId)
          .eq('quarter', _selectedQuarter!)
          .eq('date', selected.toIso8601String())
          .inFilter('student_id', ids);

      final Map<String, String> map = {};
      for (final row in (resp as List)) {
        final sid = row['student_id']?.toString();
        final status = row['status']?.toString();
        if (sid != null && status != null) map[sid] = status;
      }
      if (!mounted) return;
      if (expectedCourseIdStr != _selectedCourse?.id ||
          expectedQuarter != _selectedQuarter ||
          expectedDateIso != _normalizeDate(_selectedDate!).toIso8601String()) {
        return; // drop stale response
      }
      setState(() {
        _statusByStudent
          ..clear()
          ..addAll(map);
      });
    } catch (e) {
      // ignore load errors for now
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedDate == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
      return;
    }
    final selected = _normalizeDate(_selectedDate!);
    final today = _normalizeDate(DateTime.now());
    if (selected.isAfter(today)) return;
    if (_statusByStudent.isEmpty) return;
    final courseId = int.tryParse(_selectedCourse!.id);
    if (courseId == null) return;

    final List<Map<String, dynamic>> rows = [];
    final List<String> idsToAffect = [];
    _statusByStudent.forEach((sid, status) {
      idsToAffect.add(sid);
      rows.add({
        'student_id': sid,
        'course_id': courseId,
        'quarter': _selectedQuarter!,
        'date': selected.toIso8601String(),
        'status': status,
      });
    });
    if (rows.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      // Classroom-scoped / course-scoped write:
      // - Deletes then re-inserts attendance for this course, quarter, date,
      //   and the affected student ids.
      // - RLS policy "Teachers can manage course attendance" controls which
      //   teachers can perform this operation.
      await client
          .from('attendance')
          .delete()
          .eq('course_id', courseId)
          .eq('quarter', _selectedQuarter!)
          .eq('date', selected.toIso8601String())
          .inFilter('student_id', idsToAffect);

      await client.from('attendance').insert(rows);

      setState(() {
        _markedDateKeys.add(_dateKey(selected));
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Attendance saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Active quarter lock helpers
  Future<void> _loadActiveQuarterForCurrentCourse() async {
    final co = _selectedCourse;
    if (co == null) return;
    try {
      final cid = int.tryParse(co.id);
      if (cid == null) return;
      final row = await Supabase.instance.client
          .from('course_active_quarters')
          .select('active_quarter')
          .eq('course_id', cid)
          .maybeSingle();
      final aq = row == null ? null : int.tryParse('${row['active_quarter']}');
      if (!mounted) return;
      setState(() => _activeQuarterForCourse = aq);
    } catch (e) {
      // silently ignore if table not present or query fails
    }
  }

  void _setupActiveQuarterRealtime() {
    final co = _selectedCourse;
    if (co == null) return;
    final cid = int.tryParse(co.id);
    if (cid == null) return;
    // Teardown previous
    if (_rtActiveQuarter != null) {
      Supabase.instance.client.removeChannel(_rtActiveQuarter!);
      _rtActiveQuarter = null;
    }
    _rtActiveQuarter = Supabase.instance.client
        .channel('teacher_active_q_${co.id}')
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
            try {
              final data = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              final aqVal = data['active_quarter'];
              final aq = aqVal == null ? null : int.tryParse('$aqVal');
              if (!mounted) return;
              setState(() => _activeQuarterForCourse = aq);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  void _teardownActiveQuarterRealtime() {
    if (_rtActiveQuarter != null) {
      Supabase.instance.client.removeChannel(_rtActiveQuarter!);
      _rtActiveQuarter = null;
    }
  }

  Future<void> _setActiveQuarter(int q) async {
    final co = _selectedCourse;
    if (co == null) return;
    final cid = int.tryParse(co.id);
    if (cid == null) return;
    setState(() => _isSettingActiveQuarter = true);
    try {
      await Supabase.instance.client.from('course_active_quarters').upsert({
        'course_id': cid,
        'active_quarter': q,
        'set_by_teacher_id': _teacherId,
      }, onConflict: 'course_id');
      await _loadActiveQuarterForCurrentCourse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set active quarter: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettingActiveQuarter = false);
    }
  }

  Future<void> _confirmAndSetActiveQuarter() async {
    final q = _selectedQuarter;
    if (q == null) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Active Quarter'),
        content: Text('Set Q$q as active quarter for this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      await _setActiveQuarter(q);
    }
  }

  Widget _buildActiveQuarterBanner() {
    final aq = _activeQuarterForCourse;
    if (aq == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade800, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No active quarter set — students may view any quarter. You may set an active quarter.',
                  style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final isActive = _selectedQuarter == aq;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green.shade200 : Colors.amber.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.lock,
              color: isActive ? Colors.green.shade700 : Colors.amber.shade800,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isActive
                    ? 'Active Quarter (Q$aq)'
                    : 'Viewing Q${_selectedQuarter ?? '-'} (Read-only) — Q$aq is active',
                style: TextStyle(
                  color: isActive
                      ? Colors.green.shade700
                      : Colors.amber.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toolbar helpers

  Future<void> _exportMonthlyAttendanceSf2() async {
    if (_selectedCourse == null || _selectedQuarter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select course and quarter first')),
      );
      return;
    }

    final course = _selectedCourse!;
    final classroom = _selectedClassroom;
    final month = _visibleMonth;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    // Build student id list
    final studentIds = _students
        .map((s) => (s['student_id'] ?? s['id']).toString())
        .toList();

    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students in this course')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final courseId = int.tryParse(course.id);
      if (courseId == null) {
        throw Exception('Invalid course id');
      }

      // Fetch month attendance (student_id, date, status).
      // Classroom-scoped / course-scoped data:
      // - This loads all attendance rows for the selected course, quarter, and
      //   month for the given studentIds.
      // - All teachers for the course share the same dataset, enforced by the
      //   "Teachers can manage course attendance" RLS policy on public.attendance.
      // - There is intentionally no teacher_id filter here.
      final resp = await Supabase.instance.client
          .from('attendance')
          .select('student_id,date,status')
          .eq('course_id', courseId)
          .eq('quarter', _selectedQuarter!)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .inFilter('student_id', studentIds)
          .order('date');

      final List<Map<String, dynamic>> list = (resp as List)
          .cast<Map<String, dynamic>>();

      final daysInMonth = end.day;
      bool _isWeekendDay(int day) {
        final wd = DateTime(month.year, month.month, day).weekday;
        return wd == DateTime.saturday || wd == DateTime.sunday;
      }

      final int schoolDays = List<int>.generate(
        daysInMonth,
        (i) => i + 1,
      ).where((d) => !_isWeekendDay(d)).length;

      // map[studentId][day] = code
      final Map<String, Map<int, String>> monthMap = {
        for (final id in studentIds) id: {},
      };
      for (final row in list) {
        final sid = row['student_id']?.toString();
        final dStr = row['date']?.toString();
        final st = row['status']?.toString();
        if (sid == null || dStr == null || st == null) continue;
        final d = DateTime.tryParse(dStr);
        if (d == null) continue;
        String code;
        switch (st.toLowerCase()) {
          case 'present':
            code = 'P';
            break;
          case 'absent':
            code = 'A';
            break;
          case 'late':
            code = 'L';
            break;
          case 'excused':
            code = 'E';
            break;
          default:
            code = '';
        }
        monthMap[sid]?[d.day] = code;
      }

      // Create workbook
      final book = xls.Excel.createExcel();
      final sheet = book['SF2'];

      String monthName = [
        '',
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
      ][month.month];

      String computeSchoolYear(DateTime m) {
        final y = m.year;
        if (m.month >= 6) {
          return '$y-${y + 1}';
        } else {
          return '${y - 1}-$y';
        }
      }

      String teacherName = '';
      try {
        final u = Supabase.instance.client.auth.currentUser;
        final meta = u?.userMetadata;
        teacherName = (meta?['full_name'] ?? u?.email ?? '').toString();

        final uid = u?.id;
        if (uid != null) {
          try {
            final prof = await Supabase.instance.client
                .from('profiles')
                .select('full_name')
                .eq('id', uid)
                .maybeSingle();
            if (prof != null) {
              final fn = (prof['full_name'] ?? '').toString();
              if (fn.trim().isNotEmpty) {
                teacherName = fn;
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      // School/system information (env with fallbacks)
      final schoolName = dotenv.env['SCHOOL_NAME'] ?? 'Oro Site High School';
      final schoolId = dotenv.env['SCHOOL_ID'] ?? '';
      final division =
          dotenv.env['DIVISION'] ?? 'Division of Cagayan de Oro City';
      final region = dotenv.env['REGION'] ?? 'Region X - Northern Mindanao';

      // Title
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('SCHOOL FORM 2 (SF2) – Daily Attendance of Learners'),
      ]);

      final header1 = <xls.CellValue?>[
        xls.TextCellValue('School:'),
        xls.TextCellValue(schoolName),
        xls.TextCellValue('School ID:'),
        xls.TextCellValue(schoolId),
        xls.TextCellValue('Division:'),
        xls.TextCellValue(division),
        xls.TextCellValue('Region:'),
        xls.TextCellValue(region),
      ];
      final header2 = <xls.CellValue?>[
        xls.TextCellValue('Grade Level:'),
        xls.TextCellValue(classroom?.gradeLevel.toString() ?? ''),
        xls.TextCellValue('Section/Course:'),
        xls.TextCellValue('${classroom?.title ?? ''} / ${course.title}'),
        xls.TextCellValue('Month:'),
        xls.TextCellValue('$monthName ${month.year}'),
        xls.TextCellValue('School Year:'),
        xls.TextCellValue(computeSchoolYear(month)),
      ];
      final header3 = <xls.CellValue?>[
        xls.TextCellValue('Teacher:'),
        xls.TextCellValue(teacherName),
        xls.TextCellValue(''),
        xls.TextCellValue(''),
        xls.TextCellValue('Quarter:'),
        xls.TextCellValue('Q${_selectedQuarter!}'),
        xls.TextCellValue(''),
        xls.TextCellValue(''),
      ];

      sheet.appendRow(header1);
      sheet.appendRow(header2);
      sheet.appendRow(header3);
      sheet.appendRow(<xls.CellValue?>[null]);

      // Table header
      final dayCols = List<xls.CellValue?>.generate(
        daysInMonth,
        (i) => xls.TextCellValue((i + 1).toString()),
      );
      final tableHeader = <xls.CellValue?>[
        xls.TextCellValue('LRN'),
        xls.TextCellValue('Learner Name'),
        ...dayCols,
        xls.TextCellValue('P'),
        xls.TextCellValue('A'),
        xls.TextCellValue('L'),
        xls.TextCellValue('E'),
        xls.TextCellValue('%'),
      ];
      sheet.appendRow(tableHeader);

      // Student rows
      List<Map<String, dynamic>> sorted = [..._students];
      sorted.sort(
        (a, b) => (a['full_name'] ?? a['name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo(
              (b['full_name'] ?? b['name'] ?? '').toString().toLowerCase(),
            ),
      );

      int totalP = 0, totalA = 0, totalL = 0, totalE = 0;
      int pctSum = 0, pctCount = 0;

      for (final s in sorted) {
        final id = (s['student_id'] ?? s['id']).toString();
        final name = (s['full_name'] ?? s['name'] ?? '').toString();
        final lrn = (s['lrn'] ?? '').toString();
        final byDay = monthMap[id] ?? {};

        int p = 0, a = 0, l = 0, e = 0;
        final List<String> daily = [];
        for (int d = 1; d <= daysInMonth; d++) {
          final code = byDay[d] ?? '';
          daily.add(code);
          switch (code) {
            case 'P':
              p++;
              break;
            case 'A':
              a++;
              break;
            case 'L':
              l++;
              break;
            case 'E':
              e++;
              break;
          }
        }
        final totalMarked = p + a + l + e;
        final attendancePct = totalMarked == 0
            ? 0
            : (((p + l + e) / totalMarked) * 100).round();

        totalP += p;
        totalA += a;
        totalL += l;
        totalE += e;
        if (totalMarked > 0) {
          pctSum += attendancePct;
          pctCount++;
        }

        final dailyCells = daily
            .map<xls.CellValue?>((c) => xls.TextCellValue(c))
            .toList();
        sheet.appendRow(<xls.CellValue?>[
          xls.TextCellValue(lrn),
          xls.TextCellValue(name),
          ...dailyCells,
          xls.IntCellValue(p),
          xls.IntCellValue(a),
          xls.IntCellValue(l),
          xls.IntCellValue(e),
          xls.TextCellValue('$attendancePct%'),
        ]);
      }

      // Save file
      // Summary row (monthly totals/average)
      final avgPct = pctCount == 0 ? 0 : (pctSum / pctCount).round();
      final blankDays = List<xls.CellValue?>.generate(
        daysInMonth,
        (_) => xls.TextCellValue(''),
      );
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue(''),
        xls.TextCellValue('Totals'),
        ...blankDays,
        xls.IntCellValue(totalP),
        xls.IntCellValue(totalA),
        xls.IntCellValue(totalL),
        xls.IntCellValue(totalE),
        xls.TextCellValue('Avg $avgPct%'),
      ]);
      // DepEd formatting and auto-computations
      final thin = xls.Border(borderStyle: xls.BorderStyle.Thin);

      final headerStyle = xls.CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
      );
      final weekendHeaderStyle = xls.CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        backgroundColorHex: xls.ExcelColor.fromHexString('FFF2F2F2'),
      );
      final baseCellStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
      );
      final weekendDataStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        backgroundColorHex: xls.ExcelColor.fromHexString('FFF2F2F2'),
      );
      final missingStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        backgroundColorHex: xls.ExcelColor.fromHexString('FFFFF2CC'),
      );
      final nameStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
      );
      final aStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        fontColorHex: xls.ExcelColor.fromHexString('FFFF0000'),
      );
      final lStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        fontColorHex: xls.ExcelColor.fromHexString('FFFF8C00'),
      );
      final eStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        topBorder: thin,
        bottomBorder: thin,
        leftBorder: thin,
        rightBorder: thin,
        fontColorHex: xls.ExcelColor.fromHexString('FF0070C0'),
      );

      final int lastCol = 2 + daysInMonth + 4; // LRN, Name, days, P, A, L, E, %
      const int titleRow = 0;
      const int header1Row = 1;
      const int header2Row = 2;
      const int header3Row = 3;
      const int spacerRow = 4;
      const int tableHeaderRow = 5;
      final int dataStartRow = tableHeaderRow + 1;
      final int summaryRow = dataStartRow + sorted.length;

      const int lrnCol = 0;
      const int nameCol = 1;
      final int firstDayCol = 2;
      final int pCol = firstDayCol + daysInMonth;
      final int aCol = pCol + 1;
      final int lCol = pCol + 2;
      final int eCol = pCol + 3;
      final int pctCol = pCol + 4;

      // Merge title across
      sheet.merge(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: titleRow),
        xls.CellIndex.indexByColumnRow(
          columnIndex: lastCol,
          rowIndex: titleRow,
        ),
        customValue: xls.TextCellValue(
          'SCHOOL FORM 2 (SF2) – Daily Attendance of Learners',
        ),
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: titleRow),
          )
          .cellStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
      );

      // Style table header and highlight weekends
      for (int c = 0; c <= lastCol; c++) {
        final ci = xls.CellIndex.indexByColumnRow(
          columnIndex: c,
          rowIndex: tableHeaderRow,
        );
        final cell = sheet.cell(ci);
        if (c >= firstDayCol && c < firstDayCol + daysInMonth) {
          final day = c - firstDayCol + 1;
          final isWknd = _isWeekendDay(day);
          cell.cellStyle = isWknd ? weekendHeaderStyle : headerStyle;
        } else {
          cell.cellStyle = headerStyle;
        }
      }

      // Style data rows, apply color coding, and recompute % against schoolDays
      int pctSumNew = 0;
      int pctCountNew = 0;
      final orderedIds = sorted
          .map((s) => (s['student_id'] ?? s['id']).toString())
          .toList();

      for (int r = 0; r < orderedIds.length; r++) {
        final rowIndex = dataStartRow + r;
        final sid = orderedIds[r];
        final byDay = monthMap[sid] ?? {};

        // LRN and Name styles
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: lrnCol,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            baseCellStyle;
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: nameCol,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            nameStyle;

        int pCount = 0;
        for (int d = 1; d <= daysInMonth; d++) {
          final col = firstDayCol + d - 1;
          final ci = xls.CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: rowIndex,
          );
          final code = (byDay[d] ?? '').toString();
          final isWknd = _isWeekendDay(d);
          if (code == 'P') pCount++;

          if (isWknd) {
            sheet.cell(ci).cellStyle = weekendDataStyle;
          } else if (code.isEmpty) {
            sheet.cell(ci).cellStyle = missingStyle;
          } else if (code == 'A') {
            sheet.cell(ci).cellStyle = aStyle;
          } else if (code == 'L') {
            sheet.cell(ci).cellStyle = lStyle;
          } else if (code == 'E') {
            sheet.cell(ci).cellStyle = eStyle;
          } else {
            sheet.cell(ci).cellStyle = baseCellStyle;
          }
        }

        // Totals columns
        for (final col in [pCol, aCol, lCol, eCol]) {
          sheet
                  .cell(
                    xls.CellIndex.indexByColumnRow(
                      columnIndex: col,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              baseCellStyle;
        }

        // New percentage = P / totalSchoolDays
        final pct = schoolDays == 0 ? 0 : ((pCount / schoolDays) * 100).round();
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: pctCol,
                rowIndex: rowIndex,
              ),
            )
            .value = xls.TextCellValue(
          '$pct%',
        );
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: pctCol,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            baseCellStyle;

        if (schoolDays > 0) {
          pctSumNew += pct;
          pctCountNew++;
        }
      }

      // Update summary row '%'
      final avgNew = pctCountNew == 0 ? 0 : (pctSumNew / pctCountNew).round();
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(
              columnIndex: pctCol,
              rowIndex: summaryRow,
            ),
          )
          .value = xls.TextCellValue(
        'Avg $avgNew%',
      );

      // Summary section at bottom
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue(''),
        xls.TextCellValue('Total Students:'),
        xls.IntCellValue(orderedIds.length),
        xls.TextCellValue('Average Attendance Rate:'),
        xls.TextCellValue('$avgNew%'),
        xls.TextCellValue('Total School Days:'),
        xls.IntCellValue(schoolDays),
        xls.TextCellValue('Generated:'),
        xls.TextCellValue(DateTime.now().toString().split('.').first),
      ]);

      // Footer sign-off
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Prepared by:'),
        xls.TextCellValue(teacherName),
      ]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Checked by:'),
        xls.TextCellValue('_____________________'),
      ]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Date:'),
        xls.TextCellValue(todayStr),
      ]);

      final sectionSanitized = (classroom?.title ?? course.title)
          .toString()
          .replaceAll(' ', '');
      final fileName =
          'SF2_${sectionSanitized}_${monthName}_${month.year}_Q$_selectedQuarter.xlsx';

      List<int>? bytes;
      try {
        bytes = book.encode();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed during Excel encoding: $e')),
          );
        }
        return;
      }

      if (bytes != null) {
        try {
          await saveExcelBytes(bytes, fileName);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed while saving: $e')),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported: $fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ===== SF2 Template-based Export Helpers =====

  String _monthName(int m) {
    const names = [
      '',
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
    return (m >= 1 && m <= 12) ? names[m] : '';
  }

  String _computeSchoolYear(DateTime m) {
    final y = m.year;
    return m.month >= 6 ? '$y-${y + 1}' : '${y - 1}-$y';
  }

  ({int row, int col})? _findCellContainingText(
    xls.Sheet sheet,
    String substring,
  ) {
    final needle = substring.toLowerCase();
    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      for (int c = 0; c < row.length; c++) {
        final s = row[c]?.value?.toString() ?? '';
        if (s.toLowerCase().contains(needle)) {
          return (row: r, col: c);
        }
      }
    }
    return null;
  }

  bool _writeRightOf(
    xls.Sheet sheet,
    ({int row, int col}) pos,
    xls.CellValue value, {
    int maxOffset = 20,
  }) {
    for (int off = 1; off <= maxOffset; off++) {
      final ci = xls.CellIndex.indexByColumnRow(
        columnIndex: pos.col + off,
        rowIndex: pos.row,
      );
      final existing = sheet.cell(ci).value;
      final existingStr = existing?.toString() ?? '';
      if (existing == null || existingStr.isEmpty) {
        sheet.cell(ci).value = value;
        debugPrint('SF2: wrote header at r=${pos.row}, c=${pos.col + off}');
        return true;
      }
    }
    debugPrint(
      'SF2: could not find empty cell to the right of r=${pos.row}, c=${pos.col} within $maxOffset',
    );
    return false;
  }

  // Detect the header row that contains the day numbers (1..31) and map day->column
  // Returns tuple-like via a small holder class pattern.
  ({int headerRow, Map<int, int> dayToCol})? _findDayColumnsInTemplate(
    xls.Sheet sheet,
  ) {
    int bestRow = -1;
    int bestCount = 0;
    Map<int, int> bestMap = {};
    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final Map<int, int> map = {};
      for (int c = 0; c < row.length; c++) {
        final s = row[c]?.value?.toString().trim() ?? '';
        if (s.isEmpty) continue;
        final d = int.tryParse(s);
        if (d != null && d >= 1 && d <= 31) {
          map[d] = c;
        }
      }
      if (map.length >= bestCount && map.isNotEmpty) {
        bestCount = map.length;
        bestRow = r;
        bestMap = Map<int, int>.from(map);
      }
    }
    if (bestRow >= 0 && bestMap.isNotEmpty) {
      return (headerRow: bestRow, dayToCol: bestMap);
    }
    return null;
  }

  int _computeDataStartRow(
    xls.Sheet sheet,
    ({int headerRow, Map<int, int> dayToCol}) dayCols,
  ) {
    // If the next row has day-of-week letters under the day cols, skip it.
    final nextRow = dayCols.headerRow + 1;
    final dow = {'m', 't', 'w', 'th', 'f', 'sat', 'sun'};
    bool hasDow = false;
    if (nextRow < sheet.rows.length) {
      final row = sheet.rows[nextRow];
      for (final col in dayCols.dayToCol.values) {
        if (col < row.length) {
          final s = row[col]?.value?.toString().toLowerCase() ?? '';
          if (s.isNotEmpty && dow.any((d) => s.contains(d))) {
            hasDow = true;
            break;
          }
        }
      }
    }
    return dayCols.headerRow + (hasDow ? 2 : 1);
  }

  // Fill a header field by finding a label and writing to the right (with debug and wider search span)
  void _fillHeaderField(
    xls.Sheet sheet,
    String labelSubstring,
    String value, {
    int maxOffset = 16,
  }) {
    final pos = _findCellContainingText(sheet, labelSubstring);
    debugPrint(
      'SF2: header locate "$labelSubstring" => \'${pos?.row}\', \'${pos?.col}\'',
    );
    if (pos != null) {
      final ok = _writeRightOf(
        sheet,
        pos,
        xls.TextCellValue(value),
        maxOffset: maxOffset,
      );
      if (!ok) {
        debugPrint('SF2: writeRightOf failed for "$labelSubstring"');
      }
    } else {
      debugPrint('SF2: header label "$labelSubstring" not found');
    }
  }

  // Locate and load the SF2 template bytes using the asset manifest for robustness
  Future<List<int>> _loadSf2TemplateBytes() async {
    const preferred = 'assets/School Form 2 (SF2).xlsx';
    try {
      // Try resolving via AssetManifest first (exact key matching)
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest =
          jsonDecode(manifestJson) as Map<String, dynamic>;

      String? chosen;
      if (manifest.containsKey(preferred)) {
        chosen = preferred;
      } else {
        // Search for reasonable candidates (any .xlsx containing 'sf2' or 'school form 2')
        final candidates = manifest.keys.where((k) {
          final kl = k.toLowerCase();
          if (!kl.endsWith('.xlsx')) return false;
          final base = k.split('/').last.toLowerCase();
          // Exclude Excel temp/lock files and common junk
          if (base.startsWith('~\$') || base.startsWith('._')) return false;
          if (base.endsWith('~') ||
              base.endsWith('.tmp') ||
              base.endsWith('.bak')) {
            return false;
          }
          return kl.contains('sf2') || kl.contains('school form 2');
        }).toList();
        if (candidates.isNotEmpty) {
          candidates.sort((a, b) => a.length.compareTo(b.length));
          chosen =
              candidates.first; // prefer the shortest, typically under assets/
        }
      }

      if (chosen != null) {
        final data = await rootBundle.load(chosen);
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) {
          throw Exception('Asset "$chosen" exists but is empty.');
        }
        return bytes;
      }

      // Fallback: try the preferred path directly
      final data = await rootBundle.load(preferred);
      final bytes = data.buffer.asUint8List();
      if (bytes.isEmpty) {
        throw Exception('Asset "$preferred" exists but is empty.');
      }
      return bytes;
    } catch (e) {
      // As a last resort, try a few common alternate names
      const alts = <String>[
        'assets/SchoolForm2(SF2).xlsx',
        'assets/School_Form_2_(SF2).xlsx',
        'assets/SF2.xlsx',
        'assets/sf2.xlsx',
      ];
      for (final p in alts) {
        try {
          final data = await rootBundle.load(p);
          final bytes = data.buffer.asUint8List();
          if (bytes.isNotEmpty) return bytes;
        } catch (_) {}
      }
      throw Exception('Unable to load SF2 template asset. Details: $e');
    }
  }

  Future<void> _exportMonthlyAttendanceSf2TemplateBased({
    DateTime? selectedMonth,
    String? overrideSchoolYear,
    String? overrideGradeLevel,
    String? overrideSection,
  }) async {
    if (_selectedCourse == null || _selectedQuarter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select course and quarter first')),
      );
      return;
    }

    final course = _selectedCourse!;
    final classroom = _selectedClassroom;
    final month = selectedMonth ?? _visibleMonth;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    // Manual overrides from dialog (captured for inner closures)
    final String? _ovSy = overrideSchoolYear;
    final String? _ovGrade = overrideGradeLevel;
    final String? _ovSection = overrideSection;

    // Build student id list
    final studentIds = _students
        .map((s) => (s['student_id'] ?? s['id']).toString())
        .toList();

    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students in this course')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final courseId = int.tryParse(course.id);
      if (courseId == null) {
        throw Exception('Invalid course id');
      }

      // Fetch month attendance (student_id, date, status).
      // Classroom-scoped / course-scoped data:
      // - This loads all attendance rows for the selected course, quarter, and
      //   month for the given studentIds.
      // - All teachers for the course share the same dataset, enforced by the
      //   "Teachers can manage course attendance" RLS policy on public.attendance.
      // - There is intentionally no teacher_id filter here.
      final resp = await Supabase.instance.client
          .from('attendance')
          .select('student_id,date,status')
          .eq('course_id', courseId)
          .eq('quarter', _selectedQuarter!)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .inFilter('student_id', studentIds)
          .order('date');

      final List<Map<String, dynamic>> list = (resp as List)
          .cast<Map<String, dynamic>>();
      debugPrint('SF2: attendance rows fetched: ${list.length}');

      // map[studentId][day] = code (kept for next steps)
      final Map<String, Map<int, String>> monthMap = {
        for (final id in studentIds) id: {},
      };
      for (final row in list) {
        final sid = row['student_id']?.toString();
        final dStr = row['date']?.toString();
        final st = row['status']?.toString();
        if (sid == null || dStr == null || st == null) continue;
        final d = DateTime.tryParse(dStr);
        if (d == null) continue;
        String code;
        switch (st.toLowerCase()) {
          case 'present':
            code = 'P';
            break;
          case 'absent':
            code = 'A';
            break;
          case 'late':
            code = 'L';
            break;
          case 'excused':
            code = 'E';
            break;
          default:
            code = '';
        }
        monthMap[sid]?[d.day] = code;
      }
      final nonEmptyMonthMapEntries = monthMap.values.fold<int>(
        0,
        (acc, m) => acc + m.length,
      );
      debugPrint(
        'SF2: monthMap day entries (all statuses): $nonEmptyMonthMapEntries',
      );
      // New: XML-injection export (preserves template formatting)
      final okXml = await _exportSf2ViaXmlInjection(
        month: month,
        classroom: classroom,
        course: course,
        studentIds: studentIds,
        monthMap: monthMap,
      );
      if (okXml) {
        return;
      }

      // Load official template
      final templateBytes = await _loadSf2TemplateBytes();
      debugPrint('SF2: template bytes loaded: \\${templateBytes.length}');
      final book = xls.Excel.decodeBytes(templateBytes);
      debugPrint('SF2: workbook sheets: \\${book.sheets.keys.toList()}');
      const wantedSheetName = 'School Form 2 (SF2)';
      xls.Sheet? sheet = book.sheets[wantedSheetName];
      if (sheet == null) {
        for (final entry in book.sheets.entries) {
          final k = entry.key.trim().toLowerCase();
          if (k == wantedSheetName.trim().toLowerCase() ||
              k.contains('school form 2')) {
            sheet = entry.value;
            break;
          }
        }
      }
      sheet ??= book.sheets.values.first;
      final chosenName = book.sheets.entries
          .firstWhere(
            (e) => e.value == sheet,
            orElse: () => book.sheets.entries.first,
          )
          .key;
      debugPrint('SF2: using sheet: $chosenName');

      // Populate header fields (Step 3)
      final schoolName = dotenv.env['SCHOOL_NAME'] ?? 'Oro Site High School';
      final schoolId = '302258';
      final division = dotenv.env['DIVISION'] ?? '';
      final region = dotenv.env['REGION'] ?? '';

      _fillHeaderField(sheet, 'Name of School', schoolName);
      _fillHeaderField(sheet, 'School ID', schoolId);
      if (division.isNotEmpty) _fillHeaderField(sheet, 'Division', division);
      if (region.isNotEmpty) _fillHeaderField(sheet, 'Region', region);
      _fillHeaderField(sheet, 'School Year', _computeSchoolYear(month));
      _fillHeaderField(
        sheet,
        'Report for the Month',
        '${_monthName(month.month)} ${month.year}',
      );
      if (classroom?.gradeLevel != null) {
        _fillHeaderField(
          sheet,
          'Grade Level',
          classroom!.gradeLevel.toString(),
        );
      }
      final sectionStr = classroom?.title ?? course.title;
      _fillHeaderField(sheet, 'Section', sectionStr);

      // Prepare day columns (Step 4: detect only; writing marks in next step)
      final dayCols = _findDayColumnsInTemplate(sheet);
      if (dayCols == null) {
        debugPrint('SF2: day columns not found');
      } else {
        debugPrint(
          'SF2: day headerRow=\\${dayCols.headerRow} cols=\\${dayCols.dayToCol.length}',
        );
      }

      // Step 5: Populate student identity rows (No., LRN, LEARNER'S NAME)
      // Locate header columns for No., LRN, and Learner's Name
      ({int row, int col})? nameLabel =
          _findCellContainingText(sheet, "LEARNER'S NAME") ??
          _findCellContainingText(sheet, 'LEARNER');
      final int headerRowId = nameLabel?.row ?? (dayCols?.headerRow ?? 0);
      int colName = nameLabel?.col ?? -1;
      int colLrn = -1;
      int colNo = -1;
      if (headerRowId < sheet.rows.length) {
        final row = sheet.rows[headerRowId];
        for (int c = 0; c < row.length; c++) {
          final t = row[c]?.value?.toString().toLowerCase().trim() ?? '';
          if (t.contains('lrn')) colLrn = c;
          final tn = t.replaceAll('.', '').replaceAll(':', '').trim();
          if (tn == 'no') colNo = c;
          if (colLrn >= 0 && colNo >= 0 && colName >= 0) break;
        }
      }
      if (colName < 0 && headerRowId < sheet.rows.length) {
        // Try a looser search on the header row
        final row = sheet.rows[headerRowId];
        for (int c = 0; c < row.length; c++) {
          final t = row[c]?.value?.toString().toLowerCase() ?? '';
          if (t.contains('learn')) {
            colName = c;
            break;
          }
        }
      }
      if (colName >= 1 && colLrn < 0) colLrn = colName - 1;
      if (colLrn >= 1 && colNo < 0) colNo = colLrn - 1;

      debugPrint(
        'SF2: headerRowId=$headerRowId colNo=$colNo colLrn=$colLrn colName=$colName',
      );

      final int dataStartRow = dayCols != null
          ? _computeDataStartRow(sheet, dayCols)
          : (headerRowId + 1);

      // Create a sorted copy of students by name
      List<Map<String, dynamic>> sorted = [..._students];
      sorted.sort(
        (a, b) => (a['full_name'] ?? a['name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo(
              (b['full_name'] ?? b['name'] ?? '').toString().toLowerCase(),
            ),
      );

      // Helper to format name as "LAST, FIRST MI" when possible
      String formatStudentName(Map<String, dynamic> s) {
        final last = (s['last_name'] ?? s['lastname'] ?? s['surname'] ?? '')
            .toString()
            .trim();
        final first = (s['first_name'] ?? s['firstname'] ?? '')
            .toString()
            .trim();
        final middleRaw =
            (s['middle_initial'] ??
                    s['mi'] ??
                    s['middle_name'] ??
                    s['middlename'] ??
                    '')
                .toString()
                .trim();
        final mi = middleRaw.isNotEmpty ? middleRaw[0].toUpperCase() : '';
        if (last.isNotEmpty && first.isNotEmpty) {
          return mi.isNotEmpty ? '$last, $first $mi' : '$last, $first';
        }
        return (s['full_name'] ?? s['name'] ?? '').toString();
      }

      // Write identity rows
      int totalX = 0;
      final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      debugPrint(
        'SF2: dataStartRow=$dataStartRow students=\\${sorted.length} daysInMonth=\\$daysInMonth',
      );
      for (int i = 0; i < sorted.length; i++) {
        final s = sorted[i];
        final rowIndex = dataStartRow + i;
        final sid = (s['student_id'] ?? s['id']).toString();
        final lrn = (s['lrn'] ?? '').toString();
        final nameStr = formatStudentName(s);
        if (i < 3) {
          debugPrint(
            'SF2: write row=\\$rowIndex sid=\\$sid name=\\"$nameStr\\" lrn=\\"$lrn\\"',
          );
        }

        if (colNo >= 0) {
          sheet
              .cell(
                xls.CellIndex.indexByColumnRow(
                  columnIndex: colNo,
                  rowIndex: rowIndex,
                ),
              )
              .value = xls.TextCellValue(
            (i + 1).toString(),
          );
        }
        if (colLrn >= 0) {
          sheet
              .cell(
                xls.CellIndex.indexByColumnRow(
                  columnIndex: colLrn,
                  rowIndex: rowIndex,
                ),
              )
              .value = xls.TextCellValue(
            lrn,
          );
        }
        if (colName >= 0) {
          sheet
              .cell(
                xls.CellIndex.indexByColumnRow(
                  columnIndex: colName,
                  rowIndex: rowIndex,
                ),
              )
              .value = xls.TextCellValue(
            nameStr,
          );
        }

        // Step 6: Absence marking (X for absences only), skip weekends
        if (dayCols != null) {
          final byDay = monthMap[sid] ?? const <int, String>{};
          for (final entry in dayCols.dayToCol.entries) {
            final d = entry.key;
            final col = entry.value;
            if (d < 1 || d > daysInMonth) continue;
            final dt = DateTime(month.year, month.month, d);
            if (dt.weekday == DateTime.saturday ||
                dt.weekday == DateTime.sunday) {
              continue; // leave weekends blank
            }
            final code = (byDay[d] ?? '').toUpperCase();
            if (code == 'A') {
              sheet
                  .cell(
                    xls.CellIndex.indexByColumnRow(
                      columnIndex: col,
                      rowIndex: rowIndex,
                    ),
                  )
                  .value = xls.TextCellValue(
                'X',
              );
              totalX++;
            }
          }
        }
      }

      debugPrint('SF2: total X written: $totalX');

      // Save result for visual verification
      final sectionSanitized = sectionStr.replaceAll(' ', '');
      final fileName =
          'SF2_${sectionSanitized}_${_monthName(month.month)}_${month.year}_Q$_selectedQuarter.xlsx';
      final bytes = book.encode();
      if (bytes == null) throw Exception('Failed to encode workbook');
      await saveExcelBytes(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported (template-based): $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Template export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<bool> _exportSf2ViaXmlInjection({
    required DateTime month,
    required dynamic classroom,
    required dynamic course,
    required List<String> studentIds,
    required Map<String, Map<int, String>> monthMap,
  }) async {
    try {
      final templateBytes = await _loadSf2TemplateBytes();
      debugPrint('SF2: XML: template bytes=${templateBytes.length}');

      // Unzip .xlsx
      final arc = ZipDecoder().decodeBytes(templateBytes, verify: false);
      String norm(String p) => p.replaceAll('\\', '/');
      ArchiveFile? fileWhere(bool Function(ArchiveFile f) test) {
        for (final f in arc.files) {
          if (test(f)) return f;
        }
        return null;
      }

      // Locate workbook & rels
      final workbook =
          fileWhere((f) => norm(f.name).endsWith('xl/workbook.xml')) ??
          fileWhere((f) => norm(f.name).toLowerCase().endsWith('workbook.xml'));
      if (workbook == null) throw Exception('workbook.xml not found');
      final rels =
          fileWhere(
            (f) => norm(f.name).endsWith('xl/_rels/workbook.xml.rels'),
          ) ??
          fileWhere(
            (f) => norm(f.name).toLowerCase().endsWith('workbook.xml.rels'),
          );

      final wbDoc = XmlDocument.parse(
        utf8.decode(workbook.content as List<int>),
      );
      Map<String, String> relMap = {};
      if (rels != null) {
        final relDoc = XmlDocument.parse(
          utf8.decode(rels.content as List<int>),
        );
        for (final r in relDoc.findAllElements('Relationship')) {
          final id = r.getAttribute('Id');
          final tgt = r.getAttribute('Target');
          if (id != null && tgt != null) relMap[id] = tgt;
        }
      }

      // Choose the SF2 sheet
      XmlElement? chosenSheetElem;
      for (final s in wbDoc.findAllElements('sheet')) {
        final name = s.getAttribute('name')?.trim().toLowerCase();
        if (name == 'school form 2 (sf2)'.toLowerCase() ||
            (name != null && name.contains('school form 2'))) {
          chosenSheetElem = s;
          break;
        }
      }
      final sheetsList = wbDoc.findAllElements('sheet').toList();
      chosenSheetElem ??= sheetsList.isNotEmpty ? sheetsList.first : null;
      if (chosenSheetElem == null) throw Exception('No <sheet> in workbook');
      final rid =
          chosenSheetElem.getAttribute('r:id') ??
          chosenSheetElem.getAttribute('id');
      final rawTarget =
          (rid != null ? relMap[rid] : null) ?? 'worksheets/sheet1.xml';
      final sheetPath = rawTarget.startsWith('xl/')
          ? rawTarget
          : 'xl/$rawTarget';
      final sheetFile =
          fileWhere((f) => norm(f.name) == norm(sheetPath)) ??
          fileWhere((f) => norm(f.name).endsWith(norm(rawTarget))) ??
          fileWhere((f) => norm(f.name).toLowerCase().endsWith('sheet1.xml'));
      if (sheetFile == null) throw Exception('Sheet xml not found: $sheetPath');

      final sstFile = fileWhere(
        (f) => norm(f.name).endsWith('xl/sharedStrings.xml'),
      );
      List<String> shared = [];
      if (sstFile != null) {
        final sstDoc = XmlDocument.parse(
          utf8.decode(sstFile.content as List<int>),
        );
        for (final si in sstDoc.findAllElements('si')) {
          final buf = StringBuffer();
          for (final t in si.findAllElements('t')) {
            buf.write(t.innerText);
          }
          shared.add(buf.toString());
        }
      }

      String colToLetters(int col) {
        var s = '';
        while (col > 0) {
          final r = (col - 1) % 26;
          s = String.fromCharCode(65 + r) + s;
          col = (col - 1) ~/ 26;
        }
        return s;
      }

      int lettersToCol(String s) {
        int n = 0;
        for (final ch in s.codeUnits) {
          if (ch < 65 || ch > 90) continue;
          n = n * 26 + (ch - 64);
        }
        return n;
      }

      (int row, int col) parseRef(String r) {
        final m = RegExp(r'([A-Z]+)(\d+)').firstMatch(r)!;
        return (int.parse(m.group(2)!), lettersToCol(m.group(1)!));
      }

      final sheetDoc = XmlDocument.parse(
        utf8.decode(sheetFile.content as List<int>),
      );
      final sheetData = sheetDoc.findAllElements('sheetData').first;

      XmlElement? findRow(int r) {
        for (final row in sheetData.findElements('row')) {
          if (row.getAttribute('r') == r.toString()) return row;
        }
        return null;
      }

      XmlElement? findCell(XmlElement row, int col) {
        final ref = '${colToLetters(col)}${row.getAttribute('r')}';
        for (final c in row.findElements('c')) {
          if (c.getAttribute('r') == ref) return c;
        }
        return null;
      }

      String readCell(XmlElement c) {
        final t = c.getAttribute('t');
        if (t == 's') {
          final v = c.getElement('v')?.innerText;
          if (v == null) return '';
          final i = int.tryParse(v) ?? -1;
          return (i >= 0 && i < shared.length) ? shared[i] : '';
        }
        if (t == 'inlineStr') {
          return c
                  .getElement('is')
                  ?.findAllElements('t')
                  .map((e) => e.innerText)
                  .join() ??
              '';
        }
        return c.getElement('v')?.innerText ?? '';
      }

      String textAt(int r, int c) {
        final row = findRow(r);
        if (row == null) return '';
        final cell = findCell(row, c);
        if (cell == null) return '';
        return readCell(cell);
      }

      int xmlWrites = 0;
      int xmlSkips = 0;
      void setTextAt(int r, int c, String v) {
        final row = findRow(r);
        if (row == null) {
          debugPrint('SF2: XML skip write missing row r=$r');
          xmlSkips++;
          return;
        }
        final ref = '${colToLetters(c)}$r';
        var cell = findCell(row, c);
        if (cell == null) {
          debugPrint('SF2: XML skip write missing cell $ref');
          xmlSkips++;
          return;
        }
        // preserve style 's' if present; replace content with inlineStr
        cell.attributes.removeWhere((a) => a.name.local == 't');
        cell.attributes.add(XmlAttribute(XmlName('t'), 'inlineStr'));
        cell.children.removeWhere(
          (n) =>
              n is XmlElement &&
              (n.name.local == 'v' ||
                  n.name.local == 'f' ||
                  n.name.local == 'is'),
        );
        final isElem = XmlElement(XmlName('is'));
        isElem.children.add(XmlElement(XmlName('t'), [], [XmlText(v)]));
        cell.children.add(isElem);
        xmlWrites++;
      }

      bool isEmptyAt(int r, int c) => textAt(r, c).trim().isEmpty;

      // Find header cells and day columns
      ({int row, int col})? findCellContaining(String sub) {
        final needle = sub.toLowerCase();
        for (final c in sheetDoc.findAllElements('c')) {
          final rAttr = c.getAttribute('r');
          if (rAttr == null) continue;
          final txt = readCell(c).toLowerCase();
          if (txt.contains(needle)) {
            final pr = parseRef(rAttr);
            return (row: pr.$1, col: pr.$2);
          }
        }
        return null;
      }

      // Day columns detection: numeric scan first, then DOW-label heuristic
      Map<int, int> dayToCol = {};
      int headerRow = 0;

      // Numeric day scan across all cells
      final rowMap = <int, Map<int, int>>{};
      int scan = 0, hits = 0;
      for (final c in sheetDoc.findAllElements('c')) {
        scan++;
        final rAttr = c.getAttribute('r');
        if (rAttr == null) continue;
        final txt = readCell(c).trim();
        int? d = int.tryParse(txt);
        if (d == null) {
          final dd = double.tryParse(txt);
          if (dd != null && dd == dd.roundToDouble()) d = dd.toInt();
        }
        if (d != null && d >= 1 && d <= 31) {
          hits++;
          final pr = parseRef(rAttr);
          final map = rowMap.putIfAbsent(pr.$1, () => {});
          map[d] = pr.$2;
        }
      }
      int bestCount = 0;
      rowMap.forEach((r, m) {
        if (m.length > bestCount) {
          bestCount = m.length;
          headerRow = r;
          dayToCol = m;
        }
      });
      debugPrint(
        'SF2: numeric day-scan cells=$scan hits=$hits rows=${rowMap.length} topRow=$headerRow cnt=$bestCount',
      );
      if (bestCount < 3) {
        // Treat as not found; fall back to DOW heuristic
        dayToCol = {};
      }

      // Fallback: DOW row heuristic
      if (dayToCol.isEmpty) {
        debugPrint('SF2: numeric day-scan found none; trying DOW heuristic');
        int bestDowCount = 0;
        int dowRow = 0;
        final colToken = <int, String>{};
        for (final row in sheetData.findElements('row')) {
          int cnt = 0;
          final cur = <int, String>{};
          for (final c in row.findElements('c')) {
            final rAttr = c.getAttribute('r');
            if (rAttr == null) continue;
            final s0 = readCell(
              c,
            ).trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
            String? tok;
            if (s0 == 'M') {
              tok = 'M';
            } else if (s0 == 'T') {
              tok = 'T';
            } else if (s0 == 'W') {
              tok = 'W';
            } else if (s0 == 'TH') {
              tok = 'TH';
            } else if (s0 == 'F') {
              tok = 'F';
            } else if (s0 == 'SAT') {
              tok = 'SAT';
            } else if (s0 == 'SUN') {
              tok = 'SUN';
            }
            if (tok != null) {
              final pr = parseRef(rAttr);
              cur[pr.$2] = tok;
              cnt++;
            }
          }
          if (cnt > bestDowCount) {
            bestDowCount = cnt;
            dowRow = int.tryParse(row.getAttribute('r') ?? '0') ?? 0;
            colToken
              ..clear()
              ..addAll(cur);
          }
        }
        debugPrint('SF2: DOW heuristic row=$dowRow tokens=$bestDowCount');
        if (bestDowCount >= 5) {
          final wkCols = <int>[];
          final wkToks = <String>[];
          final sortedCols = colToken.keys.toList()..sort();
          for (final col in sortedCols) {
            final tok = colToken[col]!;
            if (tok == 'M' ||
                tok == 'T' ||
                tok == 'W' ||
                tok == 'TH' ||
                tok == 'F') {
              wkCols.add(col);
              wkToks.add(tok);
            }
          }
          debugPrint('SF2: weekday header columns=${wkCols.length}');
          String letterFor(int wd) {
            switch (wd) {
              case DateTime.monday:
                return 'M';
              case DateTime.tuesday:
                return 'T';
              case DateTime.wednesday:
                return 'W';
              case DateTime.thursday:
                return 'TH';
              case DateTime.friday:
                return 'F';
              case DateTime.saturday:
                return 'SAT';
              case DateTime.sunday:
                return 'SUN';
              default:
                return '';
            }
          }

          dayToCol = {};
          int p = 0;
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          for (int d = 1; d <= daysInMonth; d++) {
            final wd = DateTime(month.year, month.month, d).weekday;
            final want = letterFor(wd);
            if (want == 'SAT' || want == 'SUN') continue;
            while (p < wkToks.length && wkToks[p] != want) {
              p++;
            }
            if (p >= wkToks.length) break;
            dayToCol[d] = wkCols[p];
            p++;
          }
          headerRow =
              dowRow -
              1; // assume DOW row is the one visible; data starts below it
          debugPrint(
            'SF2: DOW heuristic mapped days=${dayToCol.length} headerRow=$headerRow',
          );
        }
      }

      if (dayToCol.isEmpty) throw Exception('Day header not found');
      debugPrint('SF2: day headerRow=$headerRow cols=${dayToCol.length}');

      // Data start row (skip DOW row if present)
      bool hasDow() {
        final next = headerRow + 1;
        const dows = ['m', 't', 'w', 'th', 'f', 'sat', 'sun'];
        for (final col in dayToCol.values) {
          final s = textAt(next, col).toLowerCase();
          if (s.isNotEmpty && dows.any((d) => s.contains(d))) return true;
        }
        return false;
      }

      final dataStartRow = headerRow + (hasDow() ? 2 : 1);

      // Identity columns: derive strictly from first day column to avoid label/merge ambiguity
      final minDayCol = dayToCol.values.reduce((a, b) => a < b ? a : b);
      ({int row, int col})? anchor(String s) => findCellContaining(s);
      final candName = anchor("learner") ?? anchor("learner's name");
      final candNo = anchor("no.");
      // LRN column is disabled for SF2; shift Name one column left (No at far left)
      int colName = minDayCol - 2;
      int colNo = colName - 1;
      if (colName < 1) colName = 1;
      if (colNo < 1) colNo = 1;
      debugPrint(
        'SF2: minDayCol=$minDayCol anchors -> name=${candName?.col}/${candName?.row} no=${candNo?.col}/${candNo?.row}',
      );
      debugPrint(
        'SF2: cols (derived from day grid) -> No=$colNo Name=$colName (LRN disabled)',
      );

      // Header fills
      String monthLabel = '${_monthName(month.month)} ${month.year}';
      final schoolName = dotenv.env['SCHOOL_NAME'] ?? 'Oro Site High School';
      final schoolId = dotenv.env['SCHOOL_ID'] ?? '302258';
      final division = dotenv.env['DIVISION'] ?? '';
      final region = dotenv.env['REGION'] ?? '';
      final sy =
          (_sf2OverrideSchoolYear != null &&
              _sf2OverrideSchoolYear!.trim().isNotEmpty)
          ? _sf2OverrideSchoolYear!.trim()
          : _computeSchoolYear(month);
      if (_sf2OverrideSchoolYear != null &&
          _sf2OverrideSchoolYear!.trim().isNotEmpty) {
        debugPrint('SF2: override School Year from dialog -> "$sy"');
      }
      void fillRightOf(
        String label,
        String value, {
        int maxOffset = 16,
        int minOffset = 1,
      }) {
        final p = findCellContaining(label);
        debugPrint('SF2: header locate "$label" => r=${p?.row} c=${p?.col}');
        if (p == null) return;
        // Start at minOffset to avoid merged label cells right next to the title
        for (int off = minOffset; off <= maxOffset; off++) {
          final rr = p.row;
          final cc = p.col + off;
          final row = findRow(rr);
          final cell = row != null ? findCell(row, cc) : null;
          if (row != null && cell != null && isEmptyAt(rr, cc)) {
            setTextAt(rr, cc, value);
            debugPrint(
              'SF2: header write "$label" -> r=$rr c=$cc (offset $off) value="$value"',
            );
            return;
          }
        }
        debugPrint(
          'SF2: header "$label" no existing empty cell to the right; skipped write',
        );
      }

      bool fillHeaderByLabels(
        String field,
        List<String> labels,
        String value, {
        int maxOffset = 16,
      }) {
        for (final label in labels) {
          final p = findCellContaining(label);
          debugPrint(
            'SF2: header scan $field candidate "$label" => r=${p?.row} c=${p?.col}',
          );
          if (p != null) {
            fillRightOf(label, value, maxOffset: maxOffset);
            debugPrint('SF2: header "$field" written using label "$label"');
            return true;
          }
        }

        // Not found
        debugPrint('SF2: header "$field" not present in template; skipping');
        return false;
      }

      // Write to the first empty cell within a fixed row/column range
      void writeFirstEmptyInRange({
        required String field,
        required int row,
        required List<int> cols,
        required String value,
      }) {
        for (final c in cols) {
          if (isEmptyAt(row, c)) {
            setTextAt(row, c, value);
            debugPrint(
              'SF2: header write "$field" (fixed) -> r=$row c=$c value="$value"',
            );
            return;
          }
        }
        debugPrint(
          'SF2: header "$field" no empty cell found in fixed range r=$row cols=' +
              cols.join(','),
        );
      }

      fillRightOf('Name of School', schoolName);

      fillRightOf('School ID', schoolId);
      fillHeaderByLabels('Division', [
        'Division',
        'Division:',
        'Schools Division',
        'School Division',
        'Division of',
      ], division);
      fillHeaderByLabels('Region', [
        'Region',
        'Region:',
        'Region No.',
        'Region No',
        'Region Number',
      ], region);
      // Fixed-position header writes per template spec
      // School Year -> row 6, columns K-O (11..15)
      writeFirstEmptyInRange(
        field: 'School Year',
        row: 6,
        cols: const [11, 12, 13, 14, 15],
        value: sy,
      );

      // Report for the Month -> row 6, columns X-AC (24..29)
      writeFirstEmptyInRange(
        field: 'Month',
        row: 6,
        cols: const [24, 25, 26, 27, 28, 29],
        value: monthLabel,
      );
      // Grade Level: prefer dialog override; otherwise use classroom value
      final gradeFromDialog = (_sf2OverrideGradeLevel ?? '').trim();
      String? gradeNumeric;
      if (gradeFromDialog.isNotEmpty) {
        final m = RegExp(r'\d+').firstMatch(gradeFromDialog);
        gradeNumeric = m != null ? m.group(0) : gradeFromDialog;
        debugPrint(
          'SF2: override Grade Level from dialog -> "${gradeNumeric ?? ''}" (raw="$gradeFromDialog")',
        );
      } else {
        final gradeLevelVal = (classroom is Map
            ? (classroom['grade_level'] ?? classroom['gradeLevel'])
            : classroom?.gradeLevel);
        if (gradeLevelVal != null && gradeLevelVal.toString().isNotEmpty) {
          final gv = gradeLevelVal.toString();
          final match = RegExp(r'\d+').firstMatch(gv);
          gradeNumeric = match != null ? match.group(0)! : gv;
          debugPrint(
            'SF2: header write Grade Level numeric="$gradeNumeric" source="$gv"',
          );
        }
      }
      if (gradeNumeric != null && gradeNumeric.isNotEmpty) {
        // Grade Level -> row 8, columns X-Y (24..25)
        writeFirstEmptyInRange(
          field: 'Grade Level',
          row: 8,
          cols: const [24, 25],
          value: gradeNumeric,
        );
      }

      // Section: prefer dialog override; otherwise classroom/course title
      final sectionOverride = (_sf2OverrideSection ?? '').trim();
      final sectionStr = sectionOverride.isNotEmpty
          ? sectionOverride
          : ((classroom is Map ? classroom['title'] : classroom?.title) ??
                (course is Map ? course['title'] : course?.title) ??
                '');
      if (sectionOverride.isNotEmpty) {
        debugPrint('SF2: override Section from dialog -> "$sectionStr"');
      }
      // Section -> row 8, columns AC-AH (29..34) using first-empty-in-range strategy
      if (sectionStr.trim().isNotEmpty) {
        writeFirstEmptyInRange(
          field: 'Section',
          row: 8,
          cols: const [29, 30, 31, 32, 33, 34],
          value: sectionStr.trim(),
        );
      } else {
        debugPrint('SF2: header "Section" empty; skipping');
      }

      // Populate day numbers (row 11) based on DOW labels in row 12 across columns 4..28
      // This is idempotent and safe: we only write the numeric labels and do not change
      // any existing structure or student data.
      try {
        final dowCols = <int>[];
        final dowToks = <String>[];
        for (int c = 4; c <= 28; c++) {
          final s0 = textAt(12, c).trim().toUpperCase();
          String tok = '';
          if (s0 == 'TH' || s0.contains('TH')) {
            tok = 'TH';
          } else if (s0.startsWith('M')) {
            tok = 'M';
          } else if (s0.startsWith('T')) {
            // Tuesday is typically just 'T' in the template
            tok = 'T';
          } else if (s0.startsWith('W')) {
            tok = 'W';
          } else if (s0.startsWith('F')) {
            tok = 'F';
          }
          if (tok.isNotEmpty) {
            dowCols.add(c);
            dowToks.add(tok);
          }
        }
        debugPrint('SF2: day-number scan DOW row=12 cols=${dowCols.length}');

        String letterFor(int wd) {
          switch (wd) {
            case DateTime.monday:
              return 'M';
            case DateTime.tuesday:
              return 'T';
            case DateTime.wednesday:
              return 'W';
            case DateTime.thursday:
              return 'TH';
            case DateTime.friday:
              return 'F';
            case DateTime.saturday:
              return 'SAT';
            case DateTime.sunday:
              return 'SUN';
            default:
              return '';
          }
        }

        final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        int p = 0; // pointer into DOW sequence (row 12)
        for (int d = 1; d <= daysInMonth; d++) {
          final dt = DateTime(month.year, month.month, d);
          final want = letterFor(dt.weekday);
          if (want == 'SAT' || want == 'SUN') {
            continue; // skip weekends entirely
          }

          while (p < dowToks.length && dowToks[p] != want) {
            p++;
          }
          if (p >= dowToks.length) {
            debugPrint('SF2: day number mapping exhausted at d=$d want=$want');
            break;
          }
          final col = dowCols[p];
          setTextAt(11, col, d.toString());
          final y = dt.year.toString().padLeft(4, '0');
          final mm = dt.month.toString().padLeft(2, '0');
          final dd = dt.day.toString().padLeft(2, '0');
          debugPrint(
            'SF2: day number write r=11 c=$col value="${d.toString()}" (dow=$want, date=$y-$mm-$dd)',
          );
          p++;
        }
      } catch (e) {
        debugPrint('SF2: day-number population skipped (error): $e');
      }

      // Prepare roster
      final sorted = List<Map<String, dynamic>>.from(_students);

      String normalizeSpaces(String s) =>
          s.replaceAll(RegExp(r'\s+'), ' ').trim();
      String sortKey(Map s) {
        final ln = (s['last_name'] ?? s['lastName'] ?? '').toString();
        final fn = (s['first_name'] ?? s['firstName'] ?? '').toString();
        if (ln.isNotEmpty || fn.isNotEmpty) {
          return '${ln.toLowerCase()},${fn.toLowerCase()}';
        }
        final full = (s['full_name'] ?? s['name'] ?? '').toString();
        if (full.isNotEmpty) return normalizeSpaces(full).toLowerCase();
        final sid = (s['student_id'] ?? s['id'] ?? '').toString();
        return sid.toLowerCase();
      }

      sorted.sort((a, b) => sortKey(a).compareTo(sortKey(b)));

      String fmtName(Map s) {
        // Prefer explicit parts if present
        String ln = (s['last_name'] ?? s['lastName'] ?? '').toString().trim();
        String fn = (s['first_name'] ?? s['firstName'] ?? '').toString().trim();
        String mn = (s['middle_name'] ?? s['middleName'] ?? '')
            .toString()
            .trim();
        if (ln.isNotEmpty || fn.isNotEmpty) {
          final midPart = mn.isNotEmpty ? ' $mn' : '';
          return ln.isNotEmpty ? '$ln, $fn$midPart' : '$fn$midPart';
        }

        // Fall back to profile display fields
        final display = (s['display_name'] ?? s['full_name'] ?? s['name'] ?? '')
            .toString()
            .trim();
        if (display.isEmpty) return '';

        // If already formatted with a comma, keep as-is
        if (display.contains(',')) return normalizeSpaces(display);

        // Reorder: Last, First Middle...
        final toks = normalizeSpaces(display).split(' ');
        if (toks.length == 1) return toks.first; // single name
        ln = toks.last;
        fn = toks.first;
        final mids = toks.length > 2
            ? toks.sublist(1, toks.length - 1).join(' ')
            : '';
        final midPart = mids.isNotEmpty ? ' $mids' : '';
        return '$ln, $fn$midPart';
      }

      bool isWeekend(int d) {
        final wd = DateTime(month.year, month.month, d).weekday;
        return wd == DateTime.saturday || wd == DateTime.sunday;
      }

      // Detect TARDY total column
      int? colTardy;
      final tardyPos =
          findCellContaining('TARDY') ?? findCellContaining('Tardy');
      if (tardyPos != null) {
        colTardy = tardyPos.col;
        debugPrint(
          'SF2: TARDY column detected at col=$colTardy (row=${tardyPos.row})',
        );
      } else {
        debugPrint('SF2: TARDY label not found; will skip tardy counts');
      }

      // Write rows
      int totalX = 0;
      int rowIdx = dataStartRow;
      for (final s in sorted) {
        final sid = (s['student_id'] ?? s['id'] ?? '').toString();
        if (!studentIds.contains(sid)) continue;
        final noVal = (rowIdx - dataStartRow + 1).toString();
        setTextAt(rowIdx, colNo, noVal);
        debugPrint('SF2: row=$rowIdx No=$noVal at col=$colNo');

        // LRN population disabled for SF2

        final rawDisplay =
            ((s['display_name'] ?? s['full_name'] ?? s['name'] ?? '')
                .toString()
                .trim());
        final name = fmtName(s).trim();
        debugPrint(
          'SF2: row=$rowIdx raw name from DB: "$rawDisplay" formatted to: "$name"',
        );
        setTextAt(rowIdx, colName, name);
        debugPrint('SF2: row=$rowIdx Name="$name" at col=$colName');
        final map = monthMap[sid] ?? {};
        int tardyCount = 0;
        for (final e in dayToCol.entries) {
          final day = e.key;
          if (day < 1 || day > 31) {
            final codeRaw = map[day];
            if (codeRaw != null && codeRaw.toString().isNotEmpty) {
              debugPrint('SF2: row=$rowIdx day=$day out-of-range; skip');
            }
            continue;
          }
          if (isWeekend(day)) {
            final codeRaw = map[day];
            if (codeRaw != null && codeRaw.toString().isNotEmpty) {
              debugPrint('SF2: row=$rowIdx day=$day weekend; skip');
            }
            continue;
          }
          final code = (map[day] ?? '').toString().toUpperCase();
          if (code == 'A') {
            setTextAt(rowIdx, e.value, 'X');
            debugPrint('SF2: row=$rowIdx day=$day write X at col=${e.value}');
            totalX++;
          } else if (code == 'L') {
            tardyCount++;
            debugPrint('SF2: row=$rowIdx day=$day status=L -> tardy+1');
          } else if (code.isNotEmpty) {
            debugPrint('SF2: row=$rowIdx day=$day status=$code -> ignored');
          }
        }
        if (colTardy != null) {
          setTextAt(
            rowIdx,
            colTardy,
            tardyCount == 0 ? '' : tardyCount.toString(),
          );
          debugPrint(
            'SF2: row=$rowIdx tardy=$tardyCount written at col=$colTardy',
          );
        }
        rowIdx++;
      }
      debugPrint('SF2: total X written (XML): $totalX');
      debugPrint('SF2: XML cell writes=$xmlWrites skips=$xmlSkips');

      // Save back into zip (build a new archive to avoid modifying unmodifiable lists)
      final updated = utf8.encode(sheetDoc.toXmlString());
      final newArc = Archive();
      for (final f in arc.files) {
        if (norm(f.name) == norm(sheetFile.name)) {
          newArc.addFile(ArchiveFile(f.name, updated.length, updated));
        } else {
          final c = f.content;
          List<int> bytes;
          if (c is List<int>) {
            bytes = List<int>.from(c);
          } else {
            bytes = utf8.encode(c.toString());
          }
          newArc.addFile(ArchiveFile(f.name, bytes.length, bytes));
        }
      }
      final outBytes = ZipEncoder().encode(newArc);
      if (outBytes == null) throw Exception('Zip encode failed');

      final sectionSanitized = sectionStr.replaceAll(' ', '');
      final fileName =
          'SF2_${sectionSanitized}_${_monthName(month.month)}_${month.year}_Q$_selectedQuarter.xlsx';
      await saveExcelBytes(outBytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported (template preserved): $fileName')),
        );
      }
      return true;
    } catch (e) {
      debugPrint('SF2: XML injection failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _pickSf2ParamsDialog(DateTime initial) async {
    int year = initial.year;
    int month = initial.month;
    final gradeController = TextEditingController(
      text: (_selectedClassroom?.gradeLevel)?.toString() ?? '',
    );
    final sectionController = TextEditingController(
      text: (_selectedClassroom?.title ?? ''),
    );
    final syController = TextEditingController(
      text: _computeSchoolYear(initial),
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Export SF2'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Month'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Prev Year',
                          onPressed: () => setState(() => year--),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '$year',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          tooltip: 'Next Year',
                          onPressed: () => setState(() => year++),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        const names = [
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
                        final m = i + 1;
                        final selected = m == month;
                        return ChoiceChip(
                          label: Text(names[i]),
                          selected: selected,
                          onSelected: (_) => setState(() => month = m),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: syController,
                      decoration: const InputDecoration(
                        labelText: 'School Year (e.g., 2025-2026)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Grade Level (numeric, e.g., 10)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop({
                  'month': DateTime(year, month, 1),
                  'schoolYear': syController.text.trim(),
                  'gradeLevel': gradeController.text.trim(),
                  'section': sectionController.text.trim(),
                }),
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onExportSf2Pressed() async {
    if (_selectedCourse == null || _selectedQuarter == null) return;
    final params = await _pickSf2ParamsDialog(_visibleMonth);
    if (params == null) return;
    final DateTime chosen = (params['month'] as DateTime);
    final String sy = (params['schoolYear'] as String?)?.trim() ?? '';
    final String grade = (params['gradeLevel'] as String?)?.trim() ?? '';
    final String section = (params['section'] as String?)?.trim() ?? '';
    setState(() {
      _sf2OverrideSchoolYear = sy;
      _sf2OverrideGradeLevel = grade;
      _sf2OverrideSection = section;
    });
    await _exportMonthlyAttendanceSf2TemplateBased(
      selectedMonth: chosen,
      overrideSchoolYear: sy,
      overrideGradeLevel: grade,
      overrideSection: section,
    );
  }

  Widget _buildExportButton() {
    final enabled =
        _selectedClassroom != null &&
        _selectedCourse != null &&
        _selectedQuarter != null;
    return OutlinedButton.icon(
      onPressed: enabled && !_isExporting ? _onExportSf2Pressed : null,
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined),
      label: const Text('Export SF2'),
    );
  }

  // Compact icon button to set the active quarter (with tooltip)
  Widget _buildSetActiveQuarterIconButton() {
    final enabled = _selectedQuarter != null && !_isSettingActiveQuarter;
    return Tooltip(
      message: 'Set Active Quarter',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          tooltip: 'Set Active Quarter',
          onPressed: enabled ? _confirmAndSetActiveQuarter : null,
          icon: _isSettingActiveQuarter
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.lock_outline, color: Colors.deepPurple.shade700),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  // Right sidebar (calendar)
  Widget _buildRightSidebar() {
    final today = _normalizeDate(DateTime.now());
    final DateTime? selected = _selectedDate != null
        ? _normalizeDate(_selectedDate!)
        : null;
    final bool isTodaySelected =
        selected != null && _isSameDate(selected, today);

    return Container(
      width: 300,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calendar card styled like dashboard calendar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month - 1,
                                );
                              });
                              _loadMarkedDatesForVisibleMonth();
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                _monthYearLabel(_visibleMonth),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next month',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month + 1,
                                );
                              });
                              _loadMarkedDatesForVisibleMonth();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildWeekdayHeader(),
                      const SizedBox(height: 4),
                      Expanded(child: _buildMonthGrid()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Save button anchored at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: FilledButton.icon(
              onPressed:
                  (_isSaving ||
                      !(_selectedClassroom != null &&
                          _selectedCourse != null &&
                          _selectedDate != null &&
                          _selectedQuarter != null &&
                          _statusByStudent.isNotEmpty &&
                          isTodaySelected))
                  ? null
                  : () => _saveAttendance(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Attendance'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isWeekend = i >= 5; // Saturday & Sunday
          return Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWeekend ? Colors.redAccent : Colors.black87,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthGrid() {
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
        final bool isFuture = date.isAfter(today);

        final bool isWeekend =
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
        final Color circleColor = isSelected
            ? Colors.deepOrange
            : (isToday ? Colors.blueAccent : Colors.transparent);
        final Color textColor = isFuture
            ? Colors.grey.shade400
            : ((isSelected || isToday)
                  ? Colors.white
                  : (isWeekend ? Colors.redAccent : Colors.black87));

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadAttendanceForSelectedDate();
                },
          child: Stack(
            children: [
              // Circular day highlight like dashboard calendar
              Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Event/marked date indicator (red dot)
              if (_markedDateKeys.contains(_dateKey(date)))
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String name) {
    return name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _historicalBanner(DateTime date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing attendance for ${_formatShortDate(date)} (read-only)',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildLeftPanel(),
          const VerticalDivider(width: 1),
          Expanded(child: _buildWorkspace()),
          const VerticalDivider(width: 1),
          _buildRightSidebar(),
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
          // Header with back button and title - ALWAYS VISIBLE
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
                  tooltip: 'Back to Dashboard',
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ATTENDANCE WORKSPACE',
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
                      final baseCount =
                          _enrollmentCounts[classroom.id] ??
                          classroom.currentStudents;
                      // Use live roster count for the selected classroom as a
                      // safe, RLS-resilient enhancement so the sidebar count
                      // always reflects the actual students fetched on the
                      // right panel.
                      final count = isSelected ? _students.length : baseCount;
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
        ],
      ),
    );
  }

  Widget _buildWorkspace() {
    if (_selectedClassroom == null) {
      return Center(
        child: Text(
          'Select a classroom on the left to begin',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    final courses = _courses;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkspaceHeader(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildCourseDropdown(courses),
                    _buildQuarterChips(),
                    _buildSetActiveQuarterIconButton(),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [_buildExportButton()],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildActiveQuarterBanner(),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader() {
    // Only show the classroom name pill in the workspace header; back button and
    // screen title are now in the left panel header to match other teacher screens.
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _selectedClassroom?.title ?? '',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown(List<Course> courses) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: _isLoadingCourses
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading…', style: TextStyle(fontSize: 12)),
                  ],
                )
              : DropdownButton<Course>(
                  isExpanded: false,
                  value: _selectedCourse,
                  hint: const Text('Course', style: TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  items: courses
                      .map(
                        (c) => DropdownMenuItem<Course>(
                          value: c,
                          child: Text(c.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (Course? val) async {
                    setState(() {
                      _selectedCourse = val;
                      _statusByStudent.clear();
                    });
                    await _loadActiveQuarterForCurrentCourse();
                    _setupActiveQuarterRealtime();
                    await _loadMarkedDatesForVisibleMonth();
                    await _loadAttendanceForSelectedDate();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildQuarterChips() {
    final lockSet = _activeQuarterForCourse != null;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(4, (i) {
        final q = i + 1;
        final selected = _selectedQuarter == q;
        final isActive = _activeQuarterForCourse == q;
        final iconColor = isActive ? Colors.green : Colors.grey;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lockSet)
                Icon(
                  isActive ? Icons.check_circle : Icons.lock,
                  size: 14,
                  color: iconColor,
                ),
              if (lockSet) const SizedBox(width: 4),
              Text('Q$q'),
            ],
          ),
          selected: selected,
          onSelected: (_) => _onQuarterSelected(q),
          labelStyle: const TextStyle(fontSize: 12),
          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? Colors.blue.shade300 : Colors.blue.shade200,
            ),
          ),
          backgroundColor: Colors.blue.shade50,
          selectedColor: Colors.blue.shade100,
        );
      }),
    );
  }

  // Bulk apply helpers
  void _applyStatusToAll(String value) {
    setState(() {
      for (final s in _students) {
        final id = (s['student_id'] ?? s['id']).toString();
        _statusByStudent[id] = value;
      }
    });
  }

  void _clearAllStatuses() {
    setState(() {
      _statusByStudent.clear();
    });
  }

  Widget _buildBulkSelectRow({
    required bool enabled,
    required bool isPast,
    required bool isFuture,
  }) {
    bool allStudentsHave(String status) {
      if (_students.isEmpty) return false;
      if (_statusByStudent.length != _students.length) return false;
      final target = status.toLowerCase();
      for (final s in _students) {
        final id = (s['student_id'] ?? s['id']).toString();
        final st = _statusByStudent[id]?.toLowerCase();
        if (st != target) return false;
      }
      return true;
    }

    // Helper to draw the select-all checkbox cell (today only)
    Widget selectAllBox(
      String letter,
      String value,
      Color color,
      String tooltip,
    ) {
      final bool checked = allStudentsHave(value);

      return SizedBox(
        width: _statusColWidth,
        child: Center(
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: Container(
              decoration: BoxDecoration(
                color: checked
                    ? color.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: checked
                    ? Border.all(color: color.withValues(alpha: 0.3))
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: checked,
                  onChanged: enabled
                      ? (v) {
                          if (v == true) {
                            _applyStatusToAll(value);
                          } else {
                            _clearAllStatuses();
                          }
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return color;
                    return null; // default theme when unchecked
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Column label cell (slight left nudge for perfect checkbox alignment)
    Widget label(String letter) => SizedBox(
      width: _statusColWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ),
    );

    // Summary box for past/future
    Widget summaryBox(String text, Color color) => SizedBox(
      width: _statusColWidth,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                // Left side mimics student card name area; keep same structure/spacing
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 52,
                      ), // avatar (40) + gap (12) to align with name text
                      Text(
                        'Total: ${_students.length} ${_students.length == 1 ? 'student' : 'students'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isPast) ...[
                  summaryBox(
                    'P: ${_statusByStudent.values.where((s) => s == 'Present' || s == 'present').length}',
                    Colors.green,
                  ),
                  summaryBox(
                    'A: ${_statusByStudent.values.where((s) => s == 'Absent' || s == 'absent').length}',
                    Colors.red,
                  ),
                  summaryBox(
                    'L: ${_statusByStudent.values.where((s) => s == 'Late' || s == 'late').length}',
                    Colors.grey,
                  ),
                  summaryBox(
                    'E: ${_statusByStudent.values.where((s) => s == 'Excused' || s == 'excused').length}',
                    Colors.blue,
                  ),
                ] else if (isFuture) ...[
                  summaryBox('—', Colors.grey.shade500),
                  summaryBox('—', Colors.grey.shade500),
                  summaryBox('—', Colors.grey.shade500),
                  summaryBox('—', Colors.grey.shade500),
                ] else ...[
                  // Today (editable): show select-all checkboxes
                  selectAllBox(
                    'P',
                    'Present',
                    Colors.green,
                    'Mark all students as Present',
                  ),
                  selectAllBox(
                    'A',
                    'Absent',
                    Colors.red,
                    'Mark all students as Absent',
                  ),
                  selectAllBox(
                    'L',
                    'Late',
                    Colors.grey,
                    'Mark all students as Late',
                  ),
                  selectAllBox(
                    'E',
                    'Excused',
                    Colors.blue,
                    'Mark all students as Excused',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                label('P'),
                label('A'),
                label('L'),
                label('E'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_selectedCourse == null) {
      return Center(
        child: Text(
          'Select a course to view students',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    if (_selectedQuarter == null) {
      return Center(
        child: Text(
          'Select a quarter to begin marking attendance',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final today = _normalizeDate(DateTime.now());
    final DateTime? selected = _selectedDate != null
        ? _normalizeDate(_selectedDate!)
        : null;
    final bool isToday = selected != null && _isSameDate(selected, today);
    final bool isPast = selected != null && selected.isBefore(today);
    final bool isFuture = selected != null && selected.isAfter(today);
    final bool canMark =
        selected != null && isToday && _selectedQuarter != null;

    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No students to display',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    // Consolidated header + list inside a single scrollable ListView so
    // the Select-All PALE row scrolls together with the student cards.
    return ListView(
      children: [
        if (isPast) _historicalBanner(_selectedDate!),
        _buildBulkSelectRow(
          enabled: canMark,
          isPast: isPast,
          isFuture: isFuture,
        ),
        if (isFuture)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Attendance cannot be marked for future dates',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else if (selected == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Pick a date from the calendar to start marking',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ..._students.map((s) {
          final id = (s['student_id'] ?? s['id']).toString();
          final name = (s['full_name'] ?? s['name'] ?? '').toString();
          final status = _statusByStudent[id];
          final ls = status?.toLowerCase();

          Widget statusCell(
            String value,
            bool checked,
            Color color,
            ValueChanged<bool?> onChanged,
          ) {
            return SizedBox(
              width: _statusColWidth,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: checked
                        ? color.withValues(alpha: value == 'Late' ? 0.12 : 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: checked
                        ? Border.all(
                            color: color.withValues(
                              alpha: value == 'Late' ? 0.35 : 0.3,
                            ),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: checked,
                      onChanged: canMark ? onChanged : null,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return color;
                        return null; // use theme when unchecked
                      }),
                    ),
                  ),
                ),
              ),
            );
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(_initials(name))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  if (isPast) ...[
                    SizedBox(
                      width: _statusColWidth * 4,
                      child: Center(
                        child: Text(
                          status ?? 'No Record',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: () {
                              final s = ls;
                              if (s == 'present') return Colors.green;
                              if (s == 'absent') return Colors.red;
                              if (s == 'late') return Colors.grey;
                              if (s == 'excused') return Colors.blue;
                              return Colors.grey.shade500;
                            }(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ] else if (isFuture) ...[
                    SizedBox(
                      width: _statusColWidth * 4,
                      child: Center(
                        child: Text(
                          'Upcoming',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    statusCell('Present', ls == 'present', Colors.green, (v) {
                      setState(() {
                        if (v == true) {
                          _statusByStudent[id] = 'Present';
                        } else {
                          _statusByStudent.remove(id);
                        }
                      });
                    }),
                    statusCell('Absent', ls == 'absent', Colors.red, (v) {
                      setState(() {
                        if (v == true) {
                          _statusByStudent[id] = 'Absent';
                        } else {
                          _statusByStudent.remove(id);
                        }
                      });
                    }),
                    statusCell('Late', ls == 'late', Colors.grey, (v) {
                      setState(() {
                        if (v == true) {
                          _statusByStudent[id] = 'Late';
                        } else {
                          _statusByStudent.remove(id);
                        }
                      });
                    }),
                    statusCell('Excused', ls == 'excused', Colors.blue, (v) {
                      setState(() {
                        if (v == true) {
                          _statusByStudent[id] = 'Excused';
                        } else {
                          _statusByStudent.remove(id);
                        }
                      });
                    }),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
