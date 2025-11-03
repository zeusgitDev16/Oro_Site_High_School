/// expanded_replies.dart
///
/// Copy/paste-ready code and patches scoped to the announcements/replies
/// flow. Use these snippets to manually update my_classroom_screen.dart.
///
/// IMPORTANT: Do NOT import this file. It is a copy/paste guide only.
///
/// This file already contains earlier patches. New items below harden the
/// delete behavior so deleted replies never show again after navigation,
/// while keeping them stored in Supabase (soft delete but filtered out).
///
/// NEW IN THIS UPDATE (to prevent reappearing deleted messages)
/// - REPLIES_STREAM_FILTERED_PATCH
/// - REPLIES_PRELOAD_FILTERED_PATCH
/// - REPLIES_ROW_MAPPING_FIX_NOTE
///
/// APPLY ALL THREE (idempotently) as described below.

// ------------------------------------------------------------------
// 1) REPLIES_STREAM_FILTERED_PATCH
// ------------------------------------------------------------------
// WHERE TO PUT IN my_classroom_screen.dart
// - Inside _subscribeRepliesForSelectedAnnouncement()
// - Replace ONLY the stream build section with this block. Keep the method
//   signature and pre-checks the same.
// Search anchor to locate the spot quickly:
//   .from('announcement_replies')
//   .stream(primaryKey: ['id'])
//
// What this does:
// - Adds .eq('is_deleted', false) so realtime stream only emits non-deleted rows.
// - Adds a defensive skip if any deleted slips through.
const String REPLIES_STREAM_FILTERED_PATCH = r'''
_repliesStream = Supabase.instance.client
    .from('announcement_replies')
    .stream(primaryKey: ['id'])
    .eq('announcement_id', annId)
    .eq('is_deleted', false)
    .listen((rows) {
      final list = <Map<String, dynamic>>[];
      for (final row in rows) {
        // Defensive guard
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
          'isDeleted': false, // filtered stream guarantees not deleted
          'createdAt': created,
        });
      }
      if (!mounted) return;
      setState(() { _announcementReplies[idStr] = list; });
    });
''';

// ------------------------------------------------------------------
// 2) REPLIES_PRELOAD_FILTERED_PATCH
// ------------------------------------------------------------------
// WHERE TO PUT IN my_classroom_screen.dart
// - Inside _loadRepliesForSelectedAnnouncement()
// - Replace ONLY the Supabase query + mapping block with this version.
// Search anchor to locate the spot quickly:
//   .from('announcement_replies')
//   .select()
//
// What this does:
// - Adds .eq('is_deleted', false) so preload fetch excludes deleted replies.
const String REPLIES_PRELOAD_FILTERED_PATCH = r'''
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
    'isDeleted': false, // explicitly non-deleted
    'createdAt': created,
  });
}
if (!mounted) return;
setState(() { _announcementReplies[idStr] = list; });
''';

// ------------------------------------------------------------------
// 3) REPLIES_ROW_MAPPING_FIX_NOTE
// ------------------------------------------------------------------
// Important correction to earlier change:
//   list.add({ 'isDeleted': (row['is_deleted'] == false), ... })
// is WRONG and will invert the meaning. Please change it back to either:
//   'isDeleted': (row['is_deleted'] == true)
// or when applying the filtered patches above, simply set:
//   'isDeleted': false
// because deleted rows are already filtered out and should not appear.
const String REPLIES_ROW_MAPPING_FIX_NOTE = r'''
// Replace any inverted mapping with the correct semantics:
// 'isDeleted': (row['is_deleted'] == true)
// If you applied the filtered patches, set 'isDeleted': false consistently
// for mapped rows coming from stream/preload.
''';
