import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/post_provider.dart';
import '../../core/routing/routes.dart';
import '../shared_widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../store/stores_list_screen.dart';
import '../search/search_tab_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

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
  String? _searchQuery;

  // Method to navigate to search tab with a query
  void navigateToSearchWithQuery(String query) {
    setState(() {
      _searchQuery = query;
      _selectedIndex = 1; // Switch to Search tab
    });
  }

  // Build screens dynamically (5 screens for 5-item bottom nav)
  List<Widget> get _screens => [
    const HomeScreen(),           // 0 - Home
    const FavoritesScreen(),      // 1 - Favorites
    const StoresListScreen(),     // 2 - My Stores (Followed)
    NotificationsScreen(),        // 3 - Notifications
    const ProfileScreen(),        // 4 - Profile
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Use initial index from widget
    _searchQuery = widget.initialSearchQuery; // Use initial search query if provided
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
    // Only show AppBar on Home (0) tab - removed for now as screens have their own headers
    final showAppBar = false;

    return Directionality(
      textDirection: TextDirection.ltr,  // Changed to LTR
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: showAppBar ? AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.location_on, color: AppColors.primaryColor, size: 24),
          ),
          leadingWidth: 56,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyColor,
                ),
              ),
              Text(
                'Algiers, Algeria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          actions: [
            // Search Icon
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchTabScreen(initialQuery: null),
                  ),
                );
              },
              icon: const Icon(Icons.search_outlined, size: 24),
              color: AppColors.blackColor,
            ),
            // Notification Icon
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              color: AppColors.blackColor,
            ),
          ],
        ) : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
