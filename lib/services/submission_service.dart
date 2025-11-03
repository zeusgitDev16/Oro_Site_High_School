import 'package:supabase_flutter/supabase_flutter.dart';

/// Submission Service
/// Handles CRUD for assignment_submissions with RLS-safe operations.
class SubmissionService {
  final _supabase = Supabase.instance.client;

  /// Get a student's submission for an assignment, or null if it doesn't exist
  Future<Map<String, dynamic>?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final rows = await _supabase
          .from('assignment_submissions')
          .select()
          .eq('assignment_id', assignmentId)
          .eq('student_id', studentId)
          .limit(1);
      if (rows is List && rows.isNotEmpty) {
        return Map<String, dynamic>.from(rows.first);
      }
      return null;
    } catch (e) {
      // If no row due to RLS or not found, return null
      return null;
    }
  }

  /// Create a draft submission row for a student. RLS requires student is enrolled.
  Future<Map<String, dynamic>> createSubmission({
    required String assignmentId,
    required String studentId,
    required String classroomId,
  }) async {
    final payload = {
      'assignment_id': assignmentId,
      'student_id': studentId,
      'classroom_id': classroomId,
      'status': 'draft',
      'submission_content': {},
    };
    final inserted = await _supabase
        .from('assignment_submissions')
        .insert(payload)
        .select()
        .single();
    return inserted as Map<String, dynamic>;
  }

  /// Get or create (draft) submission row for a student.
  Future<Map<String, dynamic>> getOrCreateSubmission({
    required String assignmentId,
    required String studentId,
    required String classroomId,
  }) async {
    final existing = await getStudentSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
    );
    if (existing != null) return existing;

    // Create new draft submission
    return await createSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
      classroomId: classroomId,
    );
  }

  /// Save submission content (UI autosave or explicit save)
  Future<Map<String, dynamic>> saveSubmissionContent({
    required String assignmentId,
    required String studentId,
    required Map<String, dynamic> content,
  }) async {
    final row = await _supabase
        .from('assignment_submissions')
        .update({'submission_content': content})
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .select()
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  /// Submit submission (finalize)
  Future<void> submitSubmission({
    required String assignmentId,
    required String studentId,
    int? score,
    int? maxScore,
  }) async {
    final update = <String, dynamic>{
      'status': 'submitted',
      'submitted_at': DateTime.now().toIso8601String(),
    };
    if (score != null) update['score'] = score;
    if (maxScore != null) update['max_score'] = maxScore;

    await _supabase
        .from('assignment_submissions')
        .update(update)
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId);
  }

  /// Get all submissions for a given assignment (teacher view)
  Future<List<Map<String, dynamic>>> getSubmissionsForAssignment(String assignmentId) async {
    final rows = await _supabase
        .from('assignment_submissions')
        .select('id, student_id, status, submitted_at, score, max_score, is_late')
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
