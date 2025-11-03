import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher.dart';

/// Teacher Service - Manages teacher data and operations
/// Handles fetching, filtering, and managing teacher information
class TeacherService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get all active teachers
  /// Joins with profiles table to get email and full_name
  Future<List<Teacher>> getActiveTeachers() async {
    try {
      print('🔍 TeacherService: Fetching active teachers...');
      
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('is_active', true)
          .order('last_name');

      print('✅ TeacherService: Received ${(response as List).length} teachers');

      return (response as List).map((json) {
        // Merge teacher data with profile data
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        print('📝 Teacher: ${teacherData['full_name'] ?? teacherData['first_name']} ${teacherData['last_name']}');
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('❌ Error fetching active teachers: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
        print('❌ Postgrest code: ${e.code}');
        print('❌ Postgrest details: ${e.details}');
      }
      return [];
    }
  }

  /// Get all teachers (including inactive)
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .order('last_name');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching all teachers: $e');
      return [];
    }
  }

  /// Get teacher by ID
  Future<Teacher?> getTeacherById(String id) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final teacherData = Map<String, dynamic>.from(response);
      if (response['profiles'] != null) {
        teacherData['email'] = response['profiles']['email'];
        teacherData['full_name'] = response['profiles']['full_name'];
        teacherData['phone'] = response['profiles']['phone'];
      }

      return Teacher.fromMap(teacherData);
    } catch (e) {
      print('Error fetching teacher by ID: $e');
      return null;
    }
  }

  /// Get teachers by subject
  /// Uses JSONB contains operator to search subjects array
  Future<List<Teacher>> getTeachersBySubject(String subject) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .contains('subjects', [subject])
          .eq('is_active', true)
          .order('last_name');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching teachers by subject: $e');
      return [];
    }
  }

  /// Get teachers by department
  Future<List<Teacher>> getTeachersByDepartment(String department) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('department', department)
          .eq('is_active', true)
          .order('last_name');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching teachers by department: $e');
      return [];
    }
  }

  /// Get grade coordinators
  Future<List<Teacher>> getGradeCoordinators() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('is_grade_coordinator', true)
          .eq('is_active', true)
          .order('coordinator_grade_level');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching grade coordinators: $e');
      return [];
    }
  }

  /// Get coordinator for specific grade level
  Future<Teacher?> getCoordinatorForGrade(int gradeLevel) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('is_grade_coordinator', true)
          .eq('coordinator_grade_level', gradeLevel.toString())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final teacherData = Map<String, dynamic>.from(response);
      if (response['profiles'] != null) {
        teacherData['email'] = response['profiles']['email'];
        teacherData['full_name'] = response['profiles']['full_name'];
        teacherData['phone'] = response['profiles']['phone'];
      }

      return Teacher.fromMap(teacherData);
    } catch (e) {
      print('Error fetching coordinator for grade: $e');
      return null;
    }
  }

  /// Get SHS teachers
  Future<List<Teacher>> getSHSTeachers() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('is_shs_teacher', true)
          .eq('is_active', true)
          .order('last_name');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching SHS teachers: $e');
      return [];
    }
  }

  /// Get SHS teachers by track
  Future<List<Teacher>> getSHSTeachersByTrack(String track) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .eq('is_shs_teacher', true)
          .eq('shs_track', track)
          .eq('is_active', true)
          .order('last_name');

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error fetching SHS teachers by track: $e');
      return [];
    }
  }

  /// Get teachers assigned to a course
  Future<List<Teacher>> getTeachersByCourse(int courseId) async {
    try {
      final response = await _supabase
          .from('course_assignments')
          .select('teacher_id, teachers!inner(*, profiles!inner(email, full_name, phone))')
          .eq('course_id', courseId)
          .eq('status', 'active');

      final teachers = <Teacher>[];
      for (final item in response as List) {
        if (item['teachers'] != null) {
          final teacherData = Map<String, dynamic>.from(item['teachers']);
          if (item['teachers']['profiles'] != null) {
            teacherData['email'] = item['teachers']['profiles']['email'];
            teacherData['full_name'] = item['teachers']['profiles']['full_name'];
            teacherData['phone'] = item['teachers']['profiles']['phone'];
          }
          teachers.add(Teacher.fromMap(teacherData));
        }
      }
      return teachers;
    } catch (e) {
      print('Error fetching teachers by course: $e');
      return [];
    }
  }

  // ============================================
  // SEARCH OPERATIONS
  // ============================================

  /// Search teachers by name
  Future<List<Teacher>> searchTeachers(String query) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('*, profiles!inner(email, full_name, phone)')
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%')
          .eq('is_active', true)
          .order('last_name')
          .limit(50);

      return (response as List).map((json) {
        final teacherData = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          teacherData['email'] = json['profiles']['email'];
          teacherData['full_name'] = json['profiles']['full_name'];
          teacherData['phone'] = json['profiles']['phone'];
        }
        return Teacher.fromMap(teacherData);
      }).toList();
    } catch (e) {
      print('Error searching teachers: $e');
      return [];
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update teacher information
  Future<void> updateTeacher(String teacherId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('teachers')
          .update(updates)
          .eq('id', teacherId);
    } catch (e) {
      print('Error updating teacher: $e');
      rethrow;
    }
  }

  /// Activate teacher
  Future<void> activateTeacher(String teacherId) async {
    await updateTeacher(teacherId, {'is_active': true});
  }

  /// Deactivate teacher
  Future<void> deactivateTeacher(String teacherId) async {
    await updateTeacher(teacherId, {'is_active': false});
  }

  // ============================================
  // STATISTICS OPERATIONS
  // ============================================

  /// Get teacher statistics
  Future<Map<String, dynamic>> getTeacherStats(String teacherId) async {
    try {
      // Get assigned courses count
      final courses = await _supabase
          .from('course_assignments')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('status', 'active');

      final courseCount = (courses as List).length;

      // Get teacher info
      final teacher = await getTeacherById(teacherId);

      return {
        'teacher': teacher,
        'course_count': courseCount,
        'is_coordinator': teacher?.isGradeCoordinator ?? false,
        'is_shs_teacher': teacher?.isSHSTeacher ?? false,
        'subjects_count': teacher?.subjects.length ?? 0,
      };
    } catch (e) {
      print('Error getting teacher stats: $e');
      return {};
    }
  }

  /// Get total teachers count
  Future<int> getTotalTeachersCount() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('id')
          .eq('is_active', true);
      return (response as List).length;
    } catch (e) {
      print('Error getting total teachers count: $e');
      return 0;
    }
  }

  /// Get teachers count by department
  Future<Map<String, int>> getTeachersCountByDepartment() async {
    try {
      final teachers = await getActiveTeachers();
      final counts = <String, int>{};

      for (final teacher in teachers) {
        final dept = teacher.department ?? 'Unassigned';
        counts[dept] = (counts[dept] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting teachers count by department: $e');
      return {};
    }
  }
}
