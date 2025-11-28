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

  /// Batch fetch submissions for a student across multiple assignments
  /// Returns a list of rows with at least: assignment_id, status, submitted_at, score, max_score
  Future<List<Map<String, dynamic>>> getStudentSubmissionsForAssignments({
    required String studentId,
    required List<String> assignmentIds,
  }) async {
    if (assignmentIds.isEmpty) return [];
    final rows = await _supabase
        .from('assignment_submissions')
        .select('assignment_id, status, submitted_at, score, max_score')
        .inFilter('assignment_id', assignmentIds)
        .eq('student_id', studentId);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Create a draft submission row for a student. RLS requires student is enrolled.
  Future<Map<String, dynamic>> createSubmission({
    required String assignmentId,
    required String studentId,
    required String classroomId,
  }) async {
    print('📝 SubmissionService.createSubmission: Starting...');
    print('📝 Assignment ID (string): $assignmentId');
    print('📝 Student ID: $studentId');
    print('📝 Classroom ID: $classroomId');

    // Convert assignmentId to integer (assignments.id is bigint)
    final assignmentIdInt = int.tryParse(assignmentId);
    if (assignmentIdInt == null) {
      print('❌ SubmissionService.createSubmission: Invalid assignment ID');
      throw Exception('Invalid assignment ID: $assignmentId');
    }
    print('📝 Assignment ID (integer): $assignmentIdInt');

    final payload = {
      'assignment_id': assignmentIdInt,
      'student_id': studentId,
      'classroom_id': classroomId,
      'status': 'draft',
      'submission_content': {},
    };
    print('📝 SubmissionService.createSubmission: Payload: $payload');

    try {
      final inserted = await _supabase
          .from('assignment_submissions')
          .insert(payload)
          .select()
          .single();
      print('✅ SubmissionService.createSubmission: Success! ID: ${inserted['id']}');
      return Map<String, dynamic>.from(inserted);
    } catch (e, stackTrace) {
      print('❌ SubmissionService.createSubmission: Failed!');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
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

  /// Auto-grade and submit a student's objective assignment using
  /// the server-side RPC. Returns the updated submission row.
  Future<Map<String, dynamic>> autoGradeAndSubmit({
    required String assignmentId,
  }) async {
    print('📝 SubmissionService.autoGradeAndSubmit: Starting...');
    print('📝 Assignment ID (string): $assignmentId');

    // Convert assignmentId to integer for RPC (assignments.id is bigint)
    final assignmentIdInt = int.tryParse(assignmentId);
    if (assignmentIdInt == null) {
      print('❌ SubmissionService.autoGradeAndSubmit: Invalid assignment ID');
      throw Exception('Invalid assignment ID: $assignmentId');
    }
    print('📝 Assignment ID (integer): $assignmentIdInt');

    try {
      print('📝 SubmissionService.autoGradeAndSubmit: Calling RPC...');
      final result = await _supabase.rpc(
        'auto_grade_and_submit_assignment',
        params: {'p_assignment_id': assignmentIdInt},
      );
      print('✅ SubmissionService.autoGradeAndSubmit: RPC returned');
      print('📊 Result type: ${result.runtimeType}');
      print('📊 Result: $result');

      if (result == null) {
        print('❌ SubmissionService.autoGradeAndSubmit: RPC returned null');
        throw Exception('Auto-grade RPC returned null');
      }

      if (result is List) {
        if (result.isEmpty) {
          print('❌ SubmissionService.autoGradeAndSubmit: RPC returned empty list');
          throw Exception('Auto-grade RPC returned no rows');
        }
        print('✅ SubmissionService.autoGradeAndSubmit: Success (List)');
        return Map<String, dynamic>.from(result.first as Map);
      }

      if (result is Map) {
        print('✅ SubmissionService.autoGradeAndSubmit: Success (Map)');
        return Map<String, dynamic>.from(result);
      }

      print('❌ SubmissionService.autoGradeAndSubmit: Unexpected response type');
      throw Exception('Unexpected auto-grade RPC response');
    } catch (e, stackTrace) {
      print('❌ SubmissionService.autoGradeAndSubmit: Failed!');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update/override the score for a student's submission (manual grading)
  /// Also marks the submission as graded and timestamps it, so UI can reclassify
  /// from "to grade" to "completed" immediately without a manual refresh.
  Future<void> updateSubmissionGrade({
    required String assignmentId,
    required String studentId,
    required int score,
    int? maxScore,
  }) async {
    final update = <String, dynamic>{
      'score': score,
      'status': 'graded',
      'graded_at': DateTime.now().toIso8601String(),
    };
    if (maxScore != null) update['max_score'] = maxScore;
    await _supabase
        .from('assignment_submissions')
        .update(update)
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId);
  }

  /// Get all submissions for a given assignment (teacher view).
  ///
  /// Classroom-scoped / classroom-shared data:
  /// - Intended for grading workflows where teachers need to see all student
  ///   submissions for an assignment in a classroom.
  /// - Visibility is enforced by the "Teachers can view classroom submissions"
  ///   RLS policy on public.assignment_submissions.
  ///
  /// IMPORTANT: This method is classroom-scoped via RLS. Do not add
  /// teacher-specific filters here. For personal teacher dashboards, filter
  /// assignments by teacher_id in the caller before invoking this method.
  Future<List<Map<String, dynamic>>> getSubmissionsForAssignment(
    String assignmentId,
  ) async {
    // Classroom-scoped query: fetch all submissions for this assignment.
    // RLS ensures only teachers for the classroom/assignment can see these rows.
    final rows = await _supabase
        .from('assignment_submissions')
        .select(
          'id, student_id, status, submitted_at, score, max_score, is_late',
        )
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// **Phase 4: Update submission score (for gradebook)**
  /// Updates score and marks as graded with graded_by and graded_at
  Future<void> updateSubmissionScore({
    required String submissionId,
    required double score,
    String? gradedBy,
  }) async {
    final update = <String, dynamic>{
      'score': score,
      'status': 'graded',
      'graded_at': DateTime.now().toIso8601String(),
    };

    if (gradedBy != null) {
      update['graded_by'] = gradedBy;
    }

    await _supabase
        .from('assignment_submissions')
        .update(update)
        .eq('id', submissionId);
  }

  /// **Phase 4: Create manual submission (for gradebook)**
  /// Creates a submission when student hasn't submitted but teacher wants to enter a score
  Future<Map<String, dynamic>> createManualSubmission({
    required String assignmentId,
    required String studentId,
    required String classroomId,
    required double score,
    String? gradedBy,
  }) async {
    // Convert assignmentId to integer (assignments.id is bigint)
    final assignmentIdInt = int.tryParse(assignmentId);
    if (assignmentIdInt == null) {
      throw Exception('Invalid assignment ID: $assignmentId');
    }

    final payload = {
      'assignment_id': assignmentIdInt,
      'student_id': studentId,
      'classroom_id': classroomId,
      'status': 'graded',
      'score': score,
      'submitted_at': DateTime.now().toIso8601String(),
      'graded_at': DateTime.now().toIso8601String(),
      'submission_content': {},
    };

    if (gradedBy != null) {
      payload['graded_by'] = gradedBy;
    }

    final inserted = await _supabase
        .from('assignment_submissions')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(inserted);
  }
}
