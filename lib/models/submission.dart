
class Submission {
  final int id;
  final DateTime createdAt;
  final int assignmentId;
  final String studentId;
  final DateTime submittedAt;
  final String? content;

  Submission({
    required this.id,
    required this.createdAt,
    required this.assignmentId,
    required this.studentId,
    required this.submittedAt,
    this.content,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      assignmentId: map['assignment_id'],
      studentId: map['student_id'],
      submittedAt: DateTime.parse(map['submitted_at']),
      content: map['content'],
    );
  }
}
