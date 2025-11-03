/// replies_example_code.dart
///
/// Purpose: Provide exact, idempotent code snippets to add to
/// lib/screens/teacher/classroom/my_classroom_screen.dart
/// focusing ONLY on the Announcements right pane (Replies).
///
/// How to use this file:
/// - Do NOT import it anywhere. It is only a copy/paste guide.
/// - Open my_classroom_screen.dart and use the search anchors and
///   copy the code blocks below into the specified places.
/// - After applying the changes, you may delete this file safely.
///
/// Prerequisites (already present in your codebase as per analysis):
/// - Replies mapping includes: {'id','authorId','content','isDeleted','createdAt'}
///   for both stream and preload.
/// - Database: public.announcement_replies has column is_deleted boolean NOT NULL DEFAULT false.

// =============================
// SEARCH ANCHORS (to locate spots)
// =============================
// 1) Replies ListView.builder in right pane:
//    Search: "Select an announcement to view replies"
//    OR:     "_announcementReplies[_selectedAnnouncementId!]"
//
// 2) Send handler for replies composer:
//    Search: "final text = _replyCtrl.text.trim();"
//    And near it: "_replyCtrl.clear();"

// ====================================================
// A) REPLIES LISTVIEW.BUILDER: HEADER + INDEX SHIFT PATCH
// ====================================================
// 1) Change the itemCount in the replies ListView.builder to add +1 (for header row):
//
// Replace your current itemCount with the following EXACT line:
const String REPLIES_ITEMCOUNT_PATCH = r'''
itemCount: ((_announcementReplies[_selectedAnnouncementId!] ?? const []).length) + 1,
''';

// 2) Add the header row guard and index shift at the TOP of itemBuilder:
//    Paste this block immediately inside itemBuilder, BEFORE computing `r`/`isMine`.
const String REPLIES_HEADER_AND_INDEX_SHIFT = r'''
// Preload replies list
final list = _announcementReplies[_selectedAnnouncementId!] ?? const [];

// Header row (index 0) — replying to card
if (i == 0) {
  String title = '';
  try {
    final match = _announcements.firstWhere(
      (a) => a['id'].toString() == _selectedAnnouncementId,
    );
    title = (match['title'] ?? '').toString();
  } catch (_) {}
  return Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
      ],
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: const ListTile(
      dense: true,
      leading: Icon(Icons.forum_outlined, color: Colors.blue),
      title: Text(
        'replying to',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
      // Subtitle set after title compute (title or 'announcement')
    ),
  );
}

// For all message rows (shift by header)
final r = list[i - 1];
final bool isMine = (r['authorId']?.toString() == _teacherId);
''';

// Note: The above ListTile sets a static subtitle in code comment. If you prefer a dynamic subtitle
// showing the title, replace the ListTile above with the version below:
const String REPLIES_HEADER_CARD_DYNAMIC = r'''
return Container(
  margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
    ],
    border: Border.all(color: Colors.grey.shade300),
  ),
  child: ListTile(
    dense: true,
    leading: const Icon(Icons.forum_outlined, color: Colors.blue),
    title: Text(
      'replying to',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    ),
    subtitle: Text(
      title.isEmpty ? 'announcement' : title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
''';

// ======================================================
// B) BUBBLE GESTURE WRAPPER: LONG-PRESS SOFT DELETE PATCH
// ======================================================
// Wrap your existing message bubble Container with this GestureDetector.
// Place this wrapper exactly around the bubble Container (the one that currently
// renders the message text using r['content'] and r['isDeleted']).
const String REPLY_BUBBLE_GESTURE_WRAPPER = r'''
GestureDetector(
  onLongPress: () async {
    final bool isDeleted = (r['isDeleted'] == true);
    if (!isMine || isDeleted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('This message will be marked as deleted.'),
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

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('announcement_replies')
            .update({'is_deleted': true})
            .eq('id', r['id']);
      } catch (_) {}
    }
  },
  child: Container(
    // KEEP YOUR EXISTING BUBBLE WIDGET CONTENT HERE (padding/decoration/Column/Text)
  ),
)
''';

// Reference text style inside the bubble (keep as-is if you already have it):
const String REPLY_TEXT_STYLE = r'''
Text(
  (r['isDeleted'] == true) ? 'deleted message' : (r['content'] ?? ''),
  style: TextStyle(
    fontSize: 13,
    fontStyle: (r['isDeleted'] == true) ? FontStyle.italic : FontStyle.normal,
    color: (r['isDeleted'] == true) ? Colors.grey : Colors.black87,
  ),
)
''';

// ==============================================
// C) SEND HANDLER: OPTIMISTIC INSERT WITH RETURN
// ==============================================
// Locate the send button handler (search: "final text = _replyCtrl.text.trim();").
// Replace the insert + clear logic with the following block (keeping your initial
// validation checks intact):
const String SEND_HANDLER_PATCH = r'''
final text = _replyCtrl.text.trim();
if (_selectedAnnouncementId == null || text.isEmpty) return;

final userId = _teacherId;
final annId = int.tryParse(_selectedAnnouncementId!);
if (userId == null || annId == null) return;

try {
  final inserted = await Supabase.instance.client
      .from('announcement_replies')
      .insert({
        'announcement_id': annId,
        'author_id': userId,
        'content': text,
      })
      .select()
      .single();

  setState(() {
    final k = _selectedAnnouncementId!;
    final current = List<Map<String, dynamic>>.from(
      _announcementReplies[k] ?? const [],
    );
    DateTime created = DateTime.now();
    final s = inserted['created_at']?.toString();
    if (s != null && s.isNotEmpty) {
      try { created = DateTime.parse(s).toLocal(); } catch (_) {}
    }
    current.add({
      'id': inserted['id'],
      'authorId': inserted['author_id'],
      'content': inserted['content'],
      'isDeleted': (inserted['is_deleted'] == true),
      'createdAt': created,
    });
    _announcementReplies[k] = current;
  });
  _replyCtrl.clear();
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sending reply: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
''';

// =======================
// D) QUICK CHECKLIST
// =======================
// - Replies ListView.builder:
//   [ ] itemCount uses list.length + 1
//   [ ] At top of itemBuilder: header guard for i == 0
//   [ ] For messages: r = list[i - 1]
//   [ ] Bubble wrapped with GestureDetector (long-press delete)
//   [ ] Text shows 'deleted message' when r['isDeleted'] == true
//
// - Send handler:
//   [ ] Uses insert(...).select().single()
//   [ ] Appends returned row (id, authorId, content, isDeleted, createdAt) to _announcementReplies
//   [ ] Clears _replyCtrl after success
//
// - Do NOT modify unrelated tabs or left panes. Keep changes scoped to right replies pane.

//
