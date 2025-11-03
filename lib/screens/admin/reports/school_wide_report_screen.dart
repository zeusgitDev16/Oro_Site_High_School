import 'package:flutter/material.dart';

/// School-Wide Report Screen - Placeholder
/// UI-only component following OSHS architecture
class SchoolWideReportScreen extends StatelessWidget {
  const SchoolWideReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School-Wide Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text('School-Wide Report - Coming Soon'),
      ),
    );
  }
}
