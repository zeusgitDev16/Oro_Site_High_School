import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/course.dart';

/// Classroom Service
/// Handles all classroom-related database operations
class ClassroomService {
  final _supabase = Supabase.instance.client;

  /// Generate random access code
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new classroom
  Future<Classroom> createClassroom({
    required String teacherId,
    required String title,
    String? description,
    required int gradeLevel,
    required int maxStudents,
  }) async {
    try {
      // Validate grade level
      if (gradeLevel < 7 || gradeLevel > 12) {
        throw Exception('Grade level must be between 7 and 12');
      }

      // Validate max students
      if (maxStudents < 1 || maxStudents > 100) {
        throw Exception('Max students must be between 1 and 100');
      }

      final accessCode = _generateAccessCode();
      
      final response = await _supabase
          .from('classrooms')
          .insert({
            'teacher_id': teacherId,
            'title': title,
            'description': description,
            'grade_level': gradeLevel,
            'max_students': maxStudents,
            'current_students': 0,
            'is_active': true,
            'access_code': accessCode,
          })
          .select()
          .single();

      return Classroom.fromJson(response);
    } catch (e) {
      print('❌ Error creating classroom: $e');
      rethrow;
    }
  }

  /// Get all classrooms for a teacher
  Future<List<Classroom>> getTeacherClassrooms(String teacherId) async {
    try {
      // Owned classrooms
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final owned = (response as List)
          .map((json) => Classroom.fromJson(json))
          .toList();

      // Co-teaching classrooms (optional; ignore if mapping table/policies are absent)
      List<Classroom> coTeaching = [];
      try {
        final coRows = await _supabase
            .from('classroom_teachers')
            .select('classroom_id, classrooms(*)')
            .eq('teacher_id', teacherId)
            .order('joined_at', ascending: false);

        coTeaching = (coRows as List)
            .map((item) => Classroom.fromJson(item['classrooms']))
            .where((c) => c.isActive)
            .toList();
      } catch (e) {
        // Backend not yet prepared for co-teachers; proceed with owned only
      }

      // Merge and deduplicate by classroom id
      final byId = <String, Classroom>{};
      for (final c in [...owned, ...coTeaching]) {
        byId[c.id] = c;
      }
      return byId.values.toList();
    } catch (e) {
      print('❌ Error fetching teacher classrooms: $e');
      rethrow;
    }
  }

  /// Get a single classroom by ID
  Future<Classroom?> getClassroomById(String classroomId) async {
    try {
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('id', classroomId)
          .single();

      return Classroom.fromJson(response);
    } catch (e) {
      print('❌ Error fetching classroom: $e');
      return null;
    }
  }

  /// Update classroom
  Future<Classroom> updateClassroom({
    required String classroomId,
    String? title,
    String? description,
    int? gradeLevel,
    int? maxStudents,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (gradeLevel != null) {
        if (gradeLevel < 7 || gradeLevel > 12) {
          throw Exception('Grade level must be between 7 and 12');
        }
        updates['grade_level'] = gradeLevel;
      }
      if (maxStudents != null) {
        if (maxStudents < 1 || maxStudents > 100) {
          throw Exception('Max students must be between 1 and 100');
        }
        updates['max_students'] = maxStudents;
      }
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase
          .from('classrooms')
          .update(updates)
          .eq('id', classroomId)
          .select()
          .single();

      return Classroom.fromJson(response);
    } catch (e) {
      print('❌ Error updating classroom: $e');
      rethrow;
    }
  }

  /// Delete classroom (soft delete by setting is_active to false)
  Future<void> deleteClassroom(String classroomId) async {
    try {
      await _supabase
          .from('classrooms')
          .update({'is_active': false})
          .eq('id', classroomId);
    } catch (e) {
      print('❌ Error deleting classroom: $e');
      rethrow;
    }
  }

  /// Get classroom count for a teacher
  Future<int> getTeacherClassroomCount(String teacherId) async {
    try {
      final response = await _supabase
          .from('classrooms')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      print('❌ Error getting classroom count: $e');
      return 0;
    }
  }

