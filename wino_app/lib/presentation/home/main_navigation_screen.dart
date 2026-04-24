import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_badge_service.dart';
import '../../core/theme/app_colors.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../shared_widgets/custom_bottom_nav.dart';
import '../store/stores_list_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialSearchQuery;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialSearchQuery,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  int _unreadCount = 0;
  Timer? _badgeTimer;
  late final VoidCallback _badgeListener;

  // Method to navigate to search tab with a query
  void navigateToSearchWithQuery(String query) {
    setState(() {
      _selectedIndex = 1; // Switch to Search tab
    });
  }

  // Build screens dynamically (4 screens for 4-item bottom nav)
  List<Widget> get _screens => [
        const HomeScreen(), // 0 - Home
        const FavoritesScreen(), // 1 - Favorites
        const StoresListScreen(), // 2 - My Stores (Followed)
        ProfileScreen(isActive: _selectedIndex == 3), // 3 - Profile (was 4)
      ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Use initial index from widget
    WidgetsBinding.instance.addObserver(this);
    _refreshTokenIfNeeded();
    _badgeListener = () {
      if (!mounted) return;
      setState(() {
        _unreadCount = NotificationBadgeService.instance.unreadCount.value;
      });
    };
    NotificationBadgeService.instance.unreadCount.addListener(_badgeListener);

    // Fetch badge count immediately and set up periodic refresh
    _fetchUnreadBadgeCount();
    _badgeTimer = Timer.periodic(
        const Duration(minutes: 2), (_) => _fetchUnreadBadgeCount());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletProvider>().fetchWallet(notifyStart: false);
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    NotificationBadgeService.instance.unreadCount
        .removeListener(_badgeListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshTokenIfNeeded();
      _fetchUnreadBadgeCount();
      context.read<WalletProvider>().fetchWallet(notifyStart: false);
      NotificationBadgeService.instance.syncMissedUnreadToShade();
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    try {
      await ApiService.proactiveRefreshIfNeeded();
    } catch (e) {
      debugPrint('Token refresh check failed: $e');
    }
  }

  Future<void> _fetchUnreadBadgeCount() async {
    try {
      final response = await ApiService.get(ApiConfig.notificationsUnreadCount);
      if (response is Map<String, dynamic> &&
          response.containsKey('unread_count')) {
        if (mounted) {
          final next = response['unread_count'] as int;
          setState(() => _unreadCount = next);
          NotificationBadgeService.instance.unreadCount.value = next;
        }
      }
    } catch (e) {
      final message = e.toString();
      final isExpectedAuthExpiry = message.contains('Session expired') ||
          message.contains('Please login again');
      if (!isExpectedAuthExpiry) {
        debugPrint('Failed to fetch unread badge count: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveUnread = NotificationBadgeService.instance.unreadCount.value;
    final badge = liveUnread > 0 ? liveUnread : _unreadCount;
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: null, // No AppBar as screens have their own headers
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          notificationsBadgeCount: badge > 0 ? badge : null,
        ),
      ),
    );
  }
}
