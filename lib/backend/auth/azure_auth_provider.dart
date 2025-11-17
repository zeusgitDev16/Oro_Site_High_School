// Azure AD Authentication Provider
// Handles Azure Active Directory authentication with Supabase
//
// Configured users:
// - admin@aezycreativegmail.onmicrosoft.com (Admin)
// - ICT_Coordinator@aezycreativegmail.onmicrosoft.com (ICT Coordinator)
// - Teacher@aezycreativegmail.onmicrosoft.com (Teacher)
// - student@aezycreativegmail.onmicrosoft.com (Student)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/environment.dart';

class AzureAuthProvider {
  // Singleton pattern
  static final AzureAuthProvider _instance = AzureAuthProvider._internal();
  factory AzureAuthProvider() => _instance;
  AzureAuthProvider._internal();

  final _client = SupabaseConfig.client;

  /// Azure AD user role mapping
  static const Map<String, String> _azureUserRoles = {
    'admin@aezycreativegmail.onmicrosoft.com': 'admin',
    'ict_coordinator@aezycreativegmail.onmicrosoft.com': 'coordinator',
    'teacher@aezycreativegmail.onmicrosoft.com': 'teacher',
    'student@aezycreativegmail.onmicrosoft.com': 'student',
  };

  /// Sign in with Azure AD
  Future<AuthResponse?> signInWithAzure() async {
    try {
      print('[AUTH] Initiating Azure AD sign in...');

      if (!Environment.enableAzureAuth) {
        throw Exception('Azure AD authentication is disabled');
      }

      // Note: signInWithOAuth returns a bool, not AuthResponse
      // The actual session will be available through auth state change listener
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.azure,
        scopes:
            'openid profile email offline_access https://graph.microsoft.com/User.Read',
        redirectTo: Environment.azureRedirectUri,
        queryParams: {
          'tenant': Environment.azureTenantId,
          'prompt': 'select_account', // Force account selection
        },
      );

      if (success) {
        print('[INFO] Azure AD sign in initiated');

        // Wait for auth state change to get the session
        // The session will be handled by the auth state listener
        // Return a placeholder response
        return AuthResponse(session: null);
      }

      return null;
    } catch (e) {
      print('[ERROR] Azure AD sign in failed: $e');
      rethrow;
    }
  }

  /// Sign in with email/password (fallback for development)
  Future<AuthResponse?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('[AUTH] Signing in with email/password...');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        print('[INFO] Sign in successful');

        // Create or update user profile
        await _createOrUpdateProfile(response.session!);

        return response;
      }

      return null;
    } catch (e) {
      print('[ERROR] Sign in failed: $e');
      rethrow;
    }
  }

  /// Create or update user profile after authentication
  Future<void> _createOrUpdateProfile(Session session) async {
    try {
      final user = session.user;
      final email = user.email?.toLowerCase();

      if (email == null) {
        throw Exception('User email is null');
      }

      // Determine role based on email
      final role = _determineRole(email);

      // Get role ID from database
      final roleId = await _getRoleId(role);

      // Check if profile exists
      final existingProfile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await _client.from('profiles').insert({
          'id': user.id,
          'email': email,
          'full_name':
              user.userMetadata?['full_name'] ?? _extractNameFromEmail(email),
          'avatar_url': user.userMetadata?['avatar_url'],
          'role_id': roleId,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('[INFO] User profile created');

        // Create role-specific record
        await _createRoleSpecificRecord(user.id, email, role);
      } else {
        // Update existing profile
        await _client
            .from('profiles')
            .update({
              'email': email,
              'full_name':
                  user.userMetadata?['full_name'] ??
                  existingProfile['full_name'],
              'avatar_url':
                  user.userMetadata?['avatar_url'] ??
                  existingProfile['avatar_url'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        print('[INFO] User profile updated');
      }
    } catch (e) {
      print('[ERROR] Error creating/updating profile: $e');
      // Don't throw - allow login to continue even if profile update fails
    }
  }

  /// Determine user role based on email
  String _determineRole(String email) {
    // Check Azure AD mapping first
    final azureRole = _azureUserRoles[email];
    if (azureRole != null) {
      return azureRole;
    }

    // Fallback role determination based on email patterns
    if (email.contains('admin')) return 'admin';
    if (email.contains('coordinator') || email.contains('ict'))
      return 'coordinator';
    if (email.contains('teacher')) return 'teacher';
    if (email.contains('parent')) return 'parent';
    if (email.contains('student')) return 'student';

    // Default to student role
    return 'student';
  }

  /// Get role ID from database
  Future<int> _getRoleId(String roleName) async {
    try {
      final response = await _client
          .from('roles')
          .select('id')
          .eq('name', roleName)
          .single();

      return response['id'];
    } catch (e) {
      print('[WARN] Role not found: $roleName, using default');

      // Create role if it doesn't exist
      final newRole = await _client
          .from('roles')
          .insert({'name': roleName})
          .select('id')
          .single();

      return newRole['id'];
    }
  }

  /// Create role-specific record (student, teacher, etc.)
  Future<void> _createRoleSpecificRecord(
    String userId,
    String email,
    String role,
  ) async {
    try {
      switch (role) {
        case 'student':
          // Check if student record exists
          final existingStudent = await _client
              .from('students')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (existingStudent == null) {
            await _client.from('students').insert({
              'id': userId,
              'lrn': _generateLRN(),
              'grade_level': 7, // Default grade level
              'section': '7-A', // Default section
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            });
            print('[INFO] Student record created');
          }
          break;

        case 'teacher':
        case 'coordinator':
          // Teachers and coordinators don't need additional records
          // Their assignments are handled separately
          break;

        case 'parent':
          // Parent-student relationships are created separately
          break;

        case 'admin':
          // Admins don't need additional records
          break;
      }
    } catch (e) {
      print('[WARN] Error creating role-specific record: $e');
    }
  }

  /// Generate a unique LRN for students
  String _generateLRN() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '1${timestamp.toString().substring(3, 13)}'; // 11-digit LRN starting with 1
  }

  /// Extract name from email
  String _extractNameFromEmail(String email) {
    final parts = email.split('@')[0].split('.');
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join(' ');
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

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

  /// Check if user has specific role
  Future<bool> hasRole(String roleName) async {
    final currentRole = await getCurrentUserRole();
    return currentRole == roleName;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async => await hasRole('admin');

  /// Check if user is teacher
  Future<bool> isTeacher() async => await hasRole('teacher');

  /// Check if user is student
  Future<bool> isStudent() async => await hasRole('student');

  /// Check if user is parent
  Future<bool> isParent() async => await hasRole('parent');

  /// Check if user is coordinator
  Future<bool> isCoordinator() async => await hasRole('coordinator');

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('[INFO] User signed out successfully');
    } catch (e) {
      print('[ERROR] Error signing out: $e');
      rethrow;
    }
  }

  /// Get authentication status
  Map<String, dynamic> getAuthStatus() {
    final user = _client.auth.currentUser;
    return {
      'isAuthenticated': user != null,
      'userId': user?.id,
      'email': user?.email,
      'provider': user?.appMetadata['provider'],
      'lastSignIn': user?.lastSignInAt,
    };
  }

  /// Reset password for a user (coordinator feature)
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: '${Environment.azureRedirectUri}reset-password',
      );
      print('[INFO] Password reset email sent to $email');
    } catch (e) {
      print('[ERROR] Error sending password reset: $e');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      print('[INFO] Password updated successfully');
    } catch (e) {
      print('[ERROR] Error updating password: $e');
      rethrow;
    }
  }
}
