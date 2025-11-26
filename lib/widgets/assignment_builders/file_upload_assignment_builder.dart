import 'package:flutter/material.dart';

/// File Upload Assignment Builder Widget
/// 
/// Reusable widget for building file upload assignments.
/// 
/// Content Structure:
/// ```json
/// {
///   "instructions": "Upload your project files",
///   "max_file_size": 10,
///   "max_files": 3,
///   "allowed_extensions": [".pdf", ".docx", ".zip"]
/// }
/// ```
/// 
/// Features:
/// - Set instructions
/// - Configure max file size (MB)
/// - Configure max files
/// - Optional allowed extensions
/// - Small text UI (10-12px)
/// - Manual grading required
class FileUploadAssignmentBuilder extends StatefulWidget {
  final Map<String, dynamic> initialContent;
  final ValueChanged<Map<String, dynamic>> onContentChanged;

  const FileUploadAssignmentBuilder({
    super.key,
    required this.initialContent,
    required this.onContentChanged,
  });

  @override
  State<FileUploadAssignmentBuilder> createState() =>
      _FileUploadAssignmentBuilderState();
}

class _FileUploadAssignmentBuilderState
    extends State<FileUploadAssignmentBuilder> {
  late TextEditingController _instructionsController;
  late TextEditingController _maxFileSizeController;
  late TextEditingController _maxFilesController;
  late TextEditingController _allowedExtensionsController;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController(
      text: widget.initialContent['instructions'] ?? 'Upload your files',
    );
    _maxFileSizeController = TextEditingController(
      text: (widget.initialContent['max_file_size'] ?? 10).toString(),
    );
    _maxFilesController = TextEditingController(
      text: (widget.initialContent['max_files'] ?? 3).toString(),
    );
    final extensions = widget.initialContent['allowed_extensions'] as List?;
    _allowedExtensionsController = TextEditingController(
      text: extensions?.join(', ') ?? '',
    );

    _instructionsController.addListener(_notifyChanges);
    _maxFileSizeController.addListener(_notifyChanges);
    _maxFilesController.addListener(_notifyChanges);
    _allowedExtensionsController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _maxFileSizeController.dispose();
    _maxFilesController.dispose();
    _allowedExtensionsController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    final extensions = _allowedExtensionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.onContentChanged({
      'instructions': _instructionsController.text,
      'max_file_size': int.tryParse(_maxFileSizeController.text) ?? 10,
      'max_files': int.tryParse(_maxFilesController.text) ?? 3,
      if (extensions.isNotEmpty) 'allowed_extensions': extensions,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'File Upload Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 12, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Manual Grading',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    labelStyle: TextStyle(fontSize: 11),
                    hintText: 'Enter instructions for file upload',
                    hintStyle: TextStyle(fontSize: 10),
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxFileSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max File Size (MB)',
                          labelStyle: TextStyle(fontSize: 11),
                          hintText: '10',
                          hintStyle: TextStyle(fontSize: 10),
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxFilesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Files',
                          labelStyle: TextStyle(fontSize: 11),
                          hintText: '3',
                          hintStyle: TextStyle(fontSize: 10),
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allowedExtensionsController,
                  decoration: const InputDecoration(
                    labelText: 'Allowed Extensions (Optional)',
                    labelStyle: TextStyle(fontSize: 11),
                    hintText: 'e.g., .pdf, .docx, .zip',
                    hintStyle: TextStyle(fontSize: 10),
                    helperText: 'Comma-separated. Leave empty to allow all.',
                    helperStyle: TextStyle(fontSize: 9),
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Students will upload files when submitting this assignment. You will need to manually grade their submissions.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

