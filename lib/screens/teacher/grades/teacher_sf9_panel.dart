import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/attendance_monthly_summary.dart';
import 'package:oro_site_high_school/models/quarterly_grade.dart';
import 'package:oro_site_high_school/models/sf9_core_value_rating.dart';
import 'package:oro_site_high_school/models/student_transfer_record.dart';
import 'package:oro_site_high_school/services/sf9_attendance_monthly_summary_service.dart';
import 'package:oro_site_high_school/services/sf9_core_value_rating_service.dart';
import 'package:oro_site_high_school/services/sf9_final_grade_service.dart';
import 'package:oro_site_high_school/services/student_transfer_record_service.dart';

/// Compact SF9 workspace for teachers.
///
/// This widget mirrors the student SF9 preview but adds
/// inline editing for core values and monthly attendance.
class TeacherSf9Panel extends StatefulWidget {
  const TeacherSf9Panel({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  State<TeacherSf9Panel> createState() => _TeacherSf9PanelState();
}

class _TeacherSf9PanelState extends State<TeacherSf9Panel> {
  final Sf9FinalGradeService _finalGradeService = Sf9FinalGradeService();
  final Sf9CoreValueRatingService _coreValueService =
      Sf9CoreValueRatingService();
  final Sf9AttendanceMonthlySummaryService _attendanceService =
      Sf9AttendanceMonthlySummaryService();
  final StudentTransferRecordService _transferService =
      StudentTransferRecordService();

  bool _loading = true;
  bool _savingCoreValues = false;
  bool _savingAttendance = false;

  String? _schoolYear;
  String? _schoolYearError;
  String? _finalGradesError;
  String? _coreValuesError;
  String? _attendanceError;
  String? _transferError;

  List<FinalGrade> _finalGrades = [];
  List<SF9CoreValueRating> _coreValues = [];
  List<AttendanceMonthlySummary> _attendance = [];
  StudentTransferRecord? _transfer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _resolveSchoolYear() async {
    final supa = Supabase.instance.client;
    final studentId = widget.studentId;
    String? sy;

    // 1) Try students.school_year
    try {
      final row = await supa
          .from('students')
          .select('school_year')
          .eq('id', studentId)
          .maybeSingle();
      if (row is Map<String, dynamic>) {
        final raw = row['school_year'] as String?;
        final trimmed = raw?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          sy = trimmed;
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('TeacherSf9Panel._resolveSchoolYear step1 error: $e\n$st');
    }

    // 2) Derive from latest courses.school_year for student's classrooms
    if (sy == null || sy.isEmpty) {
      try {
        final csRows = await supa
            .from('classroom_students')
            .select('classroom_id')
            .eq('student_id', studentId);

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
        print('TeacherSf9Panel._resolveSchoolYear step2 error: $e\n$st');
      }
    }

    // 3) Derive from latest final_grades.school_year
    if (sy == null || sy.isEmpty) {
      try {
        final rows = await supa
            .from('final_grades')
            .select('school_year')
            .eq('student_id', studentId)
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
        print('TeacherSf9Panel._resolveSchoolYear step3 error: $e\n$st');
      }
    }

    return sy;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _schoolYearError = null;
      _finalGradesError = null;
      _coreValuesError = null;
      _attendanceError = null;
      _transferError = null;
    });

    final sy = await _resolveSchoolYear();
    if (!mounted) return;

    if (sy == null || sy.isEmpty) {
      setState(() {
        _loading = false;
        _schoolYear = null;
        _schoolYearError =
            'Unable to determine the school year for this SF9 view.\n'
            'Please check the student profile or final grades.';
        _finalGrades = [];
        _coreValues = [];
        _attendance = [];
        _transfer = null;
      });
      return;
    }

    String? fgError;
    String? cvError;
    String? attError;
    String? trError;

    final futures = <Future<dynamic>>[
      _finalGradeService
          .getFinalGradesForStudent(studentId: widget.studentId, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print('TeacherSf9Panel._loadData final_grades error: $e\n$st');
            fgError = 'Failed to load final grades.';
            return <FinalGrade>[];
          }),
      _coreValueService
          .getRatingsForStudent(studentId: widget.studentId, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print('TeacherSf9Panel._loadData core_values error: $e\n$st');
            cvError = 'Failed to load core values.';
            return <SF9CoreValueRating>[];
          }),
      _attendanceService
          .getMonthlySummariesForStudent(
            studentId: widget.studentId,
            schoolYear: sy,
          )
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print('TeacherSf9Panel._loadData attendance error: $e\n$st');
            attError = 'Failed to load attendance.';
            return <AttendanceMonthlySummary>[];
          }),
      _transferService
          .getActiveTransferRecord(studentId: widget.studentId, schoolYear: sy)
          .catchError((Object e, StackTrace st) {
            // ignore: avoid_print
            print('TeacherSf9Panel._loadData transfer error: $e\n$st');
            trError = 'Failed to load transfer/admission record.';
            return null;
          }),
    ];

    final results = await Future.wait<dynamic>(futures);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _schoolYear = sy;
      _finalGrades = results[0] as List<FinalGrade>;
      _coreValues = results[1] as List<SF9CoreValueRating>;
      _attendance = results[2] as List<AttendanceMonthlySummary>;
      _transfer = results[3] as StudentTransferRecord?;
      _finalGradesError = fgError;
      _coreValuesError = cvError;
      _attendanceError = attError;
      _transferError = trError;
    });
  }

  Future<void> _updateCoreValueRating({
    required String coreValueCode,
    required String indicatorCode,
    required int quarter,
    required String rating,
  }) async {
    if (_schoolYear == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingCoreValues = true);
    try {
      await _coreValueService.saveRating(
        studentId: widget.studentId,
        schoolYear: _schoolYear!,
        quarter: quarter,
        coreValueCode: coreValueCode,
        indicatorCode: indicatorCode,
        rating: rating,
      );
      await _loadData();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Core value rating saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save rating: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCoreValues = false);
      }
    }
  }

  Future<void> _editAttendance(AttendanceMonthlySummary summary) async {
    final messenger = ScaffoldMessenger.of(context);
    final schoolDaysController = TextEditingController(
      text: summary.schoolDays.toString(),
    );
    final presentController = TextEditingController(
      text: summary.daysPresent.toString(),
    );
    final absentController = TextEditingController(
      text: summary.daysAbsent.toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${_monthLabel(summary.month)} attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'School days'),
              ),
              TextField(
                controller: presentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Days present'),
              ),
              TextField(
                controller: absentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Days absent'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final schoolDays = int.tryParse(schoolDaysController.text.trim());
    final present = int.tryParse(presentController.text.trim());
    final absent = int.tryParse(absentController.text.trim());

    if (schoolDays == null || present == null || absent == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers.')),
      );
      return;
    }
    if (_schoolYear == null) return;

    setState(() => _savingAttendance = true);
    try {
      await _attendanceService.saveMonthlySummary(
        studentId: widget.studentId,
        schoolYear: _schoolYear!,
        month: summary.month,
        schoolDays: schoolDays,
        daysPresent: present,
        daysAbsent: absent,
      );
      await _loadData();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Attendance summary saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAttendance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_schoolYearError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _schoolYearError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    final ratingsByCore = <String, Map<String, Map<int, String>>>{};
    for (final r in _coreValues) {
      final byIndicator = ratingsByCore.putIfAbsent(
        r.coreValueCode,
        () => <String, Map<int, String>>{},
      );
      final perQuarter = byIndicator.putIfAbsent(
        r.indicatorCode,
        () => <int, String>{},
      );
      perQuarter[r.quarter] = r.rating;
    }
    final coreKeys = ratingsByCore.keys.toList()..sort();
    const ratingOptions = ['AO', 'SO', 'RO', 'NO'];

    final attendance = List<AttendanceMonthlySummary>.from(_attendance)
      ..sort((a, b) => a.month.compareTo(b.month));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SF9 – ${widget.studentName}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (_schoolYear != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                'School Year: $_schoolYear',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          if (_finalGradesError != null)
            Text(
              _finalGradesError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          if (_finalGrades.isNotEmpty)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _finalGrades.map((g) {
                    final fg = g.finalGrade.toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.courseName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fg,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: g.isPassing
                                  ? Colors.green.shade700
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'No final grades yet for this school year.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Core Values',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'AO=Always, SO=Sometimes, RO=Rarely, NO=Not observed',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          if (_coreValuesError != null)
            Text(
              _coreValuesError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          if (ratingsByCore.isEmpty)
            const Text(
              'No core value ratings yet for this school year.',
              style: TextStyle(fontSize: 12),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final core in coreKeys) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      core,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: ratingsByCore[core]!.entries.map((entry) {
                          final indicator = entry.key;
                          final perQuarter = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    indicator,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                for (var q = 1; q <= 4; q++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: DropdownButton<String>(
                                      value: perQuarter[q],
                                      hint: const Text(
                                        '-',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      items: ratingOptions
                                          .map(
                                            (code) => DropdownMenuItem(
                                              value: code,
                                              child: Text(
                                                code,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _savingCoreValues
                                          ? null
                                          : (value) {
                                              if (value == null) return;
                                              _updateCoreValueRating(
                                                coreValueCode: core,
                                                indicatorCode: indicator,
                                                quarter: q,
                                                rating: value,
                                              );
                                            },
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          if (_savingCoreValues)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          Text(
            'Attendance',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (_attendanceError != null)
            Text(
              _attendanceError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          if (attendance.isEmpty)
            const Text(
              'No monthly attendance summary yet.',
              style: TextStyle(fontSize: 12),
            )
          else
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: attendance.map((s) {
                    final rate = s.attendanceRate;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _monthLabel(s.month),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${s.schoolDays}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${s.daysPresent}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${s.daysAbsent}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rate.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: _savingAttendance
                                ? null
                                : () => _editAttendance(s),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          if (_savingAttendance)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          Text(
            'Transfer / Admission',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (_transferError != null)
            Text(
              _transferError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            )
          else if (_transfer == null)
            const Text(
              'No active transfer/admission record for this school year.',
              style: TextStyle(fontSize: 12),
            )
          else
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_transfer!.eligibilityForAdmissionGrade != null)
                      Text(
                        'Eligibility: ${_transfer!.eligibilityForAdmissionGrade}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.admittedGrade != null)
                      Text(
                        'Admitted grade: ${_transfer!.admittedGrade}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.admissionDate != null)
                      Text(
                        'Admission date: ${_formatDate(_transfer!.admissionDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.fromSchool != null &&
                        _transfer!.fromSchool!.isNotEmpty)
                      Text(
                        'From school: ${_transfer!.fromSchool}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.toSchool != null &&
                        _transfer!.toSchool!.isNotEmpty)
                      Text(
                        'To school: ${_transfer!.toSchool}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.canceledIn != null &&
                        _transfer!.canceledIn!.isNotEmpty)
                      Text(
                        'Cancelled in: ${_transfer!.canceledIn}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_transfer!.cancellationDate != null)
                      Text(
                        'Cancellation date: ${_formatDate(_transfer!.cancellationDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _monthLabel(int month) {
    const names = [
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
    if (month < 1 || month > 12) return 'Month $month';
    return names[month - 1];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
