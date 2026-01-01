import 'user_model.dart';
import '../../core/config/api_config.dart';

/// Represents a single message
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final User? senderDetails;
  final User? receiverDetails;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.senderDetails,
    this.receiverDetails,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['sender'] ?? 0,
      receiverId: json['receiver'] ?? 0,
      senderDetails: json['sender_details'] != null
          ? User.fromJson(json['sender_details'])
          : null,
      receiverDetails: json['receiver_details'] != null
          ? User.fromJson(json['receiver_details'])
          : null,
      content: json['content'] ?? '',
      isRead: json['read_status'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
      'read_status': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Represents a conversation (grouped messages with another user)
class Conversation {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isSender;

  const Conversation({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isSender,
  });

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }

  String? get avatarUrl {
    if (profileImage == null || profileImage!.isEmpty) return null;
    if (profileImage!.startsWith('http')) return profileImage;
    return ApiConfig.getImageUrl(profileImage!);
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImage: json['profile_image'],
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.tryParse(json['last_message_time'] ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      isSender: json['is_sender'] ?? false,
    );
  }

  /// Format time for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);

    if (diff.inDays == 0) {
      // Today - show time
      final hour = lastMessageTime.hour;
      final minute = lastMessageTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'م' : 'ص';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      // This week - show day name
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[lastMessageTime.weekday % 7];
    } else {
      // Show date
      return '${lastMessageTime.day}/${lastMessageTime.month}';
    }
  }
}