  /// Get classrooms by grade level
  Future<List<Classroom>> getClassroomsByGrade(int gradeLevel) async {
    try {
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('grade_level', gradeLevel)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Classroom.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching classrooms by grade: $e');
      rethrow;
    }
  }

  /// Increment student count
  Future<void> incrementStudentCount(String classroomId) async {
    try {
      // Get current classroom
      final classroom = await getClassroomById(classroomId);
      if (classroom == null) {
        throw Exception('Classroom not found');
      }

      // Check if classroom is full
      if (classroom.isFull) {
        throw Exception('Classroom is full');
      }

      // Increment count
      await _supabase
          .from('classrooms')
          .update({'current_students': classroom.currentStudents + 1})
          .eq('id', classroomId);
    } catch (e) {
      print('❌ Error incrementing student count: $e');
      rethrow;
    }
  }

  /// Decrement student count
  Future<void> decrementStudentCount(String classroomId) async {
    try {
      // Get current classroom
      final classroom = await getClassroomById(classroomId);
      if (classroom == null) {
        throw Exception('Classroom not found');
      }

      // Decrement count (don't go below 0)
      final newCount = classroom.currentStudents > 0 
          ? classroom.currentStudents - 1 
          : 0;

      await _supabase
          .from('classrooms')
          .update({'current_students': newCount})
          .eq('id', classroomId);
    } catch (e) {
      print('❌ Error decrementing student count: $e');
      rethrow;
    }
  }

  /// Regenerate access code for classroom
  Future<String> regenerateAccessCode(String classroomId) async {
    try {
      final newAccessCode = _generateAccessCode();
      
      await _supabase
          .from('classrooms')
          .update({'access_code': newAccessCode})
          .eq('id', classroomId);

      return newAccessCode;
    } catch (e) {
      print('❌ Error regenerating access code: $e');
      rethrow;
    }
  }

  /// Add course to classroom
  Future<void> addCourseToClassroom({
    required String classroomId,
    required String courseId,
    required String addedBy,
  }) async {
    try {
      await _supabase.from('classroom_courses').insert({
        'classroom_id': classroomId,
        'course_id': int.parse(courseId),
        'added_by': addedBy,
      });
    } catch (e) {
      print('❌ Error adding course to classroom: $e');
      rethrow;
    }
  }

  /// Remove course from classroom
  Future<void> removeCourseFromClassroom({
    required String classroomId,
    required String courseId,
  }) async {
    try {
      await _supabase
          .from('classroom_courses')
          .delete()
          .eq('classroom_id', classroomId)
          .eq('course_id', int.parse(courseId));
    } catch (e) {
      print('❌ Error removing course from classroom: $e');
      rethrow;
    }
  }

  /// Get courses for a classroom
  Future<List<Course>> getClassroomCourses(String classroomId) async {
    try {
      final response = await _supabase
          .from('classroom_courses')
          // Include added_by to determine ownership when courses.teacher_id is null
          .select('course_id, added_by, courses(*)')
          .eq('classroom_id', classroomId);

      return (response as List).map((item) {
        final courseData = item['courses'];
        var course = Course.fromJson(courseData);
        // Determine effective owner strictly by course teacher_id; fallback to mapping's added_by
        final effectiveOwner = course.teacherId ?? item['added_by']?.toString();
        if (effectiveOwner != null && effectiveOwner != course.teacherId) {
          course = course.copyWith(teacherId: effectiveOwner);
        }
        return course;
      }).toList();
    } catch (e) {
      print('❌ Error fetching classroom courses: $e');
      rethrow;
    }
  }

