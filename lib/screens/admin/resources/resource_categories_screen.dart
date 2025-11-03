import 'package:flutter/material.dart';

class ResourceCategoriesScreen extends StatefulWidget {
  const ResourceCategoriesScreen({super.key});

  @override
  State<ResourceCategoriesScreen> createState() => _ResourceCategoriesScreenState();
}

class _ResourceCategoriesScreenState extends State<ResourceCategoriesScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Computer Science', 'resourceCount': 45, 'color': Colors.blue, 'active': true},
    {'id': 2, 'name': 'Mathematics', 'resourceCount': 38, 'color': Colors.green, 'active': true},
    {'id': 3, 'name': 'Science', 'resourceCount': 52, 'color': Colors.orange, 'active': true},
    {'id': 4, 'name': 'Language', 'resourceCount': 29, 'color': Colors.purple, 'active': true},
    {'id': 5, 'name': 'Arts', 'resourceCount': 18, 'color': Colors.pink, 'active': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resource Categories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder, color: category['color']),
              ),
              title: Text(category['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${category['resourceCount']} resources', style: TextStyle(color: Colors.grey.shade600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(value: category['active'], onChanged: (value) => setState(() => category['active'] = value)),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(category['name']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value ${category['name']}')));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Category added successfully')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
