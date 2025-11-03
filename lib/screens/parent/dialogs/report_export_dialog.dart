import 'package:flutter/material.dart';

/// Report Export Dialog - Options for exporting reports
/// Allows parent to choose export format and options
class ReportExportDialog extends StatefulWidget {
  final String reportType;
  final Function(String format, Map<String, bool> options) onExport;

  const ReportExportDialog({
    super.key,
    required this.reportType,
    required this.onExport,
  });

  @override
  State<ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends State<ReportExportDialog> {
  String _selectedFormat = 'PDF';
  final Map<String, bool> _options = {
    'includeCharts': true,
    'includeComments': true,
    'includeAttendance': true,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export ${widget.reportType}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('PDF'),
              value: 'PDF',
              groupValue: _selectedFormat,
              onChanged: (value) => setState(() => _selectedFormat = value!),
            ),
            RadioListTile<String>(
              title: const Text('Excel'),
              value: 'Excel',
              groupValue: _selectedFormat,
              onChanged: (value) => setState(() => _selectedFormat = value!),
            ),
            const Divider(),
            const Text(
              'Include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Charts'),
              value: _options['includeCharts'],
              onChanged: (value) => setState(() => _options['includeCharts'] = value!),
            ),
            CheckboxListTile(
              title: const Text('Teacher Comments'),
              value: _options['includeComments'],
              onChanged: (value) => setState(() => _options['includeComments'] = value!),
            ),
            CheckboxListTile(
              title: const Text('Attendance Records'),
              value: _options['includeAttendance'],
              onChanged: (value) => setState(() => _options['includeAttendance'] = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onExport(_selectedFormat, _options);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
