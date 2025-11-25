import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/backend/config/supabase_config.dart';
import 'package:oro_site_high_school/backend/config/environment.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Cache for user role
  String? _currentUserRole;

  // Singleton pattern for consistent state
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  // Flag to identify that the current OAuth login was initiated from the
  // parent Google login entrypoint. This is used by _createOrUpdateProfile
  // to force roleName = 'parent' for first-time profiles from this flow.
  bool _pendingParentGoogleLogin = false;

  Future<bool> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // Close loading indicator
      Navigator.of(context).pop();

      if (response.session != null) {
        // Create or update user profile
        await _createOrUpdateProfile(response.session!);

        // Get and cache user role
        _currentUserRole = await getUserRole();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        return true;
      }

      return false;
    } on AuthException catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Azure AD Sign In
  Future<bool> signInWithAzure(
    BuildContext context, {
    bool requireAdmin = false,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('[AUTH] Starting Azure AD authentication...');
      print('[AUTH] Tenant ID: ${Environment.azureTenantId}');
      print('[AUTH] Client ID: ${Environment.azureClientId}');
      print('[AUTH] Require Admin: $requireAdmin');
      print('═══════════════════════════════════════════════════════════');

      // Dynamically get the current URL - works with ANY port
      final currentUrl = Uri.base.toString();
      String appRedirectUrl;

      // Parse the current URL to get the exact host and port
      final uri = Uri.parse(currentUrl);

      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        // For local development, dynamically use whatever port Flutter assigned
        // This works with ANY port number
        appRedirectUrl = '${uri.scheme}://${uri.host}:${uri.port}/';
        print('[AUTH] Dynamic redirect URL: $appRedirectUrl');
        print('[AUTH] Running on port: ${uri.port}');
      } else {
        // For production deployment
        appRedirectUrl = '${uri.scheme}://${uri.host}/';
        if (uri.port != 80 && uri.port != 443 && uri.port != 0) {
          appRedirectUrl = '${uri.scheme}://${uri.host}:${uri.port}/';
        }
      }

      // Clean up the URL - remove hash and query parameters
      appRedirectUrl = appRedirectUrl.split('#').first.split('?').first;

      // Store the requireAdmin flag for later verification
      if (requireAdmin) {
        _pendingAdminCheck = true;
      }

      // Use Supabase's OAuth with Azure provider
      // The redirectTo will dynamically match whatever port Flutter is using
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.azure,
        scopes:
            'openid profile email offline_access https://graph.microsoft.com/User.Read',
        redirectTo: appRedirectUrl, // Dynamically determined redirect URL
        queryParams: {
          'prompt': 'select_account', // Force account selection
        },
      );

      print('[AUTH] OAuth initiated: $response');
      print('[AUTH] Supabase will redirect back to: $appRedirectUrl');

      if (response) {
        // OAuth flow started successfully
        return true;
      }

      return false;
    } catch (e) {
      print('[ERROR] Azure sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Azure sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Google OAuth sign in flow dedicated for parent accounts
  Future<bool> signInWithGoogleForParent(BuildContext context) async {
    try {
      print('[AUTH] Starting Google OAuth authentication for parent...');

      // Dynamically get the current URL - works with ANY port
      final currentUrl = Uri.base.toString();
      String appRedirectUrl;

      // Parse the current URL to get the exact host and port
      final uri = Uri.parse(currentUrl);

      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        // For local development, dynamically use whatever port Flutter assigned
        // This works with ANY port number
        appRedirectUrl = '${uri.scheme}://${uri.host}:${uri.port}/';
        print('[AUTH] (Google Parent) Dynamic redirect URL: $appRedirectUrl');
        print('[AUTH] (Google Parent) Running on port: ${uri.port}');
      } else {
        // For production deployment
        appRedirectUrl = '${uri.scheme}://${uri.host}/';
        if (uri.port != 80 && uri.port != 443 && uri.port != 0) {
          appRedirectUrl = '${uri.scheme}://${uri.host}:${uri.port}/';
        }
      }

      // Clean up the URL - remove hash and query parameters
      appRedirectUrl = appRedirectUrl.split('#').first.split('?').first;

      // Mark that the next OAuth login should create a parent profile
      _pendingParentGoogleLogin = true;

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: appRedirectUrl,
        scopes: 'openid profile email',
      );

      print('[AUTH] Google OAuth (parent) initiated: $response');
      print('[AUTH] Supabase will redirect back to: $appRedirectUrl');

      if (response) {
        // OAuth flow started successfully
        return true;
      }

      // If OAuth did not start, clear the flag so other logins are unaffected
      _pendingParentGoogleLogin = false;
      return false;
    } catch (e) {
      print('[ERROR] Google (parent) sign in error: $e');
      // Clear the flag on error to avoid affecting future logins
      _pendingParentGoogleLogin = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parent Google sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Flag to track if we need to verify admin role after OAuth
  bool _pendingAdminCheck = false;

  // Check admin role after OAuth callback
  Future<bool> verifyAdminRole(BuildContext context) async {
    try {
      final role = await getUserRole();
      _currentUserRole = role;

      if (role != 'admin') {
        await signOut();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error verifying admin role: $e');
      return false;
    }
  }

  // Quick login for development/testing
  Future<bool> quickLogin({
    required BuildContext context,
    required String userType,
  }) async {
    // Test credentials for each user type
    final credentials = {
      'admin': {'email': 'admin@orosite.edu.ph', 'password': 'Admin123!'},
      'teacher': {'email': 'teacher@orosite.edu.ph', 'password': 'Teacher123!'},
      'student': {'email': 'student@orosite.edu.ph', 'password': 'Student123!'},
      'parent': {'email': 'parent@orosite.edu.ph', 'password': 'Parent123!'},
    };

    final creds = credentials[userType.toLowerCase()];
    if (creds == null) return false;

    // If mock mode is enabled, skip actual authentication
    if (Environment.useMockData) {
      _currentUserRole = userType.toLowerCase();
      return true;
    }

    // Otherwise, do real authentication
    return await signIn(
      context: context,
      email: creds['email']!,
      password: creds['password']!,
    );
  }

  String _getErrorMessage(AuthException e) {
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password. Please try again.';
      case 'email not confirmed':
        return 'Please verify your email address first.';
      case 'user not found':
        return 'No account found with this email.';
      default:
        return e.message;
    }
  }

  Future<void> signUp({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current user's role
  Future<String?> getUserRole() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      // Detect auth provider (e.g., 'google', 'azure', 'email')
      final authProvider = user.appMetadata['provider'] as String?;
      final bool isGoogleProvider = authProvider == 'google';

      // Query from database
      final response = await _supabase
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['roles'] != null) {
        var role = response['roles']['name'] as String;

        // For Google OAuth, always treat the user as a parent in routing,
        // regardless of what's currently stored in the roles table.
        if (isGoogleProvider) {
          role = 'parent';
        }

        _currentUserRole = role;
        return role;
      }

      // If no profile/role row yet but this is a Google OAuth session,
      // still treat the user as a parent for routing.
      if (isGoogleProvider) {
        _currentUserRole = 'parent';
        return 'parent';
      }

      // Fallback: determine role from email (non-Google flows only)
      final email = user.email?.toLowerCase();
      if (email != null) {
        if (email.contains('admin')) return 'admin';
        if (email.contains('coordinator')) return 'grade_coordinator';
        if (email.contains('teacher')) return 'teacher';
        if (email.contains('parent')) return 'parent';
        if (email.contains('student')) return 'student';
      }

      return 'student'; // Default role
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => getCurrentUser() != null;

  // Get auth state changes stream
  Stream<AuthState> get authStateChanges {
    // Add debugging for auth state changes
    return _supabase.auth.onAuthStateChange.map((authState) {
      print('🔐 Auth state changed: ${authState.event}');

      if (authState.session != null) {
        final user = authState.session!.user;
        print('📧 User ID: ${user.id}');
        print('📧 User Email: ${user.email ?? "NO EMAIL"}');
        print('📧 User Metadata: ${user.userMetadata}');
        print('📧 App Metadata: ${user.appMetadata}');
        print(
          '📧 Identity Data: ${user.identities?.map((i) => {'provider': i.provider, 'identity_data': i.identityData}).toList()}',
        );
      } else {
        print('🔐 No session in auth state');
      }

      return authState;
    });
  }

  // Public method to ensure profile exists (called from auth_gate)
  Future<void> ensureProfileExists(Session session) async {
    await _createOrUpdateProfile(session);
  }

  // Create or update user profile after authentication
  Future<void> _createOrUpdateProfile(Session session) async {
    try {
      final user = session.user;

      print('═══════════════════════════════════════════════════════════');
      print('🔍 DEBUG: Creating/updating profile');
      print('═══════════════════════════════════════════════════════════');
      print('🔍 User ID: ${user.id}');
      print('🔍 User Email: ${user.email ?? "❌ NULL"}');
      print('🔍 User Phone: ${user.phone ?? "NULL"}');
      print('🔍 User Created At: ${user.createdAt}');
      print(
        '🔍 Session Access Token: ${session.accessToken.substring(0, 50)}...',
      );
      print('═══════════════════════════════════════════════════════════');
      print('🔍 User Metadata:');
      print('   ${user.userMetadata}');
      print('═══════════════════════════════════════════════════════════');
      print('🔍 User App Metadata:');
      print('   ${user.appMetadata}');
      print('═══════════════════════════════════════════════════════════');
      print('🔍 User Identities:');
      if (user.identities != null && user.identities!.isNotEmpty) {
        for (var i = 0; i < user.identities!.length; i++) {
          final identity = user.identities![i];
          print('   Identity #$i:');
          print('     Provider: ${identity.provider}');
          print('     ID: ${identity.id}');
          print('     Created At: ${identity.createdAt}');
          print('     Updated At: ${identity.updatedAt}');
          print('     Identity Data:');
          if (identity.identityData != null) {
            identity.identityData!.forEach((key, value) {
              print('       $key: $value');
            });
          } else {
            print('       ❌ NULL');
          }
        }
      } else {
        print('   ❌ NULL or EMPTY');
      }
      print('═══════════════════════════════════════════════════════════');

      // Detect auth provider (e.g., 'google', 'azure', 'email')
      final authProvider = user.appMetadata['provider'] as String?;
      final bool isGoogleProvider = authProvider == 'google';

      // Extract potential Azure Employee ID (candidate LRN for students)
      final String? azureEmployeeLrn = _extractAzureEmployeeId(user);

      // Try to get email from multiple sources
      String? email = user.email?.toLowerCase();

      // If email is null, try to extract from identity data
      if (email == null || email.isEmpty) {
        print('⚠️ Email is null, trying to extract from identity data...');

        if (user.identities != null && user.identities!.isNotEmpty) {
          for (var identity in user.identities!) {
            print('🔍 Checking identity provider: ${identity.provider}');
            print('🔍 Identity data: ${identity.identityData}');

            // Try different possible email fields
            final identityData = identity.identityData;
            if (identityData != null) {
              email =
                  identityData['email'] as String? ??
                  identityData['mail'] as String? ??
                  identityData['preferred_username'] as String? ??
                  identityData['upn'] as String?;

              if (email != null && email.isNotEmpty) {
                print('✅ Found email in identity data: $email');
                break;
              }
            }
          }
        }

        // Try user metadata
        if (email == null || email.isEmpty) {
          print('⚠️ Still no email, checking user metadata...');
          email =
              user.userMetadata?['email'] as String? ??
              user.userMetadata?['mail'] as String? ??
              user.userMetadata?['preferred_username'] as String?;

          if (email != null && email.isNotEmpty) {
            print('✅ Found email in user metadata: $email');
          }
        }
      }

      if (email == null || email.isEmpty) {
        print('❌ ERROR: Could not extract email from any source');
        print('❌ This will cause profile creation to fail');
        print('❌ User object: ${user.toJson()}');
        return;
      }

      email = email.toLowerCase();
      print('✅ Using email: $email');

      // Check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Determine role from provider/App Roles first, then fallback to email.
        // For parent Google login flow, we always treat the user as a parent.
        final bool isParentGoogleFlow =
            _pendingParentGoogleLogin || isGoogleProvider;

        // One-shot flag: clear it so future logins are not affected
        _pendingParentGoogleLogin = false;

        String? roleName;
        if (isParentGoogleFlow) {
          roleName = 'parent';
        }

        // Try extract roles from Azure token (only for non-parent Google flows)
        try {
          if (!isParentGoogleFlow) {
            final identities = user.identities;
            final identityData = identities != null && identities.isNotEmpty
                ? identities.first.identityData
                : null;
            final List<dynamic>? azureRoles =
                (identityData?['roles'] as List?) ??
                (identityData?['custom_claims']?['roles'] as List?);
            if (azureRoles != null && azureRoles.isNotEmpty) {
              final rolesLower = azureRoles
                  .map((e) => e.toString().toLowerCase())
                  .toList();
              if (rolesLower.contains('admin'))
                roleName = 'admin';
              else if (rolesLower.contains('grade_coordinator'))
                roleName = 'grade_coordinator';
              else if (rolesLower.contains('teacher'))
                roleName = 'teacher';
              else if (rolesLower.contains('student'))
                roleName = 'student';
              else if (rolesLower.contains('parent'))
                roleName = 'parent';
              else if (rolesLower.contains('ict_coordinator'))
                roleName = 'ict_coordinator';
            }
          }
        } catch (_) {}

        if (!isParentGoogleFlow) {
          // Fallback: determine role based on email for non-Google flows
          roleName ??= 'student'; // Default
          if (email.contains('admin'))
            roleName = 'admin';
          else if (email.contains('coordinator'))
            roleName = 'grade_coordinator';
          else if (email.contains('teacher'))
            roleName = 'teacher';
          else if (email.contains('parent'))
            roleName = 'parent';
          else if (email.contains('student'))
            roleName = 'student';
        } else {
          // Defensive: for parent Google flow, ensure we end up with 'parent'
          roleName ??= 'parent';
        }

        // Get or create role
        var roleResponse = await _supabase
            .from('roles')
            .select('id')
            .eq('name', roleName)
            .maybeSingle();

        int? roleId;
        if (roleResponse == null) {
          // Fallback to 'student' if configured role not found
          roleResponse = await _supabase
              .from('roles')
              .select('id')
              .eq('name', 'student')
              .maybeSingle();
        }
        roleId = roleResponse?['id'];

        // Create profile
        print('🔧 Attempting to insert profile...');
        print('🔧 Profile data: id=${user.id}, email=$email, role_id=$roleId');

        try {
          await _supabase.from('profiles').insert({
            'id': user.id,
            'email': email,
            'full_name':
                user.userMetadata?['full_name'] ?? _extractNameFromEmail(email),
            'avatar_url': user.userMetadata?['avatar_url'],
            'role_id': roleId,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('✅ Profile created successfully!');

          // Create role-specific records
          await _createRoleSpecificRecord(
            userId: user.id,
            email: email,
            fullName:
                user.userMetadata?['full_name'] ?? _extractNameFromEmail(email),
            roleId: roleId!,
            roleName: roleName,
            azureEmployeeLrn: azureEmployeeLrn,
          );
        } catch (insertError) {
          print('❌ ERROR inserting profile: $insertError');
          print('❌ Error type: ${insertError.runtimeType}');
          if (insertError is PostgrestException) {
            print('❌ Postgrest error code: ${insertError.code}');
            print('❌ Postgrest error message: ${insertError.message}');
            print('❌ Postgrest error details: ${insertError.details}');
            print('❌ Postgrest error hint: ${insertError.hint}');
          }
          rethrow;
        }
      } else {
        // Update existing profile
        await _supabase
            .from('profiles')
            .update({
              'email': email,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        // Try to update role from Azure App Roles if present
        try {
          final identities = user.identities;
          final identityData = identities != null && identities.isNotEmpty
              ? identities.first.identityData
              : null;
          final List<dynamic>? azureRoles =
              (identityData?['roles'] as List?) ??
              (identityData?['custom_claims']?['roles'] as List?);
          String? azureRoleName;
          if (azureRoles != null && azureRoles.isNotEmpty) {
            final rolesLower = azureRoles
                .map((e) => e.toString().toLowerCase())
                .toList();
            if (rolesLower.contains('admin'))
              azureRoleName = 'admin';
            else if (rolesLower.contains('grade_coordinator'))
              azureRoleName = 'grade_coordinator';
            else if (rolesLower.contains('teacher'))
              azureRoleName = 'teacher';
            else if (rolesLower.contains('student'))
              azureRoleName = 'student';
            else if (rolesLower.contains('parent'))
              azureRoleName = 'parent';
            else if (rolesLower.contains('ict_coordinator'))
              azureRoleName = 'ict_coordinator';
          }
          if (azureRoleName != null) {
            final r = await _supabase
                .from('roles')
                .select('id')
                .eq('name', azureRoleName)
                .maybeSingle();
            final int? newRoleId = r?['id'] as int?;
            if (newRoleId != null) {
              await _supabase
                  .from('profiles')
                  .update({
                    'role_id': newRoleId,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', user.id);
              // If role is grade coordinator, also flag teacher record
              if (azureRoleName == 'grade_coordinator') {
                try {
                  final teacher = await _supabase
                      .from('teachers')
                      .select('id')
                      .eq('id', user.id)
                      .maybeSingle();
                  if (teacher == null) {
                    await _createTeacherRecord(
                      user.id,
                      email,
                      (user.userMetadata?['full_name'] ??
                          _extractNameFromEmail(email)),
                    );
                  }
                  await _supabase
                      .from('teachers')
                      .update({'is_grade_coordinator': true})
                      .eq('id', user.id);
                } catch (e) {
                  print('⚠️ Warning: could not set GLC flag for teacher: $e');
                }
              }
            }
          }
        } catch (_) {}

        // Ensure role-specific record exists (based on current role)
        final roleId =
            (await _supabase
                    .from('profiles')
                    .select('role_id')
                    .eq('id', user.id)
                    .maybeSingle())?['role_id']
                as int?;

        if (roleId != null) {
          final roleResponse = await _supabase
              .from('roles')
              .select('name')
              .eq('id', roleId)
              .maybeSingle();

          if (roleResponse != null) {
            final roleName = roleResponse['name'] as String;
            await _ensureRoleSpecificRecordExists(
              userId: user.id,
              email: email,
              fullName:
                  existingProfile['full_name'] as String? ??
                  _extractNameFromEmail(email),
              roleId: roleId,
              roleName: roleName,
            );

            // Step 4: safely sync student LRN with Azure Employee ID for existing profiles
            if (roleName == 'student' &&
                azureEmployeeLrn != null &&
                RegExp(r'^\d{12} ?$').hasMatch(azureEmployeeLrn)) {
              await _syncStudentLrnWithAzureEmployeeId(
                userId: user.id,
                azureEmployeeLrn: azureEmployeeLrn,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error creating/updating profile: $e');
      // Don't throw - allow login to continue
    }
  }

  String _extractNameFromEmail(String email) {
    final parts = email.split('@')[0].split('.');
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join(' ');
  }

  /// Extract 12-digit Azure Employee ID (to be used as LRN for students)
  ///
  /// This is a safe, nullable helper:
  /// - Only attempts extraction when provider is 'azure'.
  /// - Returns a 12-digit numeric string if found, otherwise null.
  /// - Never throws; logs diagnostics for visibility.
  String? _extractAzureEmployeeId(User user) {
    try {
      final provider = user.appMetadata['provider'] as String?;
      if (provider != 'azure') {
        return null;
      }

      // Prefer identity data coming from Azure
      final identities = user.identities;
      final dynamic rawIdentityData =
          identities != null && identities.isNotEmpty
          ? identities.first.identityData
          : null;

      final Map<String, dynamic>? identityData =
          rawIdentityData is Map<String, dynamic> ? rawIdentityData : null;

      final candidates = <String?>[];

      if (identityData != null) {
        // Common/likely keys
        candidates.add(identityData['employeeId']?.toString());
        candidates.add(identityData['employee_id']?.toString());

        // Also scan keys case-insensitively in case Azure mapping uses a variant
        identityData.forEach((key, value) {
          final lowerKey = key.toString().toLowerCase();
          if (lowerKey == 'employeeid' || lowerKey == 'employee_id') {
            candidates.add(value?.toString());
          }
        });

        // Sometimes custom claims may hold extended attributes
        final customClaims = identityData['custom_claims'];
        if (customClaims is Map) {
          candidates.add(customClaims['employeeId']?.toString());
          candidates.add(customClaims['employee_id']?.toString());
        }
      }

      // Fallback: user metadata
      final Map<String, dynamic>? meta = user.userMetadata;
      if (meta != null) {
        candidates.add(meta['employeeId']?.toString());
        candidates.add(meta['employee_id']?.toString());
      }

      for (final raw in candidates) {
        if (raw == null) continue;
        final value = raw.trim();
        // DepEd LRN is exactly 12 digits
        if (RegExp(r'^\d{12} ?$').hasMatch(value)) {
          print('🔎 Azure Employee ID accepted as LRN candidate: $value');
          return value.substring(0, 12); // Ensure exactly 12 digits
        }
      }

      print('ℹ️ No valid 12-digit Azure Employee ID found for user ${user.id}');
      return null;
    } catch (e) {
      print('⚠️ Failed to extract Azure Employee ID: $e');
      return null;
    }
  }

  /// Step 4 helper: safely sync existing student's LRN with Azure Employee ID
  ///
  /// Rules (idempotent and non-destructive):
  /// - Only runs when we already know this user is a student.
  /// - If no student row exists: do nothing (creation is handled elsewhere).
  /// - If `lrn` is NULL/empty or looks like a placeholder (non-12-digit),
  ///   it is updated to the 12-digit Azure Employee ID.
  /// - If `lrn` is already a 12-digit value:
  ///     - If equal to Azure Employee ID: no-op.
  ///     - If different: log a warning, do NOT overwrite.
  Future<void> _syncStudentLrnWithAzureEmployeeId({
    required String userId,
    required String azureEmployeeLrn,
  }) async {
    try {
      // Fetch current LRN for this student (by id/user_id)
      final existing = await _supabase
          .from('students')
          .select('id, lrn, user_id')
          .or('id.eq.$userId,user_id.eq.$userId')
          .maybeSingle();

      if (existing == null) {
        // No student row yet; creation path will handle initial LRN.
        return;
      }

      final String? currentLrn = existing['lrn'] as String?;

      // Normalize and validate Azure LRN again for safety
      final String candidate = azureEmployeeLrn.trim();
      if (!RegExp(r'^\d{12} ?$').hasMatch(candidate)) {
        // Should not happen if caller validated, but stay defensive.
        return;
      }

      if (currentLrn == null || currentLrn.trim().isEmpty) {
        // Simple case: previously empty, now set to official LRN.
        await _supabase
            .from('students')
            .update({'lrn': candidate})
            .eq('id', existing['id']);
        return;
      }

      final String current = currentLrn.trim();

      // If current is already a 12-digit value
      if (RegExp(r'^\d{12} ?$').hasMatch(current)) {
        if (current == candidate) {
          // Already in sync; nothing to do.
          return;
        }
        // Mismatch between stored LRN and Azure Employee ID - do not overwrite.
        print(
          '⚠️ LRN mismatch for student $userId: db=$current, azure=$candidate',
        );
        return;
      }

      // Current looks like a placeholder (e.g., "LRN-..."), upgrade to official LRN.
      await _supabase
          .from('students')
          .update({'lrn': candidate})
          .eq('id', existing['id']);
    } catch (e) {
      print(
        '⚠️ Failed to sync student LRN with Azure Employee ID for $userId: $e',
      );
    }
  }

  /// Create role-specific record (teacher, student, etc.)
  Future<void> _createRoleSpecificRecord({
    required String userId,
    required String email,
    required String fullName,
    required int roleId,
    required String roleName,
    String? azureEmployeeLrn,
  }) async {
    try {
      print(
        '[INFO] Creating role-specific record for: $roleName (role_id: $roleId)',
      );

      if (roleId == 1 || roleName == 'admin') {
        // Create admin record
        await _createAdminRecord(userId, email, fullName);
      } else if (roleId == 2 || roleName == 'teacher') {
        // Create teacher record
        await _createTeacherRecord(userId, email, fullName);
      } else if (roleId == 3 || roleName == 'student') {
        // Create student record
        await _createStudentRecord(
          userId,
          email,
          fullName,
          lrnFromAzure: azureEmployeeLrn,
        );
      } else if (roleId == 4 || roleName == 'parent') {
        // Create parent record
        await _createParentRecord(userId, email, fullName);
      } else if (roleId == 5 || roleName == 'ict_coordinator') {
        // Create ICT coordinator record
        await _createICTCoordinatorRecord(userId, email, fullName);
      } else if (roleId == 6 || roleName == 'grade_coordinator') {
        // Create grade coordinator record
        await _createGradeCoordinatorRecord(userId, email, fullName);
      } else if (roleId == 7 || roleName == 'hybrid') {
        // Create hybrid user record
        await _createHybridUserRecord(userId, email, fullName);
      }
    } catch (e) {
      print('[WARN] Could not create role-specific record: $e');
      // Don't throw - profile creation should succeed even if role record fails
    }
  }

  /// Ensure role-specific record exists (for existing profiles)
  Future<void> _ensureRoleSpecificRecordExists({
    required String userId,
    required String email,
    required String fullName,
    required int roleId,
    required String roleName,
  }) async {
    try {
      if (roleId == 1 || roleName == 'admin') {
        // Check if admin record exists
        print('[INFO] Checking if admin record exists for user: $userId');
        try {
          final existing = await _supabase
              .from('admins')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

          if (existing == null) {
            print('[INFO] Admin record missing, creating...');
            await _createAdminRecord(userId, email, fullName);
          } else {
            print('[INFO] Admin record already exists');
          }
        } catch (checkError) {
          print('[ERROR] Error checking admin record: $checkError');
          if (checkError is PostgrestException) {
            print('[ERROR] Postgrest error code: ${checkError.code}');
            print('[ERROR] Postgrest error message: ${checkError.message}');
          }
          // Try to create anyway
          print('[INFO] Attempting to create admin record anyway...');
          await _createAdminRecord(userId, email, fullName);
        }
      } else if (roleId == 2 || roleName == 'teacher') {
        // Check if teacher record exists
        final existing = await _supabase
            .from('teachers')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] Teacher record missing, creating...');
          await _createTeacherRecord(userId, email, fullName);
        }
      } else if (roleId == 3 || roleName == 'student') {
        // Check if student record exists
        final existing = await _supabase
            .from('students')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] Student record missing, creating...');
          await _createStudentRecord(userId, email, fullName);
        }
      } else if (roleId == 4 || roleName == 'parent') {
        // Check if parent record exists
        final existing = await _supabase
            .from('parents')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] Parent record missing, creating...');
          await _createParentRecord(userId, email, fullName);
        }
      } else if (roleId == 5 || roleName == 'ict_coordinator') {
        // Check if ICT coordinator record exists
        final existing = await _supabase
            .from('ict_coordinators')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] ICT Coordinator record missing, creating...');
          await _createICTCoordinatorRecord(userId, email, fullName);
        }
      } else if (roleId == 6 || roleName == 'grade_coordinator') {
        // Check if grade coordinator record exists
        final existing = await _supabase
            .from('grade_coordinators')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] Grade Coordinator record missing, creating...');
          await _createGradeCoordinatorRecord(userId, email, fullName);
        }
        // Ensure teacher record exists and set GLC flag for UI filtering
        try {
          final teacher = await _supabase
              .from('teachers')
              .select('id, is_grade_coordinator')
              .eq('id', userId)
              .maybeSingle();
          if (teacher == null) {
            await _createTeacherRecord(userId, email, fullName);
          }
          await _supabase
              .from('teachers')
              .update({'is_grade_coordinator': true})
              .eq('id', userId);
        } catch (e) {
          print('[WARN] Could not ensure teacher GLC flag: $e');
        }
      } else if (roleId == 7 || roleName == 'hybrid') {
        // Check if hybrid user record exists
        final existing = await _supabase
            .from('hybrid_users')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing == null) {
          print('[INFO] Hybrid user record missing, creating...');
          await _createHybridUserRecord(userId, email, fullName);
        }
      }
    } catch (e) {
      print('[WARN] Could not ensure role-specific record: $e');
    }
  }

  /// Create admin record
  Future<void> _createAdminRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('[INFO] Creating admin record for user: $userId');
      print('Admin full name: $fullName');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      final adminData = {
        'id': userId,
        'employee_id': 'ADM-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'admin_level': 'admin', // Default admin level
        'department': 'Administration',
        'position': 'Administrator',
        'permissions': [
          'manage_users',
          'manage_courses',
          'manage_system',
          'view_reports',
        ], // Default permissions
        'can_manage_users': true,
        'can_manage_courses': true,
        'can_manage_system': true,
        'can_view_reports': true,
        'is_active': true,
      };

      print('[INFO] Admin data to insert: $adminData');

      await _supabase.from('admins').insert(adminData);
      print('[INFO] Admin record created successfully!');
    } catch (e) {
      print('[ERROR] Error creating admin record: $e');
      if (e is PostgrestException) {
        print('[ERROR] Postgrest error code: ${e.code}');
        print('[ERROR] Postgrest error message: ${e.message}');
        print('[ERROR] Postgrest error details: ${e.details}');
        print('[ERROR] Postgrest error hint: ${e.hint}');
      }
      // Don't rethrow - allow login to continue even if admin record fails
    }
  }

  /// Create teacher record
  Future<void> _createTeacherRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('🔧 Creating teacher record for user: $userId');
      print('🔧 Full name: $fullName');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      final teacherData = {
        'id': userId,
        'employee_id': 'EMP-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'department': 'General',
        'subjects': ['General'], // JSONB array
        'is_grade_coordinator': false,
        'is_shs_teacher': false,
        'is_active': true,
      };

      print('🔧 Teacher data to insert: $teacherData');

      await _supabase.from('teachers').insert(teacherData);
      print('✅ Teacher record created successfully!');
    } catch (e) {
      print('❌ Error creating teacher record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error code: ${e.code}');
        print('❌ Postgrest error message: ${e.message}');
        print('❌ Postgrest error details: ${e.details}');
        print('❌ Postgrest error hint: ${e.hint}');
      }
      // Don't rethrow - allow login to continue even if teacher record fails
    }
  }

  /// Create student record (basic)
  Future<void> _createStudentRecord(
    String userId,
    String email,
    String fullName, {
    String? lrnFromAzure,
  }) async {
    try {
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      // Decide LRN: prefer a valid 12-digit LRN from Azure; otherwise keep existing temp scheme
      String lrnToUse;
      if (lrnFromAzure != null && RegExp(r'^\d{12}$').hasMatch(lrnFromAzure)) {
        lrnToUse = lrnFromAzure;
      } else {
        lrnToUse = 'LRN-${DateTime.now().millisecondsSinceEpoch}';
      }

      await _supabase.from('students').insert({
        'id': userId,
        'lrn': lrnToUse,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'grade_level': 7, // Default grade
        'section': 'Unassigned',
        'email': email,
        'school_year': '2024-2025',
        'status': 'active',
        'is_active': true,
        'enrollment_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ Student record created successfully!');
    } catch (e) {
      print('❌ Error creating student record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
    }
  }

  /// Create parent record
  Future<void> _createParentRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('🔧 Creating parent record for user: $userId');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      await _supabase.from('parents').insert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'email': email,
        'relationship_to_student': 'guardian', // Default
        'is_emergency_contact': true,
        'can_pickup_student': true,
        'can_view_grades': true,
        'can_receive_notifications': true,
        'preferred_contact_method': 'email',
        'is_active': true,
      });
      print('✅ Parent record created successfully!');
    } catch (e) {
      print('❌ Error creating parent record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
    }
  }

  /// Create ICT coordinator record
  Future<void> _createICTCoordinatorRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('🔧 Creating ICT coordinator record for user: $userId');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      await _supabase.from('ict_coordinators').insert({
        'id': userId,
        'employee_id': 'ICT-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'department': 'ICT',
        'specialization': 'General ICT',
        'certifications': [], // Empty JSONB array
        'tech_skills': [
          'Computer Literacy',
          'System Administration',
        ], // Default skills
        'is_system_admin': false,
        'managed_systems': [], // Empty JSONB array
        'is_active': true,
      });
      print('✅ ICT Coordinator record created successfully!');
    } catch (e) {
      print('❌ Error creating ICT coordinator record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
    }
  }

  /// Create grade coordinator record
  Future<void> _createGradeCoordinatorRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('🔧 Creating grade coordinator record for user: $userId');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      await _supabase.from('grade_coordinators').insert({
        'id': userId,
        'employee_id': 'GC-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'grade_level': 7, // Default grade level
        'department': 'Academic Affairs',
        'subjects': [], // Empty JSONB array
        'is_also_teaching': true,
        'responsibilities': [
          'Grade Level Management',
          'Student Affairs',
        ], // Default responsibilities
        'managed_sections': [], // Empty JSONB array
        'is_active': true,
      });
      print('✅ Grade Coordinator record created successfully!');

      // Ensure teacher record exists and flag as grade coordinator for UI filtering
      try {
        final existingTeacher = await _supabase
            .from('teachers')
            .select('id, is_grade_coordinator')
            .eq('id', userId)
            .maybeSingle();
        if (existingTeacher == null) {
          await _createTeacherRecord(userId, email, fullName);
        }
        await _supabase
            .from('teachers')
            .update({'is_grade_coordinator': true})
            .eq('id', userId);
      } catch (e) {
        print('⚠️ Warning: could not ensure teacher GLC flag: $e');
      }
    } catch (e) {
      print('❌ Error creating grade coordinator record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
    }
  }

  /// Create hybrid user record
  Future<void> _createHybridUserRecord(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      print('🔧 Creating hybrid user record for user: $userId');

      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      await _supabase.from('hybrid_users').insert({
        'id': userId,
        'employee_id': 'HYB-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName.isNotEmpty ? middleName : null,
        'primary_role': 'admin', // Default primary role
        'secondary_roles': ['teacher'], // Default secondary role
        'admin_level': 'admin',
        'admin_permissions': [
          'manage_users',
          'manage_courses',
        ], // Default permissions
        'department': 'Administration',
        'subjects': [], // Empty JSONB array
        'is_grade_coordinator': false,
        'is_active': true,
      });
      print('✅ Hybrid user record created successfully!');
    } catch (e) {
      print('❌ Error creating hybrid user record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
    }
  }
}
