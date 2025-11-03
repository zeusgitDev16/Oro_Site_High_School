import 'package:flutter/material.dart';

/// App Theme
/// Centralized theme configuration for consistent UI/UX
/// Following OSHS architecture and DepEd standards
class AppTheme {
  // ==================== COLORS ====================
  
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color primaryDeepPurple = Color(0xFF512DA8);
  
  // Secondary Colors
  static const Color secondaryGreen = Color(0xFF388E3C);
  static const Color secondaryOrange = Color(0xFFFF6F00);
  static const Color secondaryTeal = Color(0xFF00897B);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Role Colors
  static const Color adminColor = Color(0xFF512DA8); // Deep Purple
  static const Color coordinatorColor = Color(0xFF1976D2); // Blue
  static const Color teacherColor = Color(0xFF388E3C); // Green
  static const Color studentColor = Color(0xFFFF6F00); // Orange
  
  // ==================== TEXT STYLES ====================
  
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle heading6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.4,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );
  
  // ==================== DIMENSIONS ====================
  
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Elevation
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;
  static const double elevationXHigh = 8.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  static const double iconXXLarge = 40.0;
  
  // Avatar Sizes
  static const double avatarSmall = 24.0;
  static const double avatarMedium = 32.0;
  static const double avatarLarge = 40.0;
  static const double avatarXLarge = 56.0;
  
  // ==================== THEME DATA ====================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: elevationLow,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        filled: true,
        fillColor: backgroundWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
    );
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Get color for user role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return adminColor;
      case 'grade level coordinator':
      case 'coordinator':
        return coordinatorColor;
      case 'teacher':
        return teacherColor;
      case 'student':
        return studentColor;
      default:
        return textSecondary;
    }
  }
  
  /// Get color for status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'active':
      case 'success':
        return successGreen;
      case 'pending':
      case 'in_progress':
      case 'warning':
        return warningOrange;
      case 'rejected':
      case 'failed':
      case 'error':
      case 'inactive':
        return errorRed;
      case 'info':
      default:
        return infoBlue;
    }
  }
  
  /// Get color for priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return errorRed;
      case 'high':
        return warningOrange;
      case 'medium':
        return infoBlue;
      case 'low':
        return successGreen;
      default:
        return textSecondary;
    }
  }
  
  /// Create gradient for role
  static LinearGradient getRoleGradient(String role) {
    final color = getRoleColor(role);
    return LinearGradient(
      colors: [
        color,
        Color.lerp(color, Colors.white, 0.3)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
