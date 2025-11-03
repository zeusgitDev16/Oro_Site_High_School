
class Assignment {
  final int id;
  final DateTime createdAt;
  final int courseId;
  final String title;
  final String? description;
  final DateTime? dueDate;

  Assignment({
    required this.id,
    required this.createdAt,
    required this.courseId,
    required this.title,
    this.description,
    this.dueDate,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      courseId: map['course_id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }
}
