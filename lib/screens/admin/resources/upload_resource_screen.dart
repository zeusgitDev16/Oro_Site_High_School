import 'package:flutter/material.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Computer Science';
  String _selectedVisibility = 'Public';
  bool _allowDownload = true;
  bool _requireLogin = false;

  final List<String> _categories = ['Computer Science', 'Mathematics', 'Science', 'Language', 'Arts', 'Other'];
  final List<String> _visibilityOptions = ['Public', 'Private', 'Restricted'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Resource')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Resource Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              child: InkWell(
                onTap: () {
                  // TODO: Implement file picker
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File picker will be implemented')));
                },
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text('Click to upload file', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Supported: PDF, DOC, PPT, Video, Images', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Resource Title *', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Access Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVisibility,
              decoration: const InputDecoration(labelText: 'Visibility', border: OutlineInputBorder()),
              items: _visibilityOptions.map((vis) => DropdownMenuItem(value: vis, child: Text(vis))).toList(),
              onChanged: (value) => setState(() => _selectedVisibility = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow downloads'),
              subtitle: const Text('Users can download this resource'),
              value: _allowDownload,
              onChanged: (value) => setState(() => _allowDownload = value),
            ),
            SwitchListTile(
              title: const Text('Require login'),
              subtitle: const Text('Only logged-in users can access'),
              value: _requireLogin,
              onChanged: (value) => setState(() => _requireLogin = value),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _uploadResource,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Resource'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _uploadResource() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement backend upload
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource uploaded successfully!')));
      Navigator.pop(context);
    }
  }
}
