import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_messages_logic.dart';
import 'package:oro_site_high_school/screens/student/dashboard/student_dashboard_screen.dart';
import 'package:intl/intl.dart';

/// Student Messages Screen
/// Three-column layout for viewing and replying to messages from teachers
/// UI only - logic in StudentMessagesLogic
class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({super.key});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  late StudentMessagesLogic _logic;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logic = StudentMessagesLogic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.loadMessages();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboardScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentDashboardScreen(),
                ),
              );
            },
          ),
        ),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) {
            if (_logic.isLoadingMessages) {
              return const Center(child: CircularProgressIndicator());
            }

            return Row(
              children: [
                _buildFolderSidebar(),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: _buildThreadList()),
                const VerticalDivider(width: 1),
                Expanded(flex: 3, child: _buildMessageView()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFolderSidebar() {
    return Container(
      width: 200,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Folders',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          _buildFolderItem('All', Icons.inbox_outlined),
          _buildFolderItem('Unread', Icons.markunread_outlined),
          _buildFolderItem('Starred', Icons.star_border),
          _buildFolderItem('Archived', Icons.archive_outlined),
        ],
      ),
    );
  }

  Widget _buildFolderItem(String name, IconData icon) {
    final isSelected = _logic.selectedFolder == name;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      leading: Icon(icon, size: 20, color: isSelected ? Colors.blue : Colors.grey.shade600),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.blue : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () => _logic.setFolder(name),
    );
  }

  Widget _buildThreadList() {
    final threads = _logic.getFilteredThreads();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search messages...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) => _logic.setSearchQuery(value),
          ),
        ),
        Expanded(
          child: threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No messages',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    final isSelected = _logic.selectedThreadId == thread['id'];
                    return _buildThreadItem(thread, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildThreadItem(Map<String, dynamic> thread, bool isSelected) {
    final sender = thread['sender'] as Map<String, dynamic>;
    final unreadCount = thread['unreadCount'] as int;
    final isUnread = unreadCount > 0;
    final lastMessageAt = thread['lastMessageAt'] as DateTime;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListTile(
        onTap: () => _logic.selectThread(thread['id']),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade700,
          child: Text(
            sender['initials'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sender['name'],
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              thread['subject'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(lastMessageAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (thread['starred'] == true)
              Icon(Icons.star, size: 16, color: Colors.amber.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageView() {
    if (_logic.selectedThreadId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Select a message to read',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final thread = _logic.getThreadById(_logic.selectedThreadId!);
    if (thread == null) {
      return const Center(child: Text('Message not found'));
    }

    final messages = thread['messages'] as List;

    return Column(
      children: [
        _buildMessageHeader(thread),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(messages[index]);
            },
          ),
        ),
        const Divider(height: 1),
        _buildReplyComposer(thread),
      ],
    );
  }

  Widget _buildMessageHeader(Map<String, dynamic> thread) {
    final sender = thread['sender'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade700,
            child: Text(
              sender['initials'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread['subject'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sender['name']} (${sender['role']})',
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
              thread['starred'] == true ? Icons.star : Icons.star_border,
              color: thread['starred'] == true ? Colors.amber.shade700 : null,
            ),
            onPressed: () => _logic.toggleStar(thread['id']),
            tooltip: 'Star',
          ),
          IconButton(
            icon: Icon(
              thread['archived'] == true ? Icons.unarchive : Icons.archive_outlined,
            ),
            onPressed: () => _logic.toggleArchive(thread['id']),
            tooltip: thread['archived'] == true ? 'Unarchive' : 'Archive',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromMe = message['isFromMe'] as bool;
    final timestamp = message['timestamp'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                message['senderName'].toString().split(' ').map((e) => e[0]).take(2).join(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromMe ? Colors.blue.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['senderName'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFromMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isFromMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message['body'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isFromMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Text(
                message['senderName'].toString().split(' ').map((e) => e[0]).take(2).join(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyComposer(Map<String, dynamic> thread) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blue,
            onPressed: () {
              if (_replyController.text.trim().isNotEmpty) {
                _logic.sendReply(thread['id'], _replyController.text.trim());
                _replyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reply sent!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
