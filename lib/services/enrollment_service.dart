import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enrollment.dart';

/// Enrollment Service - Manages student course enrollments
/// Handles enrollment creation, retrieval, updates, and bulk operations
class EnrollmentService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create single enrollment
  Future<Enrollment> createEnrollment({
    required String studentId,
    required int courseId,
    String status = 'active',
    String enrollmentType = 'manual',
  }) async {
    try {
      final response = await _supabase.from('enrollments').insert({
        'student_id': studentId,
        'course_id': courseId,
        'status': status,
        'enrollment_type': enrollmentType,
      }).select().single();

      return Enrollment.fromMap(response);
    } catch (e) {
      print('Error creating enrollment: $e');
      rethrow;
    }
  }

  /// Bulk enroll students in a course
  Future<List<Enrollment>> bulkEnrollStudents({
    required List<String> studentIds,
    required int courseId,
    String status = 'active',
    String enrollmentType = 'manual',
  }) async {
    try {
      final enrollments = studentIds.map((studentId) => {
            'student_id': studentId,
            'course_id': courseId,
            'status': status,
            'enrollment_type': enrollmentType,
          }).toList();

      final response = await _supabase
          .from('enrollments')
          .insert(enrollments)
          .select();

      return (response as List)
          .map((item) => Enrollment.fromMap(item))
          .toList();
    } catch (e) {
      print('Error bulk enrolling students: $e');
      rethrow;
    }
  }

  /// Auto-enroll students by section (uses database function)
  Future<int> autoEnrollBySection({
    required int courseId,
    required int gradeLevel,
    required String section,
  }) async {
    try {
      final response = await _supabase.rpc(
        'auto_enroll_students',
        params: {
          'p_course_id': courseId,
          'p_grade_level': gradeLevel,
          'p_section': section,
        },
      );
      return response as int;
    } catch (e) {
      print('Error auto-enrolling by section: $e');
      // Fallback to manual enrollment
      return await _manualAutoEnroll(courseId, gradeLevel, section);
    }
  }

  /// Manual auto-enrollment (fallback)
  Future<int> _manualAutoEnroll(
    int courseId,
    int gradeLevel,
    String section,
  ) async {
    try {
      final studentIds = await getStudentIdsBySection(gradeLevel, section);
      if (studentIds.isEmpty) return 0;

      await bulkEnrollStudents(
        studentIds: studentIds,
        courseId: courseId,
        enrollmentType: 'section_based',
      );

      return studentIds.length;
    } catch (e) {
      print('Error in manual auto-enrollment: $e');
      return 0;
    }
  }

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get enrollments for a student
  Future<List<Enrollment>> getEnrollmentsForStudent(
    String studentId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('enrollments')
          .select()
          .eq('student_id', studentId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('enrolled_at', ascending: false);
      return (response as List)
          .map((item) => Enrollment.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching enrollments for student: $e');
      return [];
    }
  }

  /// Get enrollments for a course
  Future<List<Enrollment>> getEnrollmentsForCourse(
    int courseId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('enrollments')
          .select()
          .eq('course_id', courseId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('enrolled_at', ascending: false);
      return (response as List)
          .map((item) => Enrollment.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching enrollments for course: $e');
      return [];
    }
  }

  /// Get active enrollments for student
  Future<List<Enrollment>> getActiveEnrollments(String studentId) async {
    return getEnrollmentsForStudent(studentId, status: 'active');
  }

  /// Get enrollment by ID
  Future<Enrollment?> getEnrollmentById(int id) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Enrollment.fromMap(response);
    } catch (e) {
      print('Error fetching enrollment by ID: $e');
      return null;
    }
  }

  /// Check if student is enrolled in course
  Future<bool> isStudentEnrolled(String studentId, int courseId) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select('id')
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  /// Get enrollment count for course
  Future<int> getEnrollmentCount(int courseId, {String? status}) async {
    try {
      var query = _supabase
          .from('enrollments')
          .select('id')
          .eq('course_id', courseId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      print('Error getting enrollment count: $e');
      return 0;
    }
  }

  /// Get student IDs by section
  Future<List<String>> getStudentIdsBySection(
    int gradeLevel,
    String section,
  ) async {
    try {
      final response = await _supabase
          .from('students')
          .select('id')
          .eq('grade_level', gradeLevel)
          .eq('section', section)
          .eq('is_active', true);

      return (response as List).map((item) => item['id'] as String).toList();
    } catch (e) {
      print('Error getting student IDs by section: $e');
      return [];
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update enrollment status
  Future<void> updateEnrollmentStatus(int enrollmentId, String status) async {
    try {
      await _supabase
          .from('enrollments')
          .update({'status': status})
          .eq('id', enrollmentId);
    } catch (e) {
      print('Error updating enrollment status: $e');
      rethrow;
    }
  }

  /// Drop enrollment (set status to 'dropped')
  Future<void> dropEnrollment(int enrollmentId) async {
    await updateEnrollmentStatus(enrollmentId, 'dropped');
  }

  /// Complete enrollment (set status to 'completed')
  Future<void> completeEnrollment(int enrollmentId) async {
    await updateEnrollmentStatus(enrollmentId, 'completed');
  }

  /// Reactivate enrollment (set status to 'active')
  Future<void> reactivateEnrollment(int enrollmentId) async {
    await updateEnrollmentStatus(enrollmentId, 'active');
  }

  /// Drop student from course
  Future<void> dropStudentFromCourse(String studentId, int courseId) async {
    try {
      await _supabase
          .from('enrollments')
          .update({'status': 'dropped'})
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .eq('status', 'active');
    } catch (e) {
      print('Error dropping student from course: $e');
      rethrow;
    }
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete enrollment (hard delete)
  Future<void> deleteEnrollment(int enrollmentId) async {
    try {
      await _supabase
          .from('enrollments')
          .delete()
          .eq('id', enrollmentId);
    } catch (e) {
      print('Error deleting enrollment: $e');
      rethrow;
    }
  }

  /// Delete all enrollments for a course
  Future<void> deleteAllEnrollmentsForCourse(int courseId) async {
    try {
      await _supabase
          .from('enrollments')
          .delete()
          .eq('course_id', courseId);
    } catch (e) {
      print('Error deleting enrollments for course: $e');
      rethrow;
    }
  }

  // ============================================
  // STATISTICS OPERATIONS
  // ============================================

  /// Get enrollment statistics for a course
  Future<Map<String, dynamic>> getCourseEnrollmentStats(int courseId) async {
    try {
      final enrollments = await getEnrollmentsForCourse(courseId);

      final stats = {
        'total': enrollments.length,
        'active': 0,
        'dropped': 0,
        'completed': 0,
        'pending': 0,
        'manual': 0,
        'auto': 0,
        'section_based': 0,
      };

      for (final enrollment in enrollments) {
        // Count by status
        stats[enrollment.status] = (stats[enrollment.status] as int) + 1;
        // Count by type
        stats[enrollment.enrollmentType] = (stats[enrollment.enrollmentType] as int) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting course enrollment stats: $e');
      return {};
    }
  }

  /// Get enrollment statistics for a student
  Future<Map<String, dynamic>> getStudentEnrollmentStats(String studentId) async {
    try {
      final enrollments = await getEnrollmentsForStudent(studentId);

      final stats = {
        'total': enrollments.length,
        'active': 0,
        'dropped': 0,
        'completed': 0,
        'pending': 0,
      };

      for (final enrollment in enrollments) {
        stats[enrollment.status] = (stats[enrollment.status] as int) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting student enrollment stats: $e');
      return {};
    }
  }

  /// Get total enrollments count
  Future<int> getTotalEnrollmentsCount({String? status}) async {
    try {
      var query = _supabase.from('enrollments').select('id');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      print('Error getting total enrollments count: $e');
      return 0;
    }
  }

  /// Get enrollments count by type
  Future<Map<String, int>> getEnrollmentsCountByType() async {
    try {
      final enrollments = await _supabase
          .from('enrollments')
          .select('enrollment_type')
          .eq('status', 'active');

      final counts = <String, int>{
        'manual': 0,
        'auto': 0,
        'section_based': 0,
      };

      for (final enrollment in enrollments as List) {
        final type = enrollment['enrollment_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting enrollments count by type: $e');
      return {};
    }
  }
}
