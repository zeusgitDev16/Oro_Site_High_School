
class Lesson {
  final int id;
  final DateTime createdAt;
  final String title;
  final String? content;
  final int moduleId;
  final String? videoUrl;

  Lesson({
    required this.id,
    required this.createdAt,
    required this.title,
    this.content,
    required this.moduleId,
    this.videoUrl,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      title: map['title'],
      content: map['content'],
      moduleId: map['module_id'],
      videoUrl: map['video_url'],
    );
  }
}
