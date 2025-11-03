// Supabase Configuration and Initialization
// Handles Supabase client setup and configuration
// 
// This is the main entry point for Supabase initialization
// Call SupabaseConfig.initialize() in main.dart before runApp()

import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment.dart';

class SupabaseConfig {
  // Private constructor to prevent instantiation
  SupabaseConfig._();

  /// Singleton instance of Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Check if Supabase is initialized
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Connection status
  static bool _isConnected = false;
  static bool get isConnected => _isConnected;

  /// Initialize Supabase with configuration
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing Supabase...');
      
      // Load environment variables first
      await Environment.initialize();
      
      // Validate environment
      if (!Environment.validate()) {
        throw Exception('Environment validation failed. Check your .env file.');
      }
      
      // Print configuration in debug mode
      if (Environment.debugMode) {
        Environment.printConfiguration();
      }
      
      // Initialize Supabase
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
        realtimeClientOptions: RealtimeClientOptions(
          logLevel: Environment.debugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3,
        ),
        postgrestOptions: const PostgrestClientOptions(
          schema: 'public',
        ),
      );
      
      _isInitialized = true;
      
      // Test connection
      await testConnection();
      
      // Setup auth state listener
      _setupAuthListener();
      
      // Setup realtime if enabled
      if (Environment.enableRealtime) {
        _setupRealtimeConnection();
      }
      
      print('✅ Supabase initialized successfully');
      
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      _isInitialized = false;
      _isConnected = false;
      
      // If mock data is enabled, don't throw error
      if (Environment.useMockData) {
        print('⚠️ Falling back to mock data mode');
      } else {
        rethrow;
      }
    }
  }

  /// Test database connection
  static Future<bool> testConnection() async {
    try {
      // Try to fetch a single row from profiles table
      final response = await client
          .from('profiles')
          .select('id')
          .limit(1);
      
      _isConnected = true;
      print('✅ Database connection successful');
      return true;
      
    } catch (e) {
      _isConnected = false;
      print('❌ Database connection failed: $e');
      
      if (!Environment.useMockData) {
        print('💡 Tip: Enable mock data in .env to work offline');
      }
      
      return false;
    }
  }

  /// Setup authentication state listener
  static void _setupAuthListener() {
    client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (Environment.debugMode) {
        print('🔐 Auth state changed: $event');
      }
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          print('✅ User signed in: ${session?.user.email}');
          _handleSignIn(session);
          break;
          
        case AuthChangeEvent.signedOut:
          print('👋 User signed out');
          _handleSignOut();
          break;
          
        case AuthChangeEvent.tokenRefreshed:
          if (Environment.debugMode) {
            print('🔄 Token refreshed');
          }
          break;
          
        case AuthChangeEvent.userUpdated:
          print('👤 User profile updated');
          break;
          
        case AuthChangeEvent.passwordRecovery:
          print('🔑 Password recovery initiated');
          break;
          
        default:
          break;
      }
    });
  }

  /// Handle user sign in
  static void _handleSignIn(Session? session) {
    if (session == null) return;
    
    // Log user activity
    _logActivity('sign_in', {
      'user_id': session.user.id,
      'email': session.user.email,
      'provider': session.user.appMetadata['provider'],
    });
  }

  /// Handle user sign out
  static void _handleSignOut() {
    // Clean up any cached data
    _clearCache();
  }

  /// Setup realtime connection
  static void _setupRealtimeConnection() {
    try {
      // Realtime is automatically connected when needed in newer versions
      // Just verify it's available
      if (client.realtime.isConnected) {
        print('✅ Realtime connection available');
      } else {
        print('⚠️ Realtime not connected yet, will connect when needed');
      }
      
    } catch (e) {
      print('⚠️ Realtime setup error: $e');
    }
  }

  /// Log user activity
  static Future<void> _logActivity(String action, Map<String, dynamic> details) async {
    if (!_isConnected) return;
    
    try {
      await client.from('activity_log').insert({
        'user_id': client.auth.currentUser?.id,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (Environment.debugMode) {
        print('Failed to log activity: $e');
      }
    }
  }

  /// Clear cached data
  static void _clearCache() {
    // This will be implemented when we add cache manager
    if (Environment.debugMode) {
      print('🧹 Clearing cache...');
    }
  }

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Get current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user role from profile
  static Future<String?> getUserRole() async {
    try {
      if (!isAuthenticated) return null;
      
      final response = await client
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', currentUser!.id)
          .single();
      
      return response['roles']?['name'];
      
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      _clearCache();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Dispose resources
  static void dispose() {
    if (_isInitialized) {
      client.realtime.disconnect();
      _isInitialized = false;
      _isConnected = false;
    }
  }

  /// Get connection status summary
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'connected': _isConnected,
      'authenticated': isAuthenticated,
      'user': currentUser?.email,
      'realtime': client.realtime.isConnected,
      'mockMode': Environment.useMockData,
    };
  }

  /// Print status summary
  static void printStatus() {
    final status = getStatus();
    print('══════════════════════════���════════════════');
    print('         SUPABASE CONNECTION STATUS         ');
    print('═══════════════════════════════════════════');
    print('Initialized: ${status['initialized'] ? "✅" : "❌"} ${status['initialized']}');
    print('Connected: ${status['connected'] ? "✅" : "❌"} ${status['connected']}');
    print('Authenticated: ${status['authenticated'] ? "✅" : "❌"} ${status['authenticated']}');
    print('User: ${status['user'] ?? "Not logged in"}');
    print('Realtime: ${status['realtime'] ? "✅" : "❌"} ${status['realtime']}');
    print('Mock Mode: ${status['mockMode'] ? "⚠️" : "✅"} ${status['mockMode']}');
    print('═══════════════════════════════════════════');
  }
}