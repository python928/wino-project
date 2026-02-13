import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/post_provider.dart';
import '../shared_widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../store/stores_list_screen.dart';
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

  // Build screens dynamically (4 screens for 4-item bottom nav)
  List<Widget> get _screens => [
    const HomeScreen(),           // 0 - Home
    const FavoritesScreen(),      // 1 - Favorites
    const StoresListScreen(),     // 2 - My Stores (Followed)
    const ProfileScreen(),        // 3 - Profile (was 4)
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
    return Directionality(
      textDirection: TextDirection.ltr,  // Changed to LTR
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: null,  // No AppBar as screens have their own headers
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