  /// Find classroom by access code (exact match - case sensitive)
  Future<Classroom?> findClassroomByAccessCode(String accessCode) async {
    try {
      print('🔍 Searching for classroom with exact access code: $accessCode');
      print('🔍 Access code length: ${accessCode.length}');
      print('🔍 Access code bytes: ${accessCode.codeUnits}');
      
      // First, let's check all active classrooms to debug
      final allClassrooms = await _supabase
          .from('classrooms')
          .select()
          .eq('is_active', true);
      
      print('📊 Total active classrooms: ${(allClassrooms as List).length}');
      for (var classroom in allClassrooms) {
        print('   - Classroom: ${classroom['title']}, Code: ${classroom['access_code']}');
      }
      
      // Query using exact match (case-sensitive)
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('access_code', accessCode)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        print('❌ No classroom found with access code: $accessCode');
        
        // Try case-insensitive as fallback to see if it's a case issue
        final caseInsensitiveResponse = await _supabase
            .from('classrooms')
            .select()
            .ilike('access_code', accessCode)
            .eq('is_active', true)
            .maybeSingle();
        
        if (caseInsensitiveResponse != null) {
          print('⚠️ Found classroom with case-insensitive match!');
          print('⚠️ Expected: $accessCode');
          print('⚠️ Found: ${caseInsensitiveResponse['access_code']}');
        }
        
        return null;
      }
      
      print('✅ Found classroom: ${response['title']} with code: ${response['access_code']}');
      return Classroom.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ Error finding classroom by access code: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Join classroom (student enrollment)
  Future<Map<String, dynamic>> joinClassroom({
    required String studentId,
    required String accessCode,
  }) async {
    try {
      print('🎓 Student $studentId attempting to join with code: $accessCode');
      
      // Find classroom by access code (exact match - case sensitive)
      final classroom = await findClassroomByAccessCode(accessCode);
      
      if (classroom == null) {
        print('❌ No classroom found with access code: $accessCode');
        return {
          'success': false,
          'message': 'Invalid access code. Please check and try again.',
        };
      }

      print('✅ Found classroom: ${classroom.title} (ID: ${classroom.id})');

      // Check capacity using live enrollment count to avoid stale values
      final enrollments = await _supabase
          .from('classroom_students')
          .select('student_id')
          .eq('classroom_id', classroom.id);
      final enrollmentCount = (enrollments as List).length;
      if (enrollmentCount >= classroom.maxStudents) {
        print('❌ Classroom is full (live): $enrollmentCount/${classroom.maxStudents}');
        return {
          'success': false,
          'message': 'This classroom is full. Cannot join at this time.',
        };
      }

      // Check if student is already enrolled
      final existingEnrollment = await _supabase
          .from('classroom_students')
          .select()
          .eq('classroom_id', classroom.id)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingEnrollment != null) {
        print('❌ Student already enrolled in classroom');
        return {
          'success': false,
          'message': 'You are already enrolled in this classroom.',
        };
      }

      print('📝 Enrolling student in classroom...');

      // Enroll student
      await _supabase.from('classroom_students').insert({
        'classroom_id': classroom.id,
        'student_id': studentId,
        'enrolled_at': DateTime.now().toIso8601String(),
      });

      print('✅ Student enrolled successfully');

      // Update student count based on live enrollments (avoids race conditions)
      final newEnrollments = await _supabase
          .from('classroom_students')
          .select('student_id')
          .eq('classroom_id', classroom.id);
      final updatedCount = (newEnrollments as List).length;
      await _supabase
          .from('classrooms')
          .update({'current_students': updatedCount})
          .eq('id', classroom.id);

      print('✅ Student count updated to $updatedCount');

      return {
        'success': true,
        'message': 'Successfully joined ${classroom.title}!',
        'classroom': classroom,
      };
    } catch (e) {
      print('❌ Error joining classroom: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'An error occurred while joining the classroom. Please try again. Error: $e',
      };
    }
  }

