import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../data/models/category_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../services/api_service.dart';
import '../services/product_api_service.dart';
import '../services/store_api_service.dart';

class HomeProvider with ChangeNotifier {
  final ProductApiService _productService = ProductApiService();
  final StoreApiService _storeService = StoreApiService();

  // Categories
  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  // Featured Stores
  List<User> _featuredStores = [];
  bool _isLoadingStores = false;
  String? _storesError;

  // Recent Products
  List<Post> _recentProducts = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  // Hot Deals
  List<Post> _hotDeals = [];
  bool _isLoadingHotDeals = false;
  String? _hotDealsError;

  // Featured Packs
  List<Pack> _featuredPacks = [];
  bool _isLoadingPacks = false;
  String? _packsError;

  // Shared discovery location filter (used across Home/Search screens)
  String _discoveryLocationLabel = '';
  String? _discoveryWilaya;
  String? _discoveryBaladiya;
  double? _discoveryRadiusKm;
  double? _discoveryUserLat;
  double? _discoveryUserLng;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;

  List<User> get featuredStores => _featuredStores;
  bool get isLoadingStores => _isLoadingStores;
  String? get storesError => _storesError;

  List<Post> get recentProducts => _recentProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;

  List<Post> get hotDeals => _hotDeals;
  bool get isLoadingHotDeals => _isLoadingHotDeals;
  String? get hotDealsError => _hotDealsError;

  List<Pack> get featuredPacks => _featuredPacks;
  List<Pack> get packs => _featuredPacks; // Alias for compatibility
  bool get isLoadingPacks => _isLoadingPacks;
  String? get packsError => _packsError;

  String get discoveryLocationLabel => _discoveryLocationLabel;
  String? get discoveryWilaya => _discoveryWilaya;
  String? get discoveryBaladiya => _discoveryBaladiya;
  double? get discoveryRadiusKm => _discoveryRadiusKm;
  double? get discoveryUserLat => _discoveryUserLat;
  double? get discoveryUserLng => _discoveryUserLng;

  bool get isLoading =>
      _isLoadingCategories ||
      _isLoadingStores ||
      _isLoadingProducts ||
      _isLoadingHotDeals ||
      _isLoadingPacks;

