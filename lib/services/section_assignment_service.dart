import 'package:oro_site_high_school/models/section_assignment.dart';
import 'package:oro_site_high_school/services/notification_trigger_service.dart';

/// Service for managing section-adviser assignments
/// Backend integration point: Supabase 'section_assignments' table
class SectionAssignmentService {
  // Singleton pattern
  static final SectionAssignmentService _instance = SectionAssignmentService._internal();
  factory SectionAssignmentService() => _instance;
  SectionAssignmentService._internal();

  final NotificationTriggerService _notificationTrigger = NotificationTriggerService();

  // Mock data for UI testing (will be replaced with Supabase calls)
  final List<SectionAssignment> _mockAssignments = [
    SectionAssignment(
      id: 'sa-1',
      sectionId: 'section-1',
      sectionName: 'Grade 7 - Diamond',
      adviserId: 'teacher-1',
      adviserName: 'Maria Santos',
      gradeLevel: 7,
      studentCount: 35,
      assignedDate: DateTime.now().subtract(const Duration(days: 30)),
      schoolYear: '2024-2025',
      status: 'active',
      assignedBy: 'Steven Johnson',
      room: 'Room 101',
      schedule: 'Monday-Friday, 7:00 AM - 3:00 PM',
      notes: 'Grade Level Coordinator for Grade 7',
    ),
    SectionAssignment(
      id: 'sa-2',
      sectionId: 'section-2',
      sectionName: 'Grade 8 - Sapphire',
      adviserId: 'teacher-2',
      adviserName: 'Juan Reyes',
      gradeLevel: 8,
      studentCount: 35,
      assignedDate: DateTime.now().subtract(const Duration(days: 25)),
      schoolYear: '2024-2025',
      status: 'active',
      assignedBy: 'Steven Johnson',
      room: 'Room 201',
      schedule: 'Monday-Friday, 7:00 AM - 3:00 PM',
    ),
  ];

  /// Get all section assignments
  Future<List<SectionAssignment>> getAllAssignments() async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('section_assignments').select();
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockAssignments);
  }

  /// Get assignments for a specific adviser
  Future<List<SectionAssignment>> getAssignmentsByAdviser(String adviserId) async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('section_assignments')
    //   .select()
    //   .eq('adviser_id', adviserId);
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments.where((a) => a.adviserId == adviserId).toList();
  }

  /// Get assignment for a specific section
  Future<SectionAssignment?> getAssignmentBySection(String sectionId) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockAssignments.firstWhere((a) => a.sectionId == sectionId);
    } catch (e) {
      return null;
    }
  }

  /// Get assignments by grade level
  Future<List<SectionAssignment>> getAssignmentsByGradeLevel(int gradeLevel) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments.where((a) => a.gradeLevel == gradeLevel).toList();
  }

  /// Get active assignments for current school year
  Future<List<SectionAssignment>> getActiveAssignments(String schoolYear) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments
        .where((a) => a.status == 'active' && a.schoolYear == schoolYear)
        .toList();
  }

  /// Create a new section assignment
  Future<SectionAssignment> createAssignment(SectionAssignment assignment) async {
    // TODO: Replace with Supabase insert
    // final response = await supabase.from('section_assignments')
    //   .insert(assignment.toJson())
    //   .select()
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAssignments.add(assignment);
    
    // Trigger notification to adviser
    await _notificationTrigger.triggerAdviserAssignment(
      teacherId: assignment.adviserId,
      sectionName: assignment.sectionName,
      adminName: assignment.assignedBy ?? 'Admin',
    );
    
    return assignment;
  }

  /// Update an existing assignment
  Future<SectionAssignment> updateAssignment(SectionAssignment assignment) async {
    // TODO: Replace with Supabase update
    // final response = await supabase.from('section_assignments')
    //   .update(assignment.toJson())
    //   .eq('id', assignment.id)
    //   .select()
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockAssignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) {
      _mockAssignments[index] = assignment;
    }
    return assignment;
  }

  /// Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    // TODO: Replace with Supabase delete
    // await supabase.from('section_assignments')
    //   .delete()
    //   .eq('id', assignmentId);
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAssignments.removeWhere((a) => a.id == assignmentId);
  }

  /// Get adviser workload (number of sections assigned)
  Future<Map<String, int>> getAdviserWorkload() async {
    // TODO: Replace with Supabase aggregation query
    await Future.delayed(const Duration(milliseconds: 300));
    final workload = <String, int>{};
    for (var assignment in _mockAssignments) {
      if (assignment.status == 'active') {
        workload[assignment.adviserId] = (workload[assignment.adviserId] ?? 0) + 1;
      }
    }
    return workload;
  }

  /// Check if a section has an adviser
  Future<bool> hasSectionAdviser(String sectionId) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockAssignments.any(
      (a) => a.sectionId == sectionId && a.status == 'active',
    );
  }

  /// Get sections without advisers
  Future<List<String>> getSectionsWithoutAdvisers(List<String> allSectionIds) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    final assignedSections = _mockAssignments
        .where((a) => a.status == 'active')
        .map((a) => a.sectionId)
        .toSet();
    return allSectionIds.where((id) => !assignedSections.contains(id)).toList();
  }

  /// Archive assignments for a school year
  Future<void> archiveAssignments(String schoolYear) async {
    // TODO: Replace with Supabase update
    await Future.delayed(const Duration(milliseconds: 500));
    for (var i = 0; i < _mockAssignments.length; i++) {
      if (_mockAssignments[i].schoolYear == schoolYear) {
        _mockAssignments[i] = _mockAssignments[i].copyWith(status: 'archived');
      }
    }
  }
}
