import 'package:flutter/material.dart';
import '../services/message_api_service.dart';
import '../../data/models/message_model.dart';

class MessageProvider with ChangeNotifier {
  final MessageApiService _apiService = MessageApiService();

  // Conversations
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;

  // Current chat messages
  List<Message> _messages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;
  int? _currentChatUserId;

  // Unread count
  int _unreadCount = 0;

  // Sending state
  bool _isSending = false;

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;

  List<Message> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;
  int? get currentChatUserId => _currentChatUserId;

  int get unreadCount => _unreadCount;
  bool get isSending => _isSending;

  /// Load conversations list
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      // Update unread count from conversations
      _unreadCount = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
    } catch (e) {
      _conversationsError = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific user
  Future<void> loadMessages(int userId) async {
    _isLoadingMessages = true;
    _messagesError = null;
    _currentChatUserId = userId;
    notifyListeners();

    try {
      _messages = await _apiService.getMessages(userId);
      // Mark conversation as read
      await markConversationRead(userId);
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _apiService.sendMessage(
        receiverId: receiverId,
        content: content.trim(),
      );

      // Add to messages list
      _messages.insert(0, message);

      // Update conversation in list
      _updateConversation(receiverId, content);
    } catch (e) {
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Mark a conversation as read
  Future<void> markConversationRead(int userId) async {
    try {
      await _apiService.markConversationRead(userId);

      // Update local conversation
      final index = _conversations.indexWhere((c) => c.userId == userId);
      if (index != -1) {
        final conv = _conversations[index];
        _conversations[index] = Conversation(
          userId: conv.userId,
          username: conv.username,
          firstName: conv.firstName,
          lastName: conv.lastName,
          profileImage: conv.profileImage,
          lastMessage: conv.lastMessage,
          lastMessageTime: conv.lastMessageTime,
          unreadCount: 0,
          isSender: conv.isSender,
        );
        _unreadCount = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Update unread count
  Future<void> updateUnreadCount() async {
    try {
      _unreadCount = await _apiService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  /// Update conversation after sending a message
  void _updateConversation(int userId, String content) {
    final index = _conversations.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final conv = _conversations[index];
      _conversations[index] = Conversation(
        userId: conv.userId,
        username: conv.username,
        firstName: conv.firstName,
        lastName: conv.lastName,
        profileImage: conv.profileImage,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isSender: true,
      );

      // Move to top
      final updated = _conversations.removeAt(index);
      _conversations.insert(0, updated);
      notifyListeners();
    }
  }

  /// Clear current chat
  void clearCurrentChat() {
    _messages = [];
    _currentChatUserId = null;
    _messagesError = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadConversations();
  }
}
