import 'package:flutter/material.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String _selectedDataType = 'Users';
  String _selectedFormat = 'CSV';
  bool _includeArchived = false;
  bool _includeMetadata = true;

  final List<String> _dataTypes = [
    'Users',
    'Courses',
    'Enrollments',
    'Grades',
    'Resources',
    'Groups',
  ];
  final List<String> _formats = ['CSV', 'Excel', 'JSON', 'XML'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Export Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedDataType,
            decoration: const InputDecoration(
              labelText: 'Data Type *',
              border: OutlineInputBorder(),
            ),
            items: _dataTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDataType = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedFormat,
            decoration: const InputDecoration(
              labelText: 'Export Format *',
              border: OutlineInputBorder(),
            ),
            items: _formats
                .map(
                  (format) =>
                      DropdownMenuItem(value: format, child: Text(format)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedFormat = value!),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Export Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Include archived data'),
            subtitle: const Text('Export data marked as archived'),
            value: _includeArchived,
            onChanged: (value) => setState(() => _includeArchived = value),
          ),
          SwitchListTile(
            title: const Text('Include metadata'),
            subtitle: const Text('Export additional metadata fields'),
            value: _includeMetadata,
            onChanged: (value) => setState(() => _includeMetadata = value),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Export Summary',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Data Type: $_selectedDataType',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Format: $_selectedFormat',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Estimated records: ~1,245',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement backend export
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporting Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing your export...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully!')),
      );
    });
  }
}
