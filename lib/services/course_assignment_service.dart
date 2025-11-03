import 'package:oro_site_high_school/models/course_assignment.dart';
import 'package:oro_site_high_school/services/notification_trigger_service.dart';

/// Service for managing course-teacher assignments
/// Backend integration point: Supabase 'course_assignments' table
class CourseAssignmentService {
  // Singleton pattern
  static final CourseAssignmentService _instance = CourseAssignmentService._internal();
  factory CourseAssignmentService() => _instance;
  CourseAssignmentService._internal();

  final NotificationTriggerService _notificationTrigger = NotificationTriggerService();

  // Mock data for UI testing (will be replaced with Supabase calls)
  final List<CourseAssignment> _mockAssignments = [
    CourseAssignment(
      id: 'ca-1',
      courseId: 'course-1',
      teacherId: 'teacher-1',
      teacherName: 'Maria Santos',
      courseName: 'Mathematics 7',
      section: 'Grade 7 - Diamond',
      assignedDate: DateTime.now().subtract(const Duration(days: 30)),
      status: 'active',
      studentCount: 35,
      schoolYear: '2024-2025',
      assignedBy: 'Steven Johnson',
      notes: 'Assigned as Grade Level Coordinator',
    ),
    CourseAssignment(
      id: 'ca-2',
      courseId: 'course-2',
      teacherId: 'teacher-1',
      teacherName: 'Maria Santos',
      courseName: 'Science 7',
      section: 'Grade 7 - Diamond',
      assignedDate: DateTime.now().subtract(const Duration(days: 30)),
      status: 'active',
      studentCount: 35,
      schoolYear: '2024-2025',
      assignedBy: 'Steven Johnson',
      notes: 'Assigned as Grade Level Coordinator',
    ),
    CourseAssignment(
      id: 'ca-3',
      courseId: 'course-3',
      teacherId: 'teacher-2',
      teacherName: 'Juan Reyes',
      courseName: 'Mathematics 8',
      section: 'Grade 8 - Sapphire',
      assignedDate: DateTime.now().subtract(const Duration(days: 25)),
      status: 'active',
      studentCount: 35,
      schoolYear: '2024-2025',
      assignedBy: 'Steven Johnson',
    ),
  ];

  /// Get all course assignments
  Future<List<CourseAssignment>> getAllAssignments() async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('course_assignments').select();
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return List.from(_mockAssignments);
  }

  /// Get assignments for a specific teacher
  Future<List<CourseAssignment>> getAssignmentsByTeacher(String teacherId) async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('course_assignments')
    //   .select()
    //   .eq('teacher_id', teacherId);
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments.where((a) => a.teacherId == teacherId).toList();
  }

  /// Get assignments for a specific course
  Future<List<CourseAssignment>> getAssignmentsByCourse(String courseId) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments.where((a) => a.courseId == courseId).toList();
  }

  /// Get active assignments for current school year
  Future<List<CourseAssignment>> getActiveAssignments(String schoolYear) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockAssignments
        .where((a) => a.status == 'active' && a.schoolYear == schoolYear)
        .toList();
  }

  /// Create a new course assignment
  Future<CourseAssignment> createAssignment(CourseAssignment assignment) async {
    // TODO: Replace with Supabase insert
    // final response = await supabase.from('course_assignments')
    //   .insert(assignment.toJson())
    //   .select()
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAssignments.add(assignment);
    
    // Trigger notification to teacher
    await _notificationTrigger.triggerCourseAssignment(
      teacherId: assignment.teacherId,
      teacherName: assignment.teacherName,
      courseName: assignment.courseName,
      section: assignment.section,
      adminName: assignment.assignedBy ?? 'Admin',
    );
    
    return assignment;
  }

  /// Update an existing assignment
  Future<CourseAssignment> updateAssignment(CourseAssignment assignment) async {
    // TODO: Replace with Supabase update
    // final response = await supabase.from('course_assignments')
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
    // await supabase.from('course_assignments')
    //   .delete()
    //   .eq('id', assignmentId);
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAssignments.removeWhere((a) => a.id == assignmentId);
  }

  /// Get teacher workload (number of courses assigned)
  Future<Map<String, int>> getTeacherWorkload() async {
    // TODO: Replace with Supabase aggregation query
    await Future.delayed(const Duration(milliseconds: 300));
    final workload = <String, int>{};
    for (var assignment in _mockAssignments) {
      if (assignment.status == 'active') {
        workload[assignment.teacherId] = (workload[assignment.teacherId] ?? 0) + 1;
      }
    }
    return workload;
  }

  /// Get available teachers (not overloaded)
  Future<List<String>> getAvailableTeachers({int maxCourses = 3}) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    final workload = await getTeacherWorkload();
    return workload.entries
        .where((entry) => entry.value < maxCourses)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if a teacher is assigned to a course
  Future<bool> isTeacherAssignedToCourse(String teacherId, String courseId) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockAssignments.any(
      (a) => a.teacherId == teacherId && a.courseId == courseId && a.status == 'active',
    );
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
