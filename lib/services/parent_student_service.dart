/// Parent-Student Service
/// Manages parent-student relationships and data access

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parent_student.dart';

class ParentStudentService {
  static final ParentStudentService _instance = ParentStudentService._internal();
  factory ParentStudentService() => _instance;
  ParentStudentService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all children for a parent
  Future<List<ParentStudent>> getChildrenForParent(String parentId) async {
    try {
      final response = await _supabase
          .from('parent_students')
          .select()
          .eq('parent_id', parentId)
          .eq('is_active', true);

      return (response as List)
          .map((json) => ParentStudent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching children: $e');
      // Return mock data for development
      return _getMockChildren(parentId);
    }
  }

  /// Get all parents for a student
  Future<List<ParentStudent>> getParentsForStudent(String studentId) async {
    try {
      final response = await _supabase
          .from('parent_students')
          .select()
          .eq('student_id', studentId)
          .eq('is_active', true);

      return (response as List)
          .map((json) => ParentStudent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching parents: $e');
      return [];
    }
  }

  /// Get primary guardian for a student
  Future<ParentStudent?> getPrimaryGuardian(String studentId) async {
    try {
      final response = await _supabase
          .from('parent_students')
          .select()
          .eq('student_id', studentId)
          .eq('is_primary_guardian', true)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return ParentStudent.fromJson(response);
    } catch (e) {
      print('Error fetching primary guardian: $e');
      return null;
    }
  }

  /// Create a new parent-student relationship
  Future<ParentStudent> createRelationship({
    required String parentId,
    required String studentId,
    required String studentLrn,
    required GuardianRelationship relationship,
    required bool isPrimaryGuardian,
    required Map<String, dynamic> studentInfo,
    required Map<String, dynamic> parentInfo,
  }) async {
    try {
      final response = await _supabase.from('parent_students').insert({
        'parent_id': parentId,
        'student_id': studentId,
        'student_lrn': studentLrn,
        'relationship': relationship.code,
        'is_primary_guardian': isPrimaryGuardian,
        'student_first_name': studentInfo['first_name'],
        'student_last_name': studentInfo['last_name'],
        'student_middle_name': studentInfo['middle_name'] ?? '',
        'student_grade_level': studentInfo['grade_level'],
        'student_section': studentInfo['section'],
        'student_photo_url': studentInfo['photo_url'],
        'parent_first_name': parentInfo['first_name'],
        'parent_last_name': parentInfo['last_name'],
        'parent_email': parentInfo['email'],
        'parent_phone': parentInfo['phone'],
        'is_active': true,
      }).select().single();

      return ParentStudent.fromJson(response);
    } catch (e) {
      print('Error creating relationship: $e');
      throw Exception('Failed to create parent-student relationship');
    }
  }

  /// Update relationship permissions
  Future<void> updatePermissions({
    required String relationshipId,
    bool? canViewGrades,
    bool? canViewAttendance,
    bool? canReceiveSms,
    bool? canContactTeachers,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (canViewGrades != null) updates['can_view_grades'] = canViewGrades;
      if (canViewAttendance != null) updates['can_view_attendance'] = canViewAttendance;
      if (canReceiveSms != null) updates['can_receive_sms'] = canReceiveSms;
      if (canContactTeachers != null) updates['can_contact_teachers'] = canContactTeachers;
      
      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        
        await _supabase
            .from('parent_students')
            .update(updates)
            .eq('id', relationshipId);
      }
    } catch (e) {
      print('Error updating permissions: $e');
      throw Exception('Failed to update permissions');
    }
  }

  /// Verify a parent-student relationship
  Future<void> verifyRelationship({
    required String relationshipId,
    required String verifiedBy,
  }) async {
    try {
      await _supabase
          .from('parent_students')
          .update({
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': verifiedBy,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationshipId);
    } catch (e) {
      print('Error verifying relationship: $e');
      throw Exception('Failed to verify relationship');
    }
  }

  /// Deactivate a parent-student relationship
  Future<void> deactivateRelationship(String relationshipId) async {
    try {
      await _supabase
          .from('parent_students')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationshipId);
    } catch (e) {
      print('Error deactivating relationship: $e');
      throw Exception('Failed to deactivate relationship');
    }
  }

  /// Set primary guardian for a student
  Future<void> setPrimaryGuardian({
    required String studentId,
    required String relationshipId,
  }) async {
    try {
      // First, remove primary status from all other guardians
      await _supabase
          .from('parent_students')
          .update({
            'is_primary_guardian': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentId);

      // Then set the new primary guardian
      await _supabase
          .from('parent_students')
          .update({
            'is_primary_guardian': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationshipId);
    } catch (e) {
      print('Error setting primary guardian: $e');
      throw Exception('Failed to set primary guardian');
    }
  }

  /// Get parents who should receive SMS for a student
  Future<List<ParentStudent>> getSmsRecipients(String studentId) async {
    try {
      final response = await _supabase
          .from('parent_students')
          .select()
          .eq('student_id', studentId)
          .eq('is_active', true)
          .eq('can_receive_sms', true);

      return (response as List)
          .map((json) => ParentStudent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching SMS recipients: $e');
      return [];
    }
  }

  /// Check if parent has access to student data
  Future<bool> hasAccess({
    required String parentId,
    required String studentId,
  }) async {
    try {
      final response = await _supabase
          .from('parent_students')
          .select('id, is_active, verified_at')
          .eq('parent_id', parentId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) return false;
      
      final isActive = response['is_active'] ?? false;
      final isVerified = response['verified_at'] != null;
      
      return isActive && isVerified;
    } catch (e) {
      print('Error checking access: $e');
      return false;
    }
  }

  /// Mock data for development
  List<ParentStudent> _getMockChildren(String parentId) {
    final now = DateTime.now();
    return [
      ParentStudent(
        id: 'ps-001',
        parentId: parentId,
        studentId: 'student-001',
        studentLrn: '123456789012',
        relationship: GuardianRelationship.mother,
        isPrimaryGuardian: true,
        studentFirstName: 'Juan',
        studentLastName: 'Dela Cruz',
        studentMiddleName: 'Santos',
        studentGradeLevel: 7,
        studentSection: 'Diamond',
        parentFirstName: 'Maria',
        parentLastName: 'Dela Cruz',
        parentEmail: 'maria.delacruz@parent.oshs.edu.ph',
        parentPhone: '+639123456789',
        isActive: true,
        verifiedAt: now.subtract(const Duration(days: 30)),
        verifiedBy: 'admin-001',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      ParentStudent(
        id: 'ps-002',
        parentId: parentId,
        studentId: 'student-002',
        studentLrn: '123456789013',
        relationship: GuardianRelationship.mother,
        isPrimaryGuardian: true,
        studentFirstName: 'Ana',
        studentLastName: 'Dela Cruz',
        studentMiddleName: 'Santos',
        studentGradeLevel: 9,
        studentSection: 'Ruby',
        parentFirstName: 'Maria',
        parentLastName: 'Dela Cruz',
        parentEmail: 'maria.delacruz@parent.oshs.edu.ph',
        parentPhone: '+639123456789',
        isActive: true,
        verifiedAt: now.subtract(const Duration(days: 30)),
        verifiedBy: 'admin-001',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ];
  }
}