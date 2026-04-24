import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wino/core/extensions/l10n_extension.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_badge_service.dart';
import '../../core/theme/app_colors.dart';

class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? actorName;
  final String? actorAvatar;
  final int? productId;
  final int? packId;
  final bool isRead;
  final DateTime createdAt;
  final String timeAgo;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actorName,
    this.actorAvatar,
    required this.isRead,
    required this.createdAt,
    required this.timeAgo,
    this.productId,
    this.packId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      type: json['notification_type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      actorName: json['actor_name'],
      actorAvatar: json['actor_avatar'],
      productId: json['product_id'],
      packId: json['pack_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      timeAgo: json['time_ago'] ?? '',
    );
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        actorName: actorName,
        actorAvatar: actorAvatar,
        productId: productId,
        packId: packId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        timeAgo: timeAgo,
      );
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get(ApiConfig.notifications);
      final decoded = (res is Map<String, dynamic> || res is List)
          ? res
          : jsonDecode(utf8.decode(res.bodyBytes));
      final List raw = decoded is Map
          ? (decoded['results'] ?? decoded['notifications'] ?? [])
          : (decoded is List ? decoded : const []);
      final items = raw
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _notifications = items;
        _unreadCount = items.where((n) => !n.isRead).length;
        _loading = false;
      });
      NotificationBadgeService.instance.unreadCount.value = _unreadCount;
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.post(ApiConfig.notificationsMarkAllRead, {});
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });
    NotificationBadgeService.instance.clear();
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    await ApiService.post(
      '${ApiConfig.notifications}${item.id}/mark-read/',
      {},
    );
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    });
    NotificationBadgeService.instance.unreadCount.value = _unreadCount;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                context.tr('Notifications'),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: Column(
                      children: [
                        if (_unreadCount > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _markAllRead,
                              child: Text(
                                context.tr('Mark all as read'),
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        Expanded(
                          child: _notifications.isEmpty
                              ? Center(
                                  child:
                                      Text(context.tr('No notifications yet')))
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: _notifications.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, indent: 72),
                                  itemBuilder: (context, index) {
                                    return _NotificationTile(
                                      item: _notifications[index],
                                      onTap: () =>
                                          _markRead(_notifications[index]),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  List<TextSpan> _buildBodySpans(String body) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(body)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: body.substring(last, match.start),
          style: const TextStyle(color: Color(0xFF555555), fontSize: 13.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13.5),
      ));
      last = match.end;
    }
    if (last < body.length) {
      spans.add(TextSpan(
        text: body.substring(last),
        style: const TextStyle(color: Color(0xFF555555), fontSize: 13.5),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? const Color(0xFFF0EDFF) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StoreAvatar(
                avatarUrl: item.actorAvatar, actorName: item.actorName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        if (item.actorName != null)
                          TextSpan(
                            text: '${item.actorName} ',
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5),
                          ),
                        ..._buildBodySpans(item.body),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timeAgo,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (unread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? actorName;

  const _StoreAvatar({this.avatarUrl, this.actorName});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? NetworkImage(avatarUrl!)
          : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(
              (actorName?.isNotEmpty == true)
                  ? actorName![0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
