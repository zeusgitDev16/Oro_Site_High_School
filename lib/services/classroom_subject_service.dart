import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/classroom_subject.dart';

/// Service for managing classroom subjects
class ClassroomSubjectService {
  final _supabase = Supabase.instance.client;

  /// Get all subjects for a classroom
  Future<List<ClassroomSubject>> getSubjectsByClassroom(
    String classroomId,
  ) async {
    try {
      print(
        '📚 [SubjectService] Fetching subjects for classroom: $classroomId',
      );

      final response = await _supabase
          .from('classroom_subjects_with_details')
          .select()
          .eq('classroom_id', classroomId)
          .order('subject_name');

      print('✅ [SubjectService] Fetched ${response.length} subjects');

      return (response as List)
          .map((json) => ClassroomSubject.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [SubjectService] Error fetching subjects: $e');
      rethrow;
    }
  }

  /// Phase 2 Task 2.6: Get subjects for a classroom with role-based filtering
  /// - Coordinators: See all subjects in classrooms in their grade level
  /// - Advisors: See all subjects in their advisory classroom
  /// - Subject Teachers: See only their assigned subjects
  Future<List<ClassroomSubject>> getSubjectsByClassroomForTeacher({
    required String classroomId,
    required String teacherId,
  }) async {
    try {
      print(
        '📚 [SubjectService] Fetching subjects for classroom: $classroomId, teacher: $teacherId',
      );

      // Check if teacher is coordinator
      final coordResponse = await _supabase
          .from('coordinator_assignments')
          .select('grade_level')
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .maybeSingle();

      final isCoordinator = coordResponse != null;

      // Check if teacher is advisor for this classroom
      final classroomResponse = await _supabase
          .from('classrooms')
          .select('advisory_teacher_id, grade_level')
          .eq('id', classroomId)
          .single();

      final isAdvisor = classroomResponse['advisory_teacher_id'] == teacherId;
      final classroomGradeLevel = classroomResponse['grade_level'] as int;

      // If coordinator, check if this classroom is in their grade level
      bool isCoordinatorForThisGrade = false;
      if (isCoordinator) {
        final coordGradeLevel = coordResponse['grade_level'] as int;
        isCoordinatorForThisGrade = coordGradeLevel == classroomGradeLevel;
      }

      // Fetch subjects based on role
      List<ClassroomSubject> subjects;

      if (isCoordinatorForThisGrade || isAdvisor) {
        // Coordinators and advisors see ALL subjects in the classroom
        print(
          '✅ [SubjectService] Teacher is ${isCoordinatorForThisGrade ? 'coordinator' : 'advisor'} - showing all subjects',
        );
        subjects = await getSubjectsByClassroom(classroomId);
      } else {
        // Subject teachers see only their assigned subjects
        print(
          '✅ [SubjectService] Teacher is subject teacher - showing only assigned subjects',
        );
        final response = await _supabase
            .from('classroom_subjects_with_details')
            .select()
            .eq('classroom_id', classroomId)
            .eq('teacher_id', teacherId)
            .order('subject_name');

        subjects = (response as List)
            .map((json) => ClassroomSubject.fromJson(json))
            .toList();
      }

      print('✅ [SubjectService] Fetched ${subjects.length} subjects');
      return subjects;
    } catch (e) {
      print('❌ [SubjectService] Error fetching subjects: $e');
      rethrow;
    }
  }

  /// Add a subject to a classroom
  Future<ClassroomSubject> addSubject({
    required String classroomId,
    required String subjectName,
    String? subjectCode,
    String? description,
    String? teacherId,
    String? parentSubjectId,
  }) async {
    try {
      print(
        '➕ [SubjectService] Adding subject: $subjectName to classroom: $classroomId',
      );

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('classroom_subjects')
          .insert({
            'classroom_id': classroomId,
            'subject_name': subjectName,
            'subject_code': subjectCode,
            'description': description,
            'teacher_id': teacherId,
            'parent_subject_id': parentSubjectId,
            'is_active': true,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      print('✅ [SubjectService] Subject added successfully');

      return ClassroomSubject.fromJson(response);
    } catch (e) {
      print('❌ [SubjectService] Error adding subject: $e');
      rethrow;
    }
  }

  /// Update a subject
  Future<ClassroomSubject> updateSubject({
    required String subjectId,
    String? subjectName,
    String? subjectCode,
    String? description,
    String? teacherId,
    bool? isActive,
  }) async {
    try {
      print('🔄 [SubjectService] Updating subject: $subjectId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (subjectName != null) updateData['subject_name'] = subjectName;
      if (subjectCode != null) updateData['subject_code'] = subjectCode;
      if (description != null) updateData['description'] = description;
      if (teacherId != null) updateData['teacher_id'] = teacherId;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('classroom_subjects')
          .update(updateData)
          .eq('id', subjectId)
          .select()
          .single();

      print('✅ [SubjectService] Subject updated successfully');

      return ClassroomSubject.fromJson(response);
    } catch (e) {
      print('❌ [SubjectService] Error updating subject: $e');
      rethrow;
    }
  }

  /// Delete a subject
  Future<void> deleteSubject(String subjectId) async {
    try {
      print('🗑️ [SubjectService] Deleting subject: $subjectId');

      await _supabase.from('classroom_subjects').delete().eq('id', subjectId);

      print('✅ [SubjectService] Subject deleted successfully');
    } catch (e) {
      print('❌ [SubjectService] Error deleting subject: $e');
      rethrow;
    }
  }

  /// Get subject by ID
  Future<ClassroomSubject?> getSubjectById(String subjectId) async {
    try {
      print('🔍 [SubjectService] Fetching subject: $subjectId');

      final response = await _supabase
          .from('classroom_subjects_with_details')
          .select()
          .eq('id', subjectId)
          .maybeSingle();

      if (response == null) {
        print('⚠️ [SubjectService] Subject not found');
        return null;
      }

      print('✅ [SubjectService] Subject fetched successfully');

      return ClassroomSubject.fromJson(response);
    } catch (e) {
      print('❌ [SubjectService] Error fetching subject: $e');
      rethrow;
    }
  }

  // ============================================
  // SUB-SUBJECT TREE ENHANCEMENT METHODS
  // ============================================

  /// Initialize MAPEH sub-subjects (Music, Arts, PE, Health)
  /// Automatically creates 4 hardcoded sub-subjects when MAPEH is added
  Future<void> initializeMAPEHSubSubjects({
    required String classroomId,
    required String mapehSubjectId,
  }) async {
    try {
      print('🎵 [SubjectService] Initializing MAPEH sub-subjects for: $mapehSubjectId');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call RPC function to create MAPEH sub-subjects
      await _supabase.rpc('initialize_mapeh_sub_subjects', params: {
        'p_classroom_id': classroomId,
        'p_mapeh_subject_id': mapehSubjectId,
        'p_created_by': currentUser.id,
      });

      print('✅ [SubjectService] MAPEH sub-subjects initialized successfully');
    } catch (e) {
      print('❌ [SubjectService] Error initializing MAPEH sub-subjects: $e');
      rethrow;
    }
  }

  /// Get sub-subjects for a parent subject (MAPEH or TLE)
  Future<List<ClassroomSubject>> getSubSubjects({
    required String parentSubjectId,
  }) async {
    try {
      print('📋 [SubjectService] Fetching sub-subjects for parent: $parentSubjectId');

      final response = await _supabase
          .from('classroom_subjects_with_details')
          .select()
          .eq('parent_subject_id', parentSubjectId)
          .eq('is_active', true)
          .order('subject_name');

      print('✅ [SubjectService] Fetched ${response.length} sub-subjects');

      return (response as List)
          .map((json) => ClassroomSubject.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [SubjectService] Error fetching sub-subjects: $e');
      rethrow;
    }
  }

  /// Add TLE sub-subject (admin/teacher can add custom TLE components)
  Future<ClassroomSubject> addTLESubSubject({
    required String classroomId,
    required String tleParentId,
    required String subjectName,
    String? teacherId,
    String? description,
  }) async {
    try {
      print('➕ [SubjectService] Adding TLE sub-subject: $subjectName');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('classroom_subjects')
          .insert({
            'classroom_id': classroomId,
            'subject_name': subjectName,
            'subject_type': 'tle_sub',
            'parent_subject_id': tleParentId,
            'teacher_id': teacherId,
            'description': description,
            'is_active': true,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      print('✅ [SubjectService] TLE sub-subject added successfully');

      return ClassroomSubject.fromJson(response);
    } catch (e) {
      print('❌ [SubjectService] Error adding TLE sub-subject: $e');
      rethrow;
    }
  }

  /// Add MAPEH parent subject and auto-initialize sub-subjects
  Future<ClassroomSubject> addMAPEHSubject({
    required String classroomId,
    String? teacherId,
    String? description,
  }) async {
    try {
      print('➕ [SubjectService] Adding MAPEH parent subject');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create MAPEH parent subject
      final response = await _supabase
          .from('classroom_subjects')
          .insert({
            'classroom_id': classroomId,
            'subject_name': 'MAPEH',
            'subject_type': 'mapeh_parent',
            'teacher_id': teacherId,
            'description': description,
            'is_active': true,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      final mapehSubject = ClassroomSubject.fromJson(response);

      // Auto-initialize MAPEH sub-subjects
      await initializeMAPEHSubSubjects(
        classroomId: classroomId,
        mapehSubjectId: mapehSubject.id,
      );

      print('✅ [SubjectService] MAPEH subject added with sub-subjects');

      return mapehSubject;
    } catch (e) {
      print('❌ [SubjectService] Error adding MAPEH subject: $e');
      rethrow;
    }
  }

  /// Add TLE parent subject
  Future<ClassroomSubject> addTLESubject({
    required String classroomId,
    String? teacherId,
    String? description,
  }) async {
    try {
      print('➕ [SubjectService] Adding TLE parent subject');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('classroom_subjects')
          .insert({
            'classroom_id': classroomId,
            'subject_name': 'TLE',
            'subject_type': 'tle_parent',
            'teacher_id': teacherId,
            'description': description,
            'is_active': true,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      print('✅ [SubjectService] TLE subject added successfully');

      return ClassroomSubject.fromJson(response);
    } catch (e) {
      print('❌ [SubjectService] Error adding TLE subject: $e');
      rethrow;
    }
  }
}
