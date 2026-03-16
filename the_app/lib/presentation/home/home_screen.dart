import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/providers/home_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/services/analytics_api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/geolocation_stub.dart'
    if (dart.library.html) '../../core/utils/geolocation_web.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../features/analytics/analytics_export.dart';
import '../common/constants/card_constants.dart';
import '../common/location_picker_screen.dart';
import '../common/widgets/stacked_product_images.dart';
import '../product/product_detail_screen.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/cards/store_chip.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/unified_app_bar.dart';
import 'main_navigation_screen.dart';
import 'widgets/category_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLikelyArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final AnalyticsApiService _analyticsApiService = AnalyticsApiService();
  String _selectedLocation = 'Algiers, Algeria';
  String? _selectedWilaya;
  String? _selectedBaladiya;
  double?
      _radiusKm; // null = address mode active; non-null = distance mode active
  double? _userLat;
  double? _userLng;
  bool _isNearbyLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocationFromProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final homeProvider = context.read<HomeProvider>();
    final postProvider = context.read<PostProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();
    await Future.wait([
      homeProvider.loadHomeData(),
      postProvider.refreshMarketplaceFeed(wilayaCode: _selectedWilaya),
      analyticsProvider.fetchRecommendations(limit: 80),
    ]);
  }

  void _initLocationFromProfile() {
    final userData = StorageService.getUserData();
    final rawAddress =
        (userData?['address'] ?? userData?['location'] ?? '').toString().trim();
    if (rawAddress.isEmpty) return;

    final parts = rawAddress
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;

    if (parts.length >= 2) {
      _selectedBaladiya = parts.first;
      _selectedWilaya = parts.last;
    } else {
      _selectedWilaya = parts.first;
      _selectedBaladiya = null;
    }
    _selectedLocation = rawAddress;
  }

  Future<void> _activateNearby(double km) async {
    if (km <= 0) {
      setState(() {
        _radiusKm = null;
        _selectedLocation = 'Algiers, Algeria';
      });
      return;
    }

    setState(() => _isNearbyLoading = true);
    try {
      double? lat;
      double? lng;
      if (kIsWeb) {
        final coords = await getWebCurrentPosition();
        lat = coords?['latitude'];
        lng = coords?['longitude'];
      } else {
        final pos = await LocationService.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }

      if (!mounted) return;
      if (lat == null || lng == null) {
        Helpers.showSnackBar(context, 'Could not get current GPS location');
        return;
      }

      setState(() {
        _userLat = lat;
        _userLng = lng;
        _radiusKm = km;
        _selectedLocation = '/';
      });
      _logFilterDistance(km);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('Location services are disabled')) {
        await _showLocationActionDialog(
          title: 'Enable GPS',
          message:
              'Location services are disabled. Please enable GPS to use nearby search.',
          openSettings: Geolocator.openLocationSettings,
          actionLabel: 'Open Location Settings',
        );
      } else if (msg.contains('permanently denied')) {
        await _showLocationActionDialog(
          title: 'Permission Required',
          message:
              'Location permission is permanently denied. Please allow it from app settings.',
          openSettings: Geolocator.openAppSettings,
          actionLabel: 'Open App Settings',
        );
      } else if (msg.contains('permission denied')) {
        Helpers.showSnackBar(context, 'Location permission denied');
      } else {
        Helpers.showSnackBar(context, 'Failed to get current GPS location');
      }
    } finally {
      if (mounted) {
        setState(() => _isNearbyLoading = false);
      }
    }
  }

  Future<void> _showLocationActionDialog({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
    required String actionLabel,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openSettings();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
        _selectedLocation = result.address;
        _radiusKm = null; // address mode active → clear distance
      });
      _logFilterWilaya(result.wilaya, result.baladiya);
    }
  }

  /// Filter a list of Posts to only those within [_radiusKm] km.
  /// Products without store coordinates are kept (fail-open).
  List<Post> _filterByRadius(List<Post> products) {
    if (_radiusKm == null || _userLat == null || _userLng == null) {
      return products;
    }
    return products.where((p) {
      if (!p.storeNearbyVisible) return false;
      final dist = Helpers.haversineDistance(
          _userLat, _userLng, p.storeLatitude, p.storeLongitude);
      if (dist == null) return false; // no coords -> exclude from nearby
      return dist <= _radiusKm!;
    }).toList();
  }

  bool get _isCityFilterActive =>
      _radiusKm == null &&
      _selectedWilaya != null &&
      _selectedWilaya!.trim().isNotEmpty;

  bool _addressMatchesSelectedLocation(String address) {
    if (!_isCityFilterActive) return true;
    if (address.trim().isEmpty) return false;
    final addressLower = address.toLowerCase();
    final wilayaLower = _selectedWilaya!.toLowerCase();
    if (!addressLower.contains(wilayaLower)) return false;
    if (_selectedBaladiya != null &&
        _selectedBaladiya!.trim().isNotEmpty &&
        !addressLower.contains(_selectedBaladiya!.toLowerCase())) {
      return false;
    }
    return true;
  }

  List<Post> _filterPostsForActiveLocation(List<Post> products) {
    if (_radiusKm != null) return _filterByRadius(products);
    if (_isCityFilterActive) {
      return products
          .where((p) => _addressMatchesSelectedLocation(p.storeAddress))
          .toList();
    }
    return products;
  }

  List<Offer> _filterOffersForActiveLocation(List<Offer> offers) {
    if (_radiusKm == null && !_isCityFilterActive) return offers;
    if (_radiusKm != null && _userLat != null && _userLng != null) {
      return offers.where((o) {
        if (!o.product.storeNearbyVisible) return false;
        final dist = Helpers.haversineDistance(_userLat, _userLng,
            o.product.storeLatitude, o.product.storeLongitude);
        if (dist == null) return false;
        return dist <= _radiusKm!;
      }).toList();
    }
    if (_isCityFilterActive) {
      return offers
          .where((o) => _addressMatchesSelectedLocation(o.product.storeAddress))
          .toList();
    }
    return offers;
  }

  List<Pack> _filterPacksForActiveLocation(List<Pack> packs) {
    if (_radiusKm != null) return _filterPacksByRadius(packs);
    if (_isCityFilterActive) {
      return packs
          .where((p) => p.deliveryWilayas
              .map((w) => w.toLowerCase())
              .contains(_selectedWilaya!.toLowerCase()))
          .toList();
    }
    return packs;
  }

  List<User> _filterStoresForActiveLocation(List<User> stores) {
    if (_radiusKm != null) {
      return stores.where((s) {
        if (!s.allowNearbyVisibility) return false;
        final dist = Helpers.haversineDistance(
          _userLat,
          _userLng,
          s.latitude,
          s.longitude,
        );
        if (dist == null) return false;
        return dist <= _radiusKm!;
      }).toList();
    }
    if (_isCityFilterActive) {
      return stores.where((s) {
        final address = s.address.isNotEmpty ? s.address : (s.city ?? '');
        return _addressMatchesSelectedLocation(address);
      }).toList();
    }
    return stores;
  }

  List<Pack> _filterPacksByRadius(List<Pack> packs) {
    if (_radiusKm == null || _userLat == null || _userLng == null) return packs;
    return packs.where((pack) {
      if (!pack.merchantNearbyVisible) return false;
      final dist = Helpers.haversineDistance(
        _userLat,
        _userLng,
        pack.merchantLatitude,
        pack.merchantLongitude,
      );
      if (dist == null) return false; // no coords -> exclude from nearby
      return dist <= _radiusKm!;
    }).toList();
  }

  double _gridCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const crossAxisCount = CardConstants.gridCrossAxisCount;
    final availableWidth = screenWidth -
        (CardConstants.gridHorizontalPadding * 2) -
        (CardConstants.gridCrossAxisSpacing * (crossAxisCount - 1));
    return availableWidth / crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified App Bar
                UnifiedAppBar(
                  showLocation: true,
                  showNotificationIcon: true,
                  location: _selectedLocation,
                  onLocationTap: _showLocationPicker,
                  radiusKm: _radiusKm,
                  onRadiusChanged: _activateNearby,
                  isNearbyLoading: _isNearbyLoading,
                ),

                const SizedBox(height: 16),

                // Recommendations (hidden for guests — AnalyticsProvider returns [] when not logged in)
                RecommendationsList(
                  onProductTap: _navigateToProductDetails,
                  onOfferTap: (offer) => _navigateToPromotionDetails(offer,
                      placement: 'home_feed'),
                ),
                const SizedBox(height: AppTheme.spacing24),

                _buildAdBannerBlock(),
                _buildOffersBlock(),
                _buildRecentProductsBlock(),
                _buildPacksBlock(),
                _buildFeaturedStoresBlock(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Section Headers ====================

  Widget _buildSectionHeader(
      String title, String action, VoidCallback onActionTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBannerBlock() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final ads = _filterOffersForActiveLocation(postProvider.adOffers);
        final hasAds = ads.isNotEmpty;
        final isLoading = postProvider.isLoadingOffers;
        if (!hasAds && !isLoading) return const SizedBox.shrink();
        return Column(
          children: [
            _buildAdBannerSection(),
            const SizedBox(height: AppTheme.spacing24),
          ],
        );
      },
    );
  }

  Widget _buildOffersBlock() {
    return Consumer2<PostProvider, AnalyticsProvider>(
      builder: (context, postProvider, analyticsProvider, child) {
        final offers = _filterOffersForActiveLocation(postProvider.offers);
        final hasOffers = offers.isNotEmpty;
        final isLoading = postProvider.isLoadingOffers;
        final hasError = postProvider.offersError != null;
        if (!hasOffers && !isLoading && !hasError) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Discounts', 'See All', () {
              Navigator.pushNamed(
                context,
                Routes.searchTab,
                arguments: {'type': 'Discounts', 'autoSearch': true},
              );
            }),
            const SizedBox(height: AppTheme.spacing16),
            _buildOffersSection(),
            const SizedBox(height: AppTheme.spacing24),
          ],
        );
      },
    );
  }

  Widget _buildRecentProductsBlock() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final products =
            _filterPostsForActiveLocation(homeProvider.recentProducts);
        final hasProducts = products.isNotEmpty;
        final isLoading = homeProvider.isLoadingProducts;
        final hasError = homeProvider.productsError != null;
        if (!hasProducts && !isLoading && !hasError) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Latest Products', 'View All', () {
              Navigator.pushNamed(
                context,
                Routes.searchTab,
                arguments: {'type': 'Products', 'autoSearch': true},
              );
            }),
            const SizedBox(height: AppTheme.spacing16),
            _buildRecentProductsSection(),
            const SizedBox(height: AppTheme.spacing24),
          ],
        );
      },
    );
  }

  Widget _buildPacksBlock() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final packs = _filterPacksForActiveLocation(homeProvider.packs);
        final hasPacks = packs.isNotEmpty;
        final isLoading = homeProvider.isLoadingPacks;
        final hasError = homeProvider.packsError != null;
        if (!hasPacks && !isLoading && !hasError) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Featured Packs', 'View All', () {
              Navigator.pushNamed(
                context,
                Routes.searchTab,
                arguments: {'type': 'Packs', 'autoSearch': true},
              );
            }),
            const SizedBox(height: AppTheme.spacing16),
            _buildPacksSection(),
            const SizedBox(height: AppTheme.spacing24),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedStoresBlock() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final stores =
            _filterStoresForActiveLocation(homeProvider.featuredStores);
        final hasStores = stores.isNotEmpty;
        final isLoading = homeProvider.isLoadingStores;
        final hasError = homeProvider.storesError != null;
        if (!hasStores && !isLoading && !hasError) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Featured Stores', 'View All', () {
              Navigator.pushNamed(
                context,
                Routes.searchTab,
                arguments: {'type': 'Stores', 'autoSearch': true},
              );
            }),
            const SizedBox(height: AppTheme.spacing16),
            _buildFeaturedStoresSection(),
          ],
        );
      },
    );
  }

  // ==================== Categories Section ====================

  Widget _buildCategoriesSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingCategories &&
            homeProvider.categories.isEmpty) {
          return _buildCategoriesShimmer();
        }

        final categories = homeProvider.categories;
        if (categories.isEmpty) {
          return _buildCategoriesShimmer();
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryItem(
                icon: category.iconData,
                label: category.name,
                color: _getCategoryColor(index),
                onTap: () => _navigateToCategory(category.id, category.name),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return ShimmerLoading(
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppTheme.spacing12),
          itemBuilder: (context, index) {
            return Column(
              children: [
                const ShimmerBox(width: 70, height: 70, borderRadius: 16),
                const SizedBox(height: 8),
                const ShimmerBox(width: 50, height: 14),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.categoryElectronics,
      AppColors.categoryFashion,
      AppColors.categoryHome,
      AppColors.categorySports,
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
    ];
    return colors[index % colors.length];
  }

  Widget _buildCompactErrorState({
    required double height,
    required IconData icon,
    required String message,
    required VoidCallback onRetry,
  }) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
            ),
            AppTextButton(
              text: 'Retry',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactEmptyState({
    required double height,
    required String message,
    IconData icon = Icons.search_off_rounded,
    String title = 'No Results',
  }) {
    return SizedBox(
      height: height,
      child: EmptyStateWidget(
        compact: true,
        icon: icon,
        title: title,
        message: message,
      ),
    );
  }

  // ==================== Featured Stores Section ====================

  Widget _buildFeaturedStoresSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingStores &&
            homeProvider.featuredStores.isEmpty) {
          return const StoreListSkeleton(itemCount: 3);
        }

        if (homeProvider.storesError != null &&
            homeProvider.featuredStores.isEmpty) {
          return _buildCompactErrorState(
            height: 160,
            icon: Icons.store_outlined,
            message: 'Failed to load stores',
            onRetry: () => homeProvider.loadFeaturedStores(),
          );
        }

        final stores =
            _filterStoresForActiveLocation(homeProvider.featuredStores);
        if (stores.isEmpty) {
          return _buildCompactEmptyState(
            height: 160,
            message: _radiusKm != null
                ? 'No stores found within ${_radiusKm!.toInt()} km'
                : (_isCityFilterActive
                    ? 'No stores found in this location'
                    : 'No featured stores at the moment'),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final u = stores[index];
              return StoreChip(
                imageUrl: u.profileImage,
                name: u.fullName,
                rating: u.averageRating,
                followersCount: u.followersCount,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.store,
                  arguments: u.id,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Hot Deals Section ====================

  Widget _buildHotDealsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          // Fire Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.hotDealRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: AppTheme.spacing8),

          // Title
          const Text(
            'Hot\nDeals',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.1,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          // Timer
          _buildTimerBox('02'),
          _buildTimerSeparator(),
          _buildTimerBox('45'),
          _buildTimerSeparator(),
          _buildTimerBox('30'),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: AppTextStyles.timerText,
      ),
    );
  }

  Widget _buildTimerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHotDealsSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingHotDeals && homeProvider.hotDeals.isEmpty) {
          return _buildProductsShimmer();
        }

        final hotDeals = _filterPostsForActiveLocation(homeProvider.hotDeals);
        if (hotDeals.isEmpty) {
          return _buildCompactEmptyState(
            height: 220,
            message: _radiusKm != null
                ? 'No hot deals found within ${_radiusKm!.toInt()} km'
                : (_isCityFilterActive
                    ? 'No hot deals found in this location'
                    : 'No hot deals at the moment'),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: hotDeals.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: CardConstants.gridCrossAxisSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: _gridCardWidth(context),
                child: ProductCard(
                  product: hotDeals[index],
                  userLat: _userLat,
                  userLng: _userLng,
                  onTap: () => _navigateToProductDetails(hotDeals[index]),
                  onFavoriteTap: () => _toggleFavorite(hotDeals[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Packs Section ====================

  Widget _buildPacksSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingPacks && homeProvider.packs.isEmpty) {
          return _buildProductsShimmer();
        }

        if (homeProvider.packsError != null && homeProvider.packs.isEmpty) {
          return _buildCompactErrorState(
            height: 200,
            icon: Icons.inventory_2_outlined,
            message: 'Failed to load packs',
            onRetry: () => homeProvider.loadFeaturedPacks(),
          );
        }

        final packs = _filterPacksForActiveLocation(homeProvider.packs);
        if (packs.isEmpty) {
          return _buildCompactEmptyState(
            height: 200,
            message: _radiusKm != null
                ? 'No packs found within ${_radiusKm!.toInt()} km'
                : (_isCityFilterActive
                    ? 'No packs found in this location'
                    : 'No packs available at the moment'),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: packs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: CardConstants.gridCrossAxisSpacing),
            itemBuilder: (context, index) {
              final pack = packs[index];
              return SizedBox(
                width: _gridCardWidth(context),
                child: PackCard(pack: pack),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPackCard(BuildContext context, Pack pack) {
    final discountPercent = pack.totalPrice > 0
        ? ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100)
            .round()
        : 0;

    return GestureDetector(
      onTap: () {
        // Navigate to pack details
        Navigator.pushNamed(context, Routes.packDetails, arguments: pack);
      },
      child: Container(
        width: _gridCardWidth(context),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: AppConstants.spacing12,
              offset: const Offset(0, AppConstants.cardElevation),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pack Header with gradient
            Container(
              height: AppConstants.spacing40 * 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurple.withValues(alpha: 0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.cardRadius)),
              ),
              child: Stack(
                children: [
                  // Pack Images/Icon
                  Center(
                    child: StackedProductImages(products: pack.products),
                  ),
                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Save $discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Product count badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pack.products.length} Products',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pack Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildProductSummary(pack.products),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price Row
                    Row(
                      children: [
                        Text(
                          Helpers.formatPrice(pack.discountPrice),
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (pack.totalPrice > pack.discountPrice)
                          Text(
                            Helpers.formatPrice(pack.totalPrice),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Recent Products Section ====================

  Widget _buildRecentProductsSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingProducts &&
            homeProvider.recentProducts.isEmpty) {
          return _buildProductsShimmer();
        }

        if (homeProvider.productsError != null &&
            homeProvider.recentProducts.isEmpty) {
          return _buildCompactErrorState(
            height: 280,
            icon: Icons.shopping_bag_outlined,
            message: 'Failed to load products',
            onRetry: () => homeProvider.loadRecentProducts(),
          );
        }

        final products =
            _filterPostsForActiveLocation(homeProvider.recentProducts);
        if (products.isEmpty) {
          return _buildCompactEmptyState(
            height: 220,
            message: _radiusKm != null
                ? 'No products found within ${_radiusKm!.toInt()} km'
                : (_isCityFilterActive
                    ? 'No products found in this location'
                    : 'No products available at the moment'),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: CardConstants.gridCrossAxisSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: _gridCardWidth(context),
                child: ProductCard(
                  product: products[index],
                  userLat: _userLat,
                  userLng: _userLng,
                  onTap: () => _navigateToProductDetails(products[index]),
                  onFavoriteTap: () => _toggleFavorite(products[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsShimmer() {
    return ShimmerLoading(
      child: SizedBox(
        height: 280,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
              horizontal: CardConstants.gridHorizontalPadding),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) =>
              const SizedBox(width: CardConstants.gridCrossAxisSpacing),
          itemBuilder: (context, index) {
            return SizedBox(
              width: _gridCardWidth(context),
              child: const ProductCardSkeleton(),
            );
          },
        ),
      ),
    );
  }

  // ==================== Ad Banner Section ====================

  Widget _buildAdBannerSection() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final ads = _filterOffersForActiveLocation(postProvider.adOffers);
        if (postProvider.isLoadingOffers && ads.isEmpty) {
          return const SizedBox(height: 220);
        }
        if (ads.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 228,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final storeName = ad.product.storeName;
              final productTitle = ad.product.title;
              final isStoreRtl = _isLikelyArabic(storeName);
              final isTitleRtl = _isLikelyArabic(productTitle);
              final metrics = <String>[
                if (ad.impressionsCount > 0) '${ad.impressionsCount} views',
                if (ad.clicksCount > 0) '${ad.clicksCount} clicks',
                if (ad.remainingImpressions != null)
                  '${ad.remainingImpressions} left',
              ];

              return GestureDetector(
                onTap: () =>
                    _navigateToPromotionDetails(ad, placement: 'home_top'),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A2107).withOpacity(0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF1D6),
                        Color(0xFFFFD39B),
                        Color(0xFFFFB26B)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: LayoutBuilder(
                                builder: (context, innerConstraints) {
                                  final compact =
                                      innerConstraints.maxHeight < 190;
                                  final ultraCompact =
                                      innerConstraints.maxHeight < 180;
                                  return Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      compact ? 18 : 22,
                                      compact ? 14 : 20,
                                      compact ? 12 : 14,
                                      compact ? 14 : 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: compact ? 10 : 12,
                                                vertical: compact ? 5 : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2C1808),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Sponsored',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: compact ? 10 : 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                storeName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: isStoreRtl
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontSize: compact ? 11 : 12,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF7A3F12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: compact ? 6 : 8),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder:
                                                (context, textConstraints) {
                                              final textTight =
                                                  textConstraints.maxHeight <
                                                      115;
                                              final showDiscount =
                                                  !ultraCompact && !textTight;
                                              final showMetrics = !compact &&
                                                  !textTight &&
                                                  metrics.isNotEmpty;

                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productTitle,
                                                    maxLines: textTight
                                                        ? 1
                                                        : (compact ? 1 : 2),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textDirection: isTitleRtl
                                                        ? TextDirection.rtl
                                                        : TextDirection.ltr,
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: textTight
                                                          ? 15
                                                          : (ultraCompact
                                                              ? 16
                                                              : (compact
                                                                  ? 18
                                                                  : 20)),
                                                      height: 1.08,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: const Color(
                                                          0xFF2E1C0A),
                                                    ),
                                                  ),
                                                  if (showDiscount)
                                                    SizedBox(
                                                        height:
                                                            compact ? 6 : 8),
                                                  if (showDiscount)
                                                    Text(
                                                      '${ad.discountPercentage}% OFF',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize:
                                                            compact ? 12 : 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: const Color(
                                                            0xFFB44708),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                      height: textTight
                                                          ? 4
                                                          : (ultraCompact
                                                              ? 6
                                                              : 2)),
                                                  Text(
                                                    Helpers.formatPrice(
                                                        ad.newPrice),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: textTight
                                                          ? 18
                                                          : (ultraCompact
                                                              ? 19
                                                              : (compact
                                                                  ? 21
                                                                  : 24)),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: const Color(
                                                          0xFF1D140D),
                                                    ),
                                                  ),
                                                  if (showMetrics) ...[
                                                    const SizedBox(height: 8),
                                                    SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children: metrics
                                                            .map((metric) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.62),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          999),
                                                            ),
                                                            child: Text(
                                                              metric,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color(
                                                                    0xFF5E3211),
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        if (!compact && !ultraCompact) ...[
                                          SizedBox(height: compact ? 6 : 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: compact ? 12 : 14,
                                              vertical: compact ? 8 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2D1908),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'View deal',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: compact ? 12 : 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 16, 16, 16),
                                child: Hero(
                                  tag: 'home-ad-${ad.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                      child: ad.product.image != null &&
                                              ad.product.image!.isNotEmpty
                                          ? Image.network(
                                              ad.product.image!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              child: const Icon(
                                                Icons.campaign_rounded,
                                                size: 56,
                                                color: Color(0xFF8A3C00),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Offers Section ====================

  Widget _buildOffersSection() {
    return Consumer2<PostProvider, AnalyticsProvider>(
      builder: (context, postProvider, analyticsProvider, child) {
        final offers = postProvider.offers;

        if (postProvider.isLoadingOffers && offers.isEmpty) {
          return _buildProductsShimmer();
        }

        if (postProvider.offersError != null && offers.isEmpty) {
          return _buildCompactErrorState(
            height: 280,
            icon: Icons.local_offer_outlined,
            message: 'Failed to load discounts',
            onRetry: () => postProvider.loadOffers(),
          );
        }

        // Apply radius filter on the embedded product's store location
        final filteredOffers = _filterOffersForActiveLocation(offers);

        final rankedOffers = _rankOffersByUserSignals(
          filteredOffers,
          analyticsProvider.recommendations,
        );

        if (rankedOffers.isEmpty) {
          return _buildCompactEmptyState(
            height: 220,
            message: _radiusKm != null
                ? 'No discounts found within ${_radiusKm!.toInt()} km'
                : (_isCityFilterActive
                    ? 'No discounts found in this location'
                    : 'No discounts available at the moment'),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: rankedOffers.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: CardConstants.gridCrossAxisSpacing),
            itemBuilder: (context, index) {
              final offer = rankedOffers[index];
              return SizedBox(
                width: _gridCardWidth(context),
                child: PromotionCard(
                  offer: offer,
                  userLat: _userLat,
                  userLng: _userLng,
                  onTap: () => _navigateToPromotionDetails(
                    offer,
                    placement: 'home_feed',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Offer> _rankOffersByUserSignals(
    List<Offer> offers,
    List<dynamic> recommendations,
  ) {
    if (offers.isEmpty) return offers;
    final recScoreByProductId = <int, double>{};
    for (var i = 0; i < recommendations.length; i++) {
      final item = recommendations[i];
      if (item is! Map<String, dynamic>) continue;
      final product = item['product'];
      int? productId;
      if (product is Map<String, dynamic>) {
        productId = int.tryParse('${product['id'] ?? ''}');
      }
      if (productId == null) continue;
      final score = double.tryParse('${item['score'] ?? ''}') ?? 0.0;
      recScoreByProductId[productId] = score +
          ((recommendations.length - i).clamp(0, recommendations.length) * 1.2);
    }

    final ranked = List<Offer>.from(offers);
    ranked.sort((a, b) {
      final aRec = recScoreByProductId[a.product.id] ?? 0.0;
      final bRec = recScoreByProductId[b.product.id] ?? 0.0;
      final aFresh = a.isNearEnding ? 8.0 : 0.0;
      final bFresh = b.isNearEnding ? 8.0 : 0.0;
      final aScore = (aRec * 0.65) + (a.discountPercentage * 0.25) + aFresh;
      final bScore = (bRec * 0.65) + (b.discountPercentage * 0.25) + bFresh;
      return bScore.compareTo(aScore);
    });
    return ranked;
  }

  // ==================== Navigation Methods ====================

  void _showNotifications() {
    Helpers.showSnackBar(context, 'Notifications coming soon');
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, Routes.searchTab);
  }

  void _navigateToSearchTab(String query) {
    // Find the MainNavigationScreen ancestor and switch to search tab
    final mainNavState =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavState != null) {
      mainNavState.navigateToSearchWithQuery(query);
      _searchController.clear();
    }
  }

  void _showFilters() {
    Helpers.showSnackBar(context, 'Filters coming soon');
  }

  void _navigateToCategory(int categoryId, String categoryName) {
    Navigator.pushNamed(
      context,
      Routes.searchTab,
      arguments: {'categoryId': categoryId, 'categoryName': categoryName},
    );
  }

  void _showPromoDetails() {
    Helpers.showSnackBar(context, 'New User Offer');
  }

  void _navigateToProductDetails(Post product) {
    final discoveryMode = _radiusKm != null
        ? 'nearby'
        : ((_selectedWilaya != null && _selectedWilaya!.isNotEmpty)
            ? 'location'
            : 'none');
    if (kDebugMode) {
      debugPrint(
        'Home->ProductDetails: mode=$discoveryMode radius=$_radiusKm wilaya=$_selectedWilaya baladiya=$_selectedBaladiya',
      );
    }
    _logClick(product);
    Navigator.pushNamed(
      context,
      Routes.productDetails,
      arguments: ProductDetailsArgs(
        product: product,
        sourceSurface: 'home',
        discoveryMode: discoveryMode,
        distanceKm: _radiusKm,
        wilayaCode: _isCityFilterActive ? _selectedWilaya : null,
        searchQuery: null,
      ),
    );
  }

  void _navigateToPromotionDetails(Offer offer,
      {String placement = 'home_feed'}) {
    _logPromotionClick(offer, placement: placement);
    final productWithPromotion = offer.product.copyWith(
      price: offer.newPrice,
      oldPrice: offer.product.price,
      discountPercentage: offer.discountPercentage,
    );
    _navigateToProductDetails(productWithPromotion);
  }

  Map<String, dynamic> _buildDiscoveryMetadata() {
    final discoveryMode = _radiusKm != null
        ? 'nearby'
        : (_isCityFilterActive ? 'location' : 'none');
    final meta = <String, dynamic>{
      'discovery_mode': discoveryMode,
    };
    if (_radiusKm != null) meta['distance_km'] = _radiusKm;
    if (_isCityFilterActive && _selectedWilaya != null) {
      meta['wilaya_code'] = _selectedWilaya;
    }
    if (_selectedBaladiya != null && _selectedBaladiya!.isNotEmpty) {
      meta['baladiya'] = _selectedBaladiya;
    }
    return meta;
  }

  void _logClick(Post product) {
    final meta = _buildDiscoveryMetadata();
    _analyticsApiService.logDiscoveryClick(
      productId: product.id,
      storeId: product.storeId > 0 ? product.storeId : null,
      categoryId: product.categoryId,
      discoveryMode: (meta['discovery_mode'] as String?) ?? 'none',
      distanceKm: (meta['distance_km'] as num?)?.toDouble(),
      wilayaCode: meta['wilaya_code'] as String?,
    );
  }

  void _logPromotionClick(Offer offer, {String placement = 'home_feed'}) {
    final meta = _buildDiscoveryMetadata();
    _analyticsApiService.logPromotionClick(
      promotionId: offer.id,
      productId: offer.product.id,
      storeId: offer.product.storeId > 0 ? offer.product.storeId : null,
      placement: placement,
      discoveryMode: (meta['discovery_mode'] as String?) ?? 'none',
      distanceKm: (meta['distance_km'] as num?)?.toDouble(),
      wilayaCode: meta['wilaya_code'] as String?,
      searchQuery: null,
    );
    if (offer.kind == 'advertising') {
      PostRepository.registerPromotionClick(offer.id, kind: offer.kind);
    }
  }

  void _logFilterWilaya(String wilaya, String baladiya) {
    _analyticsApiService.logWilayaFilter(
      wilayaCode: wilaya,
      baladiya: baladiya,
    );
  }

  void _logFilterDistance(double km) {
    _analyticsApiService.logDistanceFilter(
      distanceKm: km,
    );
  }

  void _toggleFavorite(Post product) {
    Helpers.showSnackBar(context, 'Added to favorites');
  }

  String _buildProductSummary(List<dynamic> products) {
    if (products.isEmpty) return 'Empty pack';

    const maxItems = 3;
    final itemsToShow = products.take(maxItems).toList();

    final validItems = itemsToShow
        .map((product) {
          int quantity = 1;
          String name = '';

          // Handle PackProduct object
          if (product is PackProduct) {
            quantity = product.quantity;
            name = product.productName;
          } else if (product is Map<String, dynamic>) {
            quantity = product['quantity'] ?? 1;
            name = product['product_name']?.toString().trim() ?? '';
          }

          if (name.isNotEmpty && name != 'null') {
            return '$quantity $name';
          }
          return null;
        })
        .where((item) => item != null)
        .toList();

    if (validItems.isEmpty) {
      return '${products.length} Products';
    }

    String summary = validItems.join(' + ');

    if (products.length > maxItems) {
      summary += ' ...';
    }

    return summary;
  }
}
