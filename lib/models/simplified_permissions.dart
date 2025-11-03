/// Simplified Role-Based Permission System
/// Reduces complexity from 20+ permissions to 5 core roles
/// 
/// Philosophy: Use roles instead of granular permissions
/// Easier to manage, understand, and maintain

enum UserRole {
  admin,
  teacher,
  student,
  parent,
  coordinator, // Grade level coordinator (enhanced teacher)
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.coordinator:
        return 'Grade Level Coordinator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access - manages school operations';
      case UserRole.teacher:
        return 'Manages own courses, grades, and attendance';
      case UserRole.student:
        return 'Views courses, submits assignments, checks grades';
      case UserRole.parent:
        return 'Monitors child\'s progress and attendance';
      case UserRole.coordinator:
        return 'Enhanced teacher with grade level management';
    }
  }

  /// Get all permissions for this role
  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          // Full access to everything
          'manage_users',
          'manage_courses',
          'manage_sections',
          'manage_teachers',
          'manage_students',
          'manage_grades',
          'manage_attendance',
          'manage_assignments',
          'view_reports',
          'manage_settings',
          'approve_requests',
          'send_messages',
          'view_analytics',
        ];

      case UserRole.teacher:
        return [
          // Own courses only
          'view_own_courses',
          'manage_own_grades',
          'manage_own_attendance',
          'create_assignments',
          'view_own_students',
          'send_messages',
          'submit_requests',
          'view_own_reports',
        ];

      case UserRole.student:
        return [
          // View and submit only
          'view_own_courses',
          'view_own_grades',
          'view_own_attendance',
          'submit_assignments',
          'view_materials',
          'send_messages',
        ];

      case UserRole.parent:
        return [
          // Monitor child only
          'view_child_courses',
          'view_child_grades',
          'view_child_attendance',
          'view_child_progress',
          'send_messages',
          'view_child_reports',
        ];

      case UserRole.coordinator:
        return [
          // Teacher + grade level management
          'view_own_courses',
          'manage_own_grades',
          'manage_own_attendance',
          'create_assignments',
          'view_own_students',
          'send_messages',
          'submit_requests',
          'view_own_reports',
          // Coordinator-specific
          'manage_grade_level',
          'bulk_grade_entry',
          'view_section_comparison',
          'coordinate_teachers',
        ];
    }
  }

  /// Check if role has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if role can access admin features
  bool get isAdmin => this == UserRole.admin;

  /// Check if role can teach
  bool get canTeach => [UserRole.teacher, UserRole.coordinator].contains(this);

  /// Check if role is a student
  bool get isStudent => this == UserRole.student;

  /// Check if role is a parent
  bool get isParent => this == UserRole.parent;
}

/// Permission checker service
class PermissionChecker {
  /// Check if user has permission
  static bool hasPermission(UserRole role, String permission) {
    return role.hasPermission(permission);
  }

  /// Check if user can access feature
  static bool canAccess(UserRole role, String feature) {
    switch (feature) {
      // Admin-only features
      case 'user_management':
      case 'system_settings':
      case 'teacher_approval':
        return role.isAdmin;

      // Teacher features
      case 'grade_entry':
      case 'attendance_taking':
      case 'assignment_creation':
        return role.canTeach;

      // Student features
      case 'assignment_submission':
      case 'grade_viewing':
        return role.isStudent;

      // Parent features
      case 'child_monitoring':
        return role.isParent;

      // Shared features
      case 'messaging':
        return true; // All roles can message

      default:
        return false;
    }
  }

  /// Get role from string
  static UserRole? getRoleFromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
      case 'guardian':
        return UserRole.parent;
      case 'coordinator':
      case 'grade_level_coordinator':
        return UserRole.coordinator;
      default:
        return null;
    }
  }

  /// Get role display name
  static String getRoleName(UserRole role) {
    return role.name;
  }

  /// Get all available roles
  static List<UserRole> getAllRoles() {
    return UserRole.values;
  }

  /// Get roles that can teach
  static List<UserRole> getTeachingRoles() {
    return [UserRole.teacher, UserRole.coordinator];
  }
}

/// User with role
class UserWithRole {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserWithRole({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Check if user has permission
  bool hasPermission(String permission) {
    return role.hasPermission(permission);
  }

  /// Check if user can access feature
  bool canAccess(String feature) {
    return PermissionChecker.canAccess(role, feature);
  }

  /// Get user's role name
  String get roleName => role.name;

  /// Get user's permissions
  List<String> get permissions => role.permissions;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserWithRole.fromJson(Map<String, dynamic> json) {
    return UserWithRole(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: PermissionChecker.getRoleFromString(json['role']) ?? UserRole.student,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Permission constants for easy reference
class Permissions {
  // Admin permissions
  static const String manageUsers = 'manage_users';
  static const String manageCourses = 'manage_courses';
  static const String manageSections = 'manage_sections';
  static const String viewReports = 'view_reports';
  static const String manageSettings = 'manage_settings';

  // Teacher permissions
  static const String viewOwnCourses = 'view_own_courses';
  static const String manageOwnGrades = 'manage_own_grades';
  static const String manageOwnAttendance = 'manage_own_attendance';
  static const String createAssignments = 'create_assignments';

  // Student permissions
  static const String submitAssignments = 'submit_assignments';
  static const String viewOwnGrades = 'view_own_grades';
  static const String viewOwnAttendance = 'view_own_attendance';

  // Parent permissions
  static const String viewChildGrades = 'view_child_grades';
  static const String viewChildAttendance = 'view_child_attendance';
  static const String viewChildProgress = 'view_child_progress';

  // Shared permissions
  static const String sendMessages = 'send_messages';
}
