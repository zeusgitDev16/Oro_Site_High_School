import 'package:supabase_flutter/supabase_flutter.dart';
import 'azure_user_service.dart';
import 'profile_service.dart';
import '../models/profile.dart';

/// Integrated service that creates users in both Azure AD and Supabase
class IntegratedUserService {
  final _azureService = AzureUserService();
  final _profileService = ProfileService();
  final _supabase = Supabase.instance.client;

  // ============================================
  // INTEGRATED USER CREATION
  // ============================================

  /// Create user in both Azure AD and Supabase
  /// This is the main method to use for creating users in the system
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required int roleId,
    // Student-specific
    String? lrn,
    int? gradeLevel,
    String? section,
    String? phone,
    String? address,
    String? gender,
    DateTime? birthDate,
    // Parent/Guardian info
    String? parentEmail,
    String? guardianName,
    String? parentRelationship,
    // Teacher-specific
    String? employeeId,
    String? department,
    List<String>? subjects,
    bool? isGradeCoordinator,
    String? coordinatorGradeLevel,
    // SHS Teacher-specific
    bool? isSHSTeacher,
    String? shsTrack,
    List<String>? shsStrands,
    // Admin-specific
    bool? isHybrid,
    // Options
    bool validateLRN = false,
    bool createInAzure = true,
  }) async {
    String? azureUserId;
    String? supabaseUserId;
    String generatedPassword = '';

    try {
      // Step 1: Generate password
      generatedPassword = _generatePassword(lrn ?? fullName);
      print('🔐 Generated password: $generatedPassword');

      // Step 2: Create user in Azure AD (if enabled)
      if (createInAzure && _azureService.isConfigured()) {
        print('📝 Creating user in Azure AD...');

        // Check if email already exists in Azure
        final existingUser = await _azureService.getUserByEmail(email);
        if (existingUser != null) {
          throw Exception(
              'User with email $email already exists in Azure AD');
        }

        // Parse name for Azure
        final nameParts = fullName.split(' ');
        final givenName = nameParts.first;
        final surname = nameParts.length > 1 ? nameParts.last : '';

        // Determine job title based on role
        String? jobTitle;
        if (roleId == 1) {
          jobTitle = 'Administrator';
        } else if (roleId == 2) {
          jobTitle = 'Teacher';
        } else if (roleId == 3) {
          jobTitle = 'Student';
        } else if (roleId == 4) {
          jobTitle = 'Parent';
        } else if (roleId == 5) {
          jobTitle = 'Grade Coordinator';
        }

        // Create in Azure AD
        final azureUser = await _azureService.createAzureUser(
          email: email,
          displayName: fullName,
          password: generatedPassword,
          givenName: givenName,
          surname: surname,
          jobTitle: jobTitle,
          department: department,
          mobilePhone: phone,
          forceChangePasswordNextSignIn: true,
        );

        azureUserId = azureUser['id'];
        print('✅ Azure AD user created: $azureUserId');
      } else {
        print('⚠️ Skipping Azure AD creation (disabled or not configured)');
      }

      // Step 3: Create user in Supabase
      print('📝 Creating user in Supabase...');

      final profile = await _profileService.createUser(
        email: email,
        fullName: fullName,
        roleId: roleId,
        lrn: lrn,
        gradeLevel: gradeLevel,
        section: section,
        phone: phone,
        address: address,
        gender: gender,
        birthDate: birthDate,
        parentEmail: parentEmail,
        guardianName: guardianName,
        parentRelationship: parentRelationship,
        employeeId: employeeId,
        department: department,
        subjects: subjects,
        isGradeCoordinator: isGradeCoordinator,
        coordinatorGradeLevel: coordinatorGradeLevel,
        isSHSTeacher: isSHSTeacher,
        shsTrack: shsTrack,
        shsStrands: shsStrands,
        isHybrid: isHybrid,
        validateLRN: validateLRN,
      );

      supabaseUserId = profile.id;
      print('✅ Supabase user created: $supabaseUserId');

      // Step 4: Link Azure ID to Supabase profile (if Azure user was created)
      if (azureUserId != null) {
        await _supabase.from('profiles').update({
          'azure_user_id': azureUserId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', supabaseUserId);

        print('✅ Azure ID linked to Supabase profile');
      }

      // Step 5: Log the creation
      await _logUserCreation(
        supabaseUserId: supabaseUserId,
        azureUserId: azureUserId,
        email: email,
        roleId: roleId,
      );

      return {
        'success': true,
        'supabase_user_id': supabaseUserId,
        'azure_user_id': azureUserId,
        'email': email,
        'password': generatedPassword,
        'message': 'User created successfully in both Azure AD and Supabase',
      };
    } catch (e) {
      print('❌ Error creating user: $e');

      // Rollback: Delete Azure user if Supabase creation failed
      if (azureUserId != null && supabaseUserId == null) {
        try {
          print('🔄 Rolling back: Deleting Azure AD user...');
          await _azureService.deleteAzureUser(azureUserId);
          print('✅ Azure AD user deleted (rollback)');
        } catch (rollbackError) {
          print('⚠️ Failed to rollback Azure user: $rollbackError');
        }
      }

      rethrow;
    }
  }

  // ============================================
  // USER UPDATES
  // ============================================

  /// Update user in both Azure AD and Supabase
  Future<void> updateUser({
    required String supabaseUserId,
    String? azureUserId,
    String? fullName,
    String? phone,
    String? department,
    String? jobTitle,
  }) async {
    try {
      // Update in Supabase
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _profileService.updateProfile(supabaseUserId, updates);
        print('✅ Supabase profile updated');
      }

      // Update in Azure AD (if Azure ID exists)
      if (azureUserId != null && _azureService.isConfigured()) {
        final nameParts = fullName?.split(' ');
        await _azureService.updateAzureUser(
          userId: azureUserId,
          displayName: fullName,
          givenName: nameParts?.first,
          surname: nameParts != null && nameParts.length > 1
              ? nameParts.last
              : null,
          mobilePhone: phone,
          department: department,
          jobTitle: jobTitle,
        );
        print('✅ Azure AD user updated');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // ============================================
  // USER DEACTIVATION
  // ============================================

  /// Deactivate user in both systems
  Future<void> deactivateUser({
    required String supabaseUserId,
    String? azureUserId,
  }) async {
    try {
      // Deactivate in Supabase
      await _profileService.deactivateUser(supabaseUserId);
      print('✅ Supabase user deactivated');

      // Disable in Azure AD
      if (azureUserId != null && _azureService.isConfigured()) {
        await _azureService.disableUser(azureUserId);
        print('✅ Azure AD user disabled');
      }
    } catch (e) {
      print('Error deactivating user: $e');
      rethrow;
    }
  }

  /// Activate user in both systems
  Future<void> activateUser({
    required String supabaseUserId,
    String? azureUserId,
  }) async {
    try {
      // Activate in Supabase
      await _profileService.activateUser(supabaseUserId);
      print('✅ Supabase user activated');

      // Enable in Azure AD
      if (azureUserId != null && _azureService.isConfigured()) {
        await _azureService.enableUser(azureUserId);
        print('✅ Azure AD user enabled');
      }
    } catch (e) {
      print('Error activating user: $e');
      rethrow;
    }
  }

  // ============================================
  // PASSWORD RESET
  // ============================================

  /// Reset user password in both systems
  Future<String> resetUserPassword({
    required String supabaseUserId,
    String? azureUserId,
    String? newPassword,
  }) async {
    try {
      // Generate new password if not provided
      final password = newPassword ?? _generatePassword(supabaseUserId);

      // Reset in Supabase
      await _profileService.resetUserPassword(supabaseUserId, password);
      print('✅ Supabase password reset');

      // Reset in Azure AD
      if (azureUserId != null && _azureService.isConfigured()) {
        await _azureService.resetUserPassword(
          userId: azureUserId,
          newPassword: password,
          forceChangePasswordNextSignIn: true,
        );
        print('✅ Azure AD password reset');
      }

      return password;
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Generate secure password
  String _generatePassword(String identifier) {
    final year = DateTime.now().year;
    final cleanIdentifier = identifier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '$cleanIdentifier@$year';
  }

  /// Log user creation activity
  Future<void> _logUserCreation({
    required String supabaseUserId,
    String? azureUserId,
    required String email,
    required int roleId,
  }) async {
    try {
      await _supabase.from('activity_log').insert({
        'user_id': supabaseUserId,
        'action': 'USER_CREATED_INTEGRATED',
        'details': {
          'email': email,
          'role_id': roleId,
          'azure_user_id': azureUserId,
          'created_in_azure': azureUserId != null,
          'created_by': _supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Warning: Could not log user creation: $e');
    }
  }

  /// Check if Azure integration is enabled
  bool isAzureEnabled() {
    return _azureService.isConfigured();
  }

  /// Get Azure user service (for direct access if needed)
  AzureUserService get azureService => _azureService;

  /// Get profile service (for direct access if needed)
  ProfileService get profileService => _profileService;
}
