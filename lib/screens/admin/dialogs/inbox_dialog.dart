import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/message_detail_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/compose_message_dialog.dart';

/// NEO LMS-style Inbox Dialog (dropdown from inbox icon)
/// Shows list of received messages with actions
class InboxDialog extends StatefulWidget {
  final MessagesState state;
  
  const InboxDialog({super.key, required this.state});

  @override
  State<InboxDialog> createState() => _InboxDialogState();
}

class _InboxDialogState extends State<InboxDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 60, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        height: 550,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Inbox',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Message list
            Expanded(
              child: widget.state.allThreads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.state.allThreads.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final thread = widget.state.allThreads[index];
                        final lastMessage = thread.messages.isNotEmpty 
                            ? thread.messages.last 
                            : null;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: thread.unreadCount > 0 ? Colors.blue : Colors.grey.shade300,
                            child: Text(
                              thread.participants.isNotEmpty
                                  ? thread.participants.first.initials
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  thread.participants.isNotEmpty
                                      ? thread.participants.first.name
                                      : 'Unknown',
                                  style: TextStyle(
                                    fontWeight: thread.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (thread.unreadCount > 0)
                                Icon(Icons.circle, size: 8, color: Colors.blue),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.subject,
                                style: TextStyle(
                                  fontWeight: thread.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTimestamp(lastMessage?.createdAt ?? thread.lastMessageAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: thread.unreadCount > 0
                              ? null
                              : Icon(Icons.check, size: 16, color: Colors.grey.shade400),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => MessageDetailDialog(
                                thread: thread,
                                state: widget.state,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('See all', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        // TODO: Navigate to full messages screen
                      },
                    ),
                  ),
                  Flexible(
                    child: TextButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark all read', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        for (var thread in widget.state.allThreads) {
                          thread.unreadCount = 0;
                        }
                        widget.state.notifyListeners();
                        setState(() {});
                      },
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New message', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => ComposeMessageDialog(state: widget.state),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: () {
                      // TODO: Open settings
                    },
                    tooltip: 'Configure',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${dt.month}/${dt.day}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'pm' : 'am'}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
