import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';

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

  final Set<String> _markedDateKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
    _initializeTeacher();
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
      if (!mounted) return;
      setState(() {
        _students = rows;
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
    try {
      final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final courseId = int.tryParse(_selectedCourse!.id);
      if (courseId == null) return;
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

    try {
      final courseId = int.tryParse(_selectedCourse!.id);
      if (courseId == null) return;
      final ids = _students
          .map((s) => (s['student_id'] ?? s['id']).toString())
          .toList();
      if (ids.isEmpty) return;

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

      // Fetch month attendance (student_id, date, status)
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
      } catch (_) {}

      final header1 = <xls.CellValue?>[
        xls.TextCellValue('School:'),
        xls.TextCellValue(''),
        xls.TextCellValue('School ID:'),
        xls.TextCellValue(''),
        xls.TextCellValue('Division:'),
        xls.TextCellValue(''),
        xls.TextCellValue('Region:'),
        xls.TextCellValue(''),
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
      sheet.appendRow([null]);

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
      final blankDays = List<xls.CellValue?>.filled(daysInMonth, null);
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

      final fileName =
          'Attendance_${course.title.replaceAll(' ', '')}_${monthName}_${month.year}_Q$_selectedQuarter.xlsx';
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      final bytes = book.encode();
      if (bytes != null) {
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
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

  Widget _buildDownloadButton() {
    final enabled =
        _selectedClassroom != null &&
        _selectedCourse != null &&
        _selectedQuarter != null;
    return OutlinedButton.icon(
      onPressed: enabled && !_isExporting ? _exportMonthlyAttendanceSf2 : null,
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: const Text('Download'),
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
            children: [
              _buildCourseDropdown(courses),
              const SizedBox(width: 8),
              _buildQuarterChips(),
              const Spacer(),
              _buildDownloadButton(),
            ],
          ),
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
    return SizedBox(
      width: 240,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Course',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: _isLoadingCourses
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading courses...'),
                  ],
                )
              : DropdownButton<Course>(
                  isExpanded: true,
                  value: _selectedCourse,
                  hint: const Text('Select course'),
                  items: courses
                      .map(
                        (c) => DropdownMenuItem<Course>(
                          value: c,
                          child: Text(c.title),
                        ),
                      )
                      .toList(),
                  onChanged: (Course? val) {
                    setState(() {
                      _selectedCourse = val;
                      _statusByStudent.clear();
                    });
                    _loadMarkedDatesForVisibleMonth();
                    _loadAttendanceForSelectedDate();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildQuarterChips() {
    return Wrap(
      spacing: 6,
      children: List.generate(4, (i) {
        final q = i + 1;
        final selected = _selectedQuarter == q;
        return ChoiceChip(
          label: Text('Q$q'),
          selected: selected,
          onSelected: (_) => _onQuarterSelected(q),
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
