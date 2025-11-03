
class Announcement {
  final int id;
  final DateTime createdAt;
  final int courseId;
  final String title;
  final String content;

  Announcement({
    required this.id,
    required this.createdAt,
    required this.courseId,
    required this.title,
    required this.content,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      courseId: map['course_id'],
      title: map['title'],
      content: map['content'],
    );
  }
}
