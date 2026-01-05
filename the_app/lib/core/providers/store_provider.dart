import 'package:flutter/foundation.dart';
import '../services/store_api_service.dart';
import '../../data/models/store_model.dart';
import '../../data/models/post_model.dart';

class StoreProvider extends ChangeNotifier {
  final StoreApiService apiService;
  StoreProvider({required this.apiService});

  Store? _store;
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  String? _error;
  bool _isFollowing = false;
  List<Post> _products = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Store? get store => _store;
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get error => _error;
  bool get isFollowing => _isFollowing;
  List<Post> get products => List.unmodifiable(_products);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<Store?> getMyStore(int userId) async {
    return await apiService.getMyStore(userId);
  }

  /// Load store details and its products
  Future<void> loadStore(int storeId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load store details and check follow status in parallel
      final results = await Future.wait([
        apiService.getStoreDetails(storeId, forceRefresh: forceRefresh),
        apiService.isFollowing(storeId),
      ]);

      _store = results[0] as Store;
      _isFollowing = results[1] as bool;
      _currentPage = 1;
      _hasMore = true;
      _products = [];

      _isLoading = false;
      notifyListeners();

      // Then load products
      await loadProducts(storeId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load products for the current store
  Future<void> loadProducts(int storeId) async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _currentPage = 1;
    notifyListeners();

    try {
      final products = await apiService.getStoreProducts(storeId, page: 1);
      _products = products;
      _hasMore = products.length >= 20; // Assuming 20 is page size
      _currentPage = 1;
    } catch (e) {
      debugPrint('Error loading products: $e');
      // Don't set error - store is already loaded
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts(int storeId) async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final moreProducts = await apiService.getStoreProducts(storeId, page: nextPage);

      if (moreProducts.isEmpty) {
        _hasMore = false;
      } else {
        _products = [..._products, ...moreProducts];
        _currentPage = nextPage;
        _hasMore = moreProducts.length >= 20;
      }
    } catch (e) {
      debugPrint('Error loading more products: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Follow the current store
  Future<void> followStore(int storeId) async {
    final wasFollowing = _isFollowing;
    _isFollowing = true; // Optimistic update
    notifyListeners();

    try {
      await apiService.followStore(storeId);
    } catch (e) {
      _isFollowing = wasFollowing; // Revert on error
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unfollow the current store
  Future<void> unfollowStore(int storeId) async {
    final wasFollowing = _isFollowing;
    _isFollowing = false; // Optimistic update
    notifyListeners();

    try {
      await apiService.unfollowStore(storeId);
    } catch (e) {
      _isFollowing = wasFollowing; // Revert on error
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle follow state
  Future<void> toggleFollow(int storeId) async {
    if (_isFollowing) {
      await unfollowStore(storeId);
    } else {
      await followStore(storeId);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _store = null;
    _products = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _isFollowing = false;
    notifyListeners();
  }
}
