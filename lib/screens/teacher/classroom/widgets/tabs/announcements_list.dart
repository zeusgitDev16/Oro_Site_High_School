import 'package:flutter/material.dart';

class MyAnnouncementsListPane extends StatelessWidget {
  const MyAnnouncementsListPane({
    super.key,
    required this.isLoading,
    required this.announcements,
    required this.selectedAnnouncementId,
    required this.formatLongDate,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  final bool isLoading;
  final List<Map<String, dynamic>> announcements;
  final String? selectedAnnouncementId;
  final String Function(DateTime) formatLongDate;

  final void Function(Map<String, dynamic> a) onReply;
  final void Function(Map<String, dynamic> a) onEdit;
  final Future<void> Function(Map<String, dynamic> a) onDelete;
  final void Function(Map<String, dynamic> a) onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
          ? Center(
              child: Text(
                'No announcements yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: announcements.length,
              itemBuilder: (ctx, i) {
                final a = announcements[i];
                final isSelected = selectedAnnouncementId == a['id'];
                return Card(
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  child: ListTile(
                    title: Text(
                      a['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          a['body'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a['createdAt'] != null
                              ? 'posted at: ${formatLongDate(a['createdAt'] as DateTime)}'
                              : '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => onReply(a),
                            icon: const Icon(Icons.reply_outlined, size: 16),
                            label: const Text('Reply'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'edit') {
                          onEdit(a);
                        } else if (val == 'delete') {
                          await onDelete(a);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => onTap(a),
                  ),
                );
              },
            ),
    );
  }
}
