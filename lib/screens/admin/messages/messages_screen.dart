import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/compose_message_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/broadcast_dialog.dart';

/// Admin Messages Screen - Full messaging interface with folders, labels, and threads
/// Enhanced with admin-specific features: broadcast, templates, announcements
class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  late final MessagesState state;

  @override
  void initState() {
    super.initState();
    state = MessagesState()..initMockData();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            // Broadcast button (Admin-specific)
            IconButton(
              icon: const Icon(Icons.campaign),
              onPressed: () {
                _showBroadcastDialog(context);
              },
              tooltip: 'Broadcast Message',
            ),
            // Compose button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ComposeMessageDialog(state: state),
                );
              },
              tooltip: 'Compose Message',
            ),
          ],
        ),
        body: Row(
          children: [
            _buildLeftSidebar(),
            const VerticalDivider(width: 1),
            Expanded(flex: 2, child: _buildThreadList()),
            const VerticalDivider(width: 1),
            Expanded(flex: 3, child: _buildMessageView()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 240,
      color: Colors.grey.shade50,
      child: Consumer<MessagesState>(
        builder: (context, state, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compose button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ComposeMessageDialog(state: state),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Compose'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Broadcast button (Admin-specific)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showBroadcastDialog(context);
                    },
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('Broadcast'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const Divider(height: 24),
              // Folders
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'FOLDERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...state.folders.map((folder) {
                      final isSelected = state.selectedFolder == folder.name;
                      return _buildSidebarItem(
                        icon: folder.icon,
                        label: folder.name,
                        isSelected: isSelected,
                        onTap: () => state.selectFolder(folder.name),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'LABELS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...state.labels.map((label) {
                      final isActive = state.activeLabelIds.contains(label.id);
                      return _buildSidebarItem(
                        icon: Icons.label,
                        label: label.name,
                        isSelected: isActive,
                        color: label.color,
                        onTap: () => state.toggleLabel(label.id),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: color ?? (isSelected ? Colors.teal : Colors.grey.shade600),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThreadList() {
    return Consumer<MessagesState>(
      builder: (context, state, _) {
        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onChanged: state.updateSearch,
              ),
            ),
            const Divider(height: 1),
            // Thread list
            Expanded(
              child: state.filteredThreads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No messages',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.filteredThreads.length,
                      itemBuilder: (context, index) {
                        final thread = state.filteredThreads[index];
                        final isSelected = state.selectedThread?.id == thread.id;
                        return _buildThreadItem(thread, isSelected, state);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThreadItem(Thread thread, bool isSelected, MessagesState state) {
    final lastMessage = thread.messages.isNotEmpty ? thread.messages.last : null;
    final isUnread = thread.unreadCount > 0;
    final otherParticipants = thread.participants
        .where((p) => p.id != 'u1')
        .map((p) => p.name)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? Colors.teal : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: thread.isAnnouncement
                  ? Colors.teal.shade100
                  : Colors.blue.shade100,
              child: Icon(
                thread.isAnnouncement ? Icons.campaign : Icons.person,
                color: thread.isAnnouncement
                    ? Colors.teal.shade700
                    : Colors.blue.shade700,
                size: 20,
              ),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (thread.pinned)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
              ),
            if (thread.isAnnouncement)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BROADCAST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                thread.subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (thread.starred)
              Icon(Icons.star, size: 16, color: Colors.amber.shade700),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherParticipants.isEmpty ? 'Me' : otherParticipants,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (lastMessage != null)
              Text(
                lastMessage.body,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text(
          _formatTime(thread.lastMessageAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        onTap: () => state.selectThread(thread),
      ),
    );
  }

  Widget _buildMessageView() {
    return Consumer<MessagesState>(
      builder: (context, state, _) {
        final thread = state.selectedThread;
        if (thread == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Select a conversation',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildMessageHeader(thread, state),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: thread.messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(thread.messages[index]);
                },
              ),
            ),
            const Divider(height: 1),
            if (!thread.isAnnouncement || !thread.locked)
              _buildMessageComposer(state),
          ],
        );
      },
    );
  }

  Widget _buildMessageHeader(Thread thread, MessagesState state) {
    final otherParticipants = thread.participants
        .where((p) => p.id != 'u1')
        .map((p) => p.name)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (thread.isAnnouncement)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign,
                                size: 14, color: Colors.teal.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'ANNOUNCEMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (thread.requireAck)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'REQUIRES ACK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  thread.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thread.isAnnouncement
                      ? 'Broadcast to: ${otherParticipants}'
                      : 'To: $otherParticipants',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              thread.starred ? Icons.star : Icons.star_border,
              color: thread.starred ? Colors.amber.shade700 : null,
            ),
            onPressed: () => state.toggleStar(thread),
            tooltip: 'Star',
          ),
          IconButton(
            icon: Icon(
              thread.locked ? Icons.lock : Icons.lock_open,
              color: thread.locked ? Colors.red : null,
            ),
            onPressed: () => state.toggleLock(thread),
            tooltip: thread.locked ? 'Unlock' : 'Lock',
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => state.toggleArchive(thread),
            tooltip: 'Archive',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete conversation?'),
                  content: const Text(
                      'This conversation will be permanently deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        state.deleteThread(thread);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Msg message) {
    final isAdmin = message.author.id == 'u1';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                message.author.initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      message.author.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.teal.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.body,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(MessagesState state) {
    final controller = TextEditingController(text: state.composerText);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PopupMenuButton<Template>(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Insert template',
            itemBuilder: (context) {
              return state.templates.map((template) {
                return PopupMenuItem<Template>(
                  value: template,
                  child: Text(template.name),
                );
              }).toList();
            },
            onSelected: (template) {
              state.insertTemplateIntoComposer(template.body);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onChanged: (value) => state.composerText = value,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                state.sendMessage(controller.text);
              }
            },
            color: Colors.teal,
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) async {
    final result = await showDialog<BroadcastResult>(
      context: context,
      builder: (context) => AdminBroadcastDialog(state: state),
    );

    if (result != null) {
      state.createBroadcast(
        subject: result.subject,
        body: result.body,
        disableReplies: result.disableReplies,
        requireAck: result.requireAck,
        targets: result.targets,
        scheduleAt: result.scheduleAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
