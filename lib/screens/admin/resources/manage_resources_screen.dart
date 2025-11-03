import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/admin/resources/resource_preview_dialog.dart';

class ManageResourcesScreen extends StatefulWidget {
  const ManageResourcesScreen({super.key});

  @override
  State<ManageResourcesScreen> createState() => _ManageResourcesScreenState();
}

class _ManageResourcesScreenState extends State<ManageResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCategory;

  final List<Map<String, dynamic>> _allResources = [
    {'id': 1, 'title': 'Introduction to Programming', 'type': 'PDF', 'category': 'Computer Science', 'size': '2.5 MB', 'downloads': 245, 'uploadDate': '2024-01-15', 'uploadedBy': 'Mr. Juan Dela Cruz'},
    {'id': 2, 'title': 'Physics Lab Manual', 'type': 'PDF', 'category': 'Science', 'size': '5.8 MB', 'downloads': 189, 'uploadDate': '2024-01-10', 'uploadedBy': 'Ms. Maria Santos'},
    {'id': 3, 'title': 'Math Tutorial Video', 'type': 'Video', 'category': 'Mathematics', 'size': '125 MB', 'downloads': 412, 'uploadDate': '2024-01-05', 'uploadedBy': 'Mr. Pedro Garcia'},
    {'id': 4, 'title': 'English Grammar Guide', 'type': 'Document', 'category': 'Language', 'size': '1.2 MB', 'downloads': 156, 'uploadDate': '2023-12-20', 'uploadedBy': 'Mrs. Ana Reyes'},
    {'id': 5, 'title': 'Chemistry Experiments', 'type': 'PDF', 'category': 'Science', 'size': '3.2 MB', 'downloads': 178, 'uploadDate': '2024-01-12', 'uploadedBy': 'Ms. Maria Santos'},
    {'id': 6, 'title': 'History Timeline', 'type': 'Image', 'category': 'Social Studies', 'size': '1.8 MB', 'downloads': 92, 'uploadDate': '2024-01-08', 'uploadedBy': 'Mr. Carlos Lopez'},
  ];

  List<Map<String, dynamic>> get _filteredResources {
    var resources = List<Map<String, dynamic>>.from(_allResources);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      resources = resources.where((resource) {
        final title = resource['title'].toString().toLowerCase();
        final category = resource['category'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || category.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      resources = resources.where((r) => r['category'] == _selectedCategory).toList();
    }

    return resources;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Manage All Resources'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Documents'),
              Tab(text: 'Videos'),
              Tab(text: 'Images'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportResourceList,
            tooltip: 'Export List',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResourceList(_filteredResources),
                _buildResourceList(_filteredResources.where((r) => r['type'] == 'PDF' || r['type'] == 'Document').toList()),
                _buildResourceList(_filteredResources.where((r) => r['type'] == 'Video').toList()),
                _buildResourceList(_filteredResources.where((r) => r['type'] == 'Image').toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadResource,
        icon: const Icon(Icons.upload),
        label: const Text('Upload Resource'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Categories')),
                DropdownMenuItem(value: 'Computer Science', child: Text('Computer Science')),
                DropdownMenuItem(value: 'Science', child: Text('Science')),
                DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                DropdownMenuItem(value: 'Language', child: Text('Language')),
                DropdownMenuItem(value: 'Social Studies', child: Text('Social Studies')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList(List<Map<String, dynamic>> resources) {
    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No resources found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or upload a new resource',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(resource['type']),
              child: Icon(_getTypeIcon(resource['type']), color: Colors.white, size: 20),
            ),
            title: Text(resource['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(resource['category'] as String, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${resource['size']} • ${resource['downloads']} downloads',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded by ${resource['uploadedBy']} on ${resource['uploadDate']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _previewResource(resource),
                  tooltip: 'Preview',
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(children: [Icon(Icons.download, size: 18), SizedBox(width: 8), Text('Download')]),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')]),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                  onSelected: (value) => _handleResourceAction(value as String, resource),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Video': return Icons.video_library;
      case 'Document': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PDF': return Colors.red;
      case 'Video': return Colors.purple;
      case 'Document': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _handleResourceAction(String action, Map<String, dynamic> resource) {
    switch (action) {
      case 'download':
        _downloadResource(resource);
        break;
      case 'share':
        _shareResource(resource);
        break;
      case 'edit':
        _editResource(resource);
        break;
      case 'delete':
        _showDeleteDialog(resource);
        break;
    }
  }

  void _previewResource(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => ResourcePreviewDialog(resource: resource),
    );
  }

  void _downloadResource(Map<String, dynamic> resource) {
    // TODO: Implement actual file download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${resource['title']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareResource(Map<String, dynamic> resource) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share link copied for ${resource['title']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editResource(Map<String, dynamic> resource) {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${resource['title']}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource['title']}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call ResourceService().deleteResource()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _uploadResource() {
    // TODO: Navigate to upload screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload Resource - Coming Soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportResourceList() {
    // TODO: Export to Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting resource list...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
