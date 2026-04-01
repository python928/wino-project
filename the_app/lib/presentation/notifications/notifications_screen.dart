import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/routing/routes.dart';
import '../../core/services/notification_badge_service.dart';
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
        final unread = results.where((e) => !(e['is_read'] ?? true)).length;
        setState(() {
          _notifications = results.map<NotificationItem>((json) {
            final title =
                json['title']?.toString() ?? context.tr('Notification');
            final body = json['body']?.toString() ?? '';
            final extraData = json['extra_data'] is Map<String, dynamic>
                ? json['extra_data'] as Map<String, dynamic>
                : <String, dynamic>{};

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

            final senderName = json['actor_name']?.toString().trim();
            final storeName = senderName != null && senderName.isNotEmpty
                ? senderName
                : _extractStoreNameFromTitle(title);
            final productName = _extractProductName(
              body: body,
              extraData: extraData,
              fallbackTitle: title,
            );
            final rawAvatar = json['actor_avatar']?.toString().trim();
            final rawImage = json['image_url']?.toString().trim();
            final avatar = (rawAvatar != null && rawAvatar.isNotEmpty)
                ? ApiConfig.getImageUrl(rawAvatar)
                : ((rawImage != null && rawImage.isNotEmpty)
                    ? ApiConfig.getImageUrl(rawImage)
                    : null);

            return NotificationItem(
              id: json['id'],
              type: _parseType(json['notification_type']),
              storeName: storeName,
              productName: productName,
              message: body.isNotEmpty ? body : title,
              time: json['time_ago']?.toString() ??
                  _formatDate(json['created_at']),
              postId: json['product_id']?.toString() ??
                  json['pack_id']?.toString() ??
                  extraData['post_id']?.toString(),
              postType: postTypeStr,
              storeAvatar: avatar,
              isNew: !(json['is_read'] ?? true),
            );
          }).toList();
          _isLoading = false;
        });
        NotificationBadgeService.instance.unreadCount.value = unread;
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.post(ApiConfig.notificationsMarkAllRead, {});
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n.isNew = false;
        }
      });
      NotificationBadgeService.instance.clear();
    } catch (e) {
      debugPrint("Error marking all read: $e");
    }
  }

  NotificationType _parseType(String? typeStr) {
    if (typeStr == 'new_promotion' ||
        typeStr == 'promotion' ||
        typeStr == 'flash_sale') {
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

  String _extractStoreNameFromTitle(String title) {
    final match = RegExp(r'from\s+(.+?)[!.]?$', caseSensitive: false)
        .firstMatch(title.trim());
    final candidate = match?.group(1)?.trim();
    if (candidate != null && candidate.isNotEmpty) return candidate;
    return 'Store';
  }

  String _extractProductName({
    required String body,
    required Map<String, dynamic> extraData,
    required String fallbackTitle,
  }) {
    final extraCandidate = (extraData['post_title'] ??
            extraData['product_name'] ??
            extraData['pack_name'] ??
            extraData['name'] ??
            '')
        .toString()
        .trim();
    if (extraCandidate.isNotEmpty) return extraCandidate;

    // Example: "Check out their new post: Samsung S24"
    final bodyMatch =
        RegExp(r':\s*(.+)$', caseSensitive: false).firstMatch(body.trim());
    final fromBody = bodyMatch?.group(1)?.trim();
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;

    return fallbackTitle;
  }

  List<TextSpan> _buildMessageSpans(NotificationItem notification) {
    final message = notification.message;
    final product = notification.productName.trim();

    if (product.isEmpty) {
      return [
        TextSpan(
          text: message,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    final lowerMessage = message.toLowerCase();
    final lowerProduct = product.toLowerCase();
    final matchIndex = lowerMessage.indexOf(lowerProduct);

    if (matchIndex < 0) {
      return [
        TextSpan(
          text: message,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    final before = message.substring(0, matchIndex);
    final matched = message.substring(matchIndex, matchIndex + product.length);
    final after = message.substring(matchIndex + product.length);

    return [
      TextSpan(
        text: before,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      TextSpan(
        text: matched,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
      TextSpan(
        text: after,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final newCount = _notifications.where((n) => n.isNew).length;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('Notifications'),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightShade,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${context.tr('You have')} $newCount ${context.tr('new notifications')}',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            AppTextButton(
                              text: context.tr('Mark all as read'),
                              onPressed: _markAllAsRead,
                            ),
                          ],
                        ),
                      ),

                    // Notifications list
                    Expanded(
                      child: _notifications.isEmpty
                          ? ListView(
                              // Use ListView so RefreshIndicator still works on empty state
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_off_outlined,
                                          size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.tr('No notifications'),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () async {
        if (notification.isNew) {
          try {
            await ApiService.post(
                '${ApiConfig.notifications}${notification.id}/mark-read/', {});
            setState(() {
              notification.isNew = false;
            });
            NotificationBadgeService.instance.refresh();
          } catch (e) {
            debugPrint("Error marking notification read: $e");
          }
        }

        // Navigate based on type and id
        if (notification.postId != null && notification.postType != null) {
          final id = int.tryParse(notification.postId!);
          if (id != null) {
            try {
              if (notification.postType == 'product' ||
                  notification.postType == 'promotion') {
                final post = await PostRepository.getPost(id);
                if (mounted) {
                  Navigator.pushNamed(context, Routes.productDetails,
                      arguments: post);
                }
              } else if (notification.postType == 'pack') {
                final pack = await PackApiService().getPack(id);
                if (mounted) {
                  Navigator.pushNamed(context, Routes.packDetails,
                      arguments: pack);
                }
              }
            } catch (e) {
              debugPrint("Error fetching item for notification: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(context.tr('This item is no longer available.')),
                  ),
                );
              }
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: notification.isNew
              ? AppColors.primaryColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isNew
                ? AppColors.primaryColor.withOpacity(0.22)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  _getNotificationColor(notification.type).withOpacity(0.12),
              backgroundImage: notification.storeAvatar != null
                  ? NetworkImage(notification.storeAvatar!)
                  : null,
              child: notification.storeAvatar == null
                  ? Text(
                      notification.storeName.isNotEmpty
                          ? notification.storeName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: _getNotificationColor(notification.type),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: notification.isNew
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: _buildMessageSpans(notification),
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
  final String storeName;
  final String productName;
  final String message;
  final String time;
  final String? postId;
  final String? postType;
  final String? storeAvatar;
  bool isNew;

  NotificationItem({
    required this.id,
    required this.type,
    required this.storeName,
    required this.productName,
    required this.message,
    required this.time,
    this.postId,
    this.postType,
    this.storeAvatar,
    this.isNew = false,
  });
}
