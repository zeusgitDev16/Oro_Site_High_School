import 'package:flutter/material.dart';
import '../../models/resource_type.dart';
import '../../models/subject_resource.dart';

/// Small, minimalist resource section widget
/// Displays a list of resources for a specific type (modules, assignment resources, or assignments)
class ResourceSectionWidget extends StatelessWidget {
  final ResourceType resourceType;
  final List<SubjectResource> resources;
  final VoidCallback onUpload;
  final Function(SubjectResource) onDownload;
  final Function(SubjectResource) onDelete;
  final bool canUpload;
  final bool canDelete;

  const ResourceSectionWidget({
    super.key,
    required this.resourceType,
    required this.resources,
    required this.onUpload,
    required this.onDownload,
    required this.onDelete,
    this.canUpload = true,
    this.canDelete = true,
  });

  MaterialColor get _sectionColor {
    switch (resourceType) {
      case ResourceType.module:
        return Colors.green;
      case ResourceType.assignmentResource:
        return Colors.orange;
      case ResourceType.assignment:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _sectionColor.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border(
                bottom: BorderSide(color: _sectionColor.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(_getIcon(), size: 14, color: _sectionColor.shade700),
                const SizedBox(width: 6),
                Text(
                  resourceType.pluralName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _sectionColor.shade900,
                  ),
                ),
                const Spacer(),
                if (canUpload)
                  InkWell(
                    onTap: onUpload,
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _sectionColor.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _sectionColor.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.upload_file,
                        size: 12,
                        color: _sectionColor.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Resource list
          if (resources.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No ${resourceType.pluralName.toLowerCase()} yet',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...resources.map((resource) => _buildResourceItem(resource)),
        ],
      ),
    );
  }

  Widget _buildResourceItem(SubjectResource resource) {
    return InkWell(
      onTap: () => onDownload(resource),
      hoverColor: Colors.grey.shade50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(resource.fileType),
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.resourceName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${resource.fileSizeFormatted} • v${resource.version}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (canDelete)
              InkWell(
                onTap: () => onDelete(resource),
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.red.shade200, width: 0.5),
                  ),
                  child: Icon(
                    Icons.delete,
                    size: 10,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (resourceType) {
      case ResourceType.module:
        return Icons.book;
      case ResourceType.assignmentResource:
        return Icons.description;
      case ResourceType.assignment:
        return Icons.assignment;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image;
      case 'mp4':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}
