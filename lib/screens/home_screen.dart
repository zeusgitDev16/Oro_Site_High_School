
import 'package:flutter/material.dart';
import 'role_based_router.dart';

/// Home Screen
/// This screen acts as the entry point after authentication
/// It uses the RoleBasedRouter to direct users to their appropriate dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The RoleBasedRouter will handle:
    // 1. Detecting the user's role from the database
    // 2. Routing to the appropriate dashboard (Admin, Teacher, Student, or Parent)
    // 3. Managing hybrid users who can switch between roles
    // 4. Handling loading and error states
    return const RoleBasedRouter();
  }
}
