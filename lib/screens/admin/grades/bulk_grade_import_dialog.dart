import 'package:flutter/material.dart';

class BulkGradeImportDialog extends StatefulWidget {
  const BulkGradeImportDialog({super.key});

  @override
  State<BulkGradeImportDialog> createState() => _BulkGradeImportDialogState();
}

class _BulkGradeImportDialogState extends State<BulkGradeImportDialog> {
  String? _selectedFile;
  bool _isValidating = false;
  bool _isImporting = false;
  List<Map<String, dynamic>>? _previewData;
  Map<String, dynamic>? _validationResults;

  // Mock preview data
  final List<Map<String, dynamic>> _mockPreviewData = [
    {
      'lrn': '123456789012',
      'studentName': 'Juan Dela Cruz',
      'mathematics': 88,
      'science': 90,
      'english': 85,
      'status': 'valid',
    },
    {
      'lrn': '123456789013',
      'studentName': 'Maria Santos',
      'mathematics': 92,
      'science': 94,
      'english': 90,
      'status': 'valid',
    },
    {
      'lrn': '123456789014',
      'studentName': 'Pedro Garcia',
      'mathematics': 105,
      'science': 75,
      'english': 78,
      'status': 'invalid',
      'error': 'Mathematics grade exceeds 100',
    },
    {
      'lrn': '999999999999',
      'studentName': 'Unknown Student',
      'mathematics': 80,
      'science': 82,
      'english': 85,
      'status': 'invalid',
      'error': 'LRN not found in system',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Grade Import'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionsSection(),
            const SizedBox(height: 16),
            _buildFileSelectionSection(),
            const SizedBox(height: 16),
            if (_previewData != null) ...[
              _buildValidationResultsSection(),
              const SizedBox(height: 16),
              Expanded(child: _buildPreviewTable()),
            ] else
              Expanded(child: _buildEmptyState()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_previewData == null)
          ElevatedButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download Template'),
          ),
        if (_previewData != null && _validationResults != null)
          ElevatedButton(
            onPressed: (_isImporting || _validationResults!['invalidCount'] > 0)
                ? null
                : _importGrades,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Import Grades'),
          ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Import Instructions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Download the Excel template\n'
            '2. Fill in student LRN and grades (75-100)\n'
            '3. Upload the completed file\n'
            '4. Review validation results\n'
            '5. Import valid entries',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select File',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.insert_drive_file : Icons.upload_file,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile ?? 'No file selected',
                        style: TextStyle(
                          color: _selectedFile != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isValidating ? null : _selectFile,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Browse'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValidationResultsSection() {
    if (_validationResults == null) return const SizedBox.shrink();

    final validCount = _validationResults!['validCount'] as int;
    final invalidCount = _validationResults!['invalidCount'] as int;
    final totalCount = validCount + invalidCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: invalidCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: invalidCount > 0 ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validation Results',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildValidationStat('Total Entries', totalCount, Colors.blue),
              ),
              Expanded(
                child: _buildValidationStat('Valid', validCount, Colors.green),
              ),
              Expanded(
                child: _buildValidationStat('Invalid', invalidCount, Colors.red),
              ),
            ],
          ),
          if (invalidCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Please fix invalid entries before importing',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildPreviewTable() {
    if (_previewData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview (First 10 rows)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('LRN', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Math', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Science', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Error', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _previewData!.take(10).map((row) {
                final isValid = row['status'] == 'valid';
                return DataRow(
                  color: MaterialStateProperty.all(
                    isValid ? null : Colors.red.shade50,
                  ),
                  cells: [
                    DataCell(
                      Icon(
                        isValid ? Icons.check_circle : Icons.error,
                        color: isValid ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    DataCell(Text(row['lrn'])),
                    DataCell(Text(row['studentName'])),
                    DataCell(Text(row['mathematics'].toString())),
                    DataCell(Text(row['science'].toString())),
                    DataCell(Text(row['english'].toString())),
                    DataCell(
                      Text(
                        row['error'] ?? '',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No file selected',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an Excel file to preview and import grades',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading grade import template...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Generate and download Excel template
  }

  Future<void> _selectFile() async {
    setState(() {
      _isValidating = true;
    });

    // Simulate file selection and validation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _selectedFile = 'grades_import.xlsx';
      _previewData = _mockPreviewData;
      _validationResults = {
        'validCount': _mockPreviewData.where((d) => d['status'] == 'valid').length,
        'invalidCount': _mockPreviewData.where((d) => d['status'] == 'invalid').length,
      };
      _isValidating = false;
    });

    // TODO: Implement actual file picker
    // final result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['xlsx', 'xls', 'csv'],
    // );
  }

  Future<void> _importGrades() async {
    setState(() {
      _isImporting = true;
    });

    // Simulate import
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isImporting = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_validationResults!['validCount']} grades imported successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    // TODO: Call GradeService().bulkImportGrades()
  }
}
