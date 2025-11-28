import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_subject_enrollment.dart';

/// Service for managing student TLE sub-subject enrollments
class StudentSubjectEnrollmentService {
  final _supabase = Supabase.instance.client;

  /// Teacher enrolls a student in a TLE sub-subject (Grades 7-8)
  Future<void> enrollStudentInTLE({
    required String studentId,
    required String classroomId,
    required String tleParentId,
    required String tleSubId,
  }) async {
    try {
      print('📝 [EnrollmentService] Enrolling student $studentId in TLE sub-subject $tleSubId');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call RPC function
      await _supabase.rpc('enroll_student_in_tle', params: {
        'p_student_id': studentId,
        'p_classroom_id': classroomId,
        'p_tle_parent_id': tleParentId,
        'p_tle_sub_id': tleSubId,
        'p_enrolled_by': currentUser.id,
      });

      print('✅ [EnrollmentService] Student enrolled successfully');
    } catch (e) {
      print('❌ [EnrollmentService] Error enrolling student: $e');
      rethrow;
    }
  }

  /// Student self-enrolls in a TLE sub-subject (Grades 9-10 only)
  Future<void> selfEnrollInTLE({
    required String studentId,
    required String classroomId,
    required String tleParentId,
    required String tleSubId,
  }) async {
    try {
      print('📝 [EnrollmentService] Student $studentId self-enrolling in TLE sub-subject $tleSubId');

      // Call RPC function (will validate grade level 9-10)
      await _supabase.rpc('self_enroll_in_tle', params: {
        'p_student_id': studentId,
        'p_classroom_id': classroomId,
        'p_tle_parent_id': tleParentId,
        'p_tle_sub_id': tleSubId,
      });

      print('✅ [EnrollmentService] Student self-enrolled successfully');
    } catch (e) {
      print('❌ [EnrollmentService] Error self-enrolling student: $e');
      rethrow;
    }
  }

  /// Get student's enrolled TLE sub-subject
  Future<String?> getStudentTLEEnrollment({
    required String studentId,
    required String classroomId,
    required String tleParentId,
  }) async {
    try {
      print('🔍 [EnrollmentService] Getting TLE enrollment for student $studentId');

      // Call RPC function
      final result = await _supabase.rpc('get_student_tle_enrollment', params: {
        'p_student_id': studentId,
        'p_classroom_id': classroomId,
        'p_tle_parent_id': tleParentId,
      });

      print('✅ [EnrollmentService] Enrollment fetched: $result');

      return result as String?;
    } catch (e) {
      print('❌ [EnrollmentService] Error fetching enrollment: $e');
      rethrow;
    }
  }

  /// Bulk enroll multiple students in TLE sub-subjects
  /// enrollments: List of maps with 'student_id' and 'tle_sub_id'
  Future<int> bulkEnrollStudentsInTLE({
    required List<Map<String, String>> enrollments,
    required String classroomId,
    required String tleParentId,
  }) async {
    try {
      print('📝 [EnrollmentService] Bulk enrolling ${enrollments.length} students');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call RPC function
      final count = await _supabase.rpc('bulk_enroll_students_in_tle', params: {
        'p_enrollments': enrollments,
        'p_classroom_id': classroomId,
        'p_tle_parent_id': tleParentId,
        'p_enrolled_by': currentUser.id,
      });

      print('✅ [EnrollmentService] Bulk enrolled $count students');

      return count as int;
    } catch (e) {
      print('❌ [EnrollmentService] Error bulk enrolling students: $e');
      rethrow;
    }
  }

  /// Get all enrollments for a classroom (for teachers)
  Future<List<StudentSubjectEnrollment>> getClassroomEnrollments({
    required String classroomId,
    required String tleParentId,
  }) async {
    try {
      print('📋 [EnrollmentService] Fetching enrollments for classroom $classroomId');

      final response = await _supabase
          .from('student_subject_enrollments')
          .select()
          .eq('classroom_id', classroomId)
          .eq('parent_subject_id', tleParentId)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      print('✅ [EnrollmentService] Fetched ${response.length} enrollments');

      return (response as List)
          .map((json) => StudentSubjectEnrollment.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [EnrollmentService] Error fetching enrollments: $e');
      rethrow;
    }
  }
}

