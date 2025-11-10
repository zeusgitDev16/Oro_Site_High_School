import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/screens/student/dashboard/student_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
                    itemBuilder: (context, i) {
                      final room = _classrooms[i];
                      final selected = _selectedClassroom?.id == room.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: Colors.green.shade50,
                        title: Text(room.title),
                        subtitle: Text('Grade ${room.gradeLevel}'),
                        onTap: () => _onSelectClassroom(room),
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
      await _loadAttendanceForVisibleMonth();
      _setupRealtime();
    } catch (_) {
      // ignore for UI
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String _dateKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(_normalizeDate(d));

  int _currentQuarterForMonth(int month) => ((month - 1) ~/ 3) + 1; // 1..4

  Future<void> _restoreQuarter() async {
    final prefs = await SharedPreferences.getInstance();
    final q =
        prefs.getInt('student_attendance_quarter') ??
        _currentQuarterForMonth(DateTime.now().month);
    setState(() => _selectedQuarter = q);
  }

  Future<void> _persistQuarter(int q) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_attendance_quarter', q);
  }

  void _setupRealtime() {
    _teardownRealtime();
    if (_studentId == null ||
        _selectedCourse == null ||
        _selectedQuarter == null)
      return;
    final cid = int.tryParse(_selectedCourse!.id);
    if (cid == null) return;
    _rtAttendance = _supabase
        .channel(
          'student_att_${_studentId}_${_selectedCourse!.id}_${_selectedQuarter}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (payload) {
            final data = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final courseIdStr = data['course_id']?.toString();
            if (courseIdStr != cid.toString()) return;
            final q = int.tryParse(data['quarter']?.toString() ?? '');
            if (q != _selectedQuarter) return;
            final dStr = data['date']?.toString();
            final dt = dStr != null ? DateTime.tryParse(dStr) : null;
            if (dt == null) return;
            if (dt.year != _visibleMonth.year ||
                dt.month != _visibleMonth.month)
              return;
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
          },
        )
        .subscribe();
  }

  void _teardownRealtime() {
    if (_rtAttendance != null) {
      _supabase.removeChannel(_rtAttendance!);
      _rtAttendance = null;
    }
  }

  Future<void> _loadAttendanceForVisibleMonth() async {
    if (_studentId == null ||
        _selectedCourse == null ||
        _selectedQuarter == null) {
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
      if (cid == null) return;
      final resp = await _supabase
          .from('attendance')
          .select('date,status,time_in,time_out,remarks,quarter,course_id')
          .eq('student_id', _studentId!)
          .eq('course_id', cid)
          .eq('quarter', _selectedQuarter!)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());
      final Map<String, String> status = {};
      final Map<String, Map<String, dynamic>> details = {};
      final Set<String> keys = {};
      for (final row in (resp as List)) {
        final dStr = row['date']?.toString();
        final dt = dStr != null ? DateTime.tryParse(dStr) : null;
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
      }
    } catch (_) {
      // ignore
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar: classroom title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedClassroom?.title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Filters row: course + quarter
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<Course>(
                  isExpanded: true,
                  value: _selectedCourse,
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
                    await _loadAttendanceForVisibleMonth();
                    _setupRealtime();
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
                  return ChoiceChip(
                    label: Text('Q$q'),
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
              Text(
                _monthYearLabel(_visibleMonth),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Summary row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _buildSummaryRow(),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        // Records list
        Expanded(
          child: _isLoadingMonth
              ? const Center(child: CircularProgressIndicator())
              : _statusByDate.isEmpty
              ? Center(
                  child: Text(
                    'No records for this month.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _buildRecordList(),
                ),
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
        box('L', '$l', Colors.orange),
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

  List<Widget> _buildRecordList() {
    final keys = _statusByDate.keys.toList()..sort();
    return keys
        .map((k) => _recordTile(k, _statusByDate[k] ?? '', _detailsByDate[k]))
        .toList();
  }

  Widget _recordTile(
    String dateKey,
    String status,
    Map<String, dynamic>? details,
  ) {
    final dt = DateTime.tryParse(dateKey);
    final color = _statusColor(status);
    final label = _statusLabel(status);
    final timeIn = details?['time_in'];
    final timeOut = details?['time_out'];
    final remarks = details?['remarks'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: dt != null ? () => _onDateSelected(dt) : null,
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(
          dt != null ? DateFormat('EEE, MMM d, yyyy').format(dt) : dateKey,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                if (timeIn != null || timeOut != null)
                  Text('Time: ${timeIn ?? '--'} - ${timeOut ?? '--'}'),
                if (remarks != null && (remarks as String).trim().isNotEmpty)
                  Text('Remarks: $remarks'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
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

  Widget _buildRightSidebar() {
    return Container(
      width: 300,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _onMonthNavigate(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthYearLabel(_visibleMonth),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _onMonthNavigate(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildWeekdayHeader(),
          Expanded(child: _buildMonthGrid()),
        ],
      ),
    );
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

  Widget _buildMonthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final firstWeekday = first.weekday; // Mon=1..Sun=7
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final total = (firstWeekday - 1) + daysInMonth;
    final rows = ((total + 6) ~/ 7);
    final gridCount = rows * 7;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: gridCount,
      itemBuilder: (context, index) {
        final dayNum = index - (firstWeekday - 1) + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
        final key = _dateKey(date);
        final st = _statusByDate[key];
        final isSelected =
            _selectedDate != null &&
            _selectedDate!.year == date.year &&
            _selectedDate!.month == date.month &&
            _selectedDate!.day == date.day;

        final bg = st != null
            ? _statusColor(st).withValues(alpha: 0.12)
            : Colors.white;
        final borderColor = isSelected
            ? Theme.of(context).colorScheme.primary
            : (st != null ? _statusColor(st) : Colors.grey.shade300);

        return InkWell(
          onTap: () => _onDateSelected(date),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: st != null ? _statusColor(st) : Colors.grey.shade700,
                ),
              ),
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

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = _normalizeDate(date));
  }
}
