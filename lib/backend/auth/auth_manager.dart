// Authentication Manager
// Centralized authentication state management
// Handles login, logout, and session management

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'azure_auth_provider.dart';
import 'role_manager.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthManager extends ChangeNotifier {
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // Dependencies
  final _azureAuth = AzureAuthProvider();
  final _roleManager = RoleManager();
  final _client = SupabaseConfig.client;

  // State
  AuthStatus _state = AuthStatus.initial;
  User? _currentUser;
  String? _currentRole;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  // Getters
  AuthStatus get state => _state;
  User? get currentUser => _currentUser;
  String? get currentRole => _currentRole;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAuthenticated => _state == AuthStatus.authenticated;
  bool get isLoading => _state == AuthStatus.loading;

  /// Initialize authentication manager
  Future<void> initialize() async {
    print('🔐 Initializing Authentication Manager...');
    
    // Check for existing session
    final session = _client.auth.currentSession;
    if (session != null) {
      await _handleAuthSuccess(session);
    } else {
      _setState(AuthStatus.unauthenticated);
    }

    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data);
    });
  }

  /// Handle auth state changes
  void _handleAuthStateChange(AuthState data) {
    final event = data.event;
    final session = data.session;

    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session != null) {
          _handleAuthSuccess(session);
        }
        break;
      case AuthChangeEvent.signedOut:
        _handleSignOut();
        break;
      case AuthChangeEvent.tokenRefreshed:
        // Token refreshed, update session
        if (session != null) {
          _currentUser = session.user;
          notifyListeners();
        }
        break;
      case AuthChangeEvent.userUpdated:
        // User profile updated
        _loadUserProfile();
        break;
      default:
        break;
    }
  }

  /// Sign in with Azure AD
  Future<bool> signInWithAzure() async {
    try {
      _setState(AuthStatus.loading);
      _errorMessage = null;

      final response = await _azureAuth.signInWithAzure();
      
      if (response?.session != null) {
        await _handleAuthSuccess(response!.session!);
        return true;
      }

      _setState(AuthStatus.unauthenticated);
      return false;
      
    } catch (e) {
      _handleError('Azure sign in failed: $e');
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setState(AuthStatus.loading);
      _errorMessage = null;

      final response = await _azureAuth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response?.session != null) {
        await _handleAuthSuccess(response!.session!);
        return true;
      }

      _setState(AuthStatus.unauthenticated);
      return false;
      
    } catch (e) {
      _handleError('Sign in failed: $e');
      return false;
    }
  }

  /// Handle successful authentication
  Future<void> _handleAuthSuccess(Session session) async {
    try {
      _currentUser = session.user;
      
      // Load user profile
      await _loadUserProfile();
      
      // Get user role
      _currentRole = await _roleManager.getUserRole(_currentUser!.id);
      
      // Log activity
      await _logActivity('sign_in', {
        'user_id': _currentUser!.id,
        'email': _currentUser!.email,
        'role': _currentRole,
      });
      
      _setState(AuthStatus.authenticated);
      
      print('✅ Authentication successful');
      print('   User: ${_currentUser!.email}');
      print('   Role: $_currentRole');
      
    } catch (e) {
      _handleError('Failed to complete authentication: $e');
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      if (_currentUser == null) return;

      final response = await _client
          .from('profiles')
          .select('*, roles(*)')
          .eq('id', _currentUser!.id)
          .single();

      _userProfile = response;
      
      // Update role from profile
      if (response['roles'] != null) {
        _currentRole = response['roles']['name'];
      }
      
      notifyListeners();
      
    } catch (e) {
      print('⚠️ Error loading user profile: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setState(AuthStatus.loading);
      
      // Log activity before signing out
      await _logActivity('sign_out', {
        'user_id': _currentUser?.id,
        'email': _currentUser?.email,
      });
      
      await _client.auth.signOut();
      _handleSignOut();
      
    } catch (e) {
      _handleError('Sign out failed: $e');
    }
  }

  /// Handle sign out
  void _handleSignOut() {
    _currentUser = null;
    _currentRole = null;
    _userProfile = null;
    _errorMessage = null;
    _setState(AuthStatus.unauthenticated);
    print('✅ User signed out');
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _azureAuth.resetPassword(email);
      return true;
    } catch (e) {
      _handleError('Password reset failed: $e');
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _azureAuth.updatePassword(newPassword);
      return true;
    } catch (e) {
      _handleError('Password update failed: $e');
      return false;
    }
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return _currentRole == role;
  }

  /// Check if user is admin
  bool get isAdmin => hasRole('admin');

  /// Check if user is teacher
  bool get isTeacher => hasRole('teacher');

  /// Check if user is student  
  bool get isStudent => hasRole('student');

  /// Check if user is parent
  bool get isParent => hasRole('parent');

  /// Check if user is coordinator
  bool get isCoordinator => hasRole('coordinator');

  /// Get dashboard route based on role
  String getDashboardRoute() {
    switch (_currentRole) {
      case 'admin':
        return '/admin_dashboard';
      case 'teacher':
        return '/teacher_dashboard';
      case 'coordinator':
        return '/teacher_dashboard'; // Coordinators use teacher dashboard
      case 'student':
        return '/student_dashboard';
      case 'parent':
        return '/parent_dashboard';
      default:
        return '/login';
    }
  }

  /// Log user activity
  Future<void> _logActivity(String action, Map<String, dynamic> details) async {
    try {
      await _client.from('activity_log').insert({
        'user_id': details['user_id'],
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  /// Set state and notify listeners
  void _setState(AuthStatus newState) {
    _state = newState;
    notifyListeners();
  }

  /// Handle errors
  void _handleError(String message) {
    _errorMessage = message;
    _setState(AuthStatus.error);
    print('❌ Auth Error: $message');
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get auth status summary
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.toString(),
      'isAuthenticated': isAuthenticated,
      'user': _currentUser?.email,
      'role': _currentRole,
      'hasProfile': _userProfile != null,
      'error': _errorMessage,
    };
  }

  /// Dispose
  @override
  void dispose() {
    super.dispose();
  }
}