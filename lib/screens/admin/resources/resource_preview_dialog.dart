import 'package:flutter/material.dart';

class ResourcePreviewDialog extends StatelessWidget {
  final Map<String, dynamic> resource;

  const ResourcePreviewDialog({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getTypeColor(resource['type']).withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(resource['type']),
                    size: 32,
                    color: _getTypeColor(resource['type']),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${resource['type']} • ${resource['size']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resource Info
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    // Preview Area
                    _buildPreviewArea(),
                    const SizedBox(height: 24),
                    // Statistics
                    _buildStatistics(),
                  ],
                ),
              ),
            ),
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Share resource
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Download resource
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resource Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', resource['category'] as String),
            _buildInfoRow('Uploaded By', resource['uploadedBy'] as String),
            _buildInfoRow('Upload Date', resource['uploadDate'] as String),
            _buildInfoRow('File Size', resource['size'] as String),
            _buildInfoRow('Downloads', '${resource['downloads']} times'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    final type = resource['type'] as String;

    return Card(
      child: Container(
        width: double.infinity,
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTypeIcon(type),
              size: 64,
              color: _getTypeColor(type),
            ),
            const SizedBox(height: 16),
            Text(
              _getPreviewMessage(type),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (type == 'PDF' || type == 'Document')
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open in viewer
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in Viewer'),
              ),
            if (type == 'Video')
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Play video
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Play Video'),
              ),
            if (type == 'Image')
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: View full image
                },
                icon: const Icon(Icons.zoom_in, size: 18),
                label: const Text('View Full Size'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Downloads',
            resource['downloads'].toString(),
            Icons.download,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Views',
            '${(resource['downloads'] as int) * 2}',
            Icons.visibility,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Shares',
            '${(resource['downloads'] as int) ~/ 3}',
            Icons.share,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Video':
        return Icons.video_library;
      case 'Document':
        return Icons.description;
      case 'Image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'Video':
        return Colors.purple;
      case 'Document':
        return Colors.blue;
      case 'Image':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPreviewMessage(String type) {
    switch (type) {
      case 'PDF':
        return 'PDF preview will be displayed here.\nClick "Open in Viewer" to view the full document.';
      case 'Video':
        return 'Video preview will be displayed here.\nClick "Play Video" to watch.';
      case 'Document':
        return 'Document preview will be displayed here.\nClick "Open in Viewer" to view the full document.';
      case 'Image':
        return 'Image preview will be displayed here.\nClick "View Full Size" to see the full image.';
      default:
        return 'File preview not available.\nClick "Download" to view the file.';
    }
  }
}
