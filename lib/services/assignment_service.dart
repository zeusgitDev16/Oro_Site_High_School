import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Assignment Service
/// Handles all assignment-related database operations
class AssignmentService {
  final _supabase = Supabase.instance.client;

  /// Get all assignments for a specific classroom.
  ///
  /// Classroom-scoped / classroom-shared data:
  /// - Returns all assignments in the classroom, regardless of which teacher
  ///   created them.
  /// - Visibility is enforced by the "Teachers can view their classroom
  ///   assignments" RLS policy on public.assignments.
  ///
  /// IMPORTANT: This is classroom-scoped by design. If you need personal
  /// teacher data (for example, a "My assignments" view), add a
  /// .eq('teacher_id', auth.uid()) filter in the caller instead of changing this
  /// method.
  Future<List<Map<String, dynamic>>> getClassroomAssignments(
    String classroomId,
  ) async {
    try {
      print('📚 Fetching assignments for classroom: $classroomId');

      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ Fetched ${(response as List).length} assignments');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching classroom assignments: $e');
      rethrow;
    }
  }

  /// Get assignment count for a classroom
  Future<int> getClassroomAssignmentCount(String classroomId) async {
    try {
      final assignments = await getClassroomAssignments(classroomId);
      return assignments.length;
    } catch (e) {
      print('❌ Error getting assignment count: $e');
      return 0;
    }
  }

  /// Get unpublished (draft) assignments for a classroom (management pool).
  ///
  /// Classroom-scoped / classroom-shared data:
  /// - Returns all unpublished assignments in the classroom, not just those
  ///   authored by the current teacher.
  /// - Visibility is enforced by the "Teachers can view their classroom
  ///   assignments" RLS policy on public.assignments.
  ///
  /// IMPORTANT: This is classroom-scoped by design. If you need personal
  /// teacher data (for example, a teacher's own drafts), add a
  /// .eq('teacher_id', auth.uid()) filter in the caller instead of changing
  /// this method.
  Future<List<Map<String, dynamic>>> getUnpublishedAssignmentsByClassroom(
    String classroomId,
  ) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('is_active', true)
          .eq('is_published', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching unpublished assignments: $e');
      rethrow;
    }
  }

  /// Get a single assignment by ID
  Future<Map<String, dynamic>?> getAssignmentById(String assignmentId) async {
    try {
      print('📖 Fetching assignment: $assignmentId');

      final response = await _supabase
          .from('assignments')
          .select()
          .eq('id', assignmentId)
          .single();

      print('✅ Assignment fetched successfully');
      return response;
    } catch (e) {
      print('❌ Error fetching assignment: $e');
      return null;
    }
  }

  /// Create a new assignment
  Future<Map<String, dynamic>> createAssignment({
    required String classroomId,
    required String teacherId,
    required String title,
    String? description,
    required String assignmentType,
    required int totalPoints,
    DateTime? dueDate,
    bool allowLateSubmissions = true,
    Map<String, dynamic>? content,
    String? courseId,
    bool isPublished = false,
    String?
    component, // 'written_works' | 'performance_task' | 'quarterly_assessment'
    int? quarterNo, // 1..4
  }) async {
    try {
      print('📝 Creating assignment: $title');
      print('   Classroom: $classroomId');
      print('   Type: $assignmentType');
      print('   Points: $totalPoints');
      print('   Allow Late: $allowLateSubmissions');

      final assignmentData = {
        'classroom_id': classroomId,
        'teacher_id': teacherId,
        'title': title,
        'description': description,
        'assignment_type': assignmentType,
        'total_points': totalPoints,
        'due_date': dueDate?.toIso8601String(),
        'allow_late_submissions': allowLateSubmissions,
        'content': content ?? {},
        'is_published': isPublished,
        'is_active': true,
        if (courseId != null) 'course_id': courseId,
        if (component != null) 'component': component,
        if (quarterNo != null) 'quarter_no': quarterNo,
      };

      Map<String, dynamic>? response;
      try {
        response = await _supabase
            .from('assignments')
            .insert(assignmentData)
            .select()
            .single();
      } catch (e) {
        // Fallback if new columns are not yet present in DB
        try {
          final fallback = Map<String, dynamic>.from(assignmentData);
          fallback.remove('component');
          fallback.remove('quarter_no');
          response = await _supabase
              .from('assignments')
              .insert(fallback)
              .select()
              .single();
        } catch (_) {
          rethrow;
        }
      }

      print('✅ Assignment created successfully: ${response!['id']}');
      return response!;
    } catch (e) {
      print('❌ Error creating assignment: $e');
      rethrow;
    }
  }

  /// Update an assignment
  Future<Map<String, dynamic>> updateAssignment({
    required String assignmentId,
    String? title,
    String? description,
    String? assignmentType,
    int? totalPoints,
    DateTime? dueDate,
    bool? allowLateSubmissions,
    Map<String, dynamic>? content,
    bool? isPublished,
    bool? isActive,
    String? courseId,
    String?
    component, // 'written_works' | 'performance_task' | 'quarterly_assessment'
    int? quarterNo, // 1..4
  }) async {
    try {
      print('✏️ Updating assignment: $assignmentId');

      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (assignmentType != null) updates['assignment_type'] = assignmentType;
      if (totalPoints != null) updates['total_points'] = totalPoints;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (allowLateSubmissions != null)
        updates['allow_late_submissions'] = allowLateSubmissions;
      if (content != null) updates['content'] = content;
      if (isPublished != null) updates['is_published'] = isPublished;
      if (isActive != null) updates['is_active'] = isActive;
      if (courseId != null) updates['course_id'] = courseId;
      if (component != null) updates['component'] = component;
      if (quarterNo != null) updates['quarter_no'] = quarterNo;

      Map<String, dynamic>? response;
      try {
        response = await _supabase
            .from('assignments')
            .update(updates)
            .eq('id', assignmentId)
            .select()
            .single();
      } catch (e) {
        // Fallback if new columns are not yet present in DB
        try {
          final fallback = Map<String, dynamic>.from(updates);
          fallback.remove('component');
          fallback.remove('quarter_no');
          response = await _supabase
              .from('assignments')
              .update(fallback)
              .eq('id', assignmentId)
              .select()
              .single();
        } catch (_) {
          rethrow;
        }
      }

      print('✅ Assignment updated successfully');
      return response!;
    } catch (e) {
      print('❌ Error updating assignment: $e');
      rethrow;
    }
  }

  /// Delete an assignment and its related data (hard delete + safe cleanup)
  Future<void> deleteAssignment(String assignmentId) async {
    print('🗑️ Deleting assignment and related data: $assignmentId');

    // 1) Best-effort: delete storage files first so we still have file paths
    try {
      await deleteAssignmentStorageFiles(assignmentId);
    } catch (e) {
      print('⚠️ Storage cleanup failed (non-fatal): $e');
    }

    try {
      // 2) Best-effort: explicitly delete dependent rows (RLS may block; parent delete will cascade)
      try {
        await _supabase
            .from('assignment_files')
            .delete()
            .eq('assignment_id', assignmentId);
      } catch (e) {
        print(
          'ℹ️ Skipping explicit assignment_files delete (will cascade on parent delete): $e',
        );
      }
      try {
        await _supabase
            .from('assignment_submissions')
            .delete()
            .eq('assignment_id', assignmentId);
      } catch (e) {
        print(
          'ℹ️ Skipping explicit submissions delete (will cascade on parent delete): $e',
        );
      }

      // 3) Delete the assignment itself (ON DELETE CASCADE should remove children if configured)
      await _supabase.from('assignments').delete().eq('id', assignmentId);

      print('✅ Assignment deleted successfully (hard delete + cascade)');
    } catch (e) {
      print('❌ Error deleting assignment: $e');
      rethrow;
    }
  }

  /// Publish/Unpublish an assignment
  /// Defensive: also scope by teacher_id when available to avoid any accidental multi-row updates.
  Future<void> togglePublishAssignment(
    String assignmentId,
    bool isPublished,
  ) async {
    try {
      print(
        '📢 ${isPublished ? 'Publishing' : 'Unpublishing'} assignment: $assignmentId',
      );

      final updates = <String, dynamic>{'is_published': isPublished};
      // When unpublishing, detach from subject so it returns to the pool cleanly
      if (!isPublished) {
        updates['course_id'] = null;
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      var query = _supabase
          .from('assignments')
          .update(updates)
          .eq('id', assignmentId);
      // Extra safety: scope by teacher_id if we know it (no-op for admins without matching teacher_id)
      if (currentUserId != null && currentUserId.isNotEmpty) {
        query = query.eq('teacher_id', currentUserId);
      }
      await query;

      print(
        '✅ Assignment ${isPublished ? 'published' : 'unpublished'} successfully',
      );
    } catch (e) {
      print('❌ Error toggling publish status: $e');
      rethrow;
    }
  }

  /// Get assignments by type
  Future<List<Map<String, dynamic>>> getAssignmentsByType({
    required String classroomId,
    required String assignmentType,
  }) async {
    try {
      print(
        '📚 Fetching $assignmentType assignments for classroom: $classroomId',
      );

      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('assignment_type', assignmentType)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching assignments by type: $e');
      rethrow;
    }
  }

  /// Get upcoming assignments (due within next 7 days)
  Future<List<Map<String, dynamic>>> getUpcomingAssignments(
    String classroomId,
  ) async {
    try {
      print('📅 Fetching upcoming assignments for classroom: $classroomId');

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('is_active', true)
          .gte('due_date', now.toIso8601String())
          .lte('due_date', nextWeek.toIso8601String())
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching upcoming assignments: $e');
      rethrow;
    }
  }

  /// Get overdue assignments
  Future<List<Map<String, dynamic>>> getOverdueAssignments(
    String classroomId,
  ) async {
    try {
      print('⏰ Fetching overdue assignments for classroom: $classroomId');

      final now = DateTime.now();

      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('is_active', true)
          .lt('due_date', now.toIso8601String())
          .order('due_date', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching overdue assignments: $e');
      rethrow;
    }
  }

  /// Get assignments for a specific classroom and course (subject)
  Future<List<Map<String, dynamic>>> getAssignmentsByClassroomAndCourse({
    required String classroomId,
    required String courseId,
  }) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('course_id', courseId)
          .eq('is_active', true)
          .eq('is_published', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching assignments by classroom and course: $e');
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String assignmentId) async {
    try {
      await _supabase.rpc(
        'increment_assignment_view_count',
        params: {'assignment_id': assignmentId},
      );
    } catch (e) {
      print('❌ Error incrementing view count: $e');
      // Don't rethrow - view count is not critical
    }
  }

  /// Add uploaded files metadata to assignment_files table (batch insert)
  Future<void> addAssignmentFiles({
    required String assignmentId,
    required List<Map<String, dynamic>> files,
  }) async {
    if (files.isEmpty) return;
    try {
      print(
        '📎 Inserting ${files.length} assignment file records for assignment: $assignmentId',
      );
      // Normalize payload with assignment_id
      final payload = files
          .map(
            (f) => {
              'assignment_id': assignmentId,
              'file_name': f['file_name'],
              'file_path': f['file_path'],
              'file_size': f['file_size'],
              'file_type': f['file_type'],
              'uploaded_by': f['uploaded_by'],
              if (f['description'] != null) 'description': f['description'],
            },
          )
          .toList();

      await _supabase.from('assignment_files').insert(payload);
      print('✅ Assignment files inserted');
    } catch (e) {
      print('❌ Error inserting assignment files: $e');
      rethrow;
    }
  }

  /// Fetch file paths for an assignment (from assignment_files table)
  Future<List<String>> getAssignmentFilePaths(String assignmentId) async {
    try {
      final rows = await _supabase
          .from('assignment_files')
          .select('file_path')
          .eq('assignment_id', assignmentId);
      final list = (rows as List)
          .map((r) => (r['file_path'] as String?) ?? '')
          .where((p) => p.isNotEmpty)
          .toList();
      return list;
    } catch (e) {
      print('❌ Error fetching assignment file paths: $e');
      return [];
    }
  }

  /// Delete storage files for an assignment BEFORE deleting DB rows
  Future<void> deleteAssignmentStorageFiles(String assignmentId) async {
    try {
      final paths = await getAssignmentFilePaths(assignmentId);
      if (paths.isEmpty) {
        print('ℹ️ No storage files to delete for assignment: $assignmentId');
        return;
      }
      print(
        '🗑️ Removing ${paths.length} storage object(s) for assignment: $assignmentId',
      );
      await _supabase.storage.from('assignment_files').remove(paths);
      print('✅ Storage objects removed');
    } catch (e) {
      print('❌ Error deleting storage files: $e');
      // Do not rethrow to avoid blocking assignment delete; log instead.
    }
  }

  /// Get assignment statistics
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      print('📊 Fetching stats for assignment: $assignmentId');

      final assignment = await getAssignmentById(assignmentId);
      if (assignment == null) {
        throw Exception('Assignment not found');
      }

      // Get submission count
      final submissions = await _supabase
          .from('assignment_submissions')
          .select('id, status, is_late, score')
          .eq('assignment_id', assignmentId);

      final submissionList = submissions as List;
      final totalSubmissions = submissionList.length;
      final gradedSubmissions = submissionList
          .where((s) => s['status'] == 'graded')
          .length;
      final lateSubmissions = submissionList
          .where((s) => s['is_late'] == true)
          .length;

      // Calculate average score
      final gradedScores = submissionList
          .where((s) => s['score'] != null)
          .map((s) => s['score'] as int)
          .toList();

      final averageScore = gradedScores.isEmpty
          ? 0.0
          : gradedScores.reduce((a, b) => a + b) / gradedScores.length;

      return {
        'total_submissions': totalSubmissions,
        'graded_submissions': gradedSubmissions,
        'late_submissions': lateSubmissions,
        'average_score': averageScore,
        'view_count': assignment['view_count'] ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching assignment stats: $e');
      rethrow;
    }
  }
}
