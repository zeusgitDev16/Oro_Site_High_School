import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_workspace_screen.dart';

/// Legacy route kept for compatibility.
/// Delegates to the new Assignment Workspace screen.
class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentAssignmentWorkspaceScreen();
  }
}
