import 'package:flutter/material.dart';

class MyRepliesPane extends StatelessWidget {
  const MyRepliesPane({
    super.key,
    required this.selectedAnnouncementId,
    required this.announcements,
    required this.replies,
    required this.teacherId,
    required this.formatAmPm,
    required this.onDelete,
  });

  final String? selectedAnnouncementId;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> replies;
  final String? teacherId;
  final String Function(DateTime) formatAmPm;
  final Future<void> Function(int replyId) onDelete;

  String _announcementTitle() {
    if (selectedAnnouncementId == null) return '';
    try {
      final match = announcements.firstWhere(
        (a) => a['id'].toString() == selectedAnnouncementId,
      );
      return (match['title'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'replies',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: (selectedAnnouncementId == null)
              ? Center(
                  child: Text(
                    'Select an announcement to view replies',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: replies.length + 1, // +1 for banner
                  itemBuilder: (ctx, i) {
                    // Small messenger-style reply banner at top
                    if (i == 0) {
                      final title = _announcementTitle();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_outlined,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'replying to',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  title.isEmpty ? 'announcement' : title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final r = replies[i - 1];
                    final bool isMine = (r['authorId']?.toString() == teacherId);
                    final String authorName = (r['authorName'] ?? (isMine ? 'You' : 'User')).toString();
                    final Alignment bubbleAlign = isMine ? Alignment.centerRight : Alignment.centerLeft;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMine)
                            const CircleAvatar(
                              radius: 12,
                              child: Icon(Icons.person, size: 14),
                            ),
                          if (!isMine) const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: bubbleAlign,
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  // Author name (always visible above bubble)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                                    child: Text(
                                      authorName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  // Bubble
                                  GestureDetector(
                                    onLongPress: () async {
                                      final didDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete message'),
                                          content: const Text('Are you sure you want to delete this message?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (didDelete == true && r['id'] != null) {
                                        final id = (r['id'] is int)
                                            ? r['id'] as int
                                            : int.tryParse(r['id'].toString()) ?? -1;
                                        if (id > 0) {
                                          await onDelete(id);
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMine
                                            ? Colors.blue.shade50
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Message content or deleted placeholder
                                          Text(
                                            (r['isDeleted'] == true)
                                                ? 'deleted message'
                                                : (r['content'] ?? ''),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: (r['isDeleted'] == true)
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              color: (r['isDeleted'] == true)
                                                  ? Colors.grey.shade600
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r['createdAt'] != null
                                                ? formatAmPm(r['createdAt'] as DateTime)
                                                : '',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
