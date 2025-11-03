/// isdelete_fix.dart
///
/// Purpose
/// - Copy/paste-only guide to make soft-deleted replies never reappear after navigation
///   while still keeping them in Supabase. Idempotent, surgical replacements only.
///
/// What you will do (manually, in my_classroom_screen.dart):
/// 1) Filter out deleted rows in both replies preload and realtime stream
/// 2) Fix any inverted isDeleted mapping
/// 3) Ensure the send handler appends isDeleted: false for optimistic UI
/// 4) (Optional) Use a defensive selection store for Flutter Web
///
/// This file is NOT meant to be imported; it contains ready-to-paste code.
///
/// Prerequisites (DB)
/// - Column public.announcement_replies.is_deleted boolean NOT NULL DEFAULT false
///
/// ============================
/// SEARCH ANCHORS (quick nav)
/// ============================
/// A) "Future<void> _loadRepliesForSelectedAnnouncement()"
/// B) "void _subscribeRepliesForSelectedAnnouncement()"
/// C) "final text = _replyCtrl.text.trim();" (send handler block)
/// D) Any line mapping reply rows that looks like:
///    'isDeleted': (row['is_deleted'] == false)
///
/// ==========================
/// 1) PRELOAD FILTER (REPLACE)
/// ==========================
/// Replace ONLY the Supabase query + mapping block INSIDE
/// _loadRepliesForSelectedAnnouncement() with this code:
///
/// BEGIN REPLACE BLOCK
/*
final rows = await Supabase.instance.client
    .from('announcement_replies')
    .select()
    .eq('announcement_id', annId)
    .eq('is_deleted', false)
    .order('created_at', ascending: true);
final list = <Map<String, dynamic>>[];
for (final row in (rows as List)) {
  DateTime created = DateTime.now();
  final s = row['created_at']?.toString();
  if (s != null && s.isNotEmpty) {
    try { created = DateTime.parse(s).toLocal(); } catch (_) {}
  }
  list.add({
    'id': row['id'],
    'authorId': row['author_id'],
    'content': row['content'],
    'isDeleted': false, // filtered query ensures not deleted
    'createdAt': created,
  });
}
if (!mounted) return;
setState(() { _announcementReplies[idStr] = list; });
*/
/// END REPLACE BLOCK
///
/// Notes:
/// - We explicitly filter .eq('is_deleted', false)
/// - We map 'isDeleted': false because filtered rows are not deleted
///
/// ==========================
/// 2) STREAM FILTER (REPLACE)
/// ==========================
/// Replace ONLY the stream build section INSIDE
/// _subscribeRepliesForSelectedAnnouncement() with this code:
///
/// BEGIN REPLACE BLOCK
/*
_repliesStream = Supabase.instance.client
    .from('announcement_replies')
    .stream(primaryKey: ['id'])
    .eq('announcement_id', annId)
    .eq('is_deleted', false)
    .listen((rows) {
      final list = <Map<String, dynamic>>[];
      for (final row in rows) {
        // Defensive guard in case backend sends a deleted row
        if (row['is_deleted'] == true) continue;
        DateTime created = DateTime.now();
        final s = row['created_at']?.toString();
        if (s != null && s.isNotEmpty) {
          try { created = DateTime.parse(s).toLocal(); } catch (_) {}
        }
        list.add({
          'id': row['id'],
          'authorId': row['author_id'],
          'content': row['content'],
          'isDeleted': false,
          'createdAt': created,
        });
      }
      if (!mounted) return;
      setState(() { _announcementReplies[idStr] = list; });
    });
*/
/// END REPLACE BLOCK
///
/// Notes:
/// - We explicitly filter .eq('is_deleted', false)
/// - We map 'isDeleted': false because filtered rows are not deleted
///
/// ==================================
/// 3) FIX MAPPING (SEARCH + CORRECT)
/// ==================================
/// If you previously changed row mapping to invert deletion:
///   'isDeleted': (row['is_deleted'] == false)
///
/// Please change to either (choose one based on whether you applied filters):
/// - If you DID apply filters above:
///   'isDeleted': false
/// - If you DID NOT apply filters above:
///   'isDeleted': (row['is_deleted'] == true)
///
/// ================================
/// 4) SEND HANDLER (PATCH SNIPPET)
/// ================================
/// In the send handler (search anchor: "final text = _replyCtrl.text.trim();"),
/// ensure optimistic append always sets isDeleted: false. Example (inside setState
/// after insert().select().single() returns 'inserted'):
///
/// BEGIN SNIPPET
/*
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
    'isDeleted': false, // ensure not deleted by default
    'createdAt': created,
  });
  _announcementReplies[k] = current;
});
_replyCtrl.clear();
*/
/// END SNIPPET
///
/// ==========================================
/// 5) (OPTIONAL) DEFENSIVE SELECTION STORE
/// ==========================================
/// On Flutter Web, keep selection store fully typed to avoid runtime Symbol errors.
/// Replace your selection store block with this (inside the State class):
///
/// BEGIN REPLACE BLOCK
/*
final Map<String, String> _lastSelectedAnnouncement = <String, String>{};

String _selectionKey() {
  final String c = _selectedClassroom?.id ?? '';
  final String s = _selectedCourse?.id ?? '';
  return '$c|$s';
}

void _rememberSelectedAnnouncement(String announcementId) {
  final String k = _selectionKey();
  if (k.isEmpty) return;
  _lastSelectedAnnouncement[k] = announcementId;
}

String? _restoreSelectedAnnouncement() {
  final String k = _selectionKey();
  if (k.isEmpty) return null;
  return _lastSelectedAnnouncement[k];
}
*/
/// END REPLACE BLOCK
///
/// =================
/// QA CHECKLIST
/// =================
/// - Delete a reply → it should disappear immediately (local patch)
/// - Switch to another announcement → deleted reply should not show on return
/// - Reload page → deleted reply should not show (filtered at DB)
/// - New replies appear immediately and show the small banner when focused
/// - No runtime web errors (if using defensive selection store)
