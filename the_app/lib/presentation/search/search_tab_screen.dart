import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../common/constants/card_constants.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toggle_button.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/helpers.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/pack_model.dart';
import '../product/product_detail_screen.dart';
import '../common/location_picker_screen.dart';
import '../common/radius_picker_sheet.dart';
import '../../core/widgets/app_button.dart';
import 'category_selection_screen.dart';
import '../shared_widgets/cards/store_chip.dart';
import '../shared_widgets/location_mode_switcher.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/geolocation_stub.dart'
    if (dart.library.html) '../../core/utils/geolocation_web.dart';

class SearchTabScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialType;
  final bool autoSearchOnOpen;

  const SearchTabScreen({
    super.key,
    this.initialQuery,
    this.initialType,
    this.autoSearchOnOpen = false,
  });

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _hasSearched = false;
  bool _showAllStoresInAllView = false;

  // Selected type
  String _selectedType = 'All';
  final List<ToggleOption> _typeOptions = const [
    ToggleOption(label: 'All', icon: Icons.grid_view_rounded, value: 'All'),
    ToggleOption(
        label: 'Products', icon: Icons.shopping_bag_rounded, value: 'Products'),
    ToggleOption(
        label: 'Discounts', icon: Icons.percent_rounded, value: 'Discounts'),
    ToggleOption(
        label: 'Packs', icon: Icons.inventory_2_rounded, value: 'Packs'),
    ToggleOption(label: 'Stores', icon: Icons.store_rounded, value: 'Stores'),
  ];

  // Filters
  Set<int> _selectedCategoryIds = {};
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  // Location filter (single source of truth — uses LocationPickerScreen)
  String _selectedLocation = '';
  String? _selectedWilaya;
  String? _selectedBaladiya;

  // Distance filter — mutually exclusive with location selection
  double? _distanceKm;

  // Stores search
  List<User> _searchedStores = [];
  bool _isLoadingStores = false;
  static const int _pageSize = 12;
  int _allVisibleCount = _pageSize;
  int _productsVisibleCount = _pageSize;
  int _discountsVisibleCount = _pageSize;
  int _packsVisibleCount = _pageSize;
  int _storesVisibleCount = _pageSize;

  // User location for distance calculation
  double? _userLat;
  double? _userLng;
  bool _isNearbyLoading = false;

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Highest Rated',
    'Lowest Price',
    'Highest Price',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize selected type from widget parameter
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      final type = widget.initialType!;
      if (type == 'Stores') {
        _selectedType = 'All';
        _showAllStoresInAllView = true;
      } else {
        _selectedType = _typeOptions.any((o) => o.value == type) ? type : 'All';
      }
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }

    if (widget.autoSearchOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _performSearch();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SearchTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _resetVisibleCounts() {
    _allVisibleCount = _pageSize;
    _productsVisibleCount = _pageSize;
    _discountsVisibleCount = _pageSize;
    _packsVisibleCount = _pageSize;
    _storesVisibleCount = _pageSize;
  }

  Widget _buildLoadMoreButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.expand_more_rounded),
        label: const Text('Load more'),
      ),
    );
  }

  void _performSearch() {
    _searchFocus.unfocus();

    if (!_hasSearched) {
      setState(() => _hasSearched = true);
    }
    _resetVisibleCounts();

    final postProvider = context.read<PostProvider>();
    postProvider.loadPosts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      categoryId:
          _selectedCategoryIds.length == 1 ? _selectedCategoryIds.first : null,
    );
    postProvider.loadOffers();
    context.read<HomeProvider>().loadFeaturedPacks();
    _searchStores();
  }

  Future<void> _performSearchRefresh() async {
    _searchFocus.unfocus();
    if (!_hasSearched) {
      setState(() => _hasSearched = true);
    }
    _resetVisibleCounts();

    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();

    await Future.wait([
      postProvider.loadPosts(
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        categoryId: _selectedCategoryIds.length == 1
            ? _selectedCategoryIds.first
            : null,
      ),
      postProvider.loadOffers(),
      homeProvider.loadFeaturedPacks(),
      _searchStores(),
    ]);
  }

  Future<void> _refreshSearch() async {
    if (_hasSearched) {
      await _performSearchRefresh();
      return;
    }
    await Future.wait([
      context.read<HomeProvider>().loadHomeData(),
      _searchStores(),
    ]);
  }

  Widget _buildPreSearchState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to search',
                    style:
                        AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose type and categories, then tap Search',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _searchStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await StoreRepository.searchStores(
        query:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      if (mounted) {
        setState(() {
          _searchedStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStores = false);
      }
    }
  }

  Future<void> _openCategoryPicker() async {
    final categories = context.read<HomeProvider>().categories;
    if (categories.isEmpty) return;

    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          categories: categories,
          initialSelectedCategoryIds: _selectedCategoryIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryIds = result;
        _resetVisibleCounts();
      });
    }
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
        _distanceKm = null; // location mode active → clear distance
        _resetVisibleCounts();
      });
    }
  }

  void _showDistancePicker() {
    showRadiusPickerSheet(
      context,
      initialRadius: _distanceKm ?? 20.0,
      onRadiusChanged: _activateNearby,
    );
  }

  Future<void> _activateNearby(double km) async {
    if (km <= 0) {
      setState(() {
        _distanceKm = null;
        _resetVisibleCounts();
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
        _distanceKm = km;
        _selectedWilaya = null;
        _selectedBaladiya = null;
        _selectedLocation = '';
        _resetVisibleCounts();
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

  ProductDetailsArgs _buildProductDetailsArgs(Post product) {
    final homeProvider = context.read<HomeProvider>();
    final categoriesById = _categoriesById(homeProvider);
    final candidateProducts = context
        .read<PostProvider>()
        .posts
        .where((p) => _postMatchesSelectedCategories(p, categoriesById))
        .where((p) => _postMatchesQuery(p))
        .take(10)
        .toList();
    final candidateCategoryIds = candidateProducts
        .map((p) => p.categoryId)
        .whereType<int>()
        .toSet()
        .toList();
    final candidateStoreIds = candidateProducts
        .map((p) => p.storeId)
        .where((id) => id > 0)
        .toSet()
        .toList();

    final discoveryMode = _distanceKm != null
        ? 'nearby'
        : ((_selectedWilaya != null && _selectedWilaya!.isNotEmpty)
            ? 'location'
            : 'none');
    if (kDebugMode) {
      debugPrint(
        'Search->ProductDetails: mode=$discoveryMode distance=$_distanceKm wilaya=$_selectedWilaya baladiya=$_selectedBaladiya',
      );
    }
    return ProductDetailsArgs(
      product: product,
      sourceSurface: 'search',
      discoveryMode: discoveryMode,
      distanceKm: _distanceKm,
      wilayaCode: _selectedWilaya,
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      searchContext: {
        'search_performed': _hasSearched,
        'search_query': _searchController.text.trim().toLowerCase(),
        'selected_category_ids': _selectedCategoryIds.toList(),
        'selected_sort': _selectedSort,
        'price_min': _priceRange.start,
        'price_max': _priceRange.end,
        'min_rating': _minRating,
        'candidate_category_ids': candidateCategoryIds,
        'candidate_store_ids': candidateStoreIds,
      },
    );
  }

  ProductDetailsArgs _buildOfferDetailsArgs(Offer offer) {
    final productWithPromotion = offer.product.copyWith(
      price: offer.newPrice,
      oldPrice: offer.product.price,
      discountPercentage: offer.discountPercentage,
    );
    return _buildProductDetailsArgs(productWithPromotion);
  }

  void _showFiltersSheet() {
    final initialSort = _selectedSort;
    final initialPriceRange = _priceRange;
    final initialMinRating = _minRating;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersBottomSheet(
        initialSort: initialSort,
        initialPriceRange: initialPriceRange,
        initialMinRating: initialMinRating,
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryIds = {};
      _selectedSort = 'Newest';
      _priceRange = const RangeValues(0, 100000);
      _minRating = 0;
      _selectedWilaya = null;
      _selectedBaladiya = null;
      _selectedLocation = '';
      _distanceKm = null;
      _resetVisibleCounts();
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategoryIds.isNotEmpty ||
      _minRating > 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < 100000 ||
      (_selectedWilaya != null) ||
      _distanceKm != null;

  bool get _hasAnyLocationFilter =>
      (_selectedWilaya != null) || _distanceKm != null;

  Map<int, String> _categoriesById(HomeProvider homeProvider) {
    return {for (final c in homeProvider.categories) c.id: c.name};
  }

  bool _postMatchesSelectedCategories(
      Post post, Map<int, String> categoriesById) {
    if (_selectedCategoryIds.isEmpty) return true;

    final categoryId = post.categoryId;
    if (categoryId != null) {
      return _selectedCategoryIds.contains(categoryId);
    }

    // Fallback: match by name if API didn't provide categoryId
    final selectedNames = _selectedCategoryIds
        .map((id) => categoriesById[id])
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .toSet();
    if (selectedNames.isEmpty) return true;
    return selectedNames.contains(post.category.toLowerCase());
  }

  String get _normalizedQuery => _searchController.text.trim().toLowerCase();

  bool _matchesQueryText(String value) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    return value.toLowerCase().contains(query);
  }

  bool _postMatchesQuery(Post post) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    return _matchesQueryText(post.title) ||
        _matchesQueryText(post.description) ||
        _matchesQueryText(post.storeName) ||
        _matchesQueryText(post.category);
  }

  bool _offerMatchesQuery(Offer offer) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    return _postMatchesQuery(offer.product) ||
        _matchesQueryText(offer.discountPercentage.toString());
  }

  bool _packMatchesQuery(Pack pack) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    final productNames = pack.products.map((p) => p.productName).join(' ');
    return _matchesQueryText(pack.name) ||
        _matchesQueryText(pack.description) ||
        _matchesQueryText(pack.merchantName) ||
        _matchesQueryText(productNames);
  }

  bool _storeMatchesQuery(User store) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    return _matchesQueryText(store.fullName) ||
        _matchesQueryText(store.address) ||
        _matchesQueryText(store.city ?? '');
  }

  double _offerEffectivePrice(Offer offer) {
    if (offer.newPrice > 0) return offer.newPrice;
    return offer.product.price;
  }

  double _packEffectivePrice(Pack pack) {
    if (pack.discountPrice > 0) return pack.discountPrice;
    return pack.totalPrice;
  }

  bool _matchesPriceFilter(double price) {
    if (!(_priceRange.start > 0 || _priceRange.end < 100000)) return true;
    return price >= _priceRange.start && price <= _priceRange.end;
  }

  DateTime _parsePackDate(Pack pack) {
    return DateTime.tryParse(pack.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: AppPrimaryButton(
              text: 'Search',
              icon: Icons.search_rounded,
              onPressed: _performSearch,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search header (containing back button, location toggle, search field, and filter button)
              _buildHeader(),

              // Type Toggle Buttons
              _buildTypeToggleButtons(),

              // Categories
              _buildCategoriesSection(),

              // Active Filters
              if (_hasActiveFilters) _buildActiveFilters(),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshSearch,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final distanceActive = _distanceKm != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Back button + Location Toggle
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.primaryColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Location Toggle
              Expanded(
                child: LocationModeSwitcher(
                  distanceActive: distanceActive,
                  cityLabel: (!distanceActive &&
                          _selectedLocation.isNotEmpty &&
                          _selectedLocation != '/')
                      ? _selectedLocation
                      : 'City',
                  nearbyLabel:
                      distanceActive ? '${_distanceKm!.toInt()} km' : 'Nearby',
                  onCityTap: _showLocationPicker,
                  onNearbyTap: _showDistancePicker,
                  isLoadingNearby: _isNearbyLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Search field + Filter button
          Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: AppSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hintText: 'Search products, stores...',
                    onChanged: (_) => setState(() {}),
                    onSubmitted: () => _searchFocus.unfocus(),
                    onClear: () => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              _buildHeaderButton(
                icon: Icons.tune_rounded,
                isActive: _minRating > 0 ||
                    _priceRange.start > 0 ||
                    _priceRange.end < 100000,
                onTap: _showFiltersSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withOpacity(0.1)
              : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppColors.primaryColor, width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? AppColors.primaryColor : AppColors.textSecondary,
              size: 24,
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
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
    );
  }

  Widget _buildTypeToggleButtons() {
    final selectedIndex =
        _typeOptions.indexWhere((o) => o.value == _selectedType);
    final safeSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AppToggleButtonGroup(
        options: _typeOptions,
        selectedIndex: safeSelectedIndex,
        onChanged: (i) => setState(() {
          _selectedType = _typeOptions[i].value;
          _resetVisibleCounts();
        }),
        scrollable: true,
        compact: true,
      ),
    );
  }

  /// Palette used to colour category cards (cycles if more categories than colours)
  static const List<Color> _categoryPalette = [
    Color(0xFFFF9800), // orange  — Food
    Color(0xFF2196F3), // blue    — Electronics
    Color(0xFF9C27B0), // purple  — Fashion
    Color(0xFFE91E63), // pink    — Beauty
    Color(0xFF4CAF50), // green   — Vegetables
    Color(0xFFFF5722), // deep-orange — Sports
    Color(0xFF009688), // teal    — Home
    Color(0xFF3F51B5), // indigo  — Books
  ];

  Widget _buildCategoriesSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final categories = homeProvider.categories;
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Row 1: "Categories" title + "See all →" ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openCategoryPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_right_rounded,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Row 3: Horizontal category cards (5 items only) ───
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount:
                      (categories.length > 5 ? 5 : categories.length) + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryCard(
                        icon: Icons.grid_view_rounded,
                        label: 'All',
                        color: AppColors.primaryColor,
                        isSelected: _selectedCategoryIds.isEmpty,
                        onTap: () => setState(() {
                          _selectedCategoryIds = {};
                          _resetVisibleCounts();
                        }),
                      );
                    }
                    final cat = categories[index - 1];
                    final color =
                        _categoryPalette[(index - 1) % _categoryPalette.length];
                    final isSelected = _selectedCategoryIds.contains(cat.id);
                    return _buildCategoryCard(
                      icon: cat.iconData,
                      label: cat.name,
                      color: color,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedCategoryIds.remove(cat.id);
                        } else {
                          _selectedCategoryIds.add(cat.id);
                        }
                        _resetVisibleCounts();
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.22)
                    : color.withOpacity(0.10),
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonRemovableCategoryChip({required String name}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200, width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryChip({
    required String name,
    required VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 18, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedWilaya != null)
                    _buildFilterTag(
                      _selectedLocation.isNotEmpty && _selectedLocation != '/'
                          ? _selectedLocation
                          : _selectedWilaya!,
                      Icons.location_on_rounded,
                    ),
                  if (_distanceKm != null)
                    _buildFilterTag(
                      '${_distanceKm!.toInt()} km radius',
                      Icons.radar,
                    ),
                  if (_selectedCategoryIds.isNotEmpty)
                    _buildFilterTag(
                      'Categories: ${_selectedCategoryIds.length}',
                      Icons.category_rounded,
                    ),
                  if (_minRating > 0)
                    _buildFilterTag(
                      '${_minRating.toStringAsFixed(1)}+',
                      Icons.star_rounded,
                    ),
                  if (_priceRange.start > 0 || _priceRange.end < 100000)
                    _buildFilterTag(
                      '${_priceRange.start.toInt()}-${_priceRange.end.toInt()}',
                      Icons.attach_money_rounded,
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.errorRed,
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

  Widget _buildFilterTag(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBottomSheet({
    required String initialSort,
    required RangeValues initialPriceRange,
    required double initialMinRating,
  }) {
    var draftSort = initialSort;
    var draftPriceRange = initialPriceRange;
    var draftMinRating = initialMinRating;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filters',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    AppTextButton(
                      text: 'Reset',
                      onPressed: () {
                        setSheetState(() {
                          draftSort = 'Newest';
                          draftPriceRange = const RangeValues(0, 100000);
                          draftMinRating = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort By
                      Text(
                        'Sort By',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sortOptions.map((option) {
                          final isSelected = draftSort == option;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => draftSort = option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.neutral100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  width: 1.4,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Price Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price Range',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${draftPriceRange.start.toInt()} - ${draftPriceRange.end.toInt()} DZD',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primaryColor,
                          inactiveTrackColor: AppColors.neutral200,
                          thumbColor: AppColors.primaryColor,
                          overlayColor: AppColors.primaryColor.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: RangeSlider(
                          values: draftPriceRange,
                          min: 0,
                          max: 100000,
                          divisions: 100,
                          onChanged: (values) {
                            setSheetState(() => draftPriceRange = values);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Rating',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  draftMinRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.amber,
                          inactiveTrackColor: AppColors.neutral200,
                          thumbColor: Colors.amber,
                          overlayColor: Colors.amber.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: draftMinRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          onChanged: (value) {
                            setSheetState(() => draftMinRating = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: AppPrimaryButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      setState(() {
                        _selectedSort = draftSort;
                        _priceRange = draftPriceRange;
                        _minRating = draftMinRating;
                        _resetVisibleCounts();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) {
      return _buildPreSearchState();
    }
    switch (_selectedType) {
      case 'All':
        return _buildAllContent();
      case 'Products':
        return _buildProductsContent();
      case 'Discounts':
        return _buildDiscountsContent();
      case 'Packs':
        return _buildPacksContent();
      case 'Stores':
        return _buildStoresContent();
      default:
        return _buildAllContent();
    }
  }

  // Location filter helpers
  bool _storeMatchesLocationFilter(String address) {
    if (_selectedWilaya == null) return true;
    if (address.isEmpty) return false;

    final addressLower = address.toLowerCase();

    if (!addressLower.contains(_selectedWilaya!.toLowerCase())) {
      return false;
    }
    if (_selectedBaladiya != null &&
        !addressLower.contains(_selectedBaladiya!.toLowerCase())) {
      return false;
    }

    return true;
  }

  String? _getLocationBadgeCount() {
    if (_selectedWilaya == null) return null;
    return '1';
  }

  List<User> _getLocationFilteredStores() {
    final baseStores = _searchedStores.where(_storeMatchesQuery).toList();
    if (_selectedWilaya == null) {
      return baseStores;
    }
    return baseStores
        .where((store) => _storeMatchesLocationFilter(store.address))
        .toList();
  }

  List<User> _getDistanceFilteredStores() {
    final baseStores = _searchedStores.where(_storeMatchesQuery).toList();
    if (_distanceKm == null || _userLat == null || _userLng == null) {
      return baseStores;
    }
    return baseStores.where((store) {
      if (!store.allowNearbyVisibility) return false;
      final dist = Helpers.haversineDistance(
          _userLat, _userLng, store.latitude, store.longitude);
      return dist != null && dist <= _distanceKm!;
    }).toList();
  }

  List<User> _getActiveFilteredStores() {
    if (_distanceKm != null) return _getDistanceFilteredStores();
    if (_selectedWilaya != null) return _getLocationFilteredStores();
    return _searchedStores;
  }

  Set<int> _getValidStoreIds() {
    if (!_hasAnyLocationFilter) return {};
    return _getActiveFilteredStores().map((s) => s.id).toSet();
  }

  Widget _buildAllContent() {
    return Consumer2<PostProvider, HomeProvider>(
      builder: (context, postProvider, homeProvider, child) {
        final products = postProvider.posts;
        final offers = postProvider.offers;
        final packs = homeProvider.packs;

        final categoriesById = _categoriesById(homeProvider);

        final isLoading = postProvider.isLoadingPosts ||
            postProvider.isLoadingOffers ||
            homeProvider.isLoadingPacks ||
            _isLoadingStores;

        if (isLoading &&
            products.isEmpty &&
            offers.isEmpty &&
            packs.isEmpty &&
            _searchedStores.isEmpty) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();

        var filteredProducts = products.toList();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((p) => validStoreIds.contains(p.storeId))
              .toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          filteredProducts = [];
        }
        if (_distanceKm != null) {
          filteredProducts =
              filteredProducts.where((p) => p.storeNearbyVisible).toList();
        }

        filteredProducts = filteredProducts
            .where((p) => _postMatchesSelectedCategories(p, categoriesById))
            .toList();
        filteredProducts =
            filteredProducts.where((p) => _postMatchesQuery(p)).toList();

        if (_minRating > 0) {
          filteredProducts =
              filteredProducts.where((p) => p.rating >= _minRating).toList();
        }
        filteredProducts = filteredProducts
            .where((p) => _matchesPriceFilter(p.price))
            .toList();

        var filteredOffers = offers.toList();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          filteredOffers = filteredOffers
              .where((o) => validStoreIds.contains(o.product.storeId))
              .toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          filteredOffers = [];
        }
        if (_distanceKm != null) {
          filteredOffers = filteredOffers
              .where((o) => o.product.storeNearbyVisible)
              .toList();
        }

        filteredOffers = filteredOffers
            .where((o) =>
                _postMatchesSelectedCategories(o.product, categoriesById))
            .toList();
        filteredOffers =
            filteredOffers.where((o) => _offerMatchesQuery(o)).toList();
        if (_minRating > 0) {
          filteredOffers = filteredOffers
              .where((o) => o.product.rating >= _minRating)
              .toList();
        }
        filteredOffers = filteredOffers
            .where((o) => _matchesPriceFilter(_offerEffectivePrice(o)))
            .toList();

        var filteredPacks = packs.toList();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          filteredPacks = filteredPacks
              .where((p) => validStoreIds.contains(p.merchantId))
              .toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          filteredPacks = [];
        }
        if (_distanceKm != null) {
          filteredPacks =
              filteredPacks.where((p) => p.merchantNearbyVisible).toList();
        }
        filteredPacks =
            filteredPacks.where((p) => _packMatchesQuery(p)).toList();
        filteredPacks = filteredPacks
            .where((p) => _matchesPriceFilter(_packEffectivePrice(p)))
            .toList();

        switch (_selectedSort) {
          case 'Oldest':
            filteredProducts = List.from(filteredProducts)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            filteredOffers = List.from(filteredOffers)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            filteredPacks = List.from(filteredPacks)
              ..sort((a, b) => _parsePackDate(a).compareTo(_parsePackDate(b)));
            break;
          case 'Highest Rated':
            filteredProducts = List.from(filteredProducts)
              ..sort((a, b) => b.rating.compareTo(a.rating));
            filteredOffers = List.from(filteredOffers)
              ..sort((a, b) => b.product.rating.compareTo(a.product.rating));
            break;
          case 'Lowest Price':
            filteredProducts = List.from(filteredProducts)
              ..sort((a, b) => a.price.compareTo(b.price));
            filteredOffers = List.from(filteredOffers)
              ..sort((a, b) =>
                  _offerEffectivePrice(a).compareTo(_offerEffectivePrice(b)));
            filteredPacks = List.from(filteredPacks)
              ..sort((a, b) =>
                  _packEffectivePrice(a).compareTo(_packEffectivePrice(b)));
            break;
          case 'Highest Price':
            filteredProducts = List.from(filteredProducts)
              ..sort((a, b) => b.price.compareTo(a.price));
            filteredOffers = List.from(filteredOffers)
              ..sort((a, b) =>
                  _offerEffectivePrice(b).compareTo(_offerEffectivePrice(a)));
            filteredPacks = List.from(filteredPacks)
              ..sort((a, b) =>
                  _packEffectivePrice(b).compareTo(_packEffectivePrice(a)));
            break;
          case 'Newest':
          default:
            filteredProducts = List.from(filteredProducts)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            filteredOffers = List.from(filteredOffers)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            filteredPacks = List.from(filteredPacks)
              ..sort((a, b) => _parsePackDate(b).compareTo(_parsePackDate(a)));
            break;
        }

        final filteredStores = _getActiveFilteredStores();

        final hasProducts = filteredProducts.isNotEmpty;
        final hasOffers = filteredOffers.isNotEmpty;
        final hasPacks = filteredPacks.isNotEmpty;
        final hasStores = filteredStores.isNotEmpty;
        final hasItems = hasProducts || hasOffers || hasPacks;

        final combinedItemsCount = filteredProducts.length +
            filteredOffers.length +
            filteredPacks.length;

        final combinedCards = <Widget>[
          ...filteredProducts.map(
            (p) => ProductCard(
              product: p,
              userLat: _userLat,
              userLng: _userLng,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.productDetails,
                  arguments: _buildProductDetailsArgs(p),
                );
              },
              onFavoriteTap: () {},
            ),
          ),
          ...filteredOffers.map((o) => PromotionCard(
                offer: o,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.productDetails,
                    arguments: _buildOfferDetailsArgs(o),
                  );
                },
              )),
          ...filteredPacks.map((p) => PackCard(pack: p)),
        ];
        final visibleCards = combinedCards.take(_allVisibleCount).toList();

        if (!hasItems && !hasStores) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasItems) ...[
                Row(
                  children: [
                    Text(
                      'Results',
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$combinedItemsCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleCards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: CardConstants.gridCrossAxisCount,
                    crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                    mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                    childAspectRatio: CardConstants.gridChildAspectRatio,
                  ),
                  itemBuilder: (context, index) => visibleCards[index],
                ),
                if (combinedCards.length > visibleCards.length)
                  _buildLoadMoreButton(() {
                    setState(() {
                      _allVisibleCount += _pageSize;
                    });
                  }),
                const SizedBox(height: 28),
              ],
              if (hasStores) ...[
                Row(
                  children: [
                    Text(
                      'Stores',
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredStores.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  // keep "All" tab compact unless user explicitly expands stores
                  children: (_showAllStoresInAllView
                          ? filteredStores.take(_storesVisibleCount)
                          : filteredStores.take(_storesVisibleCount > 6
                              ? 6
                              : _storesVisibleCount))
                      .map((store) => StoreChip(
                            imageUrl: store.profileImage ?? '',
                            name: store.fullName,
                            rating: store.averageRating,
                            followersCount: store.followersCount,
                            onTap: () => Navigator.pushNamed(
                              context,
                              Routes.store,
                              arguments: store.id,
                            ),
                          ))
                      .toList(),
                ),
                if (filteredStores.length >
                    (_showAllStoresInAllView
                        ? _storesVisibleCount
                        : (_storesVisibleCount > 6 ? 6 : _storesVisibleCount)))
                  _buildLoadMoreButton(() {
                    setState(() {
                      _storesVisibleCount += _pageSize;
                    });
                  }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters\nto find what you\'re looking for',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsContent() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
        if (postProvider.isLoadingPosts) {
          return _buildGridShimmer();
        }

        final categoriesById = _categoriesById(context.read<HomeProvider>());
        var products = postProvider.posts.toList();

        final validStoreIds = _getValidStoreIds();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          products =
              products.where((p) => validStoreIds.contains(p.storeId)).toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          products = [];
        }
        if (_distanceKm != null) {
          products = products.where((p) => p.storeNearbyVisible).toList();
        }

        if (_minRating > 0) {
          products = products.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          products = products
              .where((p) =>
                  p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        products = products
            .where((p) => _postMatchesSelectedCategories(p, categoriesById))
            .toList();
        products = products.where((p) => _postMatchesQuery(p)).toList();

        switch (_selectedSort) {
          case 'Oldest':
            products = List.from(products)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case 'Highest Rated':
            products = List.from(products)
              ..sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'Lowest Price':
            products = List.from(products)
              ..sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Highest Price':
            products = List.from(products)
              ..sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'Newest':
          default:
            products = List.from(products)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
        }

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        final visible = products.take(_productsVisibleCount).toList();
        return SingleChildScrollView(
          child: Column(
            children: [
              GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: CardConstants.gridHorizontalPadding,
                  vertical: CardConstants.gridVerticalPadding,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: CardConstants.gridCrossAxisCount,
                  childAspectRatio: CardConstants.gridChildAspectRatio,
                  mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                  crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: visible[index],
                    userLat: _userLat,
                    userLng: _userLng,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.productDetails,
                        arguments: _buildProductDetailsArgs(visible[index]),
                      );
                    },
                    onFavoriteTap: () {},
                  );
                },
              ),
              if (products.length > visible.length)
                _buildLoadMoreButton(() {
                  setState(() {
                    _productsVisibleCount += _pageSize;
                  });
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountsContent() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
        var offers = postProvider.offers.toList();

        if (postProvider.isLoadingOffers) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          offers = offers
              .where((o) => validStoreIds.contains(o.product.storeId))
              .toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          offers = [];
        }
        if (_distanceKm != null) {
          offers = offers.where((o) => o.product.storeNearbyVisible).toList();
        }

        final categoriesById = _categoriesById(context.read<HomeProvider>());
        offers = offers
            .where((o) =>
                _postMatchesSelectedCategories(o.product, categoriesById))
            .toList();
        offers = offers.where((o) => _offerMatchesQuery(o)).toList();

        if (_minRating > 0) {
          offers = offers.where((o) => o.product.rating >= _minRating).toList();
        }
        offers = offers
            .where((o) => _matchesPriceFilter(_offerEffectivePrice(o)))
            .toList();

        switch (_selectedSort) {
          case 'Oldest':
            offers = List.from(offers)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case 'Highest Rated':
            offers = List.from(offers)
              ..sort((a, b) => b.product.rating.compareTo(a.product.rating));
            break;
          case 'Lowest Price':
            offers = List.from(offers)
              ..sort((a, b) =>
                  _offerEffectivePrice(a).compareTo(_offerEffectivePrice(b)));
            break;
          case 'Highest Price':
            offers = List.from(offers)
              ..sort((a, b) =>
                  _offerEffectivePrice(b).compareTo(_offerEffectivePrice(a)));
            break;
          case 'Newest':
          default:
            offers = List.from(offers)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
        }

        if (offers.isEmpty) {
          return _buildEmptyState();
        }

        final visible = offers.take(_discountsVisibleCount).toList();
        return SingleChildScrollView(
          child: Column(
            children: [
              GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: CardConstants.gridHorizontalPadding,
                  vertical: CardConstants.gridVerticalPadding,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: CardConstants.gridCrossAxisCount,
                  childAspectRatio: CardConstants.gridChildAspectRatio,
                  mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                  crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final offer = visible[index];
                  return PromotionCard(
                    offer: offer,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.productDetails,
                        arguments: _buildOfferDetailsArgs(offer),
                      );
                    },
                  );
                },
              ),
              if (offers.length > visible.length)
                _buildLoadMoreButton(() {
                  setState(() {
                    _discountsVisibleCount += _pageSize;
                  });
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPacksContent() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
        var packs = homeProvider.packs.toList();

        if (homeProvider.isLoadingPacks) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();
        if (_hasAnyLocationFilter && validStoreIds.isNotEmpty) {
          packs =
              packs.where((p) => validStoreIds.contains(p.merchantId)).toList();
        } else if (_hasAnyLocationFilter && validStoreIds.isEmpty) {
          packs = [];
        }
        if (_distanceKm != null) {
          packs = packs.where((p) => p.merchantNearbyVisible).toList();
        }

        packs = packs.where((p) => _packMatchesQuery(p)).toList();
        packs = packs
            .where((p) => _matchesPriceFilter(_packEffectivePrice(p)))
            .toList();

        switch (_selectedSort) {
          case 'Oldest':
            packs = List.from(packs)
              ..sort((a, b) => _parsePackDate(a).compareTo(_parsePackDate(b)));
            break;
          case 'Lowest Price':
            packs = List.from(packs)
              ..sort((a, b) =>
                  _packEffectivePrice(a).compareTo(_packEffectivePrice(b)));
            break;
          case 'Highest Price':
            packs = List.from(packs)
              ..sort((a, b) =>
                  _packEffectivePrice(b).compareTo(_packEffectivePrice(a)));
            break;
          case 'Newest':
          case 'Highest Rated':
          default:
            packs = List.from(packs)
              ..sort((a, b) => _parsePackDate(b).compareTo(_parsePackDate(a)));
            break;
        }

        if (packs.isEmpty) {
          return _buildEmptyState();
        }

        final visible = packs.take(_packsVisibleCount).toList();
        return SingleChildScrollView(
          child: Column(
            children: [
              GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: CardConstants.gridHorizontalPadding,
                  vertical: CardConstants.gridVerticalPadding,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: CardConstants.gridCrossAxisCount,
                  childAspectRatio: CardConstants.gridChildAspectRatio,
                  mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                  crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  return PackCard(pack: visible[index]);
                },
              ),
              if (packs.length > visible.length)
                _buildLoadMoreButton(() {
                  setState(() {
                    _packsVisibleCount += _pageSize;
                  });
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoresContent() {
    if (_isLoadingStores) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    final filteredStores = _getActiveFilteredStores();

    if (filteredStores.isEmpty) {
      return _buildEmptyState();
    }

    final visibleStores = filteredStores.take(_storesVisibleCount).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: visibleStores
                .map((store) => StoreChip(
                      imageUrl: store.profileImage ?? '',
                      name: store.fullName,
                      rating: store.averageRating,
                      followersCount: store.followersCount,
                      onTap: () => Navigator.pushNamed(
                        context,
                        Routes.store,
                        arguments: store.id,
                      ),
                    ))
                .toList(),
          ),
          if (filteredStores.length > visibleStores.length)
            _buildLoadMoreButton(() {
              setState(() {
                _storesVisibleCount += _pageSize;
              });
            }),
        ],
      ),
    );
  }

  Widget _buildGridShimmer() {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: CardConstants.gridHorizontalPadding,
          vertical: CardConstants.gridVerticalPadding,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: CardConstants.gridCrossAxisCount,
          childAspectRatio: CardConstants.gridChildAspectRatio,
          mainAxisSpacing: CardConstants.gridMainAxisSpacing,
          crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ProductCardSkeleton();
        },
      ),
    );
  }
}