  /// Allow a teacher to join a classroom using the access code (co-teacher)
  /// This is idempotent and gracefully handles absent backend mapping/policies.
  Future<Map<String, dynamic>> joinClassroomAsTeacher({
    required String teacherId,
    required String accessCode,
  }) async {
    try {
      // Find classroom by exact access code
      final classroom = await findClassroomByAccessCode(accessCode);
      if (classroom == null) {
        return {
          'success': false,
          'message': 'Invalid access code. Please check and try again.',
        };
      }

      // If already the owner
      if (classroom.teacherId == teacherId) {
        return {
          'success': true,
          'message': 'You already own this classroom.',
          'classroom': classroom,
          'alreadyJoined': true,
        };
      }

      // Optional mapping table: classroom_teachers(classroom_id, teacher_id, joined_at)
      try {
        // Check if already a co-teacher
        final existing = await _supabase
            .from('classroom_teachers')
            .select()
            .eq('classroom_id', classroom.id)
            .eq('teacher_id', teacherId)
            .maybeSingle();
        if (existing != null) {
          return {
            'success': true,
            'message': 'You are already a co-teacher in this classroom.',
            'classroom': classroom,
            'alreadyJoined': true,
          };
        }

        // Insert co-teacher membership
        await _supabase.from('classroom_teachers').insert({
          'classroom_id': classroom.id,
          'teacher_id': teacherId,
          'joined_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'message': 'Successfully joined ${classroom.title} as co-teacher.',
          'classroom': classroom,
        };
      } catch (e) {
        // Likely missing mapping table or policies; surface a helpful message
        return {
          'success': false,
          'message': 'Co-teacher access is not yet enabled on the backend. Please set up classroom_teachers and RLS policies.',
        };
      }
    } catch (e) {
      print('❌ Error joining classroom as teacher: $e');
      return {
        'success': false,
        'message': 'An error occurred while joining as co-teacher. Error: $e',
      };
    }
  }

  /// Get student's enrolled classrooms
  Future<List<Classroom>> getStudentClassrooms(String studentId) async {
    try {
      final response = await _supabase
          .from('classroom_students')
          .select('classroom_id, classrooms(*)')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false);

      return (response as List).map((item) {
        final classroomData = item['classrooms'];
        return Classroom.fromJson(classroomData);
      }).where((classroom) => classroom.isActive).toList();
    } catch (e) {
      print('❌ Error fetching student classrooms: $e');
      rethrow;
    }
  }

  /// Leave classroom (student unenrollment)
  Future<void> leaveClassroom({
    required String studentId,
    required String classroomId,
  }) async {
    try {
      await _supabase
          .from('classroom_students')
          .delete()
          .eq('classroom_id', classroomId)
          .eq('student_id', studentId);

      // Decrement student count
      await decrementStudentCount(classroomId);
    } catch (e) {
      print('❌ Error leaving classroom: $e');
      rethrow;
    }
  }

  /// Check if student is enrolled in classroom
  Future<bool> isStudentEnrolled({
    required String studentId,
    required String classroomId,
  }) async {
    try {
      final response = await _supabase
          .from('classroom_students')
          .select()
          .eq('classroom_id', classroomId)
          .eq('student_id', studentId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('�� Error checking enrollment: $e');
      return false;
    }
  }

  /// Get enrollment counts for a list of classrooms
  Future<Map<String, int>> getEnrollmentCountsForClassrooms(List<String> classroomIds) async {
    if (classroomIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('classroom_students')
          .select('classroom_id')
          .inFilter('classroom_id', classroomIds);
      
      final counts = <String, int>{};
      for (final row in (response as List)) {
        final id = row['classroom_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      print('❌ Error fetching enrollment counts: $e');
      return {};
    }
  }
  
  /// Get all students enrolled in a classroom
  Future<List<Map<String, dynamic>>> getClassroomStudents(String classroomId) async {
    try {
      // Prefer secure RPC that enforces owner/co-teacher visibility server-side.
      try {
        final rows = await _supabase.rpc(
          'get_classroom_students_with_profile',
          params: {'p_classroom_id': classroomId},
        );
        return (rows as List).map((r) => {
              'student_id': r['student_id'],
              'full_name': r['full_name'],
              'email': r['email'],
              'enrolled_at': r['enrolled_at'],
            }).toList();
      } catch (_) {
        // Fallback to direct select for environments where RPC isn't yet deployed
      }

      final response = await _supabase
          .from('classroom_students')
          .select('student_id, enrolled_at, profiles!inner(full_name, email)')
          .eq('classroom_id', classroomId)
          .order('enrolled_at', ascending: false);

      return (response as List).map((item) {
        final profile = item['profiles'];
        return {
          'student_id': item['student_id'],
          'full_name': profile['full_name'],
          'email': profile['email'],
          'enrolled_at': item['enrolled_at'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching classroom students: $e');
      rethrow;
    }
  }
}
