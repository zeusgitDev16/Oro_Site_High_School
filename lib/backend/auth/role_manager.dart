// Role Manager
// Manages user roles and permissions
// Handles role-based access control (RBAC)

import '../config/supabase_config.dart';

/// User roles in the system
enum UserRole { admin, teacher, coordinator, student, parent }

/// Permission types
enum Permission {
  // User management
  createUser,
  readUser,
  updateUser,
  deleteUser,
  resetPassword,

  // Course management
  createCourse,
  readCourse,
  updateCourse,
  deleteCourse,
  assignTeacher,

  // Grade management
  createGrade,
  readGrade,
  updateGrade,
  deleteGrade,
  verifyGrade,

  // Attendance management
  createAttendance,
  readAttendance,
  updateAttendance,
  deleteAttendance,
  scanQR,

  // Announcement management
  createAnnouncement,
  readAnnouncement,
  updateAnnouncement,
  deleteAnnouncement,

  // Message management
  sendMessage,
  readMessage,

  // Report generation
  generateReport,
  exportData,

  // System settings
  manageSettings,
  viewAnalytics,
}

class RoleManager {
  // Singleton pattern
  static final RoleManager _instance = RoleManager._internal();
  factory RoleManager() => _instance;
  RoleManager._internal();

  final _client = SupabaseConfig.client;

  /// Role permissions mapping
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.admin: {
      // Full system access
      ...Permission.values,
    },

    UserRole.coordinator: {
      // Grade coordinator permissions
      Permission.readUser,
      Permission.updateUser,
      Permission.resetPassword,
      Permission.readCourse,
      Permission.createGrade,
      Permission.readGrade,
      Permission.updateGrade,
      Permission.verifyGrade,
      Permission.createAttendance,
      Permission.readAttendance,
      Permission.updateAttendance,
      Permission.scanQR,
      Permission.readAnnouncement,
      Permission.sendMessage,
      Permission.readMessage,
      Permission.generateReport,
      Permission.exportData,
      Permission.viewAnalytics,
    },

    UserRole.teacher: {
      // Teacher permissions
      Permission.readUser,
      Permission.readCourse,
      Permission.createGrade,
      Permission.readGrade,
      Permission.updateGrade,
      Permission.createAttendance,
      Permission.readAttendance,
      Permission.updateAttendance,
      Permission.scanQR,
      Permission.createAnnouncement,
      Permission.readAnnouncement,
      Permission.updateAnnouncement,
      Permission.sendMessage,
      Permission.readMessage,
      Permission.generateReport,
    },

    UserRole.student: {
      // Student permissions
      Permission.readUser,
      Permission.readCourse,
      Permission.readGrade,
      Permission.readAttendance,
      Permission.readAnnouncement,
      Permission.sendMessage,
      Permission.readMessage,
    },

