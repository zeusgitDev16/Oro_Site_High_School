import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/services/auth_service.dart';
import 'package:oro_site_high_school/backend/config/environment.dart';
import 'login_screen.dart';
import 'simple_role_router.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _isCheckingAuth = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  // Listen to auth state changes for OAuth callbacks
  void _listenToAuthChanges() {
  _authService.authStateChanges.listen(
  (authState) async {
  print('🎯 AuthGate: Received auth state change: ${authState.event}');
  
  // DEBUG: Print the full auth state
  if (authState.session != null) {
  print('🔍 DEBUG: Session exists');
  print('🔍 DEBUG: Access Token: ${authState.session!.accessToken.substring(0, 50)}...');
  print('🔍 DEBUG: User: ${authState.session!.user.toJson()}');
  }
  
  if (authState.event == AuthChangeEvent.signedIn) {
  // User just signed in (including OAuth)
  print('✅ AuthGate: User signed in via OAuth');
  
  // CRITICAL: Ensure profile is created for OAuth logins
  if (authState.session != null) {
    print('🔧 Creating/updating profile for OAuth user...');
    await _authService.ensureProfileExists(authState.session!);
  }
  
  _checkAuthStatus();
        } else if (authState.event == AuthChangeEvent.signedOut) {
          // User signed out
          print('🚪 AuthGate: User signed out');
          setState(() {
            _userRole = null;
            _isCheckingAuth = false;
          });
        } else if (authState.event == AuthChangeEvent.tokenRefreshed) {
          print('🔄 AuthGate: Token refreshed');
        } else if (authState.event == AuthChangeEvent.userUpdated) {
          print('👤 AuthGate: User updated');
        } else if (authState.event == AuthChangeEvent.passwordRecovery) {
          print('🔑 AuthGate: Password recovery');
        }
      },
      onError: (error) {
        print('❌ AuthGate: Error in auth state stream: $error');
        if (error is AuthException) {
          print('❌ AuthException details:');
          print('   Message: ${error.message}');
          print('   Status Code: ${error.statusCode}');

          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication error: ${error.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        setState(() {
          _isCheckingAuth = false;
        });
      },
    );
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('🔍 AuthGate: Checking auth status...');

      // Check if user is authenticated
      if (_authService.isAuthenticated) {
        print('✅ AuthGate: User is authenticated');

        final currentUser = _authService.getCurrentUser();
        if (currentUser != null) {
          print('👤 AuthGate: Current user ID: ${currentUser.id}');
          print(
            '📧 AuthGate: Current user email: ${currentUser.email ?? "NO EMAIL"}',
          );
        }

        // Get user role
        final role = await _authService.getUserRole();
        print('🎭 AuthGate: User role: ${role ?? "NULL"}');

        setState(() {
          _userRole = role;
          _isCheckingAuth = false;
        });
      } else {
        print('❌ AuthGate: User is not authenticated');
        setState(() {
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      print('❌ AuthGate: Error checking auth status: $e');
      if (e is AuthException) {
        print('❌ AuthException details:');
        print('   Message: ${e.message}');
        print('   Status Code: ${e.statusCode}');
      }

      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/OroSiteLogo3.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              if (Environment.debugMode) ...[
                const SizedBox(height: 8),
                Text(
                  Environment.useMockData
                      ? 'Mock Mode'
                      : 'Connected to Supabase',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Check if we have auth state data
        if (snapshot.hasData) {
          final session = snapshot.data!.session;

          if (session != null) {
            // User is authenticated, route based on role
            return FutureBuilder<String?>(
              future: _authService.getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading user profile...'),
                        ],
                      ),
                    ),
                  );
                }

                final userRole = roleSnapshot.data;

                if (userRole != null) {
                  // Route to appropriate dashboard based on role
                  return RoleBasedRouter(userRole: userRole);
                } else {
                  // If role cannot be determined, show error
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to determine user role',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await _authService.signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          }
        }

        // User is not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}
