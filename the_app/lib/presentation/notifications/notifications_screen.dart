import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/routing/routes.dart';
import '../../core/services/pack_api_service.dart';
import '../../data/repositories/post_repository.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      // Use central ApiConfig + support both list and {results: [...]}
      final response = await ApiService.get(ApiConfig.notifications);

      final dynamic data = response;
      final List<dynamic> results;
      if (data is List) {
        results = data;
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        results = data['results'] as List;
      } else {
        results = const [];
      }

      if (mounted) {
        setState(() {
          _notifications = results.map<NotificationItem>((json) {
            final title = json['title']?.toString() ?? 'Notification';
            final subtitle = json['body']?.toString() ?? '';
            final extraData = json['extra_data'] as Map<String, dynamic>? ?? {};

            String? postTypeStr = extraData['post_type']?.toString();
            if (postTypeStr == null) {
              if (json['notification_type'] == 'new_product') {
                postTypeStr = 'product';
              } else if (json['notification_type'] == 'new_pack') {
                postTypeStr = 'pack';
              } else if (json['notification_type'] == 'new_promotion') {
                postTypeStr = 'promotion';
              }
            }

            return NotificationItem(
              id: json['id'],
              type: _parseType(json['notification_type']),
              title: title,
              subtitle: subtitle,
              time: json['time_ago']?.toString() ?? _formatDate(json['created_at']),
              postId: json['product_id']?.toString() ?? json['pack_id']?.toString() ?? extraData['post_id']?.toString(),
              postType: postTypeStr,
              senderName: json['actor_name']?.toString() ?? 'Store',
              senderAvatar: json['actor_avatar']?.toString(),
              isNew: !(json['is_read'] ?? true),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    for (var n in _notifications) {
      if (n.isNew) {
        try {
          await ApiService.post(
            '${ApiConfig.notifications}${n.id}/mark-read/',
            {},
          );
          setState(() {
            n.isNew = false;
          });
        } catch (e) {
          debugPrint("Error marking read: $e");
        }
      }
    }
  }

  NotificationType _parseType(String? typeStr) {
    if (typeStr == 'new_promotion' || typeStr == 'promotion' || typeStr == 'flash_sale') {
      return NotificationType.discount;
    }
    if (typeStr == 'follow' || typeStr == 'follower') {
      return NotificationType.follower;
    }
    return NotificationType.order;
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "Unknown";
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return "Unknown";
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final newCount = _notifications.where((n) => n.isNew).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchNotifications,
            color: AppColors.primaryColor,
            child: Column(
              children: [
                // New notifications banner
                if (newCount > 0)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightShade,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'You have $newCount new notifications',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        AppTextButton(
                          text: 'Mark all as read',
                          onPressed: _markAllAsRead,
                        ),
                      ],
                    ),
                  ),

                // Notifications list
                Expanded(
                  child: _notifications.isEmpty
                      ? ListView( // Use ListView so RefreshIndicator still works on empty state
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey[200],
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationItem(notification);
                          },
                        ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () async {
        if (notification.isNew) {
          try {
            await ApiService.post('${ApiConfig.notifications}${notification.id}/mark-read/', {});
            setState(() {
              notification.isNew = false;
            });
          } catch (e) {
            debugPrint("Error marking notification read: $e");
          }
        }

        // Navigate based on type and id
        if (notification.postId != null && notification.postType != null) {
          final id = int.tryParse(notification.postId!);
          if (id != null) {
            try {
              if (notification.postType == 'product' || notification.postType == 'promotion') {
                final post = await PostRepository.getPost(id);
                if (mounted) Navigator.pushNamed(context, Routes.productDetails, arguments: post);
              } else if (notification.postType == 'pack') {
                final pack = await PackApiService().getPack(id);
                if (mounted) Navigator.pushNamed(context, Routes.packDetails, arguments: pack);
              }
            } catch (e) {
              debugPrint("Error fetching item for notification: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This item is no longer available.')),
                );
              }
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.senderAvatar == null ? _getNotificationColor(notification.type).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                image: notification.senderAvatar != null
                    ? DecorationImage(
                        image: NetworkImage(notification.senderAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: notification.senderAvatar == null
                  ? Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notification.title,
                          style: TextStyle(
                            fontWeight: notification.isNew ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Time
            Text(
              notification.time,
              style: TextStyle(
                 fontSize: 11,
                 color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.follower:
        return Icons.person_add_outlined;
      case NotificationType.discount:
        return Icons.local_offer_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.primaryColor;
      case NotificationType.follower:
        return AppColors.successGreen;
      case NotificationType.discount:
        return AppColors.warningAmber;
    }
  }
}

enum NotificationType { order, follower, discount }

class NotificationItem {
  final int id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String time;
  final String? postId;
  final String? postType;
  final String senderName;
  final String? senderAvatar;
  bool isNew;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.postId,
    this.postType,
    required this.senderName,
    this.senderAvatar,
    this.isNew = false,
  });
}
