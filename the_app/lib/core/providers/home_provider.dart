import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/category_model.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';
import '../services/product_api_service.dart';
import '../services/storage_service.dart';
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

  bool get isLoading =>
      _isLoadingCategories ||
      _isLoadingStores ||
      _isLoadingProducts ||
      _isLoadingHotDeals ||
      _isLoadingPacks;

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

  /// Load & rank featured stores using a multi-signal scoring algorithm.
  /// Signals: rating, review count, product count, followers,
  ///          account age, category match, random jitter.
  Future<void> loadFeaturedStores() async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingStores = v,
      setError: (v) => _storesError = v,
      task: () async {
        // Fetch a large candidate pool
        final pool = await _storeService.getStores(page: 1, pageSize: 40);

        // Derive preferred categories from this session's loaded products
        final sessionCategories = <String>{};
        for (final p in _recentProducts) {
          if (p.category.isNotEmpty) sessionCategories.add(p.category);
        }
        for (final p in _hotDeals) {
          if (p.category.isNotEmpty) sessionCategories.add(p.category);
        }
        // Merge with persisted cross-session category preferences
        final storedCategories = StorageService.getLastCategories();
        final preferred = {...sessionCategories, ...storedCategories}.toList();

        // Persist updated preferences for next session
        if (sessionCategories.isNotEmpty) {
          StorageService.saveLastCategories(preferred);
        }

        _featuredStores =
            _scoreAndShuffleStores(pool, preferredCategories: preferred);
      },
    );
  }

  /// Score stores by multiple signals and return the top 8 with randomization.
  /// Random jitter ensures results vary on every load.
  List<User> _scoreAndShuffleStores(
    List<User> pool, {
    List<String> preferredCategories = const [],
  }) {
    if (pool.isEmpty) return [];
    final rng = math.Random();
    final now = DateTime.now();

    final scored = pool.map((store) {
      double score = 0.0;

      // 1. Rating component (0-25 pts) with confidence factor
      final rating = store.averageRating;
      final reviewCount = store.reviewCount;
      final ratingConfidence = math.min(reviewCount / 10.0, 1.0);
      score += (rating / 5.0) * 25.0 * ratingConfidence;

      // 2. Review count (0-15 pts, log scale)
      if (reviewCount > 0) {
        score += math.min(math.log(reviewCount + 1) / math.log(2) * 3, 15);
      }

      // 3. Post count (0-20 pts, log scale)
      final postCount = store.productCount;
      if (postCount > 0) {
        score += math.min(math.log(postCount + 1) / math.log(2) * 4, 20);
      }

      // 4. Account age (0-10 pts)
      final ageDays = now.difference(store.dateJoined).inDays;
      final ageScore = math.min(ageDays / 365.0 * 10, 10);
      score += ageScore;

      // 5. Category match bonus (0-20 pts)
      if (preferredCategories.isNotEmpty) {
        final storeCategories =
            store.categories.map((c) => c.toLowerCase()).toSet();
        final preferred =
            preferredCategories.map((c) => c.toLowerCase()).toSet();
        final matches = storeCategories.intersection(preferred).length;
        if (matches > 0) {
          score += math.min(matches * 5.0, 20.0);
        }
      }

      // 6. Followers (0-10 pts, log scale)
      final followers = store.followersCount;
      if (followers > 0) {
        score += math.min(math.log(followers + 1) / math.log(2) * 2, 10);
      }

      // 7. Random jitter (0-5 pts) for variety on each load
      score += rng.nextDouble() * 5.0;

      return MapEntry(store, score);
    }).toList();

    // First shuffle to randomize same-score items
    scored.shuffle(rng);

    // Then sort by score
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Take top stores with additional randomization
    final top20 = scored.take(20).toList();

    // Keep top 5, randomize the rest for variety
    final result = <User>[];
    if (top20.length > 5) {
      result.addAll(top20.take(5).map((e) => e.key));
      final remaining = top20.skip(5).map((e) => e.key).toList()..shuffle(rng);
      result.addAll(remaining.take(3));
    } else {
      result.addAll(top20.map((e) => e.key));
    }

    return result;
  }

  /// Load recent products from API
  Future<void> loadRecentProducts() async {
    await _runSectionLoad(
      setLoading: (v) => _isLoadingProducts = v,
      setError: (v) => _productsError = v,
      task: () async {
        final response = await _productService.getProducts(
          ordering: '-created_at',
          page: 1,
        );
        // Shuffle top-20 so each refresh shows a different varied set
        final recentPool = response.results.take(20).toList()
          ..shuffle(math.Random());
        _recentProducts = recentPool.take(10).toList();
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

  /// Load featured packs
  Future<void> loadFeaturedPacks() async {
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

        final data = await ApiService.get(
            '/api/catalog/packs/?available_status=available');

        if (data is Map<String, dynamic> && data['results'] != null) {
          _featuredPacks = (data['results'] as List)
              .map((json) => Pack.fromJson(json as Map<String, dynamic>,
                  storesById: storesById))
              .take(10)
              .toList();
        } else if (data is List) {
          _featuredPacks = data
              .map((json) => Pack.fromJson(json as Map<String, dynamic>,
                  storesById: storesById))
              .take(10)
              .toList();
        } else {
          _featuredPacks = [];
        }
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
