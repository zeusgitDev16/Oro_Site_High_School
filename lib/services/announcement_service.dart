
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final _supabase = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncementsForCourse(int courseId) async {
    // Use view that includes author_name and created_at
    final response = await _supabase
        .from('announcements_with_author')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return (response as List).map((item) => Announcement.fromMap(item)).toList();
  }

  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final user = _supabase.auth.currentUser;
    final response = await _supabase
        .from('announcements')
        .insert({
          'course_id': announcement.courseId,
          'title': announcement.title,
          'content': announcement.content,
          'author_id': user?.id,
        })
        .select()
        .single();
    return Announcement.fromMap(response);
  }
}
