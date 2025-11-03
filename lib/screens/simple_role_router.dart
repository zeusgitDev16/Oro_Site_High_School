// Simple Role-Based Router
// Routes users to appropriate dashboards based on their role string

import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'student/dashboard/student_dashboard_screen.dart';
import 'parent/dashboard/parent_dashboard_screen.dart';

class RoleBasedRouter extends StatelessWidget {
  final String userRole;
  
  const RoleBasedRouter({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Route based on user role
    switch (userRole.toLowerCase()) {
      case 'admin':
        // Full admin access
        return const AdminDashboardScreen();
        
      case 'ict_coordinator':
        // ICT Coordinators are admins (system/tech management)
        return const AdminDashboardScreen();
        
      case 'teacher':
        // Regular teachers - basic features only
        return const TeacherDashboardScreen();
        
      case 'grade_coordinator':
        // Grade Coordinators - teacher dashboard + coordinator mode
        return const TeacherDashboardScreen();
        
      case 'hybrid':
        // Hybrid users - teacher dashboard + admin features
        return const TeacherDashboardScreen();
        
      case 'student':
        return const StudentDashboardScreen();
        
      case 'parent':
        return const ParentDashboardScreen();
        
      default:
        // If role is unknown, show error screen
        return Scaffold(
          appBar: AppBar(
            title: const Text('Access Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'Unknown user role: $userRole',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please contact your system administrator',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Return to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}