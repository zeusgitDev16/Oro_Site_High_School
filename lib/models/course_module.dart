
class CourseModule {
  final int id;
  final DateTime createdAt;
  final int courseId;
  final String title;
  final int order;

  CourseModule({
    required this.id,
    required this.createdAt,
    required this.courseId,
    required this.title,
    required this.order,
  });

  factory CourseModule.fromMap(Map<String, dynamic> map) {
    return CourseModule(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      courseId: map['course_id'],
      title: map['title'],
      order: map['order'],
    );
  }
}
