import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/compose_message_dialog.dart';

/// NEO LMS-style Message Detail Dialog
/// Shows full message content with Reply/Forward/Delete actions
class MessageDetailDialog extends StatefulWidget {
  final Thread thread;
  final MessagesState state;

  const MessageDetailDialog({
    super.key,
    required this.thread,
    required this.state,
  });

  @override
  State<MessageDetailDialog> createState() => _MessageDetailDialogState();
}

class _MessageDetailDialogState extends State<MessageDetailDialog> {
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    widget.thread.unreadCount = 0;
    widget.state.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.thread.messages.isNotEmpty
        ? widget.thread.messages[_currentMessageIndex]
        : null;

    if (message == null) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Text('No message content'),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Message from ${message.author.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              widget.thread.subject,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // From
            Row(
              children: [
                const Text(
                  'From:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue,
                  child: Text(
                    message.author.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.author.name,
                  style: const TextStyle(color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  '@ ${_formatTimestamp(message.createdAt)} (${_getRelativeTime(message.createdAt)})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // To (recipients)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...widget.thread.participants.take(4).map((p) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            p.initials,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        label: Text(p.name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )),
                      if (widget.thread.participants.length > 4)
                        InkWell(
                          onTap: () => _showAllRecipients(context),
                          child: Text(
                            'and ${widget.thread.participants.length - 4} more ...',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message body
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message.body,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation arrows
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentMessageIndex > 0
                          ? () => setState(() => _currentMessageIndex--)
                          : null,
                      tooltip: 'Previous message',
                    ),
                    Text(
                      '${_currentMessageIndex + 1} of ${widget.thread.messages.length}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentMessageIndex < widget.thread.messages.length - 1
                          ? () => setState(() => _currentMessageIndex++)
                          : null,
                      tooltip: 'Next message',
                    ),
                  ],
                ),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Reply'),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => ComposeMessageDialog(
                            state: widget.state,
                            replyTo: widget.thread,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.forward, size: 18),
                      label: const Text('Forward'),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => ComposeMessageDialog(
                            state: widget.state,
                            forwardFrom: widget.thread,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      onPressed: () => _confirmDelete(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllRecipients(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'All Recipients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.thread.participants.length,
                  itemBuilder: (context, index) {
                    final p = widget.thread.participants[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(p.initials, style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(p.name),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.state.deleteThread(widget.thread);
              Navigator.pop(context); // Close confirm dialog
              Navigator.pop(context); // Close message detail dialog
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.month}/${dt.day}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'pm' : 'am'}';
  }

  String _getRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}
