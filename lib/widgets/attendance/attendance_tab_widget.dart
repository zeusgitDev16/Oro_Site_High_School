import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_quarter_selector.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_date_picker.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_grid_panel.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_summary_card.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_export_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main attendance tab widget for subject attendance tracking
///
/// **Features:**
/// - Quarter selection (Q1-Q4)
/// - Date selection with calendar
/// - Student attendance grid with status marking
/// - Summary statistics
/// - Save and export functionality
///
/// **Usage:**
/// ```dart
/// AttendanceTabWidget(
///   subject: _selectedSubject!,
///   classroomId: _selectedClassroom!.id,
///   userRole: 'teacher',
///   userId: _teacherId!,
/// )
/// ```
class AttendanceTabWidget extends StatefulWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final String? userRole;
  final String? userId;

  const AttendanceTabWidget({
    super.key,
    required this.subject,
    required this.classroomId,
    this.userRole,
    this.userId,
  });

  @override
  State<AttendanceTabWidget> createState() => _AttendanceTabWidgetState();
}

class _AttendanceTabWidgetState extends State<AttendanceTabWidget> {
  // Supabase client
  final _supabase = Supabase.instance.client;

  // State
  int _selectedQuarter = 1;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  final Map<String, String> _attendanceStatus = {}; // studentId -> status
  Set<DateTime> _markedDates = {}; // Dates with attendance recorded
  bool _isLoading = false;
  bool _isSaving = false;

  // Statistics
  int _totalStudents = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _excusedCount = 0;

  @override
  void initState() {
    super.initState();
    // Validate that subject has courseId for attendance
    if (widget.subject.courseId == null) {
      // Show error - cannot use attendance without courseId
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This subject is not linked to a course. Attendance cannot be recorded.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    } else {
      _loadStudents();
      _loadMarkedDates();
    }
  }

  @override
  void didUpdateWidget(AttendanceTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if subject changes
    if (oldWidget.subject.id != widget.subject.id) {
      _loadStudents();
    }
  }

  /// Load students enrolled in this classroom
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      // Use RPC function to get students with profile information
      final response = await _supabase.rpc(
        'get_classroom_students_with_profile',
        params: {'p_classroom_id': widget.classroomId},
      );

      final students = (response as List).map((student) {
        return {
          'id': student['student_id'],
          'full_name': student['full_name'] ?? 'Unknown',
          'email': student['email'] ?? '',
          'lrn': '', // LRN will be loaded separately if needed
          'enrolled_at': student['enrolled_at'],
        };
      }).toList();

      // Load LRN from students table
      if (students.isNotEmpty) {
        final studentIds = students.map((s) => s['id']).toList();
        final lrnResponse = await _supabase
            .from('students')
            .select('id, lrn')
            .inFilter('id', studentIds);

        final lrnMap = {
          for (var item in (lrnResponse as List))
            item['id']: item['lrn'] ?? 'N/A'
        };

        // Update students with LRN
        for (var student in students) {
          student['lrn'] = lrnMap[student['id']] ?? 'N/A';
        }
      }

