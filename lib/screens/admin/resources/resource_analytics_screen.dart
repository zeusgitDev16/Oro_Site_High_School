import 'package:flutter/material.dart';

class ResourceAnalyticsScreen extends StatelessWidget {
  const ResourceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsData = {
      'totalResources': 182,
      'totalDownloads': 3456,
      'totalViews': 8923,
      'storageUsed': '2.4 GB',
      'topResources': [
        {'title': 'Math Tutorial Video', 'downloads': 412, 'views': 1245},
        {'title': 'Introduction to Programming', 'downloads': 245, 'views': 892},
        {'title': 'Physics Lab Manual', 'downloads': 189, 'views': 567},
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Analytics'),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Resources', '${analyticsData['totalResources']}', Icons.library_books, Colors.blue),
              _buildStatCard('Total Downloads', '${analyticsData['totalDownloads']}', Icons.download, Colors.green),
              _buildStatCard('Total Views', '${analyticsData['totalViews']}', Icons.visibility, Colors.orange),
              _buildStatCard('Storage Used', analyticsData['storageUsed'] as String, Icons.storage, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Most Popular Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...(analyticsData['topResources'] as List).map((resource) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.star)),
                      title: Text(resource['title'] as String),
                      subtitle: Text('${resource['downloads']} downloads • ${resource['views']} views'),
                      trailing: const Icon(Icons.trending_up, color: Colors.green),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
