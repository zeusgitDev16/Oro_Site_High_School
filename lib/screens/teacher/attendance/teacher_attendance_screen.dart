import 'package:flutter/material.dart';

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
  // Layer 1: Classroom selection (placeholder, owned-only in Phase 2)
  final List<String> _classrooms = ['Pearl 10', 'Emerald 7'];
  String? _selectedClassroom;

  // Layer 2 controls (placeholder)
  final Map<String, List<String>> _coursesByClassroom = {
    'Pearl 10': ['TLE', 'Math 7'],
    'Emerald 7': ['Science 7'],
  };
  String? _selectedCourse;
  int? _selectedQuarter; // 1-4
  DateTime? _selectedDate; // selected via calendar in right sidebar
  late DateTime _visibleMonth; // month visible in calendar

  // Students + attendance status (placeholder)
  List<Map<String, String>> _students = [];
  final Map<String, String> _statusByStudent = {};
  static const List<String> _statuses = [
    'Present',
    'Absent',
    'Late',
    'Excused',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
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

  // Toolbar helpers
  Widget _buildStudentPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 16),
          SizedBox(width: 6),
          Text('Student', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _onClearFilters() {
    setState(() {
      _selectedCourse = null;
      _selectedQuarter = null;
      _statusByStudent.clear();
      _students = [];
    });
  }

  Widget _buildDownloadButton() {
    final enabled =
        _selectedClassroom != null &&
        _selectedCourse != null &&
        _selectedQuarter != null &&
        _selectedDate != null;
    return OutlinedButton.icon(
      onPressed: enabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download — placeholder')),
              );
            }
          : null,
      icon: const Icon(Icons.download),
      label: const Text('Download'),
    );
  }

  // Right sidebar (calendar)
  Widget _buildRightSidebar() {
    return Container(
      width: 300,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthYearLabel(_visibleMonth),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                  },
                ),
              ],
            ),
          ),
          _buildWeekdayHeader(),
          Expanded(child: _buildMonthGrid()),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
              child: Center(
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
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

        final Color fill = isSelected
            ? Colors.blue.withAlpha(31)
            : (isToday ? Colors.blue.withAlpha(15) : Colors.transparent);
        final Color border = isSelected
            ? Colors.blue
            : (isToday ? Colors.blue.shade200 : Colors.grey.shade300);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _selectedDate = date;
                    if (_selectedCourse != null) {
                      _ensurePlaceholderStudents();
                    }
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isFuture ? Colors.grey.shade400 : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  void _ensurePlaceholderStudents() {
    if (_students.isEmpty && _selectedCourse != null) {
      _students = List.generate(
        12,
        (i) => {'id': 'S${i + 1}', 'name': 'Student ${i + 1}'},
      );
    }
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

  Widget _buildStatusLabel(String status) {
    if (status == '—') {
      return Text(status, style: TextStyle(color: Colors.grey.shade500));
    }
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(31),
        border: Border.all(color: c.withAlpha(77)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
    );
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'you have ${_classrooms.length} classroom(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _classrooms.isEmpty
                ? Center(
                    child: Text(
                      'No classrooms found\n(owned classrooms only)',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _classrooms.length,
                    itemBuilder: (context, index) {
                      final room = _classrooms[index];
                      final selected = room == _selectedClassroom;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedClassroom = room;
                              _selectedCourse = null;
                              _selectedQuarter = null;
                              _students = [];
                              _statusByStudent.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              border: Border.all(
                                color: selected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Grade 10 • 1/35 students',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View students — placeholder'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_alt, size: 18),
                  label: const Text('view students'),
                ),
              ),
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

    final courses = _coursesByClassroom[_selectedClassroom] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkspaceHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStudentPill(),
              const SizedBox(width: 12),
              _buildCourseDropdown(courses),
              const SizedBox(width: 8),
              _buildQuarterChips(),
              const Spacer(),
              _buildDownloadButton(),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _onClearFilters,
                child: const Text('clear'),
              ),
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
    return Row(
      children: [
        const Text(
          'Attendance Workspace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _selectedClassroom ?? '',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown(List<String> courses) {
    return SizedBox(
      width: 240,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Course',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCourse,
            hint: const Text('Select course'),
            items: courses
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedCourse = val;
                _students = [];
                _statusByStudent.clear();
              });
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
          onSelected: (_) => setState(() => _selectedQuarter = q),
        );
      }),
    );
  }

  Widget _buildStatusChipsRow(String studentId, String? current) {
    return Wrap(
      spacing: 6,
      children: [
        for (final st in _statuses)
          ChoiceChip(
            label: Text(st),
            selected: current == st,
            onSelected: (_) {
              setState(() => _statusByStudent[studentId] = st);
            },
            selectedColor: _statusColor(st).withAlpha(51),
            labelStyle: TextStyle(
              color: current == st ? _statusColor(st) : Colors.black,
            ),
          ),
      ],
    );
  }

  Color _statusColor(String st) {
    switch (st) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      case 'Excused':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildStudentList() {
    if (_selectedCourse == null || _selectedDate == null) {
      return Center(
        child: Text(
          'Select course and pick a date from the calendar',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final today = _normalizeDate(DateTime.now());
    final selected = _normalizeDate(_selectedDate!);
    final isToday = _isSameDate(selected, today);
    final isPast = selected.isBefore(today);
    final isFuture = selected.isAfter(today);

    if (isFuture) {
      return Center(
        child: Text(
          'Attendance cannot be marked for future dates',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No students to display',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: [
        if (isPast) _historicalBanner(_selectedDate!),
        Expanded(
          child: ListView.separated(
            itemCount: _students.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = _students[index];
              final id = s['id']!;
              final name = s['name']!;
              final status = _statusByStudent[id];
              return ListTile(
                dense: true,
                leading: CircleAvatar(child: Text(_initials(name))),
                title: Text(name),
                trailing: isToday
                    ? _buildStatusChipsRow(id, status)
                    : _buildStatusLabel(status ?? '—'),
              );
            },
          ),
        ),
      ],
    );
  }
}
