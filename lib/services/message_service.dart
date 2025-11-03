
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class MessageService {
  final _supabase = Supabase.instance.client;

  Future<List<Message>> getMessages(String userId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,recipient_id.eq.$userId');
    return (response as List).map((item) => Message.fromMap(item)).toList();
  }

  Future<Message> createMessage(Message message) async {
    final response = await _supabase.from('messages').insert({
      'sender_id': message.senderId,
      'recipient_id': message.recipientId,
      'content': message.content,
      'is_read': message.isRead,
    }).select().single();
    return Message.fromMap(response);
  }
}
