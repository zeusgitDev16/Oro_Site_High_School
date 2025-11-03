/// User Role Service
/// Manages user role detection and routing
/// Handles hybrid users and role switching

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole {
  admin,
  teacher,
  student,
  parent,
  gradeCoordinator,
  hybrid, // Admin who also teaches
}

class UserRoleService extends ChangeNotifier {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final _supabase = Supabase.instance.client;

  UserRole? _currentRole;
  UserRole? _primaryRole;
  UserRole? _secondaryRole;
  bool _isHybridUser = false;
  Map<String, dynamic>? _userProfile;

  // Getters
  UserRole? get currentRole => _currentRole;
  UserRole? get primaryRole => _primaryRole;
  UserRole? get secondaryRole => _secondaryRole;
  bool get isHybridUser => _isHybridUser;
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Initialize user role from database
  Future<void> initializeUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _clearRoles();
        return;
      }

      // Fetch user profile with role information
      final response = await _supabase
          .from('profiles')
          .select('*, roles(*)')
          .eq('id', user.id)
          .single();

      if (response != null) {
        _userProfile = response;
        _detectUserRoles(response);
      }
    } catch (e) {
      print('Error initializing user role: $e');
      // For now, use mock data if database is not ready
      _useMockRoleDetection();
    }

    notifyListeners();
  }

  /// Detect user roles from profile data
  void _detectUserRoles(Map<String, dynamic> profile) {
    final roleData = profile['roles'] ?? profile['role'];

    if (roleData == null) {
      // Fallback to role_id if roles table join fails
      final roleId = profile['role_id'];
      _setRoleById(roleId);
      return;
    }

    // Parse role information
    if (roleData is Map) {
      final roleName = roleData['name']?.toString().toLowerCase() ?? '';
      _setRoleByName(roleName);

      // Check for hybrid user
      final isHybrid = roleData['is_hybrid'] ?? false;
      if (isHybrid || profile['is_hybrid'] == true) {
        _enableHybridMode(roleName);
      }
    } else if (roleData is int) {
      _setRoleById(roleData);
    }
  }

  /// Set role by role ID (legacy support)
  void _setRoleById(int? roleId) {
    // Map numeric role IDs to enum based on current DB seed values:
    // 1=admin, 2=teacher, 3=student, 4=parent, 5=ict_coordinator, 6=grade_coordinator, 7=hybrid
    switch (roleId) {
      case 1:
        _primaryRole = UserRole.admin;
        break;
      case 2:
        _primaryRole = UserRole.teacher;
        break;
      case 3:
        _primaryRole = UserRole.student;
        break;
      case 4:
        _primaryRole = UserRole.parent;
        break;
      case 5:
        // ict_coordinator should access admin dashboard
        _primaryRole = UserRole.admin;
        break;
      case 6:
        _primaryRole = UserRole.gradeCoordinator;
        break;
      default:
        _primaryRole = UserRole.student; // Default fallback
    }
    _currentRole = _primaryRole;
  }

  /// Set role by role name
  void _setRoleByName(String roleName) {
    switch (roleName) {
      case 'admin':
      case 'administrator':
        _primaryRole = UserRole.admin;
        break;
      case 'ict_coordinator':
        // Align ict_coordinator to admin dashboard
        _primaryRole = UserRole.admin;
        break;
      case 'teacher':
        _primaryRole = UserRole.teacher;
        break;
      case 'student':
        _primaryRole = UserRole.student;
        break;
      case 'parent':
      case 'guardian':
        _primaryRole = UserRole.parent;
        break;
      case 'coordinator':
      case 'grade_coordinator':
        _primaryRole = UserRole.gradeCoordinator;
        break;
      default:
        _primaryRole = UserRole.student;
    }
    _currentRole = _primaryRole;
  }

  /// Enable hybrid mode for users with dual roles
  void _enableHybridMode(String primaryRoleName) {
    _isHybridUser = true;

    // Set secondary role based on primary
    if (primaryRoleName == 'admin') {
      _secondaryRole = UserRole.teacher;
    } else if (primaryRoleName == 'teacher') {
      _secondaryRole = UserRole.admin;
    }

    _primaryRole = UserRole.hybrid;
    // Align with requirement: hybrid users land on Teacher dashboard by default
    _currentRole = UserRole.teacher;
  }

  /// Switch between roles for hybrid users
  void switchRole() {
    if (!_isHybridUser) return;

    if (_currentRole == UserRole.admin) {
      _currentRole = UserRole.teacher;
    } else {
      _currentRole = UserRole.admin;
    }

    notifyListeners();
  }

  /// Get display name for current role
  String getRoleDisplayName() {
    switch (_currentRole) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.gradeCoordinator:
        return 'Grade Level Coordinator';
      case UserRole.hybrid:
        return 'Admin/Teacher';
      default:
        return 'User';
    }
  }

  /// Check if user has admin privileges
  bool get hasAdminPrivileges {
    return _currentRole == UserRole.admin ||
        _primaryRole == UserRole.admin ||
        _primaryRole == UserRole.hybrid;
  }

  /// Check if user has teacher privileges
  bool get hasTeacherPrivileges {
    return _currentRole == UserRole.teacher ||
        _currentRole == UserRole.gradeCoordinator ||
        _primaryRole == UserRole.hybrid;
  }

  /// Check if user is a grade coordinator
  bool get isGradeCoordinator {
    return _currentRole == UserRole.gradeCoordinator ||
        _primaryRole == UserRole.gradeCoordinator;
  }

  /// Clear all role data
  void _clearRoles() {
    _currentRole = null;
    _primaryRole = null;
    _secondaryRole = null;
    _isHybridUser = false;
    _userProfile = null;
  }

  /// Mock role detection for development
  void _useMockRoleDetection() {
    // Check email pattern for role detection (development only)
    final email = _supabase.auth.currentUser?.email ?? '';

    if (email.contains('admin')) {
      _primaryRole = UserRole.admin;
      // Check if hybrid admin
      if (email.contains('hybrid') || email.contains('teacher')) {
        _enableHybridMode('admin');
      }
    } else if (email.contains('teacher')) {
      _primaryRole = UserRole.teacher;
      if (email.contains('coordinator')) {
        _primaryRole = UserRole.gradeCoordinator;
      }
    } else if (email.contains('student')) {
      _primaryRole = UserRole.student;
    } else if (email.contains('parent')) {
      _primaryRole = UserRole.parent;
    } else {
      // Default based on email patterns
      if (email.endsWith('@admin.oshs.edu.ph')) {
        _primaryRole = UserRole.admin;
      } else if (email.endsWith('@teacher.oshs.edu.ph')) {
        _primaryRole = UserRole.teacher;
      } else if (email.endsWith('@student.oshs.edu.ph')) {
        _primaryRole = UserRole.student;
      } else if (email.endsWith('@parent.oshs.edu.ph')) {
        _primaryRole = UserRole.parent;
      } else {
        _primaryRole = UserRole.student; // Default
      }
    }

    _currentRole = _primaryRole;
  }

  /// Force set role (for testing)
  @visibleForTesting
  void setRoleForTesting(UserRole role, {bool isHybrid = false}) {
    _primaryRole = role;
    _currentRole = role;
    _isHybridUser = isHybrid;
    if (isHybrid) {
      _secondaryRole = role == UserRole.admin
          ? UserRole.teacher
          : UserRole.admin;
    }
    notifyListeners();
  }

  /// Refresh user role
  Future<void> refreshUserRole() async {
    await initializeUserRole();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Extension for easy role checking
extension UserRoleExtension on UserRole {
  bool get isAdmin => this == UserRole.admin;
  bool get isTeacher =>
      this == UserRole.teacher || this == UserRole.gradeCoordinator;
  bool get isStudent => this == UserRole.student;
  bool get isParent => this == UserRole.parent;
  bool get isHybrid => this == UserRole.hybrid;
  bool get isCoordinator => this == UserRole.gradeCoordinator;
}