      if (mounted) {
        setState(() {
          _students = students;
          _totalStudents = students.length;
          _isLoading = false;
        });

        // Load attendance for current date and quarter
        await _loadAttendanceForSelectedDate();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  /// Handle quarter change
  void _onQuarterChanged(int quarter) {
    setState(() {
      _selectedQuarter = quarter;
      _attendanceStatus.clear();
    });
    // Reload attendance for new quarter
    _loadAttendanceForSelectedDate();
    _loadMarkedDates();
  }

  /// Handle date change
  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _attendanceStatus.clear();
    });
    // Reload attendance for new date
    _loadAttendanceForSelectedDate();
  }

  /// Load attendance for selected date and quarter
  Future<void> _loadAttendanceForSelectedDate() async {
    if (_students.isEmpty || widget.subject.courseId == null) return;

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final studentIds = _students.map((s) => s['id']).toList();

      final response = await _supabase
          .from('attendance')
          .select('student_id, status')
          .eq('course_id', widget.subject.courseId!)
          .eq('quarter', _selectedQuarter)
          .eq('date', dateStr)
          .inFilter('student_id', studentIds);

      if (mounted) {
        setState(() {
          _attendanceStatus.clear();
          for (var row in (response as List)) {
            _attendanceStatus[row['student_id']] = row['status'];
          }
          _updateStatistics();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  /// Load marked dates for the current month
  Future<void> _loadMarkedDates() async {
    if (widget.subject.courseId == null) return;

    try {
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final response = await _supabase
          .from('attendance')
          .select('date')
          .eq('course_id', widget.subject.courseId!)
          .eq('quarter', _selectedQuarter)
          .gte('date', startOfMonth.toIso8601String().split('T')[0])
          .lte('date', endOfMonth.toIso8601String().split('T')[0]);

      if (mounted) {
        setState(() {
          _markedDates = (response as List)
              .map((row) => DateTime.parse(row['date']))
              .toSet();
        });
      }
    } catch (e) {
      // Silently fail - marked dates are not critical
      // Error loading marked dates: $e
    }
  }

  /// Handle status change for a student
  void _onStatusChanged(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
      _updateStatistics();
    });
  }

  /// Update statistics based on current attendance status
  void _updateStatistics() {
    _totalStudents = _students.length;
    _presentCount = _attendanceStatus.values.where((s) => s == 'present').length;
    _absentCount = _attendanceStatus.values.where((s) => s == 'absent').length;
    _lateCount = _attendanceStatus.values.where((s) => s == 'late').length;
    _excusedCount = _attendanceStatus.values.where((s) => s == 'excused').length;
  }

  /// Save attendance to database
  Future<void> _saveAttendance() async {
    // Validate courseId exists
    if (widget.subject.courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This subject is not linked to a course. Cannot save attendance.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate inputs
    if (_attendanceStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark attendance for at least one student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent saving future dates
    final today = DateTime.now();
    final selectedNormalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final todayNormalized = DateTime(today.year, today.month, today.day);
    if (selectedNormalized.isAfter(todayNormalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save attendance for future dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final studentIds = _attendanceStatus.keys.toList();

      // Prepare attendance records
      final records = _attendanceStatus.entries.map((entry) {
        return {
          'student_id': entry.key,
          'course_id': widget.subject.courseId!,
          'date': dateStr,
          'status': entry.value,
          'quarter': _selectedQuarter,
          'time_in': DateTime.now().toIso8601String(),
        };
      }).toList();

      // Delete existing records for this date/course/quarter/students
      await _supabase
          .from('attendance')
          .delete()
          .eq('course_id', widget.subject.courseId!)
          .eq('quarter', _selectedQuarter)
          .eq('date', dateStr)
          .inFilter('student_id', studentIds);

      // Insert new records
      await _supabase.from('attendance').insert(records);

      // Update marked dates
      setState(() {
        _markedDates.add(_selectedDate);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload marked dates for the month
      await _loadMarkedDates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Export attendance to Excel
  Future<void> _exportAttendance() async {
    // TODO: Implement export functionality (Phase 3)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming in Phase 3')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }

  /// Build header with title and action buttons
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Title
          Text(
            'Attendance - ${widget.subject.subjectName}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Quarter Selector
          AttendanceQuarterSelector(
            selectedQuarter: _selectedQuarter,
            onQuarterSelected: _onQuarterChanged,
          ),
          const SizedBox(width: 12),

          // Date Picker
          AttendanceDatePicker(
            selectedDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
          const SizedBox(width: 12),

          // Export Button
          AttendanceExportButton(
            onExport: _exportAttendance,
            isEnabled: _students.isNotEmpty,
          ),
          const SizedBox(width: 8),

          // Save Button
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAttendance,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 16),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content area
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Summary Card
        Padding(
          padding: const EdgeInsets.all(16),
          child: AttendanceSummaryCard(
            totalStudents: _totalStudents,
            presentCount: _presentCount,
            absentCount: _absentCount,
            lateCount: _lateCount,
            excusedCount: _excusedCount,
          ),
        ),

        // Attendance Grid
        Expanded(
          child: AttendanceGridPanel(
            students: _students,
            attendanceStatus: _attendanceStatus,
            onStatusChanged: _onStatusChanged,
            isReadOnly: false,
          ),
        ),
      ],
    );
  }

  /// Build empty state when no students enrolled
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No students enrolled',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students must be enrolled in this classroom to mark attendance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

