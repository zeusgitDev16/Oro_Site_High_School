import 'package:shared_preferences/shared_preferences.dart';

/// Feature Flag Service - Manages feature toggles for gradual rollout
/// 
/// This service provides a simple feature flag system using SharedPreferences
/// to enable/disable features without code changes. Perfect for A/B testing,
/// gradual rollouts, and emergency rollbacks.
/// 
/// **Primary Use Case: Classroom UI Migration**
/// - Toggle between old and new classroom UI implementations
/// - Instant rollback capability (< 5 seconds)
/// - Zero code changes required
/// 
/// **Usage:**
/// ```dart
/// // Check if new classroom UI is enabled
/// final useNewUI = await FeatureFlagService.isNewClassroomUIEnabled();
/// 
/// // Route to appropriate screen
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => useNewUI 
///         ? const MyClassroomScreenV2()  // NEW
///         : const MyClassroomScreen(),   // OLD
///   ),
/// );
/// ```
class FeatureFlagService {
  // Storage keys
  static const String _newClassroomUIKey = 'feature_flag_new_classroom_ui';
  static const String _emergencyRollbackKey = 'feature_flag_emergency_rollback';

  // ==================== CLASSROOM UI FEATURE FLAG ====================

  /// Check if new classroom UI is enabled
  ///
  /// Returns `true` if the new classroom UI should be used, `false` for old UI.
  /// Default: `true` (new UI) - Changed to enable new classroom UI by default.
  ///
  /// **Emergency Rollback:** If emergency rollback is active, always returns `false`.
  static Future<bool> isNewClassroomUIEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for emergency rollback first
      final emergencyRollback = prefs.getBool(_emergencyRollbackKey) ?? false;
      if (emergencyRollback) {
        print('🚨 Emergency rollback active - using old classroom UI');
        return false;
      }

      // Check feature flag - DEFAULT TO TRUE (new UI enabled by default)
      final enabled = prefs.getBool(_newClassroomUIKey) ?? true;
      print('🎯 New classroom UI enabled: $enabled');
      return enabled;
    } catch (e) {
      print('❌ Error checking classroom UI feature flag: $e');
      return true; // Default to new UI on error
    }
  }

  /// Enable new classroom UI
  /// 
  /// Switches all users to the new classroom UI implementation.
  /// Takes effect immediately on next navigation.
  static Future<void> enableNewClassroomUI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_newClassroomUIKey, true);
      print('✅ New classroom UI enabled');
    } catch (e) {
      print('❌ Error enabling new classroom UI: $e');
      rethrow;
    }
  }

  /// Disable new classroom UI (revert to old)
  /// 
  /// Switches all users back to the old classroom UI implementation.
  /// Takes effect immediately on next navigation.
  static Future<void> disableNewClassroomUI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_newClassroomUIKey, false);
      print('✅ New classroom UI disabled - reverted to old UI');
    } catch (e) {
      print('❌ Error disabling new classroom UI: $e');
      rethrow;
    }
  }

  /// Toggle new classroom UI on/off
  /// 
  /// Switches between old and new classroom UI implementations.
  /// Useful for testing and comparison.
  static Future<void> toggleNewClassroomUI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getBool(_newClassroomUIKey) ?? false;
      await prefs.setBool(_newClassroomUIKey, !current);
      print('✅ Classroom UI toggled: ${!current ? "NEW" : "OLD"}');
    } catch (e) {
      print('❌ Error toggling classroom UI: $e');
      rethrow;
    }
  }

  // ==================== EMERGENCY ROLLBACK ====================

  /// Activate emergency rollback
  /// 
  /// Forces all users to old classroom UI regardless of feature flag setting.
  /// Use this in production emergencies when new UI has critical issues.
  /// 
  /// **Rollback Time:** < 5 seconds
  static Future<void> emergencyRollback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emergencyRollbackKey, true);
      print('🚨 EMERGENCY ROLLBACK ACTIVATED - All users forced to old UI');
    } catch (e) {
      print('❌ Error activating emergency rollback: $e');
      rethrow;
    }
  }

  /// Clear emergency rollback
  /// 
  /// Removes emergency rollback flag, allowing feature flag to work normally.
  static Future<void> clearEmergencyRollback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyRollbackKey);
      print('✅ Emergency rollback cleared');
    } catch (e) {
      print('❌ Error clearing emergency rollback: $e');
      rethrow;
    }
  }

  /// Check if emergency rollback is active
  static Future<bool> isEmergencyRollbackActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_emergencyRollbackKey) ?? false;
    } catch (e) {
      print('❌ Error checking emergency rollback: $e');
      return false;
    }
  }
}

