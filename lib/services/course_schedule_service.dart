import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_schedule.dart';

/// Course Schedule Service - Manages course schedules
/// Handles schedule creation, retrieval, updates, and conflict detection
class CourseScheduleService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create a new schedule
  Future<CourseSchedule> createSchedule({
    required int courseId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomNumber,
    bool isActive = true,
  }) async {
    try {
      final scheduleData = {
        'course_id': courseId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room_number': roomNumber,
        'is_active': isActive,
      };

      final response = await _supabase
          .from('course_schedules')
          .insert(scheduleData)
          .select()
          .single();

      return CourseSchedule.fromMap(response);
    } catch (e) {
      print('Error creating schedule: $e');
      rethrow;
    }
  }

  /// Create multiple schedules for a course
  Future<List<CourseSchedule>> createMultipleSchedules({
    required int courseId,
    required List<Map<String, dynamic>> schedules,
  }) async {
    try {
      final scheduleData = schedules
          .map(
            (schedule) => {
              'course_id': courseId,
              'day_of_week': schedule['dayOfWeek'] as String,
              'start_time': schedule['startTime'] as String,
              'end_time': schedule['endTime'] as String,
              'room_number': schedule['roomNumber'] as String?,
              'is_active': schedule['isActive'] as bool? ?? true,
            },
          )
          .toList();

      final response = await _supabase
          .from('course_schedules')
          .insert(scheduleData)
          .select();

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error creating multiple schedules: $e');
      rethrow;
    }
  }

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get all schedules for a course
  Future<List<CourseSchedule>> getSchedulesForCourse(
    int courseId, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('course_schedules')
          .select()
          .eq('course_id', courseId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('day_of_week');

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching schedules for course: $e');
      return [];
    }
  }

  /// Get schedule by ID
  Future<CourseSchedule?> getScheduleById(int id) async {
    try {
      final response = await _supabase
          .from('course_schedules')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CourseSchedule.fromMap(response);
    } catch (e) {
      print('Error fetching schedule by ID: $e');
      return null;
    }
  }

  /// Get schedules by day of week
  Future<List<CourseSchedule>> getSchedulesByDay(
    String dayOfWeek, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('course_schedules')
          .select()
          .eq('day_of_week', dayOfWeek);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('start_time');

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching schedules by day: $e');
      return [];
    }
  }

  /// Get schedules by room
  Future<List<CourseSchedule>> getSchedulesByRoom(
    String roomNumber, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('course_schedules')
          .select()
          .eq('room_number', roomNumber);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('day_of_week');

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching schedules by room: $e');
      return [];
    }
  }

  /// Get all schedules (for admin view)
  Future<List<CourseSchedule>> getAllSchedules({bool activeOnly = true}) async {
    try {
      var query = _supabase.from('course_schedules').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('day_of_week');

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching all schedules: $e');
      return [];
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update schedule
  Future<void> updateSchedule(
    int scheduleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase
          .from('course_schedules')
          .update(updates)
          .eq('id', scheduleId);
    } catch (e) {
      print('Error updating schedule: $e');
      rethrow;
    }
  }

  /// Activate schedule
  Future<void> activateSchedule(int scheduleId) async {
    await updateSchedule(scheduleId, {'is_active': true});
  }

  /// Deactivate schedule
  Future<void> deactivateSchedule(int scheduleId) async {
    await updateSchedule(scheduleId, {'is_active': false});
  }

  /// Update schedule time
  Future<void> updateScheduleTime({
    required int scheduleId,
    required String startTime,
    required String endTime,
  }) async {
    await updateSchedule(scheduleId, {
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  /// Update schedule room
  Future<void> updateScheduleRoom(int scheduleId, String? roomNumber) async {
    await updateSchedule(scheduleId, {'room_number': roomNumber});
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete schedule
  Future<void> deleteSchedule(int scheduleId) async {
    try {
      await _supabase.from('course_schedules').delete().eq('id', scheduleId);
    } catch (e) {
      print('Error deleting schedule: $e');
      rethrow;
    }
  }

  /// Delete all schedules for a course
  Future<void> deleteAllSchedulesForCourse(int courseId) async {
    try {
      await _supabase
          .from('course_schedules')
          .delete()
          .eq('course_id', courseId);
    } catch (e) {
      print('Error deleting schedules for course: $e');
      rethrow;
    }
  }

  // ============================================
  // CONFLICT DETECTION
  // ============================================

  /// Check for schedule conflicts in a room
  Future<List<CourseSchedule>> checkRoomConflicts({
    required String roomNumber,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? excludeScheduleId,
  }) async {
    try {
      var query = _supabase
          .from('course_schedules')
          .select()
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true);

      if (excludeScheduleId != null) {
        query = query.neq('id', excludeScheduleId);
      }

      final response = await query;
      final schedules = (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();

      // Filter for time overlaps
      return schedules.where((schedule) {
        return _timesOverlap(
          startTime,
          endTime,
          schedule.startTime,
          schedule.endTime,
        );
      }).toList();
    } catch (e) {
      print('Error checking room conflicts: $e');
      return [];
    }
  }

  /// Check if two time ranges overlap
  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    final s1 = _timeToMinutes(start1);
    final e1 = _timeToMinutes(end1);
    final s2 = _timeToMinutes(start2);
    final e2 = _timeToMinutes(end2);

    return (s1 < e2) && (s2 < e1);
  }

  /// Convert time string (HH:mm) to minutes since midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Check if schedule has conflicts
  Future<bool> hasConflicts({
    required String roomNumber,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? excludeScheduleId,
  }) async {
    final conflicts = await checkRoomConflicts(
      roomNumber: roomNumber,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      excludeScheduleId: excludeScheduleId,
    );
    return conflicts.isNotEmpty;
  }

  // ============================================
  // STATISTICS OPERATIONS
  // ============================================

  /// Get schedule statistics for a course
  Future<Map<String, dynamic>> getCourseScheduleStats(int courseId) async {
    try {
      final schedules = await getSchedulesForCourse(courseId);

      final stats = {
        'total': schedules.length,
        'active': schedules.where((s) => s.isActive).length,
        'inactive': schedules.where((s) => !s.isActive).length,
        'days': <String>{},
        'rooms': <String>{},
        'total_hours': 0.0,
      };

      for (final schedule in schedules) {
        (stats['days'] as Set<String>).add(schedule.dayOfWeek);
        if (schedule.roomNumber != null) {
          (stats['rooms'] as Set<String>).add(schedule.roomNumber!);
        }
        stats['total_hours'] =
            (stats['total_hours'] as double) +
            (schedule.durationMinutes / 60.0);
      }

      stats['days'] = (stats['days'] as Set<String>).toList();
      stats['rooms'] = (stats['rooms'] as Set<String>).toList();

      return stats;
    } catch (e) {
      print('Error getting course schedule stats: $e');
      return {};
    }
  }

  /// Get room utilization statistics
  Future<Map<String, dynamic>> getRoomUtilization(String roomNumber) async {
    try {
      final schedules = await getSchedulesByRoom(roomNumber);

      final stats = {
        'room': roomNumber,
        'total_schedules': schedules.length,
        'days_used': <String>{},
        'courses': <int>{},
        'total_hours_per_week': 0.0,
      };

      for (final schedule in schedules) {
        (stats['days_used'] as Set<String>).add(schedule.dayOfWeek);
        (stats['courses'] as Set<int>).add(schedule.courseId);
        stats['total_hours_per_week'] =
            (stats['total_hours_per_week'] as double) +
            (schedule.durationMinutes / 60.0);
      }

      stats['days_used'] = (stats['days_used'] as Set<String>).toList();
      stats['courses'] = (stats['courses'] as Set<int>).length;

      return stats;
    } catch (e) {
      print('Error getting room utilization: $e');
      return {};
    }
  }

  /// Get total schedules count
  Future<int> getTotalSchedulesCount({bool activeOnly = true}) async {
    try {
      var query = _supabase.from('course_schedules').select('id');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      print('Error getting total schedules count: $e');
      return 0;
    }
  }

  /// Get schedules count by day
  Future<Map<String, int>> getSchedulesCountByDay() async {
    try {
      final schedules = await getAllSchedules();
      final counts = <String, int>{};

      for (final schedule in schedules) {
        counts[schedule.dayOfWeek] = (counts[schedule.dayOfWeek] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting schedules count by day: $e');
      return {};
    }
  }

  /// Get upcoming classes for a list of courses (for teacher dashboard)
  Future<List<CourseSchedule>> getUpcomingClassesForCourses(
    List<int> courseIds,
  ) async {
    try {
      if (courseIds.isEmpty) return [];

      // Get today's day of week
      final now = DateTime.now();
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final today = days[now.weekday - 1];

      // Fetch schedules for these courses for today
      final response = await _supabase
          .from('course_schedules')
          .select()
          .filter('course_id', 'in', courseIds)
          .eq('day_of_week', today)
          .eq('is_active', true)
          .order('start_time');

      return (response as List)
          .map((item) => CourseSchedule.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching upcoming classes: $e');
      return [];
    }
  }
}
