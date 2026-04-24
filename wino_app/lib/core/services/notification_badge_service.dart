import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationBadgeService {
  NotificationBadgeService._();

  static final NotificationBadgeService instance = NotificationBadgeService._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  FlutterLocalNotificationsPlugin? _localNotifications;

  Future<void> refresh() async {
    try {
      final response = await ApiService.get(ApiConfig.notificationsUnreadCount);
      if (response is Map<String, dynamic>) {
        final next = (response['unread_count'] as num?)?.toInt() ?? 0;
        unreadCount.value = next;
      }
    } catch (e) {
      debugPrint('NotificationBadgeService.refresh failed: $e');
    }
  }

  void attachLocalNotifications(FlutterLocalNotificationsPlugin plugin) {
    _localNotifications = plugin;
  }

  Future<void> syncMissedUnreadToShade() async {
    try {
      if (!StorageService.isLoggedIn()) return;
      if (_localNotifications == null) return;

      final response = await ApiService.get(ApiConfig.notifications);
      final List<dynamic> items;
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic> &&
          response['results'] is List) {
        items = response['results'] as List;
      } else {
        items = const [];
      }

      final lastShownId = StorageService.getLastNotifiedNotificationId();
      int maxShownId = lastShownId;

      final pending = <Map<String, dynamic>>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final id = (item['id'] as num?)?.toInt() ?? 0;
        final isRead = item['is_read'] == true;
        if (id > lastShownId && !isRead) {
          pending.add(item);
          if (id > maxShownId) maxShownId = id;
        }
      }

      pending.sort(
        (a, b) => ((a['id'] as num?)?.toInt() ?? 0)
            .compareTo((b['id'] as num?)?.toInt() ?? 0),
      );

      for (final n in pending) {
        final id = (n['id'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000);
        final title = (n['title']?.toString().trim().isNotEmpty == true)
            ? n['title'].toString()
            : 'Notification';
        final body = n['body']?.toString() ?? '';

        await _localNotifications!.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'wino_channel',
              'Wino Notifications',
              channelDescription: 'General notifications for Wino app',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (maxShownId > lastShownId) {
        await StorageService.setLastNotifiedNotificationId(maxShownId);
      }
    } catch (e) {
      debugPrint('NotificationBadgeService.syncMissedUnreadToShade failed: $e');
    }
  }

  void increment([int by = 1]) {
    if (by <= 0) return;
    unreadCount.value = unreadCount.value + by;
  }

  void clear() {
    unreadCount.value = 0;
  }

  void dispose() {
    unreadCount.dispose();
  }
}
