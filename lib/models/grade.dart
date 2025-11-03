
class Grade {
  final int id;
  final DateTime createdAt;
  final int submissionId;
  final String graderId;
  final double score;
  final String? comments;

  Grade({
    required this.id,
    required this.createdAt,
    required this.submissionId,
    required this.graderId,
    required this.score,
    this.comments,
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      submissionId: map['submission_id'],
      graderId: map['grader_id'],
      score: map['score'].toDouble(),
      comments: map['comments'],
    );
  }
}
