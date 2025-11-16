import 'package:oro_site_high_school/models/quarterly_grade.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing final_grades records used for SF9 export.
///
/// This service is intentionally thin: the database (with RLS) owns
/// authorization, and this class focuses on:
/// - Querying final grades by student/course and school year
/// - Computing final grade metadata from quarter grades
/// - Creating/updating rows in the final_grades table
class Sf9FinalGradeService {
  Sf9FinalGradeService._internal();
  static final Sf9FinalGradeService _instance =
      Sf9FinalGradeService._internal();
  factory Sf9FinalGradeService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final DepEdGradeService _gradeService = DepEdGradeService();

  /// Get all final grades for a learner in a given school year.
  Future<List<FinalGrade>> getFinalGradesForStudent({
    required String studentId,
    required String schoolYear,
  }) async {
    try {
      final response = await _supabase
          .from('final_grades')
          .select()
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .order('course_name', ascending: true);

      final rows = response as List<dynamic>;
      return rows
          .map((row) => FinalGrade.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      // For reporting screens an empty list is usually safer than a hard crash.
      // Callers that care about errors should catch and log upstream.
      // ignore: avoid_print
      print('Sf9FinalGradeService.getFinalGradesForStudent error: $e\n$st');
      return [];
    }
  }

  /// Get all final grades for a course in a given school year.
  Future<List<FinalGrade>> getFinalGradesForCourse({
    required String courseId,
    required String schoolYear,
  }) async {
    try {
      final response = await _supabase
          .from('final_grades')
          .select()
          .eq('course_id', courseId)
          .eq('school_year', schoolYear)
          .order('student_name', ascending: true);

      final rows = response as List<dynamic>;
      return rows
          .map((row) => FinalGrade.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('Sf9FinalGradeService.getFinalGradesForCourse error: $e\n$st');
      return [];
    }
  }

  /// Create or update a final_grades row for a student + course + school_year.
  ///
  /// The method:
  /// - Computes the numeric final grade from the provided quarter grades
  /// - Derives transmuted grade, remark, and passing flag using DepEd rules
  /// - Inserts a new row or updates the existing one (if already present)
  Future<FinalGrade> saveFinalGrade({
    required String studentId,
    required String courseId,
    required String schoolYear,
    String? studentName,
    String? courseName,
    double? quarter1,
    double? quarter2,
    double? quarter3,
    double? quarter4,
  }) async {
    try {
      final finalNumeric =
          FinalGrade.calculateFinal(quarter1, quarter2, quarter3, quarter4);

      // Guard against missing quarter data; keep a consistent, explicit state.
      final double safeFinal = finalNumeric > 0 ? finalNumeric : 0.0;
      final String transmutedGrade =
          safeFinal > 0 ? safeFinal.round().toString() : '';
      final String gradeRemarks = safeFinal > 0
          ? _gradeService.getGradeRemarks(safeFinal)
          : 'No final grade available';
      final bool isPassing =
          safeFinal > 0 && _gradeService.isPassing(safeFinal);

      final now = DateTime.now().toIso8601String();

      final payload = <String, dynamic>{
        'student_id': studentId,
        'course_id': courseId,
        'school_year': schoolYear,
        'student_name': studentName,
        'course_name': courseName,
        'quarter_1': quarter1,
        'quarter_2': quarter2,
        'quarter_3': quarter3,
        'quarter_4': quarter4,
        'final_grade': safeFinal,
        'transmuted_grade': transmutedGrade,
        'grade_remarks': gradeRemarks,
        'is_passing': isPassing,
        'updated_at': now,
      };

      // Remove optional nulls so that updates do not overwrite existing values
      // with null accidentally.
      payload.removeWhere((_, value) => value == null);

      // Check if a row already exists for this (student, course, school_year).
      final existing = await _supabase
          .from('final_grades')
          .select('id')
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .eq('school_year', schoolYear)
          .maybeSingle();

      Map<String, dynamic> row;
      if (existing != null) {
        row = await _supabase
            .from('final_grades')
            .update(payload)
            .eq('id', existing['id'])
            .select()
            .single();
      } else {
        payload['created_at'] = now;
        row = await _supabase
            .from('final_grades')
            .insert(payload)
            .select()
            .single();
      }

      return FinalGrade.fromJson(row);
    } catch (e, st) {
      // For write operations we rethrow so the caller can surface a clear error.
      // ignore: avoid_print
      print('Sf9FinalGradeService.saveFinalGrade error: $e\n$st');
      rethrow;
    }
  }
}

