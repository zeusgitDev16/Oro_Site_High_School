// Environment Configuration
// Manages all environment variables and configuration settings
// 
// Usage:
// ```dart
// final url = Environment.supabaseUrl;
// final isDebug = Environment.debugMode;
// ```

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  /// Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Warning: Could not load .env file, using default values');
      // Continue with default values
    }
  }

  // ==================== SUPABASE CONFIGURATION ====================
  
  /// Supabase project URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      // Return your actual Supabase URL as fallback
      // This allows the app to work even without .env file
      return 'https://fhqzohvtioosycaafnij.supabase.co';
    }
    return url;
  }

  /// Supabase anonymous key
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      // Return your actual anon key as fallback
      // This allows the app to work even without .env file
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZocXpvaHZ0aW9vc3ljYWFmbmlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NTExNDYsImV4cCI6MjA3NjEyNzE0Nn0.P1cbaNL7S5R0yKx80n4Mcl0USf18nNbUqBmcRiAyxWI';
    }
    return key;
  }

  // ==================== AZURE AD CONFIGURATION ====================
  
  /// Azure AD tenant ID
  static String get azureTenantId {
    // Return your actual Azure Tenant ID as fallback
    return dotenv.env['AZURE_TENANT_ID'] ?? 'f205dc04-e2d3-4042-94b4-7e0bb9f13181';
  }

  /// Azure AD client ID
  static String get azureClientId {
    // Return your actual Azure Client ID as fallback
    return dotenv.env['AZURE_CLIENT_ID'] ?? '5ef49f61-b51d-4484-85e6-24c127d331ed';
  }

  /// Azure AD redirect URI
  static String get azureRedirectUri {
    // For local development, we need to use the Supabase callback URL
    // This should match what's configured in your Azure AD app registration
    return dotenv.env['AZURE_REDIRECT_URI'] ?? 'https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback';
  }

  // ==================== FEATURE FLAGS ====================
  
  /// Whether to use mock data (fallback mode)
  static bool get useMockData {
    final value = dotenv.env['USE_MOCK_DATA'] ?? 'false';
    return value.toLowerCase() == 'true';
  }

  /// Whether offline mode is enabled
  static bool get enableOffline {
    final value = dotenv.env['ENABLE_OFFLINE'] ?? 'true';
    return value.toLowerCase() == 'true';
  }

  /// Whether real-time features are enabled
  static bool get enableRealtime {
    final value = dotenv.env['ENABLE_REALTIME'] ?? 'true';
    return value.toLowerCase() == 'true';
  }

  /// Whether Azure AD authentication is enabled
  static bool get enableAzureAuth {
    // Azure AD is now properly configured
    final value = dotenv.env['ENABLE_AZURE_AUTH'] ?? 'true';
    return value.toLowerCase() == 'true';
  }

  // ==================== SCANNER CONFIGURATION ====================
  
  /// Scanner API URL
  static String get scannerApiUrl {
    return dotenv.env['SCANNER_API_URL'] ?? 'http://localhost:3000/api/scanner';
  }

  /// Scanner polling interval in milliseconds
  static int get scannerPollingInterval {
    final value = dotenv.env['SCANNER_POLLING_INTERVAL'] ?? '5000';
    return int.tryParse(value) ?? 5000;
  }

  // ==================== STORAGE CONFIGURATION ====================
  
  /// Maximum file size in MB
  static int get maxFileSizeMB {
    final value = dotenv.env['MAX_FILE_SIZE_MB'] ?? '10';
    return int.tryParse(value) ?? 10;
  }

  /// Allowed file types (comma-separated)
  static List<String> get allowedFileTypes {
    final types = dotenv.env['ALLOWED_FILE_TYPES'] ?? 'pdf,doc,docx,xls,xlsx,png,jpg,jpeg';
    return types.split(',').map((e) => e.trim()).toList();
  }

  // ==================== DEVELOPMENT SETTINGS ====================
  
  /// Whether debug mode is enabled
  static bool get debugMode {
    final value = dotenv.env['DEBUG_MODE'] ?? 'false';
    return value.toLowerCase() == 'true';
  }

  /// Logging level (debug, info, warning, error)
  static String get logLevel {
    return dotenv.env['LOG_LEVEL'] ?? 'info';
  }

  // ==================== VALIDATION ====================
  
  /// Validate all required environment variables
  static bool validate() {
    try {
      // Check required variables
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        return false;
      }
      
      // Check Azure config if enabled
      if (enableAzureAuth && azureClientId.isEmpty) {
        print('Warning: Azure Auth enabled but CLIENT_ID not configured');
      }
      
      return true;
    } catch (e) {
      print('Environment validation failed: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Get environment type (development, staging, production)
  static String get environmentType {
    if (supabaseUrl.contains('localhost')) return 'development';
    if (supabaseUrl.contains('staging')) return 'staging';
    return 'production';
  }

  /// Check if running in production
  static bool get isProduction => environmentType == 'production';

  /// Check if running in development
  static bool get isDevelopment => environmentType == 'development';

  /// Get all configuration as map (for debugging)
  static Map<String, dynamic> toMap() {
    return {
      'environment': environmentType,
      'supabase': {
        'url': supabaseUrl.replaceRange(10, supabaseUrl.length - 10, '***'),
        'configured': supabaseUrl.isNotEmpty,
      },
      'azure': {
        'tenant': azureTenantId,
        'configured': azureClientId.isNotEmpty,
        'enabled': enableAzureAuth,
      },
      'features': {
        'mockData': useMockData,
        'offline': enableOffline,
        'realtime': enableRealtime,
        'azureAuth': enableAzureAuth,
      },
      'scanner': {
        'url': scannerApiUrl,
        'polling': scannerPollingInterval,
      },
      'storage': {
        'maxSize': maxFileSizeMB,
        'allowedTypes': allowedFileTypes,
      },
      'debug': {
        'enabled': debugMode,
        'logLevel': logLevel,
      },
    };
  }

  /// Print configuration summary
  static void printConfiguration() {
    print('═══════════════════════════════════════════════════════');
    print('           ORO SITE HIGH SCHOOL ELMS                   ');
    print('           Environment Configuration                    ');
    print('═══════════════════════════════════════════════════════');
    print('Environment Type: ${environmentType.toUpperCase()}');
    print('───────────────────────────────────────────────────────');
    print('Supabase:');
    print('  ✓ URL: ${supabaseUrl.substring(0, 30)}...');
    print('  ✓ Key: Configured');
    print('───────────────────────────────────────────────────────');
    print('Azure AD:');
    print('  ${enableAzureAuth ? "✓" : "✗"} Enabled: $enableAzureAuth');
    print('  ✓ Tenant: $azureTenantId');
    print('  ${azureClientId.isNotEmpty ? "✓" : "✗"} Client ID: ${azureClientId.isNotEmpty ? "Configured" : "Not configured"}');
    print('───────────────────────────────────────────────────────');
    print('Features:');
    print('  ${useMockData ? "⚠" : "✓"} Mock Data: $useMockData');
    print('  ${enableOffline ? "✓" : "✗"} Offline Mode: $enableOffline');
    print('  ${enableRealtime ? "✓" : "✗"} Real-time: $enableRealtime');
    print('───────────────────────────────────────────────────────');
    print('Scanner:');
    print('  ✓ API URL: $scannerApiUrl');
    print('  ✓ Polling: ${scannerPollingInterval}ms');
    print('───────────────────────────────────────────────────────');
    print('Storage:');
    print('  ✓ Max Size: ${maxFileSizeMB}MB');
    print('  ✓ File Types: ${allowedFileTypes.join(", ")}');
    print('───────────────────────────────────────────────────────');
    print('Debug:');
    print('  ${debugMode ? "✓" : "✗"} Debug Mode: $debugMode');
    print('  ✓ Log Level: $logLevel');
    print('═══════════════════════════════════════════════════════');
  }
}