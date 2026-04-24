import 'dart:async';

import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/home_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/services/analytics_api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/geolocation_stub.dart'
    if (dart.library.html) '../../core/utils/geolocation_web.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toggle_button.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../common/constants/card_constants.dart';
import '../common/location_permission_helper.dart';
import '../common/location_picker_screen.dart';
import '../common/radius_picker_sheet.dart';
import '../product/product_detail_screen.dart';
import '../shared_widgets/app_icon_action_button.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/cards/store_chip.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/loading_indicator.dart';
import '../shared_widgets/location_mode_switcher.dart';
import '../shared_widgets/shimmer_loading.dart';
import 'category_selection_screen.dart';

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
    ToggleOption(label: 'All', value: 'All'),
    ToggleOption(label: 'Products', value: 'Products'),
    ToggleOption(label: 'Discounts', value: 'Discounts'),
    ToggleOption(label: 'Packs', value: 'Packs'),
    ToggleOption(label: 'Stores', value: 'Stores'),
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
  final AnalyticsApiService _analyticsApiService = AnalyticsApiService();
  HomeProvider? _sharedHomeProvider;

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Highest Rated',
    'Lowest Price',
    'Highest Price',
  ];

  String _normalizeText(String value) {
    var normalized = value.toLowerCase().trim();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    normalized = normalized.replaceAll(RegExp(r"[’'`´]"), '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ');
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _localizedLocationLabel(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '/') return raw;
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map(context.tr)
        .toList();
    return parts.isEmpty ? context.tr(raw) : parts.join(', ');
  }

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
    _syncLocationFromSharedState(useSetState: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapSearchScreen();
      if (widget.autoSearchOnOpen) {
        _performSearch();
      }
    });
  }

  void _bootstrapSearchScreen() {
    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.categories.isEmpty && !homeProvider.isLoadingCategories) {
      homeProvider.loadCategories();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<HomeProvider>();
    if (!identical(_sharedHomeProvider, nextProvider)) {
      _sharedHomeProvider?.removeListener(_onSharedLocationFilterChanged);
      _sharedHomeProvider = nextProvider;
      _sharedHomeProvider?.addListener(_onSharedLocationFilterChanged);
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
    _sharedHomeProvider?.removeListener(_onSharedLocationFilterChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSharedLocationFilterChanged() {
    if (!mounted) return;
    _syncLocationFromSharedState(useSetState: true);
  }

  void _syncLocationFromSharedState({required bool useSetState}) {
    final shared = context.read<HomeProvider>();
    final hasChanges = _selectedLocation != shared.discoveryLocationLabel ||
        _selectedWilaya != shared.discoveryWilaya ||
        _selectedBaladiya != shared.discoveryBaladiya ||
        _distanceKm != shared.discoveryRadiusKm ||
        _userLat != shared.discoveryUserLat ||
        _userLng != shared.discoveryUserLng;

    if (!hasChanges) return;

    void apply() {
      _selectedLocation = shared.discoveryLocationLabel;
      _selectedWilaya = shared.discoveryWilaya;
      _selectedBaladiya = shared.discoveryBaladiya;
      _distanceKm = shared.discoveryRadiusKm;
      _userLat = shared.discoveryUserLat;
      _userLng = shared.discoveryUserLng;
      _resetVisibleCounts();
    }

    if (useSetState) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _persistLocationToSharedState() {
    context.read<HomeProvider>().setDiscoveryLocationFilter(
          locationLabel: _selectedLocation,
          wilaya: _selectedWilaya,
          baladiya: _selectedBaladiya,
          radiusKm: _distanceKm,
          userLat: _userLat,
          userLng: _userLng,
        );
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
        label: Text(context.tr('Load more')),
      ),
    );
  }

  String? get _searchQueryForApi {
    final q = _searchController.text.trim();
    return q.isEmpty ? null : q;
  }

  int? get _singleCategoryIdForApi =>
      _selectedCategoryIds.length == 1 ? _selectedCategoryIds.first : null;

  List<int>? get _categoryIdsForApi {
    if (_selectedCategoryIds.isEmpty) return null;
    return _selectedCategoryIds.toList();
  }

  String? get _wilayaForApi {
    if (_distanceKm != null) return null;
    final w = _selectedWilaya?.trim() ?? '';
    return w.isEmpty ? null : w;
  }

  String? get _baladiyaForApi {
    if (_distanceKm != null) return null;
    final b = _selectedBaladiya?.trim() ?? '';
    return b.isEmpty ? null : b;
  }

  double? get _minPriceForApi =>
      _priceRange.start > 0 ? _priceRange.start : null;

  double? get _maxPriceForApi =>
      _priceRange.end < 100000 ? _priceRange.end : null;

  double? get _minRatingForApi => _minRating > 0 ? _minRating : null;

  double? get _radiusForApi => _distanceKm;

  double? get _userLatForApi =>
      _distanceKm != null && _userLat != null ? _userLat : null;

  double? get _userLngForApi =>
      _distanceKm != null && _userLng != null ? _userLng : null;

  double? get _activeUserLatForCards => _distanceKm != null ? _userLat : null;

  double? get _activeUserLngForCards => _distanceKm != null ? _userLng : null;

  String _apiOrderingForProducts() {
    switch (_selectedSort) {
      case 'Oldest':
        return 'created_at';
      case 'Highest Rated':
        return '-average_rating';
      case 'Lowest Price':
        return 'price';
      case 'Highest Price':
        return '-price';
      case 'Newest':
      default:
        return '-created_at';
    }
  }

  String _apiOrderingForOffers() {
    switch (_selectedSort) {
      case 'Oldest':
        return 'created_at';
      case 'Highest Rated':
        return '-product_rating';
      case 'Lowest Price':
        return 'product__price';
      case 'Highest Price':
        return '-product__price';
      case 'Newest':
      default:
        return '-created_at';
    }
  }

  String _apiOrderingForPacks() {
    switch (_selectedSort) {
      case 'Oldest':
        return 'created_at';
      case 'Highest Rated':
        return '-merchant_rating';
      case 'Lowest Price':
        return 'discount';
      case 'Highest Price':
        return '-discount';
      case 'Newest':
      default:
        return '-created_at';
    }
  }

  void _performSearch() {
    _searchFocus.unfocus();

    if (!_hasSearched) {
      setState(() => _hasSearched = true);
    }
    _resetVisibleCounts();

    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    postProvider.loadPosts(
      search: _searchQueryForApi,
      categoryId: _singleCategoryIdForApi,
      categoryIds: _categoryIdsForApi,
      wilayaCode: _wilayaForApi,
      baladiya: _baladiyaForApi,
      minPrice: _minPriceForApi,
      maxPrice: _maxPriceForApi,
      minRating: _minRatingForApi,
      ordering: _apiOrderingForProducts(),
      userLat: _userLatForApi,
      userLng: _userLngForApi,
      radiusKm: _radiusForApi,
      fetchAllPages: true,
    );
    postProvider.loadOffers(
      search: _searchQueryForApi,
      categoryId: _singleCategoryIdForApi,
      categoryIds: _categoryIdsForApi,
      wilayaCode: _wilayaForApi,
      baladiya: _baladiyaForApi,
      minPrice: _minPriceForApi,
      maxPrice: _maxPriceForApi,
      minRating: _minRatingForApi,
      ordering: _apiOrderingForOffers(),
      userLat: _userLatForApi,
      userLng: _userLngForApi,
      radiusKm: _radiusForApi,
      fetchAllPages: true,
    );
    homeProvider.loadFeaturedPacks(
      limit: null,
      search: _searchQueryForApi,
      categoryId: _singleCategoryIdForApi,
      categoryIds: _categoryIdsForApi,
      wilayaCode: _wilayaForApi,
      baladiya: _baladiyaForApi,
      minPrice: _minPriceForApi,
      maxPrice: _maxPriceForApi,
      minRating: _minRatingForApi,
      ordering: _apiOrderingForPacks(),
      userLat: _userLatForApi,
      userLng: _userLngForApi,
      radiusKm: _radiusForApi,
    );
    _searchStores(fetchAllPages: true);
    _logSearchEvent();
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
        search: _searchQueryForApi,
        categoryId: _singleCategoryIdForApi,
        categoryIds: _categoryIdsForApi,
        wilayaCode: _wilayaForApi,
        baladiya: _baladiyaForApi,
        minPrice: _minPriceForApi,
        maxPrice: _maxPriceForApi,
        minRating: _minRatingForApi,
        ordering: _apiOrderingForProducts(),
        userLat: _userLatForApi,
        userLng: _userLngForApi,
        radiusKm: _radiusForApi,
        fetchAllPages: true,
      ),
      postProvider.loadOffers(
        search: _searchQueryForApi,
        categoryId: _singleCategoryIdForApi,
        categoryIds: _categoryIdsForApi,
        wilayaCode: _wilayaForApi,
        baladiya: _baladiyaForApi,
        minPrice: _minPriceForApi,
        maxPrice: _maxPriceForApi,
        minRating: _minRatingForApi,
        ordering: _apiOrderingForOffers(),
        userLat: _userLatForApi,
        userLng: _userLngForApi,
        radiusKm: _radiusForApi,
        fetchAllPages: true,
      ),
      homeProvider.loadFeaturedPacks(
        limit: null,
        search: _searchQueryForApi,
        categoryId: _singleCategoryIdForApi,
        categoryIds: _categoryIdsForApi,
        wilayaCode: _wilayaForApi,
        baladiya: _baladiyaForApi,
        minPrice: _minPriceForApi,
        maxPrice: _maxPriceForApi,
        minRating: _minRatingForApi,
        ordering: _apiOrderingForPacks(),
        userLat: _userLatForApi,
        userLng: _userLngForApi,
        radiusKm: _radiusForApi,
      ),
      _searchStores(fetchAllPages: true),
    ]);
    _logSearchEvent();
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
                    context.tr('Ready to search'),
                    style:
                        AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('Choose type and categories, then tap Search'),
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

  Future<void> _searchStores({bool fetchAllPages = false}) async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await StoreRepository.searchStores(
        query: _searchQueryForApi,
        wilayaCode: _wilayaForApi,
        baladiya: _baladiyaForApi,
        userLat: _userLatForApi,
        userLng: _userLngForApi,
        radiusKm: _radiusForApi,
        fetchAllPages: fetchAllPages,
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
          subtitle: context.l10n.categoryPickerSearchSubtitle,
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
        _selectedLocation =
            '${context.tr(result.baladiya)}, ${context.tr(result.wilaya)}';
        _distanceKm = null; // location mode active → clear distance
        _resetVisibleCounts();
      });
      _persistLocationToSharedState();
      _logFilterWilaya(result.wilaya, result.baladiya);
    }
  }

  void _handleCityTap() {
    final hasSavedCity =
        _selectedWilaya != null && _selectedWilaya!.trim().isNotEmpty;

    if (_distanceKm != null && hasSavedCity) {
      setState(() {
        _distanceKm = null;
        _resetVisibleCounts();
      });
      _persistLocationToSharedState();

      if (_hasSearched) {
        unawaited(_performSearchRefresh());
      }
      return;
    }

    _showLocationPicker();
  }

  Future<void> _showDistancePicker() async {
    final shouldContinue = await LocationPermissionHelper.ensureEducationShown(
      context,
      flow: LocationEducationFlow.nearbySearch,
    );
    if (!shouldContinue || !mounted) return;

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
      _persistLocationToSharedState();
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
        Helpers.showSnackBar(
          context,
          context.tr('Could not get current GPS location'),
        );
        return;
      }

      setState(() {
        _userLat = lat;
        _userLng = lng;
        _distanceKm = km;
        _resetVisibleCounts();
      });
      _persistLocationToSharedState();
      _logFilterDistance(km);
    } catch (e) {
      if (!mounted) return;
      await LocationPermissionHelper.handleLocationError(
        context,
        e,
        fallbackMessage: context.tr('Failed to get current GPS location'),
      );
    } finally {
      if (mounted) {
        setState(() => _isNearbyLoading = false);
      }
    }
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
    if (offer.kind == 'advertising') {
      return ProductDetailsArgs(
        product: productWithPromotion,
        sourceSurface: 'ads',
        discoveryMode: 'advertising',
        distanceKm: _distanceKm,
        wilayaCode: _selectedWilaya,
        searchQuery: null,
        searchContext: null,
      );
    }
    return _buildProductDetailsArgs(productWithPromotion);
  }

  void _logPromotionClick(Offer offer, {String placement = 'search_top'}) {
    final meta = _buildDiscoveryMetadata();
    _analyticsApiService.logPromotionClick(
      promotionId: offer.id,
      productId: offer.product.id,
      storeId: offer.product.storeId > 0 ? offer.product.storeId : null,
      placement: placement,
      discoveryMode: (meta['discovery_mode'] as String?) ?? 'none',
      distanceKm: (meta['distance_km'] as num?)?.toDouble(),
      wilayaCode: meta['wilaya_code'] as String?,
      searchQuery: meta['search_query'] as String?,
    );
    if (offer.kind == 'advertising') {
      PostRepository.registerPromotionClick(offer.id, kind: offer.kind);
    }
  }

  Map<String, dynamic> _buildDiscoveryMetadata() {
    final discoveryMode = _distanceKm != null
        ? 'nearby'
        : ((_selectedWilaya != null && _selectedWilaya!.isNotEmpty)
            ? 'location'
            : 'none');
    final meta = <String, dynamic>{
      'discovery_mode': discoveryMode,
    };
    if (_distanceKm != null) meta['distance_km'] = _distanceKm;
    if (_selectedWilaya != null && _selectedWilaya!.isNotEmpty) {
      meta['wilaya_code'] = _selectedWilaya;
    }
    if (_selectedBaladiya != null && _selectedBaladiya!.isNotEmpty) {
      meta['baladiya'] = _selectedBaladiya;
    }
    final q = _normalizedQuery;
    if (q.isNotEmpty) meta['search_query'] = q;
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
      searchQuery: meta['search_query'] as String?,
    );
  }

  void _logSearchEvent() {
    final q = _normalizedQuery;
    if (q.isEmpty) return;
    final meta = _buildDiscoveryMetadata();
    _analyticsApiService.logSearchQuery(
      query: q,
      discoveryMode: (meta['discovery_mode'] as String?) ?? 'none',
      distanceKm: (meta['distance_km'] as num?)?.toDouble(),
      wilayaCode: meta['wilaya_code'] as String?,
    );
  }

  void _logFilterWilaya(String wilaya, String baladiya) {
    _analyticsApiService.logWilayaFilter(
      wilayaCode: wilaya,
      baladiya: baladiya,
      query: _normalizedQuery,
    );
  }

  void _logFilterDistance(double km) {
    _analyticsApiService.logDistanceFilter(
      distanceKm: km,
      query: _normalizedQuery,
    );
  }

  void _logFilterEvents({
    required RangeValues priceRange,
    required double minRating,
  }) {
    if (priceRange.start > 0 || priceRange.end < 100000) {
      _analyticsApiService.logPriceFilter(
        min: priceRange.start,
        max: priceRange.end,
        discoveryMode:
            (_buildDiscoveryMetadata()['discovery_mode'] as String?) ?? 'none',
        query: _normalizedQuery,
      );
    }
    if (minRating > 0) {
      _analyticsApiService.logRatingFilter(
        minRating: minRating,
        discoveryMode:
            (_buildDiscoveryMetadata()['discovery_mode'] as String?) ?? 'none',
        query: _normalizedQuery,
      );
    }
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
    _persistLocationToSharedState();
  }

  bool get _hasActiveFilters =>
      _selectedCategoryIds.isNotEmpty ||
      _minRating > 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < 100000 ||
      (_selectedWilaya != null && _selectedWilaya!.trim().isNotEmpty) ||
      _distanceKm != null;

  Map<int, String> _categoriesById(HomeProvider homeProvider) {
    return {for (final c in homeProvider.categories) c.id: c.name};
  }

  Set<String> _selectedCategoryNames(Map<int, String> categoriesById) {
    return _selectedCategoryIds
        .map((id) => categoriesById[id])
        .whereType<String>()
        .map(_normalizeText)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _postMatchesSelectedCategories(
      Post post, Map<int, String> categoriesById) {
    if (_selectedCategoryIds.isEmpty) return true;

    final categoryId = post.categoryId;
    if (categoryId != null) {
      return _selectedCategoryIds.contains(categoryId);
    }

    // Fallback: match by name if API didn't provide categoryId
    final selectedNames = _selectedCategoryNames(categoriesById);
    if (selectedNames.isEmpty) return true;
    return selectedNames.contains(_normalizeText(post.category));
  }

  String get _normalizedQuery => _normalizeText(_searchController.text);

  bool _matchesQueryText(String value) {
    final query = _normalizedQuery;
    if (query.isEmpty) return true;
    return _normalizeText(value).contains(query);
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
        _matchesQueryText(store.storeDescription) ||
        _matchesQueryText(store.address) ||
        _matchesQueryText(store.city ?? '') ||
        _matchesQueryText(store.country ?? '') ||
        store.categories.any(_matchesQueryText);
  }

  bool _packMatchesSelectedCategories(
    Pack pack,
    Map<int, String> categoriesById,
    List<Post> posts,
  ) {
    if (_selectedCategoryIds.isEmpty) return true;
    final packProductIds =
        pack.products.map((product) => product.productId).toSet();
    if (packProductIds.isEmpty) return false;

    return posts.any(
      (post) =>
          packProductIds.contains(post.id) &&
          _postMatchesSelectedCategories(post, categoriesById),
    );
  }

  Iterable<Post> _matchingProductsForStore(
    User store,
    List<Post> posts,
    Map<int, String> categoriesById,
  ) {
    return posts.where(
      (post) =>
          post.storeId == store.id &&
          _postMatchesQuery(post) &&
          _postMatchesSelectedCategories(post, categoriesById),
    );
  }

  Iterable<Offer> _matchingOffersForStore(
    User store,
    List<Offer> offers,
    Map<int, String> categoriesById,
  ) {
    return offers.where(
      (offer) =>
          offer.product.storeId == store.id &&
          _offerMatchesQuery(offer) &&
          _postMatchesSelectedCategories(offer.product, categoriesById),
    );
  }

  Iterable<Pack> _matchingPacksForStore(
    User store,
    List<Pack> packs,
    List<Post> posts,
    Map<int, String> categoriesById,
  ) {
    return packs.where(
      (pack) =>
          pack.merchantId == store.id &&
          _packMatchesQuery(pack) &&
          _packMatchesSelectedCategories(pack, categoriesById, posts),
    );
  }

  bool _storeMatchesSelectedCategories(
    User store,
    Map<int, String> categoriesById, {
    required List<Post> posts,
    required List<Offer> offers,
    required List<Pack> packs,
  }) {
    if (_selectedCategoryIds.isEmpty) return true;

    final selectedNames = _selectedCategoryNames(categoriesById);
    final storeCategories =
        store.categories.map(_normalizeText).where((value) => value.isNotEmpty);
    if (storeCategories.any(selectedNames.contains)) {
      return true;
    }

    return _matchingProductsForStore(store, posts, categoriesById).isNotEmpty ||
        _matchingOffersForStore(store, offers, categoriesById).isNotEmpty ||
        _matchingPacksForStore(store, packs, posts, categoriesById).isNotEmpty;
  }

  List<double> _storeCandidatePrices(
    User store, {
    required List<Post> posts,
    required List<Offer> offers,
    required List<Pack> packs,
    required Map<int, String> categoriesById,
  }) {
    final prices = <double>[
      ..._matchingProductsForStore(store, posts, categoriesById)
          .map((product) => product.price),
      ..._matchingOffersForStore(store, offers, categoriesById)
          .map(_offerEffectivePrice),
      ..._matchingPacksForStore(store, packs, posts, categoriesById)
          .map(_packEffectivePrice),
    ];
    return prices.where((price) => price > 0).toList();
  }

  bool _storeMatchesPriceFilter(
    User store, {
    required List<Post> posts,
    required List<Offer> offers,
    required List<Pack> packs,
    required Map<int, String> categoriesById,
  }) {
    if (!(_priceRange.start > 0 || _priceRange.end < 100000)) return true;
    final prices = _storeCandidatePrices(
      store,
      posts: posts,
      offers: offers,
      packs: packs,
      categoriesById: categoriesById,
    );
    if (prices.isEmpty) return false;
    return prices.any(_matchesPriceFilter);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        floatingActionButton: FloatingActionButton(
          onPressed: _performSearch,
          tooltip: context.tr('Search'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.search_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: Column(
            children: [
              // Compact header: back + search + buttons
              _buildHeader(),

              // City + Nearby on their own line
              _buildLocationRow(),

              // Type tabs: All / Products / Discounts / Packs / Stores
              _buildTypeToggleButtons(),

              // Compact categories with "show more"
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          AppBackActionButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          // Search field
          Expanded(
            child: SizedBox(
              height: 38,
              child: AppSearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                hintText: context.tr('Search products, stores...'),
                onChanged: (_) => setState(() {}),
                onSubmitted: _performSearch,
                onClear: () => setState(() {}),
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 6),
          AppIconActionButton(
            icon: Icons.tune_rounded,
            onTap: _showFiltersSheet,
          ),
        ],
      ),
    );
  }

  // ── Location row: City + Nearby chips on their own line ──────────────
  Widget _buildLocationRow() {
    final distanceActive = _distanceKm != null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: LocationModeSwitcher(
        distanceActive: distanceActive,
        cityLabel: (_selectedLocation.isNotEmpty && _selectedLocation != '/')
            ? _localizedLocationLabel(_selectedLocation)
            : context.tr('City'),
        nearbyLabel: distanceActive
            ? '${_distanceKm!.toInt()} ${context.tr('km')}'
            : context.tr('Nearby'),
        onCityTap: _handleCityTap,
        onNearbyTap: _showDistancePicker,
        isLoadingNearby: _isNearbyLoading,
      ),
    );
  }

  // ── Type tabs: All / Products / Discounts / Packs / Stores ────────────
  Widget _buildTypeToggleButtons() {
    final selectedIndex =
        _typeOptions.indexWhere((o) => o.value == _selectedType);
    final safeSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: AppToggleButtonGroup(
        options: _typeOptions,
        selectedIndex: safeSelectedIndex,
        onChanged: (i) => setState(() {
          _selectedType = _typeOptions[i].value;
          _resetVisibleCounts();
        }),
        scrollable: true,
        compact: true,
        showBorder: false,
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
        if (homeProvider.isLoadingCategories && categories.isEmpty) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 72,
                    height: 32,
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFF8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (categories.isEmpty) return const SizedBox.shrink();

        // Show first 5 as chips, then a "more" button
        const maxVisible = 5;
        final visible = categories.length > maxVisible
            ? categories.sublist(0, maxVisible)
            : categories;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip
                _buildCategoryChip(
                  label: context.tr('All'),
                  isSelected: _selectedCategoryIds.isEmpty,
                  color: AppColors.primaryColor,
                  onTap: () => setState(() {
                    _selectedCategoryIds = {};
                    _resetVisibleCounts();
                  }),
                ),
                const SizedBox(width: 6),
                // Visible category chips
                ...visible.asMap().entries.map((entry) {
                  final cat = entry.value;
                  final color =
                      _categoryPalette[entry.key % _categoryPalette.length];
                  final isSelected = _selectedCategoryIds.contains(cat.id);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _buildCategoryChip(
                      label: cat.name,
                      isSelected: isSelected,
                      color: color,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedCategoryIds.remove(cat.id);
                        } else {
                          _selectedCategoryIds.add(cat.id);
                        }
                        _resetVisibleCounts();
                      }),
                    ),
                  );
                }),
                // "More" button if there are extra categories
                if (categories.length > maxVisible)
                  GestureDetector(
                    onTap: _openCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+ ${categories.length - maxVisible}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 14, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 14,
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
                          ? _localizedLocationLabel(_selectedLocation)
                          : context.tr(_selectedWilaya!),
                      Icons.location_on_rounded,
                    ),
                  if (_distanceKm != null)
                    _buildFilterTag(
                      '${_distanceKm!.toInt()} ${context.tr('km radius')}',
                      Icons.radar,
                    ),
                  if (_selectedCategoryIds.isNotEmpty)
                    _buildFilterTag(
                      '${context.tr('Categories')}: ${_selectedCategoryIds.length}',
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.tr('Clear'),
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
      margin: const EdgeInsetsDirectional.only(end: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              fontSize: 11,
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
                          context.tr('Filters'),
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    AppTextButton(
                      text: context.tr('Reset'),
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
                        context.tr('Sort By'),
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
                                context.tr(option),
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
                            context.tr('Price Range'),
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
                            context.tr('Minimum Rating'),
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
                    text: context.tr('Apply Filters'),
                    onPressed: () {
                      setState(() {
                        _selectedSort = draftSort;
                        _priceRange = draftPriceRange;
                        _minRating = draftMinRating;
                        _resetVisibleCounts();
                      });
                      _logFilterEvents(
                        priceRange: draftPriceRange,
                        minRating: draftMinRating,
                      );
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

  List<User> _getFilteredStores({
    required Map<int, String> categoriesById,
    required List<Post> posts,
    required List<Offer> offers,
    required List<Pack> packs,
  }) {
    // Store location filtering is already applied on the backend request.
    List<User> stores = _searchedStores.where(_storeMatchesQuery).toList();

    if (_selectedCategoryIds.isNotEmpty) {
      stores = stores
          .where(
            (store) => _storeMatchesSelectedCategories(
              store,
              categoriesById,
              posts: posts,
              offers: offers,
              packs: packs,
            ),
          )
          .toList();
    }

    if (_minRating > 0) {
      stores =
          stores.where((store) => store.averageRating >= _minRating).toList();
    }

    if (_priceRange.start > 0 || _priceRange.end < 100000) {
      stores = stores
          .where(
            (store) => _storeMatchesPriceFilter(
              store,
              posts: posts,
              offers: offers,
              packs: packs,
              categoriesById: categoriesById,
            ),
          )
          .toList();
    }

    // Store ordering is server-driven.
    return stores;
  }

  List<Post> _applyLocationFilterToProducts(List<Post> products) {
    // Location filtering is already applied on the backend for search requests.
    return products;
  }

  List<Offer> _applyLocationFilterToOffers(List<Offer> offers) {
    // Location filtering is already applied on the backend for search requests.
    return offers;
  }

  List<Pack> _applyLocationFilterToPacks(List<Pack> packs) {
    // Location filtering is already applied on the backend for search requests.
    return packs;
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

        var filteredProducts =
            _applyLocationFilterToProducts(products.toList());

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

        var filteredOffers = _applyLocationFilterToOffers(offers.toList());

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

        var filteredPacks = _applyLocationFilterToPacks(packs.toList());
        filteredPacks = filteredPacks
            .where((p) =>
                _packMatchesSelectedCategories(p, categoriesById, products))
            .toList();
        filteredPacks =
            filteredPacks.where((p) => _packMatchesQuery(p)).toList();
        if (_minRating > 0) {
          filteredPacks = filteredPacks
              .where((p) => p.merchantRating >= _minRating)
              .toList();
        }
        filteredPacks = filteredPacks
            .where((p) => _matchesPriceFilter(_packEffectivePrice(p)))
            .toList();

        // Ordering is server-driven via API query params.

        final filteredStores = _getFilteredStores(
          categoriesById: categoriesById,
          posts: products,
          offers: offers,
          packs: packs,
        );

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
              userLat: _activeUserLatForCards,
              userLng: _activeUserLngForCards,
              onTap: () {
                _logClick(p);
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
                userLat: _activeUserLatForCards,
                userLng: _activeUserLngForCards,
                onTap: () {
                  _logPromotionClick(o, placement: 'search_top');
                  Navigator.pushNamed(
                    context,
                    Routes.productDetails,
                    arguments: _buildOfferDetailsArgs(o),
                  );
                },
              )),
          ...filteredPacks.map((p) => PackCard(
                pack: p,
                userLat: _activeUserLatForCards,
                userLng: _activeUserLngForCards,
              )),
        ];
        final visibleCards = combinedCards.take(_allVisibleCount).toList();

        if (!hasItems && !hasStores) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasItems) ...[
                Row(
                  children: [
                    Text(
                      context.tr('Results'),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
              ],
              if (hasStores) ...[
                Row(
                  children: [
                    Text(
                      context.tr('Stores'),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  // keep "All" tab compact unless user explicitly expands stores
                  children: (_showAllStoresInAllView
                          ? filteredStores.take(_storesVisibleCount)
                          : filteredStores.take(_storesVisibleCount > 6
                              ? 6
                              : _storesVisibleCount))
                      .map((store) => StoreChip.fromUser(
                            store: store,
                            userLat: _activeUserLatForCards,
                            userLng: _activeUserLngForCards,
                            showDistance: _distanceKm != null,
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

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: context.tr('No Results Found'),
      message: context.tr(
        'Try adjusting your search or filters to find what you\'re looking for',
      ),
      actionText: _hasActiveFilters ? context.tr('Clear Filters') : null,
      onActionPressed: _hasActiveFilters ? _clearAllFilters : null,
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

        // Filter out products with active discounts
        products = products
            .where((p) => !postProvider.isProductDiscounted(p))
            .toList();

        products = _applyLocationFilterToProducts(products);

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

        // Ordering is server-driven via API query params.

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
                    userLat: _activeUserLatForCards,
                    userLng: _activeUserLngForCards,
                    onTap: () {
                      _logClick(visible[index]);
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

        offers = _applyLocationFilterToOffers(offers);

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

        // Ordering is server-driven via API query params.

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
                    userLat: _activeUserLatForCards,
                    userLng: _activeUserLngForCards,
                    onTap: () {
                      _logPromotionClick(offer, placement: 'search_top');
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
    return Consumer2<HomeProvider, PostProvider>(
      builder: (context, homeProvider, postProvider, child) {
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
        var packs = homeProvider.packs.toList();
        final products = postProvider.posts.toList();

        if (homeProvider.isLoadingPacks ||
            (_selectedCategoryIds.isNotEmpty && postProvider.isLoadingPosts)) {
          return _buildGridShimmer();
        }

        packs = _applyLocationFilterToPacks(packs);

        final categoriesById = _categoriesById(homeProvider);
        packs = packs
            .where((p) =>
                _packMatchesSelectedCategories(p, categoriesById, products))
            .toList();
        packs = packs.where((p) => _packMatchesQuery(p)).toList();
        if (_minRating > 0) {
          packs = packs.where((p) => p.merchantRating >= _minRating).toList();
        }
        packs = packs
            .where((p) => _matchesPriceFilter(_packEffectivePrice(p)))
            .toList();

        // Ordering is server-driven via API query params.

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
                  return PackCard(
                    pack: visible[index],
                    userLat: _activeUserLatForCards,
                    userLng: _activeUserLngForCards,
                  );
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
    return Consumer2<PostProvider, HomeProvider>(
      builder: (context, postProvider, homeProvider, child) {
        if (_isLoadingStores ||
            postProvider.isLoadingPosts ||
            postProvider.isLoadingOffers ||
            homeProvider.isLoadingPacks) {
          return const LoadingIndicator();
        }

        final filteredStores = _getFilteredStores(
          categoriesById: _categoriesById(homeProvider),
          posts: postProvider.posts,
          offers: postProvider.offers,
          packs: homeProvider.packs,
        );

        if (filteredStores.isEmpty) {
          return _buildEmptyState();
        }

        final visibleStores = filteredStores.take(_storesVisibleCount).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: visibleStores
                    .map((store) => StoreChip.fromUser(
                          store: store,
                          userLat: _activeUserLatForCards,
                          userLng: _activeUserLngForCards,
                          showDistance: _distanceKm != null,
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
      },
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