  void setDiscoveryLocationFilter({
    required String locationLabel,
    String? wilaya,
    String? baladiya,
    double? radiusKm,
    double? userLat,
    double? userLng,
    bool notify = true,
  }) {
    final changed = _discoveryLocationLabel != locationLabel ||
        _discoveryWilaya != wilaya ||
        _discoveryBaladiya != baladiya ||
        _discoveryRadiusKm != radiusKm ||
        _discoveryUserLat != userLat ||
        _discoveryUserLng != userLng;

    if (!changed) return;

    _discoveryLocationLabel = locationLabel;
    _discoveryWilaya = wilaya;
    _discoveryBaladiya = baladiya;
    _discoveryRadiusKm = radiusKm;
    _discoveryUserLat = userLat;
    _discoveryUserLng = userLng;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _runSectionLoad({
    required void Function(bool) setLoading,
    required void Function(String?) setError,
    required Future<void> Function() task,
    String Function(Object error)? errorMessage,
  }) async {
    setLoading(true);
    setError(null);
    notifyListeners();
    try {
      await task();
    } catch (e) {
      setError(errorMessage != null ? errorMessage(e) : e.toString());
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Load all home data.
  /// Products load first so stores can be scored with category context.
  Future<void> loadHomeData() async {
    await Future.wait([
      loadCategories(),
      loadRecentProducts(),
      loadHotDeals(),
      loadFeaturedPacks(),
    ]);
    // Products & deals now loaded — score stores with category context
    await loadFeaturedStores();
  }

  /// Load categories from API
  Future<void> loadCategories() async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingCategories = v,
      setError: (v) => _categoriesError = v,
      task: () async {
        final data = await _productService.getCategories();
        _categories = data.map((json) => Category.fromJson(json)).toList();
        if (_categories.isEmpty) {
          _categories = _getDefaultCategories();
        }
      },
      errorMessage: (e) {
        _categories = _getDefaultCategories();
        return e.toString();
      },
    );
  }

  /// Load featured stores directly from API (server-authoritative filtering).
  Future<void> loadFeaturedStores({
    String? wilayaCode,
    String? baladiya,
    double? userLat,
    double? userLng,
    double? radiusKm,
  }) async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingStores = v,
      setError: (v) => _storesError = v,
      task: () async {
        _featuredStores = await _storeService.getStores(
          page: 1,
          pageSize: 40,
          wilaya: wilayaCode,
          city: baladiya,
          userLat: userLat,
          userLng: userLng,
          radiusKm: radiusKm,
        );
      },
    );
  }

  /// Load home products from API.
  /// When [homeRank] is true, backend returns smart ranking (rated first + demand + fallback).
  Future<void> loadRecentProducts({
    int limit = 20,
    String? wilayaCode,
    String? baladiya,
    double? userLat,
    double? userLng,
    double? radiusKm,
    bool homeRank = false,
  }) async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingProducts = v,
      setError: (v) => _productsError = v,
      task: () async {
        final response = await _productService.getProducts(
          ordering: homeRank ? null : '-created_at',
          wilayaCode: wilayaCode,
          baladiya: baladiya,
          userLat: userLat,
          userLng: userLng,
          radiusKm: radiusKm,
          homeRank: homeRank,
          page: 1,
          pageSize: limit,
        );

        if (homeRank) {
          _recentProducts = response.results.take(limit).toList();
        } else {
          // Shuffle top-20 so each refresh shows a different varied set
          final recentPool = response.results.take(20).toList()
            ..shuffle(math.Random());
          _recentProducts = recentPool.take(10).toList();
        }
      },
    );
  }

  /// Load hot deals (products with discounts)
  Future<void> loadHotDeals() async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingHotDeals = v,
      setError: (v) => _hotDealsError = v,
      task: () async {
        final response = await _productService.getProducts(page: 1);
        // Shuffle so different deals surface on each refresh
        final dealsPool = response.results
            .where((p) => (p.discountPercentage ?? 0) > 0 || p.isHotDeal)
            .take(20)
            .toList()
          ..shuffle(math.Random());
        _hotDeals = dealsPool.take(10).toList();
      },
    );
  }

  void clearAllData({bool notify = true}) {
    _categories = [];
    _featuredStores = [];
    _recentProducts = [];
    _hotDeals = [];
    _featuredPacks = [];

    _isLoadingCategories = false;
    _isLoadingStores = false;
    _isLoadingProducts = false;
    _isLoadingHotDeals = false;
    _isLoadingPacks = false;

    _categoriesError = null;
    _storesError = null;
    _productsError = null;
    _hotDealsError = null;
    _packsError = null;

    if (notify) notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _fetchPaginatedResults(
    String endpoint, {
    bool fetchAllPages = false,
  }) async {
    final results = <Map<String, dynamic>>[];
    final visitedUrls = <String>{};
    String? nextUrl = endpoint;

    while (nextUrl != null && nextUrl.isNotEmpty && visitedUrls.add(nextUrl)) {
      final data = await ApiService.get(nextUrl);

      if (data is Map<String, dynamic> && data['results'] is List) {
        results.addAll(
          (data['results'] as List).whereType<Map<String, dynamic>>(),
        );
        if (!fetchAllPages) break;

        final next = data['next']?.toString();
        if (next == null || next.isEmpty) break;
        nextUrl = next;
        continue;
      }

      if (data is List) {
        results.addAll(data.whereType<Map<String, dynamic>>());
      }
      break;
    }

    return results;
  }

  /// Load featured packs
  Future<void> loadFeaturedPacks({
    int? limit = 10,
    String? search,
    int? categoryId,
    List<int>? categoryIds,
    String? wilayaCode,
    String? baladiya,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? ordering,
    double? userLat,
    double? userLng,
    double? radiusKm,
    bool homeRank = false,
  }) async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingPacks = v,
      setError: (v) => _packsError = v,
      task: () async {
        Map<int, String> storesById = {};
        try {
          final storesResp = await ApiService.get(ApiConfig.users);
          final storesList =
              storesResp is Map && storesResp.containsKey('results')
                  ? storesResp['results'] as List
                  : (storesResp is List ? storesResp : []);
          for (final item in storesList) {
            if (item is Map<String, dynamic>) {
              storesById[item['id']] = item['name'] ?? 'Store';
            }
          }
        } catch (_) {
          // continue without enrichment
        }

        final queryParams = <String, String>{
          'available_status': 'available',
        };
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        if (categoryId != null) {
          queryParams['category'] = '$categoryId';
        }
        if (categoryIds != null && categoryIds.isNotEmpty) {
          queryParams['category_ids'] = categoryIds.join(',');
        }
        if (wilayaCode != null && wilayaCode.isNotEmpty) {
          queryParams['wilaya_code'] = wilayaCode;
        }
        if (baladiya != null && baladiya.isNotEmpty) {
          queryParams['baladiya'] = baladiya;
        }
        if (minPrice != null) {
          queryParams['min_price'] = minPrice.toStringAsFixed(2);
        }
        if (maxPrice != null) {
          queryParams['max_price'] = maxPrice.toStringAsFixed(2);
        }
        if (minRating != null) {
          queryParams['min_rating'] = minRating.toStringAsFixed(1);
        }
        if (ordering != null && ordering.isNotEmpty) {
          queryParams['ordering'] = ordering;
        }
        if (userLat != null && userLng != null) {
          queryParams['lat'] = userLat.toStringAsFixed(6);
          queryParams['lng'] = userLng.toStringAsFixed(6);
        }
        if (radiusKm != null) {
          queryParams['radius_km'] = radiusKm.toStringAsFixed(2);
        }
        if (homeRank) {
          queryParams['home_rank'] = 'true';
        }

        final endpoint =
            '/api/catalog/packs/?${Uri(queryParameters: queryParams).query}';
        final packResults = await _fetchPaginatedResults(
          endpoint,
          fetchAllPages: limit == null,
        );

        final parsedPacks = packResults
            .map((json) => Pack.fromJson(json, storesById: storesById))
            .toList();
        _featuredPacks =
            limit == null ? parsedPacks : parsedPacks.take(limit).toList();
      },
      errorMessage: (e) {
        _featuredPacks = [];
        return 'Failed to load packs: ${e.toString()}';
      },
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadHomeData();
  }

  /// Default categories when API fails or returns empty
  List<Category> _getDefaultCategories() {
    return const [
      Category(id: 1, name: 'Electronics'),
      Category(id: 2, name: 'Fashion'),
      Category(id: 3, name: 'Home'),
      Category(id: 4, name: 'Sports'),
      Category(id: 5, name: 'Beauty'),
      Category(id: 6, name: 'Food'),
      Category(id: 7, name: 'Product'),
      Category(id: 8, name: 'Pack'),
      Category(id: 9, name: 'Promotions'),
    ];
  }
}
