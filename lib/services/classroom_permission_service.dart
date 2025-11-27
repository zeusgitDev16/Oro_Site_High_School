/// Classroom Permission Service
/// 
/// Centralized RBAC (Role-Based Access Control) logic for classroom features.
/// Determines what actions users can perform based on their role and relationship
/// to the classroom/subject.
/// 
/// **Roles:**
/// - **admin**: Full access to all features
/// - **ict_coordinator**: Admin-like permissions
/// - **hybrid**: Both admin and teacher permissions
/// - **grade_level_coordinator**: Teacher-like permissions with additional coordination features
/// - **teacher**: Can manage own classrooms and subjects
/// - **student**: Read-only access, can submit assignments
/// 
/// **Usage:**
/// ```dart
/// final permissions = ClassroomPermissionService();
/// 
/// // Check if user can create subjects
/// if (permissions.canCreateSubjects(userRole: 'teacher', userId: teacherId, classroom: classroom)) {
///   // Show create subject button
/// }
/// 
/// // Check if user can upload modules
/// if (permissions.canUploadModules(userRole: 'teacher', userId: teacherId, subject: subject)) {
///   // Show upload module button
/// }
/// ```
class ClassroomPermissionService {
  /// Check if user has admin-like permissions
  /// Includes: admin, ict_coordinator, hybrid
  bool hasAdminPermissions(String? userRole) {
    final role = userRole?.toLowerCase();
    return role == 'admin' || 
           role == 'ict_coordinator' || 
           role == 'hybrid';
  }
  
  /// Check if user has teacher-like permissions
  /// Includes: teacher, grade_level_coordinator, hybrid
  bool hasTeacherPermissions(String? userRole) {
    final role = userRole?.toLowerCase();
    return role == 'teacher' || 
           role == 'grade_level_coordinator' || 
           role == 'hybrid';
  }
  
  /// Check if user is a student
  bool isStudent(String? userRole) {
    return userRole?.toLowerCase() == 'student';
  }
  
  /// Check if user can manage classrooms (create, edit, delete)
  bool canManageClassrooms({required String? userRole}) {
    return hasAdminPermissions(userRole);
  }
  
  /// Check if user can view classroom details
  bool canViewClassroom({
    required String? userRole,
    required String? userId,
    required String? classroomTeacherId,
    required String? classroomAdvisoryTeacherId,
    required List<String>? coTeacherIds,
    required List<String>? studentIds,
  }) {
    // Admins can view all classrooms
    if (hasAdminPermissions(userRole)) return true;
    
    // Teachers can view classrooms they're associated with
    if (hasTeacherPermissions(userRole) && userId != null) {
      if (userId == classroomTeacherId) return true;
      if (userId == classroomAdvisoryTeacherId) return true;
      if (coTeacherIds?.contains(userId) == true) return true;
    }
    
    // Students can view classrooms they're enrolled in
    if (isStudent(userRole) && userId != null) {
      if (studentIds?.contains(userId) == true) return true;
    }
    
    return false;
  }
  
  /// Check if user can create subjects in a classroom
  bool canCreateSubjects({
    required String? userRole,
    required String? userId,
    required String? classroomTeacherId,
    required String? classroomAdvisoryTeacherId,
  }) {
    // Admins can create subjects in any classroom
    if (hasAdminPermissions(userRole)) return true;
    
    // Teachers can create subjects in their own classrooms
    if (hasTeacherPermissions(userRole) && userId != null) {
      if (userId == classroomTeacherId) return true;
      if (userId == classroomAdvisoryTeacherId) return true;
    }
    
    return false;
  }
  
  /// Check if user can edit/delete a subject
  bool canManageSubject({
    required String? userRole,
    required String? userId,
    required String? subjectTeacherId,
  }) {
    // Admins can manage all subjects
    if (hasAdminPermissions(userRole)) return true;
    
    // Teachers can manage their own subjects
    if (hasTeacherPermissions(userRole) && userId != null) {
      if (userId == subjectTeacherId) return true;
    }
    
    return false;
  }
  
  /// Check if user can upload modules/resources
  bool canUploadModules({
    required String? userRole,
    required String? userId,
    required String? subjectTeacherId,
  }) {
    // Same as canManageSubject
    return canManageSubject(
      userRole: userRole,
      userId: userId,
      subjectTeacherId: subjectTeacherId,
    );
  }
  
  /// Check if user can create assignments
  bool canCreateAssignments({
    required String? userRole,
    required String? userId,
    required String? subjectTeacherId,
  }) {
    // Same as canManageSubject
    return canManageSubject(
      userRole: userRole,
      userId: userId,
      subjectTeacherId: subjectTeacherId,
    );
  }
  
  /// Check if user can submit assignments
  bool canSubmitAssignments({required String? userRole}) {
    return isStudent(userRole);
  }
  
  /// Check if user can manage announcements (create, edit, delete)
  bool canManageAnnouncements({
    required String? userRole,
    required String? userId,
    required String? subjectTeacherId,
  }) {
    // Same as canManageSubject
    return canManageSubject(
      userRole: userRole,
      userId: userId,
      subjectTeacherId: subjectTeacherId,
    );
  }
  
  /// Check if user can post announcement replies
  bool canPostAnnouncementReplies({required String? userRole}) {
    // All authenticated users can post replies
    return userRole != null;
  }
}

