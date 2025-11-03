/// Coordinator Mode Toggle Widget
/// Allows grade level coordinators to switch between teacher and coordinator views

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/user_role_service.dart';
import '../../../services/grade_coordinator_service.dart';
import '../coordinator/coordinator_dashboard_screen.dart';

class CoordinatorModeToggle extends StatefulWidget {
  const CoordinatorModeToggle({super.key});

  @override
  State<CoordinatorModeToggle> createState() => _CoordinatorModeToggleState();
}

class _CoordinatorModeToggleState extends State<CoordinatorModeToggle> 
    with SingleTickerProviderStateMixin {
  final UserRoleService _roleService = UserRoleService();
  final GradeCoordinatorService _coordinatorService = GradeCoordinatorService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCoordinatorMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _checkCoordinatorStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkCoordinatorStatus() async {
    setState(() => _isLoading = true);
    
    // Check if user is a grade coordinator
    if (_roleService.isGradeCoordinator) {
      // Initialize coordinator service
      // Get current user ID from Supabase auth
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _coordinatorService.initialize(userId);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleMode() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    setState(() {
      _isCoordinatorMode = !_isCoordinatorMode;
    });
    
    if (_isCoordinatorMode) {
      // Navigate to coordinator dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CoordinatorDashboardScreen(),
        ),
      ).then((_) {
        // Reset toggle when returning
        setState(() {
          _isCoordinatorMode = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if not a coordinator
    if (!_roleService.isGradeCoordinator || _coordinatorService.currentAssignment == null) {
      return const SizedBox.shrink();
    }
    
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final assignment = _coordinatorService.currentAssignment!;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isCoordinatorMode ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: _toggleMode,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _isCoordinatorMode
                    ? [Colors.purple.shade700, Colors.purple.shade500]
                    : [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isCoordinatorMode 
                            ? Icons.admin_panel_settings 
                            : Icons.swap_horiz,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCoordinatorMode 
                                ? 'Coordinator Mode Active' 
                                : 'Switch to Coordinator Mode',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade ${assignment.gradeLevel} Coordinator',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Access grade level management features',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = _coordinatorService.gradeLevelStats;
    if (stats == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        _buildStatItem(
          Icons.class_,
          '${stats.totalSections}',
          'Sections',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.people,
          '${stats.totalStudents}',
          'Students',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.trending_up,
          '${stats.averageGrade.toStringAsFixed(1)}%',
          'Avg Grade',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.check_circle,
          '${stats.attendanceRate.toStringAsFixed(1)}%',
          'Attendance',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}