import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/post_provider.dart';
import '../shared_widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0; // Start with Home

  // Screens: Home, Notifications, Profile
  final List<Widget> _screens = const [
    HomeScreen(),           // 0 - الرئيسية
    NotificationsScreen(),  // 1 - الإشعارات
    ProfileScreen(),        // 2 - حسابي
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTokenIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshTokenIfNeeded();
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    try {
      await ApiService.proactiveRefreshIfNeeded();
    } catch (e) {
      debugPrint('Token refresh check failed: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Reload data when home is selected
    if (index == 0) {
      final postProvider = context.read<PostProvider>();
      postProvider.loadPosts();
      postProvider.loadOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          notificationsBadgeCount: 2,
        ),
      ),
    );
  }
}
