import 'package:flutter/material.dart';

class BulkOperationsScreen extends StatefulWidget {
  const BulkOperationsScreen({super.key});

  @override
  State<BulkOperationsScreen> createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Import Users', icon: Icon(Icons.upload_file)),
            Tab(text: 'Export Users', icon: Icon(Icons.download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Import Users',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a file to add multiple users at once',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text(
                  'Drag and drop your file here',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'or',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement file picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File picker will be implemented')),
                    );
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse Files'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Supported formats: CSV, Excel (.xlsx)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Import Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Send welcome emails'),
          subtitle: const Text('Notify users about their new accounts'),
          value: true,
          onChanged: (value) {
            // TODO: Implement toggle
          },
        ),
        CheckboxListTile(
          title: const Text('Skip duplicates'),
          subtitle: const Text('Don\'t import users that already exist'),
          value: true,
          onChanged: (value) {
            // TODO: Implement toggle
          },
        ),
        CheckboxListTile(
          title: const Text('Require password change'),
          subtitle: const Text('Users must change password on first login'),
          value: false,
          onChanged: (value) {
            // TODO: Implement toggle
          },
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
                      'Import Template',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Download a template file to see the required format for importing users.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Download template
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading template...')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Export Users',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Download user data in various formats',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select User Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildUserTypeCard('All Users', '1,245 users', Icons.people, Colors.blue),
        const SizedBox(height: 12),
        _buildUserTypeCard('Students', '980 users', Icons.school, Colors.blue),
        const SizedBox(height: 12),
        _buildUserTypeCard('Teachers', '45 users', Icons.person, Colors.green),
        const SizedBox(height: 12),
        _buildUserTypeCard('Admins', '12 users', Icons.admin_panel_settings, Colors.purple),
        const SizedBox(height: 12),
        _buildUserTypeCard('Parents', '208 users', Icons.family_restroom, Colors.orange),
        const SizedBox(height: 24),
        const Text(
          'Export Format',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormatButton('CSV', Icons.table_chart, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatButton('Excel', Icons.grid_on, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatButton('PDF', Icons.picture_as_pdf, Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Export Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Include email addresses'),
          value: true,
          onChanged: (value) {
            // TODO: Implement toggle
          },
        ),
        CheckboxListTile(
          title: const Text('Include enrollment data'),
          value: false,
          onChanged: (value) {
            // TODO: Implement toggle
          },
        ),
        CheckboxListTile(
          title: const Text('Include last login date'),
          value: true,
          onChanged: (value) {
            // TODO: Implement toggle
          },
        ),
      ],
    );
  }

  Widget _buildUserTypeCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Select user type
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton(String label, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Export with selected format
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exporting as $label...')),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
