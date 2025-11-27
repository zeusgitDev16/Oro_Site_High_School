import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_resources_content.dart';

/// Reusable modules tab widget for subject resources
///
/// Displays subject resources (modules, assignment resources) organized by quarter.
/// Uses the existing SubjectResourcesContent widget with proper RBAC configuration.
///
/// **Phase 5: Role-Based Layout**
/// - **Students**: Tab bar layout (Modules and Assignments as sub-tabs)
/// - **Teachers/Admin**: Card layout (Modules, Assignment Resources, Assignments as cards)
///
/// **Usage:**
/// ```dart
/// SubjectModulesTab(
///   subject: _selectedSubject!,
///   classroomId: _selectedClassroom!.id,
///   userRole: 'teacher',
///   userId: _teacherId!,
/// )
/// ```
class SubjectModulesTab extends StatelessWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final String? userRole;
  final String? userId;

  const SubjectModulesTab({
    super.key,
    required this.subject,
    required this.classroomId,
    this.userRole,
    this.userId,
  });

  bool get _isAdmin {
    final role = userRole?.toLowerCase();
    return role == 'admin' || 
           role == 'ict_coordinator' || 
           role == 'hybrid';
  }

  @override
  Widget build(BuildContext context) {
    return SubjectResourcesContent(
      subject: subject,
      classroomId: classroomId,
      isCreateMode: false, // Always consume mode (classroom already exists)
      isAdmin: _isAdmin,
      currentUserId: userId,
      userRole: userRole,
    );
  }
}

