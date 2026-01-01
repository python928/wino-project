import '../config/api_config.dart';
import './api_service.dart';
import '../../data/models/message_model.dart';

class MessageApiService {
  MessageApiService();

  /// Get all conversations (grouped by other user)
  Future<List<Conversation>> getConversations() async {
    try {
      final data = await ApiService.get('${ApiConfig.messages}conversations/');

      if (data is List) {
        return data.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  /// Get messages with a specific user
  Future<List<Message>> getMessages(int userId) async {
    try {
      final data = await ApiService.get('${ApiConfig.messages}?user_id=$userId');

      List<dynamic> messagesList;
      if (data is Map<String, dynamic> && data['results'] != null) {
        messagesList = data['results'] as List;
      } else if (data is List) {
        messagesList = data;
      } else {
        return [];
      }

      return messagesList
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.messages, {
        'receiver': receiverId,
        'content': content,
      });

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Mark a single message as read
  Future<void> markMessageRead(int messageId) async {
    try {
      await ApiService.post('${ApiConfig.messages}$messageId/mark_read/', {});
    } catch (e) {
      throw Exception('Error marking message as read: $e');
    }
  }

  /// Mark all messages from a user as read
  Future<void> markConversationRead(int userId) async {
    try {
      await ApiService.post('${ApiConfig.messages}mark_conversation_read/', {
        'user_id': userId,
      });
    } catch (e) {
      throw Exception('Error marking conversation as read: $e');
    }
  }

  /// Get total unread message count
  Future<int> getUnreadCount() async {
    try {
      final data = await ApiService.get('${ApiConfig.messages}unread_count/');

      if (data is Map<String, dynamic>) {
        return data['unread_count'] as int? ?? 0;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }
}
