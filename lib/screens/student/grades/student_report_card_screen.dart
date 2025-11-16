import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/quarterly_grade.dart';
import 'package:oro_site_high_school/models/sf9_core_value_rating.dart';
import 'package:oro_site_high_school/models/attendance_monthly_summary.dart';
import 'package:oro_site_high_school/models/student_transfer_record.dart';
import 'package:oro_site_high_school/services/sf9_export_service.dart';
import 'package:oro_site_high_school/services/sf9_final_grade_service.dart';
import 'package:oro_site_high_school/services/sf9_core_value_rating_service.dart';
import 'package:oro_site_high_school/services/sf9_attendance_monthly_summary_service.dart';
import 'package:oro_site_high_school/services/student_transfer_record_service.dart';

class StudentReportCardScreen extends StatefulWidget {
  const StudentReportCardScreen({super.key});
  @override
  State<StudentReportCardScreen> createState() =>
      _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen> {
  String? _uid;
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _exportingSf9 = false;

  // Legacy grade rows grouped by quarter (still used for CSV + export)
  final Map<int, List<Map<String, dynamic>>> _byQuarter = {
    1: [],
    2: [],
    3: [],
    4: [],
  };

  // Course metadata (reused for both legacy and SF9 views)
  final Map<String, String> _courseTitles = {}; // courseId -> title
  final Map<String, String> _courseTeacherIds = {}; // courseId -> teacherId
  final Map<String, String> _teacherNames = {}; // teacherId -> full_name

  // SF9 services
  final Sf9FinalGradeService _finalGradeService = Sf9FinalGradeService();
  final Sf9CoreValueRatingService _coreValueRatingService =
      Sf9CoreValueRatingService();
  final Sf9AttendanceMonthlySummaryService _attendanceService =
      Sf9AttendanceMonthlySummaryService();
  final StudentTransferRecordService _transferService =
      StudentTransferRecordService();

  // SF9 data
  List<FinalGrade> _finalGrades = [];
  List<SF9CoreValueRating> _coreValueRatings = [];
  List<AttendanceMonthlySummary> _attendanceSummaries = [];
  StudentTransferRecord? _transferRecord;

  // SF9 errors per section
  String? _schoolYearError;
  String? _finalGradesError;
  String? _coreValuesError;
  String? _attendanceError;
  String? _transferError;

  // Student header info
  String? _studentName;
  int? _gradeLevel;
  String? _sectionName;
  String? _schoolYearLabel;
  String? _lrn;
  String? _studentSchoolYear;
  String? _resolvedSchoolYear;

  // UI state
  int _selectedQuarter = 1;

  @override
  void initState() {
    super.initState();
    _uid = Supabase.instance.client.auth.currentUser?.id;
    _subscribe();
    _loadData();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) return;
    _channel?.unsubscribe();
    final supa = Supabase.instance.client;
    _channel = supa
        .channel('student-sf9:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'final_grades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _loadSf9Data(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sf9_core_value_ratings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _loadSf9Data(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_monthly_summary',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _loadSf9Data(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_transfer_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _loadSf9Data(),
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await _loadStudentHeader(uid);
      await _loadLegacyQuarterGrades(uid);
      await _loadSf9Data();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadStudentHeader(String uid) async {
    final supa = Supabase.instance.client;
    try {
      final profileRow = await supa
          .from('profiles')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();

      final sRow = await supa
          .from('students')
          .select('grade_level, section, school_year, lrn')
          .eq('id', uid)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (profileRow != null) {
          final full = (profileRow['full_name'] as String? ?? '').trim();
          _studentName = full.isEmpty ? null : full;
        }

        if (sRow != null) {
          _gradeLevel = (sRow['grade_level'] as num?)?.toInt();
          _sectionName = (sRow['section'] as String?)?.trim();
          final sy = (sRow['school_year'] as String?)?.trim();
          if (sy != null && sy.isNotEmpty) {
            _studentSchoolYear = sy;
            _schoolYearLabel ??= sy;
          }
          final lrn = (sRow['lrn'] as String?)?.trim();
          if (lrn != null && lrn.isNotEmpty) {
            _lrn = lrn;
          }
        }
      });
    } catch (_) {
      // ignore student info load errors
    }
  }

  Future<void> _loadLegacyQuarterGrades(String uid) async {
    final supa = Supabase.instance.client;
    try {
      final rows = await supa
          .from('student_grades')
          .select()
          .eq('student_id', uid)
          .order('quarter', ascending: true);
      final map = <int, List<Map<String, dynamic>>>{
        1: <Map<String, dynamic>>[],
        2: <Map<String, dynamic>>[],
        3: <Map<String, dynamic>>[],
        4: <Map<String, dynamic>>[],
      };
      final courseIds = <String>{};
      for (final r in rows as List<dynamic>) {
        final q = (r['quarter'] as num?)?.toInt() ?? 0;
        if (q >= 1 && q <= 4) {
          map[q]!.add(Map<String, dynamic>.from(r as Map<String, dynamic>));
        }
        final cid = r['course_id']?.toString();
        if (cid != null) courseIds.add(cid);
      }

      final courseTitles = <String, String>{};
      final courseTeacherIds = <String, String>{};
      final teacherNames = <String, String>{};
      String? derivedSchoolYear = _schoolYearLabel;

      if (courseIds.isNotEmpty) {
        final cc = await supa
            .from('courses')
            .select('id, title, teacher_id, school_year')
            .inFilter('id', courseIds.toList());
        final teacherIds = <String>{};
        for (final c in cc as List<dynamic>) {
          final id = c['id'].toString();
          courseTitles[id] = (c['title'] as String? ?? '');
          final tid = c['teacher_id']?.toString();
          if (tid != null) {
            courseTeacherIds[id] = tid;
            teacherIds.add(tid);
          }
          derivedSchoolYear ??= (c['school_year'] as String?)?.trim();
        }
        if (teacherIds.isNotEmpty) {
          final tt = await supa
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', teacherIds.toList());
          for (final t in tt as List<dynamic>) {
            teacherNames[t['id'].toString()] = (t['full_name'] as String? ?? '')
                .trim();
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _byQuarter
          ..[1] = map[1]!
          ..[2] = map[2]!
          ..[3] = map[3]!
          ..[4] = map[4]!;

        _courseTitles
          ..clear()
          ..addAll(courseTitles);
        _courseTeacherIds
          ..clear()
          ..addAll(courseTeacherIds);
        _teacherNames
          ..clear()
          ..addAll(teacherNames);

        _schoolYearLabel ??= derivedSchoolYear;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _byQuarter[1] = [];
        _byQuarter[2] = [];
        _byQuarter[3] = [];
        _byQuarter[4] = [];
      });
    }
  }

  Future<String?> _resolveSchoolYear() async {
    final uid = _uid;
    if (uid == null) {
      return null;
    }

    final supa = Supabase.instance.client;
    String? sy = _studentSchoolYear;

    // 1) Try students.school_year
    if (sy == null || sy.isEmpty) {
      try {
        final row = await supa
            .from('students')
            .select('school_year')
            .eq('id', uid)
            .maybeSingle();
        if (row is Map<String, dynamic>) {
          final raw = row['school_year'] as String?;
          final trimmed = raw?.trim();
          if (trimmed != null && trimmed.isNotEmpty) {
            sy = trimmed;
            _studentSchoolYear = trimmed;
          }
        }
      } catch (e, st) {
        // ignore: avoid_print
        print(
          'StudentReportCardScreen._resolveSchoolYear step1 error: '
          '$e\n$st',
        );
      }
    }

    // 2) Derive from latest courses.school_year for student's classrooms
    if (sy == null || sy.isEmpty) {
      try {
        final csRows = await supa
            .from('classroom_students')
            .select('classroom_id')
            .eq('student_id', uid);

        final classroomIds = <String>{};
        for (final map in csRows) {
          final cid = map['classroom_id']?.toString();
          if (cid != null) classroomIds.add(cid);
        }

        if (classroomIds.isNotEmpty) {
          final ccRows = await supa
              .from('classroom_courses')
              .select('classroom_id, courses(school_year)')
              .inFilter('classroom_id', classroomIds.toList());
          String? latest;
          for (final map in ccRows) {
            final course = map['courses'];
            if (course is Map<String, dynamic>) {
              final val = (course['school_year'] as String?)?.trim();
              if (val != null && val.isNotEmpty) {
                if (latest == null || val.compareTo(latest) > 0) {
                  latest = val;
                }
              }
            }
          }
          sy ??= latest;
        }
      } catch (e, st) {
        // ignore: avoid_print
        print(
          'StudentReportCardScreen._resolveSchoolYear step2 error: '
          '$e\n$st',
        );
      }
    }

    // 3) Derive from latest final_grades.school_year
    if (sy == null || sy.isEmpty) {
      try {
        final rows = await supa
            .from('final_grades')
            .select('school_year')
            .eq('student_id', uid)
            .order('school_year', ascending: false)
            .limit(1);
        if (rows.isNotEmpty) {
          final first = rows.first;
          final raw = first['school_year'] as String?;
          final trimmed = raw?.trim();
          if (trimmed != null && trimmed.isNotEmpty) {
            sy = trimmed;
          }
        }
      } catch (e, st) {
        // ignore: avoid_print
        print(
          'StudentReportCardScreen._resolveSchoolYear step3 error: '
          '$e\n$st',
        );
      }
    }

    return sy;
  }

  Future<void> _loadSf9Data() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    // Reset per-section errors but keep previous data until new data arrives.
    if (mounted) {
      setState(() {
        _schoolYearError = null;
        _finalGradesError = null;
        _coreValuesError = null;
        _attendanceError = null;
        _transferError = null;
      });
    }

    final sy = await _resolveSchoolYear();
    if (!mounted) return;

    if (sy == null || sy.isEmpty) {
      setState(() {
        _resolvedSchoolYear = null;
        _schoolYearError =
            'Unable to determine the school year for this report card.\n'
            'Please contact your adviser or the school registrar.';
        _finalGrades = [];
        _coreValueRatings = [];
        _attendanceSummaries = [];
        _transferRecord = null;
      });
      return;
    }

    String? finalGradesError;
    String? coreValuesError;
    String? attendanceError;
    String? transferError;

    final futures = <Future<dynamic>>[
      _finalGradeService
          .getFinalGradesForStudent(studentId: uid, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print(
              'StudentReportCardScreen._loadSf9Data final_grades error: '
              '$e\n$st',
            );
            finalGradesError = 'Failed to load final grades.';
            return <FinalGrade>[];
          }),
      _coreValueRatingService
          .getRatingsForStudent(studentId: uid, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print(
              'StudentReportCardScreen._loadSf9Data core values error: '
              '$e\n$st',
            );
            coreValuesError = 'Failed to load core values ratings.';
            return <SF9CoreValueRating>[];
          }),
      _attendanceService
          .getMonthlySummariesForStudent(studentId: uid, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print(
              'StudentReportCardScreen._loadSf9Data attendance error: '
              '$e\n$st',
            );
            attendanceError = 'Failed to load attendance summary.';
            return <AttendanceMonthlySummary>[];
          }),
      _transferService
          .getActiveTransferRecord(studentId: uid, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print(
              'StudentReportCardScreen._loadSf9Data transfer error: '
              '$e\n$st',
            );
            transferError = 'Failed to load transfer/admission record.';
            return null;
          }),
    ];

    final results = await Future.wait<dynamic>(futures);
    if (!mounted) return;

    final loadedFinalGrades = results[0] as List<FinalGrade>;
    final loadedCoreValues = results[1] as List<SF9CoreValueRating>;
    final loadedAttendance = results[2] as List<AttendanceMonthlySummary>;
    final loadedTransfer = results[3] as StudentTransferRecord?;

    setState(() {
      _resolvedSchoolYear = sy;
      _schoolYearLabel ??= sy;
      _finalGrades = loadedFinalGrades;
      _coreValueRatings = loadedCoreValues;
      _attendanceSummaries = loadedAttendance;
      _transferRecord = loadedTransfer;
      _finalGradesError = finalGradesError;
      _coreValuesError = coreValuesError;
      _attendanceError = attendanceError;
      _transferError = transferError;
    });
  }

  Future<void> _exportSf9() async {
    final uid = _uid;
    if (uid == null) return;

    final q = _selectedQuarter;
    final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No grades available for Quarter $q')),
        );
      }
      return;
    }

    // Collect classroom IDs for this quarter.
    final classroomIds = <String>{};
    for (final r in rows) {
      final cid = r['classroom_id']?.toString();
      if (cid != null) classroomIds.add(cid);
    }
    if (classroomIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No classroom information for grades.')),
        );
      }
      return;
    }

    final supa = Supabase.instance.client;
    List<dynamic> data;
    try {
      data = await supa
          .from('classrooms')
          .select()
          .inFilter('id', classroomIds.toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classrooms: $e')),
        );
      }
      return;
    }

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No classrooms found for these grades.'),
          ),
        );
      }
      return;
    }

    final classrooms = <Classroom>[];
    for (final raw in data) {
      try {
        classrooms.add(Classroom.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // Ignore malformed rows.
      }
    }
    if (classrooms.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read classroom details.')),
        );
      }
      return;
    }

    Classroom? selected;
    if (classrooms.length == 1) {
      selected = classrooms.first;
    } else {
      if (!mounted) return;
      selected = await showDialog<Classroom>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Select classroom for SF9 export'),
            children: [
              for (final c in classrooms)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(c),
                  child: Text(
                    '${c.title} • Grade ${c.gradeLevel} (${c.schoolLevel})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      );
      if (selected == null) {
        return;
      }
    }

    setState(() => _exportingSf9 = true);
    try {
      await SF9ExportService.instance.exportSF9ReportCard(
        studentId: uid,
        classroom: selected,
        quarter: q,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SF9 Report Card exported successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export SF9 Report Card: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingSf9 = false);
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Quarter,Subject,Final Grade,Initial Grade,Remarks');
      for (int q = 1; q <= 4; q++) {
        final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
        for (final r in rows) {
          final title =
              _courseTitles[r['course_id'].toString()] ??
              r['course_id'].toString();
          final fg = _num(r['transmuted_grade']);
          final ig = _num(r['initial_grade']);
          final rem = (r['remarks'] as String?) ?? '';
          // Escape quotes for CSV safety
          final safeTitle = title.replaceAll('"', '""');
          final safeRem = rem.replaceAll('"', '""');
          buffer.writeln('Q$q,"$safeTitle",$fg,$ig,"$safeRem"');
        }
        if (rows.isNotEmpty) {
          final avg =
              rows
                  .map(
                    (r) => (r['transmuted_grade'] as num?)?.toDouble() ?? 0.0,
                  )
                  .fold<double>(0.0, (a, b) => a + b) /
              rows.length;
          buffer.writeln('Q$q,General Average,${avg.toStringAsFixed(2)},,');
        }
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report card copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        actions: [
          if (_exportingSf9)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentHeader(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildSf9Body()),
                ],
              ),
            ),
    );
  }

  Widget _buildSf9Body() {
    return Scrollbar(
      child: ListView(
        children: [
          if (_resolvedSchoolYear != null && _schoolYearError == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'School Year: $_resolvedSchoolYear',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_schoolYearError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _schoolYearError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildFinalGradesSection(),
          const SizedBox(height: 16),
          _buildCoreValuesSection(),
          const SizedBox(height: 16),
          _buildAttendanceSection(),
          const SizedBox(height: 16),
          _buildTransferAdmissionSection(),
          const SizedBox(height: 24),
          Text(
            'Legacy quarterly view (for CSV & PDF export)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          _buildQuarterChips(),
          const SizedBox(height: 8),
          SizedBox(height: 260, child: _buildQuarterBody()),
        ],
      ),
    );
  }

  Widget _buildFinalGradesSection() {
    final grades = List<FinalGrade>.from(_finalGrades);
    grades.sort((a, b) => a.courseName.compareTo(b.courseName));
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Final Grades', Icons.school_outlined),
            const SizedBox(height: 8),
            if (_finalGradesError != null) ...[
              Text(
                _finalGradesError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
            ],
            if (grades.isEmpty && _finalGradesError == null)
              const Text(
                'No final grades available for this school year.',
                style: TextStyle(fontSize: 12),
              )
            else if (grades.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Subject')),
                    DataColumn(label: Text('Teacher')),
                    DataColumn(label: Text('Final Grade')),
                    DataColumn(label: Text('Remarks')),
                    DataColumn(label: Text('Passing')),
                  ],
                  rows: grades.map((g) {
                    final gradeValue = g.finalGrade.toStringAsFixed(0);
                    final isPassing = g.isPassing;
                    final courseId = g.courseId;
                    final teacherId = _courseTeacherIds[courseId];
                    final teacherName = teacherId != null
                        ? _teacherNames[teacherId] ?? ''
                        : '';
                    return DataRow(
                      cells: [
                        DataCell(Text(g.courseName)),
                        DataCell(
                          Text(teacherName.isNotEmpty ? teacherName : '-'),
                        ),
                        DataCell(Text(gradeValue)),
                        DataCell(Text(g.gradeRemarks)),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                isPassing
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                size: 16,
                                color: isPassing
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPassing ? 'Passed' : 'Failed',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreValuesSection() {
    final ratings = _coreValueRatings;
    final grouped = <String, Map<String, Map<int, String>>>{
      // coreValue -> indicator -> quarter -> rating
    };
    for (final r in ratings) {
      final indicators = grouped.putIfAbsent(
        r.coreValueCode,
        () => <String, Map<int, String>>{},
      );
      final perQuarter = indicators.putIfAbsent(
        r.indicatorCode,
        () => <int, String>{},
      );
      perQuarter[r.quarter] = r.rating;
    }
    final coreValues = grouped.keys.toList()..sort();
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Core Values', Icons.favorite_border),
            const SizedBox(height: 8),
            _buildRatingLegend(),
            const SizedBox(height: 8),
            if (_coreValuesError != null) ...[
              Text(
                _coreValuesError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
            ],
            if (ratings.isEmpty && _coreValuesError == null)
              const Text(
                'No core values ratings available for this school year.',
                style: TextStyle(fontSize: 12),
              )
            else if (ratings.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final core in coreValues) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        core,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Indicator')),
                          DataColumn(label: Text('Q1')),
                          DataColumn(label: Text('Q2')),
                          DataColumn(label: Text('Q3')),
                          DataColumn(label: Text('Q4')),
                        ],
                        rows: grouped[core]!.entries.map((entry) {
                          final indicatorCode = entry.key;
                          final perQuarter = entry.value;
                          String ratingFor(int q) => perQuarter[q] ?? '';
                          return DataRow(
                            cells: [
                              DataCell(Text(indicatorCode)),
                              DataCell(Text(ratingFor(1))),
                              DataCell(Text(ratingFor(2))),
                              DataCell(Text(ratingFor(3))),
                              DataCell(Text(ratingFor(4))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingLegend() {
    const codes = ['AO', 'SO', 'RO', 'NO'];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: codes
          .map(
            (code) => Chip(
              label: Text(
                '$code - ${SF9CoreValueRating.describeRating(code)}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAttendanceSection() {
    final summaries = List<AttendanceMonthlySummary>.from(_attendanceSummaries)
      ..sort((a, b) => a.month.compareTo(b.month));
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Attendance', Icons.calendar_today_outlined),
            const SizedBox(height: 8),
            if (_attendanceError != null) ...[
              Text(
                _attendanceError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
            ],
            if (summaries.isEmpty && _attendanceError == null)
              const Text(
                'No attendance summary available for this school year.',
                style: TextStyle(fontSize: 12),
              )
            else if (summaries.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('School Days')),
                    DataColumn(label: Text('Present')),
                    DataColumn(label: Text('Absent')),
                    DataColumn(label: Text('Attendance %')),
                  ],
                  rows: summaries.map((s) {
                    final rate = s.attendanceRate;
                    return DataRow(
                      cells: [
                        DataCell(Text(_monthLabel(s.month))),
                        DataCell(Text(s.schoolDays.toString())),
                        DataCell(Text(s.daysPresent.toString())),
                        DataCell(Text(s.daysAbsent.toString())),
                        DataCell(Text('${rate.toStringAsFixed(1)}%')),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferAdmissionSection() {
    final record = _transferRecord;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Transfer / Admission',
              Icons.transfer_within_a_station,
            ),
            const SizedBox(height: 8),
            if (_transferError != null) ...[
              Text(
                _transferError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
            ],
            if (record == null && _transferError == null)
              const Text(
                'No transfer/admission record for this school year.',
                style: TextStyle(fontSize: 12),
              )
            else if (record != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.eligibilityForAdmissionGrade != null)
                    Text(
                      'Eligibility for admission: '
                      '${record.eligibilityForAdmissionGrade}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (record.admittedGrade != null ||
                      record.admittedSection != null ||
                      record.admissionDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Admitted: '
                      '${record.admittedGrade != null ? 'Grade ${record.admittedGrade}' : ''}'
                      '${record.admittedSection != null ? ' - Section ${record.admittedSection}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (record.admissionDate != null)
                      Text(
                        'Date of admission: '
                        '${_formatDate(record.admissionDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                  if (record.fromSchool != null || record.toSchool != null) ...[
                    const SizedBox(height: 4),
                    if (record.fromSchool != null)
                      Text(
                        'From school: ${record.fromSchool}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (record.toSchool != null)
                      Text(
                        'To school: ${record.toSchool}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                  if (record.hasCancellationInfo) ...[
                    const SizedBox(height: 4),
                    if (record.canceledIn != null)
                      Text(
                        'Canceled in: ${record.canceledIn}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (record.cancellationDate != null)
                      Text(
                        'Cancellation date: '
                        '${_formatDate(record.cancellationDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                  if (record.approvedBy != null ||
                      record.createdBy != null) ...[
                    const SizedBox(height: 4),
                    if (record.approvedBy != null)
                      Text(
                        'Approved by: ${record.approvedBy}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (record.createdBy != null)
                      Text(
                        'Encoded by: ${record.createdBy}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _monthLabel(int month) {
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
    if (month < 1 || month >= names.length) {
      return 'Month $month';
    }
    return names[month];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Widget _buildStudentHeader() {
    final name = _studentName ?? 'Student';
    final gradeLabel = _gradeLevel != null
        ? 'Grade ${_gradeLevel.toString()}'
        : null;
    final section = _sectionName;
    final sy = _schoolYearLabel ?? _resolvedSchoolYear;
    final lrn = _lrn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (gradeLabel != null)
              Chip(
                label: Text(gradeLabel, style: const TextStyle(fontSize: 11)),
              ),
            if (section != null && section.isNotEmpty)
              Chip(
                label: Text(
                  'Section $section',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            if (sy != null && sy.isNotEmpty)
              Chip(
                label: Text('S.Y. $sy', style: const TextStyle(fontSize: 11)),
              ),
            if (lrn != null && lrn.isNotEmpty)
              Chip(
                label: Text('LRN: $lrn', style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuarterChips() {
    return Wrap(
      spacing: 6,
      children: List.generate(4, (index) {
        final q = index + 1;
        final selected = _selectedQuarter == q;
        return ChoiceChip(
          label: Text('Q$q'),
          selected: selected,
          onSelected: (_) {
            setState(() => _selectedQuarter = q);
          },
        );
      }),
    );
  }

  Widget _buildQuarterBody() {
    final q = _selectedQuarter;
    final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No grades saved for Quarter $q'),
        ),
      );
    }

    final avg =
        rows
            .map((r) => (r['transmuted_grade'] as num?)?.toDouble() ?? 0.0)
            .fold<double>(0.0, (a, b) => a + b) /
        rows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quarter $q',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text(
                'General Average: ${avg.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final r = rows[index];
              final courseId = r['course_id'].toString();
              final title = _courseTitles[courseId] ?? courseId;
              final fg = _num(r['transmuted_grade']);
              final teacherId = _courseTeacherIds[courseId];
              final teacherName = teacherId != null
                  ? _teacherNames[teacherId] ?? ''
                  : '';
              final rem = (r['remarks'] as String?)?.trim() ?? '';

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (teacherName.isNotEmpty)
                              Text(
                                'Teacher: $teacherName',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (rem.isNotEmpty)
                              Text(
                                rem,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        fg,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _num(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0.0;
    return d.toStringAsFixed(0);
  }
}
