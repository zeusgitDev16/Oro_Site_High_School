/// Course Schedule Model
/// Represents a scheduled class session (day, time, room)
class CourseSchedule {
  final int id;
  final DateTime createdAt;
  final int courseId;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String startTime; // HH:mm format (e.g., "08:00")
  final String endTime; // HH:mm format (e.g., "09:00")
  final String? roomNumber;
  final bool isActive;
  final DateTime updatedAt;

  CourseSchedule({
    required this.id,
    required this.createdAt,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
    this.isActive = true,
    required this.updatedAt,
  });

  /// Create CourseSchedule from database map
  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    return CourseSchedule(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      courseId: map['course_id'] as int,
      dayOfWeek: map['day_of_week'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      roomNumber: map['room_number'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert CourseSchedule to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'course_id': courseId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_number': roomNumber,
      'is_active': isActive,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to map for INSERT (without id and timestamps)
  Map<String, dynamic> toInsertMap() {
    return {
      'course_id': courseId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_number': roomNumber,
      'is_active': isActive,
    };
  }

  /// Get display string for schedule
  String get displayString {
    final room = roomNumber != null ? ' • Room $roomNumber' : '';
    return '$dayOfWeek $startTime - $endTime$room';
  }

  /// Get short display (without room)
  String get shortDisplay {
    return '$dayOfWeek $startTime - $endTime';
  }

  /// Get time range display
  String get timeRange {
    return '$startTime - $endTime';
  }

  /// Parse time string to DateTime (for comparison)
  DateTime parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Get duration in minutes
  int get durationMinutes {
    final start = parseTime(startTime);
    final end = parseTime(endTime);
    return end.difference(start).inMinutes;
  }

  /// Get duration display (e.g., "1 hour", "1.5 hours")
  String get durationDisplay {
    final minutes = durationMinutes;
    if (minutes < 60) {
      return '$minutes minutes';
    }
    final hours = minutes / 60;
    if (hours == hours.floor()) {
      return '${hours.toInt()} ${hours == 1 ? 'hour' : 'hours'}';
    }
    return '${hours.toStringAsFixed(1)} hours';
  }

  /// Get day index (0 = Monday, 6 = Sunday)
  int get dayIndex {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days.indexOf(dayOfWeek);
  }

  /// Copy with updated fields
  CourseSchedule copyWith({
    int? id,
    DateTime? createdAt,
    int? courseId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? roomNumber,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return CourseSchedule(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      courseId: courseId ?? this.courseId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CourseSchedule(id: $id, day: $dayOfWeek, time: $startTime-$endTime, room: $roomNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Days of the week
class DaysOfWeek {
  static const List<String> all = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> weekend = [
    'Saturday',
    'Sunday',
  ];

  /// Get short name (e.g., "Mon", "Tue")
  static String getShortName(String day) {
    return day.substring(0, 3);
  }

  /// Check if day is weekday
  static bool isWeekday(String day) {
    return weekdays.contains(day);
  }

  /// Check if day is weekend
  static bool isWeekend(String day) {
    return weekend.contains(day);
  }
}

/// Common time slots for Philippine schools
class CommonTimeSlots {
  // Morning shift (typical for public schools)
  static const String morningStart = '07:00';
  static const String morningEnd = '12:00';

  // Afternoon shift
  static const String afternoonStart = '13:00';
  static const String afternoonEnd = '18:00';

  // Common class durations
  static const List<String> commonStartTimes = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
  ];

  // Standard class duration (minutes)
  static const int standardDuration = 60; // 1 hour
  static const int extendedDuration = 90; // 1.5 hours

  /// Generate end time from start time and duration
  static String generateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final totalMinutes = hour * 60 + minute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }
}
