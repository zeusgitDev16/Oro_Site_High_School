
class Message {
  final int id;
  final DateTime createdAt;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;

  Message({
    required this.id,
    required this.createdAt,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      senderId: map['sender_id'],
      recipientId: map['recipient_id'],
      content: map['content'],
      isRead: map['is_read'],
    );
  }
}
