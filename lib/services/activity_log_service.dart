
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  final _supabase = Supabase.instance.client;

  Future<ActivityLog> createActivityLog(ActivityLog log) async {
    final response = await _supabase.from('activity_log').insert({
      'user_id': log.userId,
      'action': log.action,
      'details': log.details,
    }).select().single();
    return ActivityLog.fromMap(response);
  }
}
