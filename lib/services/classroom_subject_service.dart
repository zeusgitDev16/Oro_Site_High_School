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
}
