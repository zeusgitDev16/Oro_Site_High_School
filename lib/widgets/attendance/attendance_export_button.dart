import 'package:flutter/material.dart';

/// Small button to export attendance to Excel (SF2 format)
///
/// **Features:**
/// - Compact button with download icon
/// - Loading state
/// - Disabled state
/// - Tooltip
///
/// **Usage:**
/// ```dart
/// AttendanceExportButton(
///   onExport: () async {
///     await _exportToExcel();
///   },
///   isEnabled: _students.isNotEmpty,
/// )
/// ```
class AttendanceExportButton extends StatelessWidget {
  final Future<void> Function() onExport;
  final bool isEnabled;

  const AttendanceExportButton({
    super.key,
    required this.onExport,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Export to Excel (SF2 Format)',
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: isEnabled ? () => onExport() : null,
          icon: const Icon(Icons.download, size: 16),
          label: const Text(
            'Export',
            style: TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}