    UserRole.parent: {
      // Parent permissions
      Permission.readUser,
      Permission.readCourse,
      Permission.readGrade,
      Permission.readAttendance,
      Permission.readAnnouncement,
      Permission.sendMessage,
      Permission.readMessage,
    },
  };

  /// Get user role from database
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', userId)
          .single();

      return response['roles']?['name'];
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  /// Get user role enum
  Future<UserRole?> getUserRoleEnum(String userId) async {
    final roleName = await getUserRole(userId);
    if (roleName == null) return null;

    return _parseRole(roleName);
  }

  /// Parse role string to enum
  UserRole? _parseRole(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'coordinator':
        return UserRole.coordinator;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      default:
        return null;
    }
  }

  /// Check if user has permission
  Future<bool> hasPermission(String userId, Permission permission) async {
    final role = await getUserRoleEnum(userId);
    if (role == null) return false;

    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Check multiple permissions
  Future<bool> hasAllPermissions(
    String userId,
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      if (!await hasPermission(userId, permission)) {
        return false;
      }
    }
    return true;
  }

  /// Check if user has any of the permissions
  Future<bool> hasAnyPermission(
    String userId,
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      if (await hasPermission(userId, permission)) {
        return true;
      }
    }
    return false;
  }

  /// Get all permissions for a role
  Set<Permission> getRolePermissions(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  /// Check if role can access feature
  bool canAccessFeature(UserRole role, String feature) {
    final featurePermissions = _getFeaturePermissions(feature);
    final rolePerms = getRolePermissions(role);

    return featurePermissions.any((perm) => rolePerms.contains(perm));
  }

  /// Get required permissions for a feature
  List<Permission> _getFeaturePermissions(String feature) {
    switch (feature) {
      case 'user_management':
        return [
          Permission.createUser,
          Permission.updateUser,
          Permission.deleteUser,
        ];
      case 'course_management':
        return [
          Permission.createCourse,
          Permission.updateCourse,
          Permission.deleteCourse,
        ];
      case 'grade_management':
        return [
          Permission.createGrade,
          Permission.updateGrade,
          Permission.verifyGrade,
        ];
      case 'attendance_management':
        return [
          Permission.createAttendance,
          Permission.updateAttendance,
          Permission.scanQR,
        ];
      case 'announcements':
        return [Permission.createAnnouncement, Permission.updateAnnouncement];
      case 'messaging':
        return [Permission.sendMessage];
      case 'reports':
        return [Permission.generateReport, Permission.exportData];
      case 'settings':
        return [Permission.manageSettings];
      default:
        return [];
    }
  }

  /// Get accessible features for a role
  List<String> getAccessibleFeatures(UserRole role) {
    final features = <String>[];
    final allFeatures = [
      'user_management',
      'course_management',
      'grade_management',
      'attendance_management',
      'announcements',
      'messaging',
      'reports',
      'settings',
    ];

    for (final feature in allFeatures) {
      if (canAccessFeature(role, feature)) {
        features.add(feature);
      }
    }

    return features;
  }

  /// Check if user is grade coordinator
  Future<bool> isGradeCoordinator(String userId) async {
    try {
      final response = await _client
          .from('coordinator_assignments')
          .select()
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking coordinator status: $e');
      return false;
    }
  }

  /// Get coordinator grade level
  Future<int?> getCoordinatorGradeLevel(String userId) async {
    try {
      final response = await _client
          .from('coordinator_assignments')
          .select('grade_level')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .single();

      return response['grade_level'];
    } catch (e) {
      print('Error fetching coordinator grade level: $e');
      return null;
    }
  }

  /// Check if user is section adviser
  Future<bool> isSectionAdviser(String userId) async {
    try {
      final response = await _client
          .from('section_assignments')
          .select()
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking adviser status: $e');
      return false;
    }
  }

  /// Get adviser section
  Future<Map<String, dynamic>?> getAdviserSection(String userId) async {
    try {
      final response = await _client
          .from('section_assignments')
          .select('grade_level, section')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .single();

      return response;
    } catch (e) {
      print('Error fetching adviser section: $e');
      return null;
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      // Get role ID
      final roleResponse = await _client
          .from('roles')
          .select('id')
          .eq('name', newRole)
          .single();

      final roleId = roleResponse['id'];

      // Update profile
      await _client
          .from('profiles')
          .update({'role_id': roleId})
          .eq('id', userId);

      print('[INFO] User role updated to $newRole');
      return true;
    } catch (e) {
      print('[ERROR] Error updating user role: $e');
      return false;
    }
  }

  /// Get role statistics
  Future<Map<String, int>> getRoleStatistics() async {
    try {
      final response = await _client
          .from('profiles')
          .select('role_id, roles(name)');

      final stats = <String, int>{};

      for (final profile in response) {
        final roleName = profile['roles']?['name'] ?? 'unknown';
        stats[roleName] = (stats[roleName] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error fetching role statistics: $e');
      return {};
    }
  }

  /// Get role display name
  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.coordinator:
        return 'Grade Coordinator';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
    }
  }

  /// Get role icon
  String getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '👨‍💼';
      case UserRole.teacher:
        return '👩‍🏫';
      case UserRole.coordinator:
        return '🎓';
      case UserRole.student:
        return '👨‍🎓';
      case UserRole.parent:
        return '👨‍👩‍👧‍👦';
    }
  }
}
