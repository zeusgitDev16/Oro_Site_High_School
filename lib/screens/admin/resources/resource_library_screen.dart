import 'package:flutter/material.dart';

class ResourceLibraryScreen extends StatelessWidget {
  const ResourceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final folders = [
      {'name': 'Course Materials', 'items': 45, 'icon': Icons.school},
      {'name': 'Lecture Notes', 'items': 38, 'icon': Icons.note},
      {'name': 'Video Tutorials', 'items': 52, 'icon': Icons.video_library},
      {'name': 'Practice Exercises', 'items': 67, 'icon': Icons.assignment},
      {'name': 'Reference Books', 'items': 29, 'icon': Icons.menu_book},
      {'name': 'Lab Manuals', 'items': 18, 'icon': Icons.science},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return Card(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${folder['name']}')));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(folder['icon'] as IconData, size: 48, color: Colors.blue),
                    const SizedBox(height: 12),
                    Text(
                      folder['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${folder['items']} items',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
