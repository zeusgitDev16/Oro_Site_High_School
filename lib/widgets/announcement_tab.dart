import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementTab extends StatefulWidget {
  final String classroomId;
  final String courseId;

  const AnnouncementTab({
    super.key,
    required this.classroomId,
    required this.courseId,
  });

  @override
  State<AnnouncementTab> createState() => _AnnouncementTabState();
}

class _AnnouncementTabState extends State<AnnouncementTab> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _announcements = [];
  Map<String, List<Map<String, dynamic>>> _announcementReplies = {};
  String? _selectedAnnouncementId;
  final TextEditingController _replyCtrl = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _isLoadingAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final rows = await supabase
          .from('announcements')
          .select()
          .eq('classroom_id', widget.classroomId)
          .eq('course_id', widget.courseId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rows,
      );

      setState(() {
        _announcements = list;
        if (_announcements.isNotEmpty) {
          _selectedAnnouncementId = _announcements.first['id'].toString();
          _loadReplies(_selectedAnnouncementId!);
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading announcements: $e');
    } finally {
      setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> _loadReplies(String announcementId) async {
    try {
      final rows = await supabase.rpc(
        'get_replies_with_author',
        params: {'p_announcement_id': int.parse(announcementId)},
      );

      final replies = List<Map<String, dynamic>>.from(rows as List);
      setState(() {
        _announcementReplies[announcementId] = replies;
      });
    } catch (e) {
      debugPrint('❌ Error loading replies: $e');
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _selectedAnnouncementId == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('announcement_replies').insert({
        'announcement_id': int.parse(_selectedAnnouncementId!),
        'author_id': user.id,
        'content': text,
        'is_deleted': false,
      });

      // Optimistic UI update
      setState(() {
        final currentReplies =
            _announcementReplies[_selectedAnnouncementId!] ?? [];
        currentReplies.add({
          'author_id': user.id,
          'author_name': 'You',
          'content': text,
          'created_at': DateTime.now().toIso8601String(),
        });
        _announcementReplies[_selectedAnnouncementId!] = currentReplies;
      });

      _replyCtrl.clear();
      _replyFocus.requestFocus();
    } catch (e) {
      debugPrint('❌ Error sending reply: $e');
    }
  }

  String _formatLongDate(DateTime dt) {
    final month = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][dt.month];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$month ${dt.day}, ${dt.year}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Announcements list
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'announcements',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoadingAnnouncements
                    ? const Center(child: CircularProgressIndicator())
                    : _announcements.isEmpty
                    ? Center(
                        child: Text(
                          'No announcements yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _announcements.length,
                        itemBuilder: (ctx, i) {
                          final a = _announcements[i];
                          final isSelected =
                              _selectedAnnouncementId == a['id'].toString();
                          final DateTime createdAt =
                              DateTime.tryParse(a['created_at'] ?? '') ??
                              DateTime.now();
                          return Card(
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            child: ListTile(
                              title: Text(
                                a['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                    'posted at: ${_formatLongDate(createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedAnnouncementId = a['id']
                                              .toString();
                                        });
                                        _loadReplies(_selectedAnnouncementId!);
                                        Future.microtask(
                                          () => _replyFocus.requestFocus(),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.reply_outlined,
                                        size: 16,
                                      ),
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Divider
        Container(width: 1, color: Colors.grey.shade300),

        // Right: Replies panel
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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

              Expanded(
                child: (_selectedAnnouncementId == null)
                    ? Center(
                        child: Text(
                          'Select an announcement to view replies',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            (_announcementReplies[_selectedAnnouncementId!] ??
                                    const [])
                                .length +
                            1,
                        itemBuilder: (ctx, i) {
                          final list =
                              _announcementReplies[_selectedAnnouncementId!] ??
                              const [];

                          if (i == 0) {
                            // Replying to banner
                            String title = '';
                            try {
                              final match = _announcements.firstWhere(
                                (a) =>
                                    a['id'].toString() ==
                                    _selectedAnnouncementId,
                              );
                              title = (match['title'] ?? '').toString();
                            } catch (_) {}
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
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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

                          final r = list[i - 1];
                          final String? me = supabase.auth.currentUser?.id;
                          final bool isMine =
                              (me != null && r['author_id']?.toString() == me);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMine)
                                  const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.person, size: 14),
                                  ),
                                if (!isMine) const SizedBox(width: 8),

                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['author_name'] ?? 'Unknown Author',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: isMine
                                                ? const Radius.circular(12)
                                                : const Radius.circular(4),
                                            bottomRight: isMine
                                                ? const Radius.circular(4)
                                                : const Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          (r['content'] ?? '').toString(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r['created_at'] != null
                                            ? _formatLongDate(
                                                DateTime.parse(r['created_at']),
                                              )
                                            : '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMine) const SizedBox(width: 8),
                                if (isMine)
                                  const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.person, size: 14),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Reply composer
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _replyCtrl,
                          focusNode: _replyFocus,
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: _selectedAnnouncementId == null
                                ? 'Select an announcement first'
                                : 'Aa',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sendReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
