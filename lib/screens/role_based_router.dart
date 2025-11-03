/// Role-Based Router
/// Automatically routes users to their appropriate dashboard based on role
/// Handles hybrid users and role switching

import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/user_role_service.dart';

// Import all dashboard screens
import 'admin/admin_dashboard_screen.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'student/dashboard/student_dashboard_screen.dart';
import 'parent/dashboard/parent_dashboard_screen.dart';

class RoleBasedRouter extends StatefulWidget {
  const RoleBasedRouter({super.key});

  @override
  State<RoleBasedRouter> createState() => _RoleBasedRouterState();
}

class _RoleBasedRouterState extends State<RoleBasedRouter> {
  final UserRoleService _roleService = UserRoleService();
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
    
    // Listen to role changes (for hybrid users switching roles)
    _roleService.addListener(_onRoleChanged);
  }

  @override
  void dispose() {
    _roleService.removeListener(_onRoleChanged);
    super.dispose();
  }

  /// Initialize user role
  Future<void> _initializeUserRole() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      await _roleService.initializeUserRole();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to load user role: $e';
      });
    }
  }

  /// Handle role changes
  void _onRoleChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild to show new dashboard
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    // Show error screen if initialization failed
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    // Route to appropriate dashboard based on role
    final currentRole = _roleService.currentRole;
    
    if (currentRole == null) {
      return _buildNoRoleScreen();
    }

    // Wrap dashboard with hybrid user controls if applicable
    if (_roleService.isHybridUser) {
      return _buildHybridUserWrapper(_getDashboardForRole(currentRole));
    }

    return _getDashboardForRole(currentRole);
  }

  /// Get dashboard widget for specific role
  Widget _getDashboardForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.hybrid: // Hybrid users see admin dashboard by default
        return const AdminDashboardScreen();
      
      case UserRole.teacher:
        return const TeacherDashboardScreen();
      
      case UserRole.gradeCoordinator:
        // Grade coordinators use enhanced teacher dashboard
        // TODO: Add coordinator-specific features to teacher dashboard
        return const TeacherDashboardScreen();
      
      case UserRole.student:
        return const StudentDashboardScreen();
      
      case UserRole.parent:
        return const ParentDashboardScreen();
      
      default:
        return _buildNoRoleScreen();
    }
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // School logo
            Image.asset(
              'assets/OroSiteLogo3.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading your dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Unable to Load Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initializeUserRole,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build screen for users with no role assigned
  Widget _buildNoRoleScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'No Role Assigned',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account does not have a role assigned.\nPlease contact the administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Sign out and return to login
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build wrapper for hybrid users with role switching
  Widget _buildHybridUserWrapper(Widget dashboard) {
    return Stack(
      children: [
        // Main dashboard
        dashboard,
        
        // Role switcher floating button
        Positioned(
          bottom: 24,
          right: 24,
          child: _buildRoleSwitcher(),
        ),
      ],
    );
  }

  /// Build role switcher for hybrid users
  Widget _buildRoleSwitcher() {
    final currentRole = _roleService.currentRole;
    final isAdmin = currentRole == UserRole.admin;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showRoleSwitchDialog();
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.school,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Role',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Administrator' : 'Teacher',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.swap_horiz,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show role switch confirmation dialog
  void _showRoleSwitchDialog() {
    final currentRole = _roleService.currentRole;
    final isAdmin = currentRole == UserRole.admin;
    final targetRole = isAdmin ? 'Teacher' : 'Administrator';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Role'),
        content: Text(
          'Switch to $targetRole view?\n\n'
          'You can switch back at any time using the role switcher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _roleService.switchRole();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Switch to $targetRole'),
          ),
        ],
      ),
    );
  }
}

/// Role indicator widget for displaying current role in app bars
class RoleIndicator extends StatelessWidget {
  const RoleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final roleService = UserRoleService();
    
    if (!roleService.isHybridUser) {
      return const SizedBox.shrink();
    }

    final currentRole = roleService.currentRole;
    final isAdmin = currentRole == UserRole.admin;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.purple.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.school,
            size: 16,
            color: isAdmin ? Colors.purple : Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Admin Mode' : 'Teacher Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isAdmin ? Colors.purple : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}