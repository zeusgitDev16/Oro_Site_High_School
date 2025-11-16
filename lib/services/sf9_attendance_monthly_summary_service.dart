import 'package:oro_site_high_school/models/attendance_monthly_summary.dart';
import 'package:oro_site_high_school/models/deped_attendance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for attendance_monthly_summary table.
///
/// This stores pre-aggregated monthly counts that SF9/SF2 exports can use
/// without scanning all daily attendance records every time.
class Sf9AttendanceMonthlySummaryService {
  Sf9AttendanceMonthlySummaryService._internal();
  static final Sf9AttendanceMonthlySummaryService _instance =
      Sf9AttendanceMonthlySummaryService._internal();
  factory Sf9AttendanceMonthlySummaryService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all monthly summaries for a learner in a school year, ordered by month.
  Future<List<AttendanceMonthlySummary>> getMonthlySummariesForStudent({
    required String studentId,
    required String schoolYear,
  }) async {
    try {
      final response = await _supabase
          .from('attendance_monthly_summary')
          .select()
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .order('month', ascending: true);

      final rows = response as List<dynamic>;
      return rows
          .map(
            (row) =>
                AttendanceMonthlySummary.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'Sf9AttendanceMonthlySummaryService.getMonthlySummariesForStudent '
        'error: $e\n$st',
      );
      return [];
    }
  }

  /// Create or update a single monthly summary row.
  ///
  /// The unique key is (student_id, school_year, month).
  Future<AttendanceMonthlySummary> saveMonthlySummary({
    required String studentId,
    required String schoolYear,
    required int month,
    required int schoolDays,
    required int daysPresent,
    required int daysAbsent,
  }) async {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12.');
    }
    if (schoolDays < 0 || daysPresent < 0 || daysAbsent < 0) {
      throw ArgumentError('Attendance counts cannot be negative.');
    }
    if (daysPresent + daysAbsent > schoolDays) {
      throw ArgumentError(
        'daysPresent + daysAbsent cannot exceed schoolDays '
        '($daysPresent + $daysAbsent > $schoolDays).',
      );
    }

    try {
      final now = DateTime.now().toIso8601String();
      final payload = <String, dynamic>{
        'student_id': studentId,
        'school_year': schoolYear,
        'month': month,
        'school_days': schoolDays,
        'days_present': daysPresent,
        'days_absent': daysAbsent,
        'updated_at': now,
      };

      final existing = await _supabase
          .from('attendance_monthly_summary')
          .select('id')
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .eq('month', month)
          .maybeSingle();

      Map<String, dynamic> row;
      if (existing != null) {
        row = await _supabase
            .from('attendance_monthly_summary')
            .update(payload)
            .eq('id', existing['id'])
            .select()
            .single();
      } else {
        payload['created_at'] = now;
        row = await _supabase
            .from('attendance_monthly_summary')
            .insert(payload)
            .select()
            .single();
      }

      return AttendanceMonthlySummary.fromJson(row);
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'Sf9AttendanceMonthlySummaryService.saveMonthlySummary error: $e\n$st',
      );
      rethrow;
    }
  }

  /// Compute a monthly summary from in-memory daily DepEd attendance records.
  ///
  /// - `schoolDays` is the number of records in the target month
  /// - `daysPresent` counts records where `isPresent` is true (code P)
  /// - `daysAbsent` counts records where `isAbsent` is true (codes A / UA)
  ///   All other codes (late, excused, etc.) contribute to `schoolDays`
  ///   but are neither present nor absent; they show up via `daysNotRecorded`.
  AttendanceMonthlySummary computeMonthlySummaryFromDaily({
    required String studentId,
    required String schoolYear,
    required int month,
    required List<DepEdAttendance> dailyRecords,
  }) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12.');
    }

    final filtered = dailyRecords.where((r) => r.date.month == month).toList();
    final schoolDays = filtered.length;
    final daysPresent = filtered.where((r) => r.isPresent).length;
    final daysAbsent = filtered.where((r) => r.isAbsent).length;

    final now = DateTime.now();

    return AttendanceMonthlySummary(
      id: 'local-$studentId-$schoolYear-$month',
      studentId: studentId,
      schoolYear: schoolYear,
      month: month,
      schoolDays: schoolDays,
      daysPresent: daysPresent,
      daysAbsent: daysAbsent,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convenience helper that computes a summary from daily records
  /// and immediately persists it to the database.
  Future<AttendanceMonthlySummary> computeAndSaveMonthlySummaryFromDaily({
    required String studentId,
    required String schoolYear,
    required int month,
    required List<DepEdAttendance> dailyRecords,
  }) async {
    final summary = computeMonthlySummaryFromDaily(
      studentId: studentId,
      schoolYear: schoolYear,
      month: month,
      dailyRecords: dailyRecords,
    );

    return saveMonthlySummary(
      studentId: studentId,
      schoolYear: schoolYear,
      month: month,
      schoolDays: summary.schoolDays,
      daysPresent: summary.daysPresent,
      daysAbsent: summary.daysAbsent,
    );
  }
}
