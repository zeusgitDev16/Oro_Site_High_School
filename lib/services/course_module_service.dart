
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_module.dart';

class CourseModuleService {
  final _supabase = Supabase.instance.client;

  Future<List<CourseModule>> getModulesForCourse(int courseId) async {
    final response = await _supabase.from('course_modules').select().eq('course_id', courseId);
    return (response as List).map((item) => CourseModule.fromMap(item)).toList();
  }

  Future<CourseModule> createModule(CourseModule module) async {
    final response = await _supabase.from('course_modules').insert({
      'course_id': module.courseId,
      'title': module.title,
      'order': module.order,
    }).select().single();
    return CourseModule.fromMap(response);
  }
}
