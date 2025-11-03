
class CalendarEvent {
  final int id;
  final DateTime createdAt;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int? courseId;

  CalendarEvent({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.courseId,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      title: map['title'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      courseId: map['course_id'],
    );
  }
}
