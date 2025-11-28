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

  /// Check if current user is a student (read-only mode)
  bool get _isStudent => widget.userRole?.toLowerCase() == 'student';

  /// Normalize date to midnight UTC for comparison
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Check if selected date is in the future
  bool get _isFutureDate {
    final today = _normalizeDate(DateTime.now());
    final selected = _normalizeDate(_selectedDate);
    return selected.isAfter(today);
  }

  @override
  void initState() {
    super.initState();
    // Load students and attendance data
    // Now supports both new system (subject_id) and old system (course_id)
    _loadStudents();
    _loadMarkedDates();
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
  /// For students: only load their own data
  /// For teachers/admin: load all students
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> students;

      if (_isStudent && widget.userId != null) {
        // Student view: Only load current student's data
        final profileResponse = await _supabase
            .from('profiles')
            .select('id, full_name, email')
            .eq('id', widget.userId!)
            .single();

        students = [
          {
            'id': profileResponse['id'],
            'full_name': profileResponse['full_name'] ?? 'Unknown',
            'email': profileResponse['email'] ?? '',
            'lrn': '',
            'enrolled_at': null,
          }
        ];

        // Load LRN
        final lrnResponse = await _supabase
            .from('students')
            .select('id, lrn')
            .eq('id', widget.userId!)
            .maybeSingle();

        if (lrnResponse != null) {
          students[0]['lrn'] = lrnResponse['lrn'] ?? 'N/A';
        }
      } else {
        // Teacher/Admin view: Load all students in classroom
        final response = await _supabase.rpc(
          'get_classroom_students_with_profile',
          params: {'p_classroom_id': widget.classroomId},
        );

        students = (response as List).map((student) {
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
    if (_students.isEmpty) return;

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final studentIds = _students.map((s) => s['id']).toList();

      // Build query with backward compatibility
      // Try new system first (subject_id), fallback to old system (course_id)
      var query = _supabase
          .from('attendance')
          .select('student_id, status')
          .eq('quarter', _selectedQuarter)
          .eq('date', dateStr)
          .inFilter('student_id', studentIds);

      // Filter by new system (subject_id) OR old system (course_id)
      // New system: Use subject_id (UUID)
      // Old system: Use course_id (bigint) - for backward compatibility
      if (widget.subject.courseId != null) {
        // Has courseId - use OR logic to support both systems
        query = query.or('subject_id.eq.${widget.subject.id},course_id.eq.${widget.subject.courseId}');
      } else {
        // No courseId - new subject, use subject_id only
        query = query.eq('subject_id', widget.subject.id);
      }

      final response = await query;

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
    try {
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      // Build query with backward compatibility
      var query = _supabase
          .from('attendance')
          .select('date')
          .eq('quarter', _selectedQuarter)
          .gte('date', startOfMonth.toIso8601String().split('T')[0])
          .lte('date', endOfMonth.toIso8601String().split('T')[0]);

      // Filter by new system (subject_id) OR old system (course_id)
      if (widget.subject.courseId != null) {
        query = query.or('subject_id.eq.${widget.subject.id},course_id.eq.${widget.subject.courseId}');
      } else {
        query = query.eq('subject_id', widget.subject.id);
      }

      final response = await query;

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

      // Prepare attendance records with NEW SYSTEM fields
      // Includes both classroom_id + subject_id (new) and course_id (old) for backward compatibility
      final records = _attendanceStatus.entries.map((entry) {
        final record = <String, dynamic>{
          'student_id': entry.key,
          'classroom_id': widget.classroomId, // NEW: Link to classroom
          'subject_id': widget.subject.id,     // NEW: Link to subject (UUID)
          'date': dateStr,
          'status': entry.value,
          'quarter': _selectedQuarter,
          // Note: time_in column removed - not in attendance table schema
        };

        // Add course_id for backward compatibility (if available)
        if (widget.subject.courseId != null) {
          record['course_id'] = widget.subject.courseId;
        }

        return record;
      }).toList();

      // Delete existing records for this date/quarter/students
      // Use subject_id for new system, course_id for old system
      if (widget.subject.courseId != null) {
        // Has courseId - delete using OR logic to handle both systems
        await _supabase
            .from('attendance')
            .delete()
            .eq('quarter', _selectedQuarter)
            .eq('date', dateStr)
            .or('subject_id.eq.${widget.subject.id},course_id.eq.${widget.subject.courseId}')
            .inFilter('student_id', studentIds);
      } else {
        // No courseId - new subject, use subject_id only
        await _supabase
            .from('attendance')
            .delete()
            .eq('subject_id', widget.subject.id)
            .eq('quarter', _selectedQuarter)
            .eq('date', dateStr)
            .inFilter('student_id', studentIds);
      }

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

          // Save Button (only for teachers/admin and only for today or past dates)
          if (!_isStudent && !_isFutureDate) ...[
            const SizedBox(width: 8),
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
            isReadOnly: _isStudent, // Read-only for students
            selectedDate: _selectedDate, // Pass selected date for context
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

