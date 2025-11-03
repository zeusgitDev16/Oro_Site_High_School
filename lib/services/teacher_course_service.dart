import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/backend/config/supabase_config.dart';
import 'package:oro_site_high_school/models/course.dart';

/// Teacher Course Service
/// Handles fetching courses assigned to teachers
/// Layer 2: Service Layer - Business logic for teacher courses
class TeacherCourseService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get courses assigned to a specific teacher
  Future<List<Course>> getTeacherCourses(String teacherId) async {
    try {
      print('📚 TeacherCourseService: Fetching courses for teacher $teacherId...');
      
      // Get course IDs from course_teachers table
      final courseTeachersResponse = await _supabase
          .from('course_teachers')
          .select('course_id')
          .eq('teacher_id', teacherId);

      if (courseTeachersResponse.isEmpty) {
        print('⚠️ TeacherCourseService: No courses assigned to this teacher');
        return [];
      }

      // Extract course IDs
      final courseIds = (courseTeachersResponse as List)
          .map((item) => item['course_id'] as int)
          .toList();

      print('📋 TeacherCourseService: Found ${courseIds.length} course assignment(s)');

      // Fetch course details
      final coursesResponse = await _supabase
          .from('courses')
          .select()
          .inFilter('id', courseIds)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ TeacherCourseService: Retrieved ${coursesResponse.length} course(s)');

      return (coursesResponse as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ TeacherCourseService: Error fetching teacher courses: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
      return [];
    }
  }

  /// Get course count for a teacher
  Future<int> getTeacherCourseCount(String teacherId) async {
    try {
      final response = await _supabase
          .from('course_teachers')
          .select('course_id')
          .eq('teacher_id', teacherId);

      return (response as List).length;
    } catch (e) {
      print('❌ TeacherCourseService: Error getting course count: $e');
      return 0;
    }
  }

  /// Check if teacher is assigned to a specific course
  Future<bool> isTeacherAssignedToCourse({
    required String teacherId,
    required String courseId,
  }) async {
    try {
      final response = await _supabase
          .from('course_teachers')
          .select()
          .eq('teacher_id', teacherId)
          .eq('course_id', int.parse(courseId))
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ TeacherCourseService: Error checking assignment: $e');
      return false;
    }
  }

  /// Get course modules for a specific course
  Future<List<Map<String, dynamic>>> getCourseModules(String courseId) async {
    try {
      print('📚 TeacherCourseService: Fetching modules for course $courseId...');
      
      final response = await _supabase
          .from('course_modules')
          .select()
          .eq('course_id', int.parse(courseId))
          .order('uploaded_at', ascending: false);

      print('✅ TeacherCourseService: Found ${response.length} module(s)');
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ TeacherCourseService: Error fetching modules: $e');
      return [];
    }
  }

  /// Get course assignments for a specific course
  Future<List<Map<String, dynamic>>> getCourseAssignments(String courseId) async {
    try {
      print('📚 TeacherCourseService: Fetching assignments for course $courseId...');
      
      final response = await _supabase
          .from('course_assignments')
          .select()
          .eq('course_id', int.parse(courseId))
          .order('uploaded_at', ascending: false);

      print('✅ TeacherCourseService: Found ${response.length} assignment(s)');
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ TeacherCourseService: Error fetching assignments: $e');
      return [];
    }
  }
}
