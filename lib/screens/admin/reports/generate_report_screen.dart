import 'package:flutter/material.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedReportType = 'Student Performance';
  String _selectedFormat = 'PDF';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeCharts = true;
  bool _includeRawData = false;

  final List<String> _reportTypes = [
    'Student Performance',
    'Course Enrollment',
    'User Activity',
    'Financial Summary',
    'Attendance Report',
    'Grade Distribution',
  ];

  final List<String> _formats = ['PDF', 'Excel', 'CSV'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Report Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: const InputDecoration(labelText: 'Report Type *', border: OutlineInputBorder()),
              items: _reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _selectedReportType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(labelText: 'Export Format *', border: OutlineInputBorder()),
              items: _formats.map((format) => DropdownMenuItem(value: format, child: Text(format))).toList(),
              onChanged: (value) => setState(() => _selectedFormat = value!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Date Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate == null ? 'Not set' : _startDate.toString().split(' ')[0]),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate == null ? 'Not set' : _endDate.toString().split(' ')[0]),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Report Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Include charts and graphs'),
              value: _includeCharts,
              onChanged: (value) => setState(() => _includeCharts = value),
            ),
            SwitchListTile(
              title: const Text('Include raw data'),
              value: _includeRawData,
              onChanged: (value) => setState(() => _includeRawData = value),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Generate Report'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateReport() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement backend generation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generating Report'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while we generate your report...'),
            ],
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated successfully!')));
      });
    }
  }
}
