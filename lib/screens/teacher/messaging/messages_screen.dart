import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oro_site_high_school/flow/teacher/messages/messages_state.dart';
import 'package:oro_site_high_school/screens/teacher/dialogs/compose_message_dialog.dart';

/// Teacher Messages Screen - Full messaging interface with folders, labels, and threads
/// Follows the same architecture as Admin messaging system
class MessagesScreen extends StatefulWidget {
  final String origin; // 'dashboard' or 'profile'

  const MessagesScreen({super.key, this.origin = 'dashboard'});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final TeacherMessagesState state;

  @override
  void initState() {
    super.initState();
    state = TeacherMessagesState()..initMockData();
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
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => TeacherComposeMessageDialog(state: state),
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
      child: Consumer<TeacherMessagesState>(
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
                        builder: (context) => TeacherComposeMessageDialog(state: state),
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
              const Divider(height: 1),
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
                      final count = folder.name == 'Unread'
                          ? state.getUnreadCount()
                          : null;
                      return _buildSidebarItem(
                        icon: folder.icon,
                        label: folder.name,
                        isSelected: isSelected,
                        count: count,
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
    int? count,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: color ?? (isSelected ? Colors.blue : Colors.grey.shade600),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: count != null && count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildThreadList() {
    return Consumer<TeacherMessagesState>(
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

  Widget _buildThreadItem(Thread thread, bool isSelected, TeacherMessagesState state) {
    final lastMessage = thread.messages.isNotEmpty ? thread.messages.last : null;
    final isUnread = thread.unreadCount > 0;
    final otherParticipants = thread.participants
        .where((p) => p.id != 'u1')
        .map((p) => p.name)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
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
              backgroundColor: Colors.blue.shade100,
              child: Text(
                thread.participants.length > 1
                    ? thread.participants[1].initials
                    : 'T',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherParticipants.isEmpty ? 'Me' : otherParticipants,
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
              thread.subject,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
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
    return Consumer<TeacherMessagesState>(
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
            _buildMessageComposer(state),
          ],
        );
      },
    );
  }

  Widget _buildMessageHeader(Thread thread, TeacherMessagesState state) {
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
                Text(
                  thread.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To: $otherParticipants',
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
    final isMe = message.author.id == 'u1';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
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
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    color: isMe ? Colors.blue.shade50 : Colors.grey.shade100,
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
          if (isMe) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(TeacherMessagesState state) {
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
            color: Colors.blue,
            tooltip: 'Send',
          ),
        ],
      ),
    );
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
