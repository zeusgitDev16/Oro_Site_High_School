
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_event.dart';

class CalendarEventService {
  final _supabase = Supabase.instance.client;

  Future<List<CalendarEvent>> getCalendarEvents() async {
    final response = await _supabase.from('calendar_events').select();
    return (response as List).map((item) => CalendarEvent.fromMap(item)).toList();
  }

  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    final response = await _supabase.from('calendar_events').insert({
      'title': event.title,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime.toIso8601String(),
      'course_id': event.courseId,
    }).select().single();
    return CalendarEvent.fromMap(response);
  }
}
