import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/backend/config/supabase_config.dart';
import 'package:oro_site_high_school/models/course.dart';

/// Course Service
/// Handles all course-related operations following 4-layer architecture
/// Layer 2: Service Layer - Business logic for courses
class CourseService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Fetch all active courses
  Future<List<Course>> fetchCourses() async {
    try {
      print('📚 CourseService: Fetching courses...');
      
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ CourseService: Received ${response.length} courses');
      
      return (response as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ CourseService: Error fetching courses: $e');
      rethrow;
    }
  }

  /// Create a new course
  Future<Course> createCourse({
    required String title,
    required String description,
  }) async {
    try {
      print('📚 CourseService: Creating course: $title');
      
      final now = DateTime.now();
      final courseData = {
        'title': title,
        'description': description,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('courses')
          .insert(courseData)
          .select()
          .single();

      print('✅ CourseService: Course created successfully');
      
      return Course.fromJson(response);
    } catch (e) {
      print('❌ CourseService: Error creating course: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Update an existing course
  Future<Course> updateCourse({
    required String id,
    String? title,
    String? description,
  }) async {
    try {
      print('📚 CourseService: Updating course: $id');
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      final response = await _supabase
          .from('courses')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      print('✅ CourseService: Course updated successfully');
      
      return Course.fromJson(response);
    } catch (e) {
      print('❌ CourseService: Error updating course: $e');
      rethrow;
    }
  }

  /// Delete a course (soft delete - set is_active to false)
  Future<void> deleteCourse(String id) async {
    try {
      print('📚 CourseService: Deleting course: $id');
      
      await _supabase
          .from('courses')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ CourseService: Course deleted successfully');
    } catch (e) {
      print('❌ CourseService: Error deleting course: $e');
      rethrow;
    }
  }

  /// Get a single course by ID
  Future<Course?> getCourseById(String id) async {
    try {
      print('📚 CourseService: Fetching course: $id');
      
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        print('⚠️ CourseService: Course not found');
        return null;
      }

      print('✅ CourseService: Course found');
      return Course.fromJson(response);
    } catch (e) {
      print('❌ CourseService: Error fetching course: $e');
      rethrow;
    }
  }

  /// Get teachers assigned to a course
  Future<List<String>> getCourseTeachers(String courseId) async {
    try {
      print('📚 CourseService: Fetching teachers for course: $courseId');
      
      final response = await _supabase
          .from('course_teachers')
          .select('teacher_id')
          .eq('course_id', int.parse(courseId)); // Convert to int

      print('✅ CourseService: Found ${response.length} teachers');
      
      return (response as List)
          .map((item) => item['teacher_id'].toString())
          .toList();
    } catch (e) {
      print('❌ CourseService: Error fetching course teachers: $e');
      return [];
    }
  }

  /// Add teacher to course
  Future<void> addTeacherToCourse({
    required String courseId,
    required String teacherId,
  }) async {
    try {
      print('📚 CourseService: Adding teacher $teacherId to course $courseId');
      
      // Check if teacher is already assigned
      final existing = await _supabase
          .from('course_teachers')
          .select()
          .eq('course_id', int.parse(courseId))
          .eq('teacher_id', teacherId)
          .maybeSingle();
      
      if (existing != null) {
        print('⚠️ CourseService: Teacher already assigned to this course');
        return; // Already assigned, skip insertion
      }
      
      await _supabase.from('course_teachers').insert({
        'course_id': int.parse(courseId), // Convert to int
        'teacher_id': teacherId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ CourseService: Teacher added successfully');
    } catch (e) {
      print('❌ CourseService: Error adding teacher: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Remove teacher from course
  Future<void> removeTeacherFromCourse({
    required String courseId,
    required String teacherId,
  }) async {
    try {
      print('📚 CourseService: Removing teacher $teacherId from course $courseId');
      
      await _supabase
          .from('course_teachers')
          .delete()
          .eq('course_id', int.parse(courseId)) // Convert to int
          .eq('teacher_id', teacherId);

      print('✅ CourseService: Teacher removed successfully');
    } catch (e) {
      print('❌ CourseService: Error removing teacher: $e');
      rethrow;
    }
  }
}
