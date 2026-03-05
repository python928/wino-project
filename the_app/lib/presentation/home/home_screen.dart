import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/models/pack_model.dart';
import '../shared_widgets/shimmer_loading.dart';
import 'widgets/category_item.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/store_chip.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/cards/pack_card.dart';
import 'main_navigation_screen.dart';
import '../common/location_picker_screen.dart';
import '../shared_widgets/unified_app_bar.dart';
import '../common/constants/card_constants.dart';
import '../../features/analytics/analytics_export.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/geolocation_stub.dart'
    if (dart.library.html) '../../core/utils/geolocation_web.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
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
    await Future.wait([
      homeProvider.loadHomeData(),
      postProvider.loadPosts(),
      postProvider.loadOffers(),
    ]);
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
                const RecommendationsList(),
                const SizedBox(height: AppTheme.spacing24),

                // Discounts
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

                // Latest Products
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

                // Featured Packs
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

                // Featured Stores
                _buildSectionHeader('Featured Stores', 'View All', () {
                  Navigator.pushNamed(
                    context,
                    Routes.searchTab,
                    arguments: {'type': 'Stores', 'autoSearch': true},
                  );
                }),
                const SizedBox(height: AppTheme.spacing16),
                _buildFeaturedStoresSection(),

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
          return SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load stores',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  AppTextButton(
                    text: 'Retry',
                    onPressed: () => homeProvider.loadFeaturedStores(),
                  ),
                ],
              ),
            ),
          );
        }

        final stores = homeProvider.featuredStores; // List<User>
        if (stores.isEmpty) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'No featured stores at the moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
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

        final hotDeals = _filterByRadius(homeProvider.hotDeals);
        if (hotDeals.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                _radiusKm != null
                    ? 'No hot deals found within ${_radiusKm!.toInt()} km'
                    : 'No hot deals at the moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
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
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load packs',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  AppTextButton(
                    text: 'Retry',
                    onPressed: () => homeProvider.loadFeaturedPacks(),
                  ),
                ],
              ),
            ),
          );
        }

        final packs = _filterPacksByRadius(homeProvider.packs);
        if (packs.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                _radiusKm != null
                    ? 'No packs found within ${_radiusKm!.toInt()} km'
                    : 'No packs available at the moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
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
                    child: _buildStackedProductImages(pack.products),
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
          return SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load products',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  AppTextButton(
                    text: 'Retry',
                    onPressed: () => homeProvider.loadRecentProducts(),
                  ),
                ],
              ),
            ),
          );
        }

        final products = _filterByRadius(homeProvider.recentProducts);
        if (products.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                _radiusKm != null
                    ? 'No products found within ${_radiusKm!.toInt()} km'
                    : 'No products available at the moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
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

  // ==================== Offers Section ====================

  Widget _buildOffersSection() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final offers = postProvider.offers;

        if (postProvider.isLoadingOffers && offers.isEmpty) {
          return _buildProductsShimmer();
        }

        if (postProvider.offersError != null && offers.isEmpty) {
          return SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load discounts',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  AppTextButton(
                    text: 'Retry',
                    onPressed: () => postProvider.loadOffers(),
                  ),
                ],
              ),
            ),
          );
        }

        // Apply radius filter on the embedded product's store location
        final filteredOffers =
            (_radiusKm == null || _userLat == null || _userLng == null)
                ? offers
                : offers.where((o) {
                    if (!o.product.storeNearbyVisible) return false;
                    final dist = Helpers.haversineDistance(_userLat, _userLng,
                        o.product.storeLatitude, o.product.storeLongitude);
                    if (dist == null) return false;
                    return dist <= _radiusKm!;
                  }).toList();

        if (filteredOffers.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                _radiusKm != null
                    ? 'No discounts found within ${_radiusKm!.toInt()} km'
                    : 'No discounts available at the moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: filteredOffers.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: CardConstants.gridCrossAxisSpacing),
            itemBuilder: (context, index) {
              final offer = filteredOffers[index];
              return SizedBox(
                width: _gridCardWidth(context),
                child: PromotionCard(
                  offer: offer,
                  userLat: _userLat,
                  userLng: _userLng,
                ),
              );
            },
          ),
        );
      },
    );
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
    Navigator.pushNamed(
      context,
      Routes.productDetails,
      arguments: product,
    );
  }

  void _toggleFavorite(Post product) {
    Helpers.showSnackBar(context, 'Added to favorites');
  }

  Widget _buildStackedProductImages(List<dynamic> products) {
    if (products.isEmpty) {
      return Icon(
        Icons.inventory_2_rounded,
        size: 50,
        color: Colors.white.withValues(alpha: 0.9),
      );
    }

    // Show up to 3 product images stacked
    final imagesToShow = products.take(3).toList();
    final imageCount = imagesToShow.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Image size adapts to container
        final imageSize = (availableHeight * 0.65).clamp(45.0, 70.0);
        final overlap = imageSize * 0.4;
        final totalWidth = imageSize + (imageCount - 1) * (imageSize - overlap);
        final startX = (availableWidth - totalWidth) / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < imageCount; i++)
              Positioned(
                left: startX + i * (imageSize - overlap),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _getProductImage(imagesToShow[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _getProductImage(dynamic product) {
    String? imageUrl;

    // Handle PackProduct object
    if (product is PackProduct) {
      imageUrl = product.productImage;
    } else if (product is Map<String, dynamic>) {
      imageUrl = product['product_image'] as String?;
    }

    // Get the full image URL using ApiConfig
    final fullImageUrl = ApiConfig.getImageUrl(imageUrl);

    if (fullImageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2,
          size: 18,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
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
