
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonService {
  final _supabase = Supabase.instance.client;

  Future<List<Lesson>> getLessonsForModule(int moduleId) async {
    final response = await _supabase.from('lessons').select().eq('module_id', moduleId);
    return (response as List).map((item) => Lesson.fromMap(item)).toList();
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final response = await _supabase.from('lessons').insert({
      'title': lesson.title,
      'content': lesson.content,
      'module_id': lesson.moduleId,
      'video_url': lesson.videoUrl,
    }).select().single();
    return Lesson.fromMap(response);
  }
}
