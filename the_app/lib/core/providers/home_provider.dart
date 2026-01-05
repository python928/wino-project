import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/models/store_model.dart';
import '../../data/models/pack_model.dart';
import '../services/api_service.dart';
import '../services/product_api_service.dart';
import '../services/store_api_service.dart';

/// Category model for home screen
class Category {
  final int id;
  final String name;
  final String? icon;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      productCount: json['product_count'] ?? json['products_count'] ?? 0,
    );
  }

  /// Get icon data based on category name
  IconData get iconData {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('إلكتروني') || nameLower.contains('electronic')) {
      return Icons.smartphone;
    } else if (nameLower.contains('أزياء') || nameLower.contains('ملابس') || nameLower.contains('fashion')) {
      return Icons.checkroom;
    } else if (nameLower.contains('منزل') || nameLower.contains('home')) {
      return Icons.chair;
    } else if (nameLower.contains('رياضة') || nameLower.contains('sport')) {
      return Icons.sports_basketball;
    } else if (nameLower.contains('تجميل') || nameLower.contains('beauty')) {
      return Icons.face;
    } else if (nameLower.contains('طعام') || nameLower.contains('food')) {
      return Icons.restaurant;
    } else if (nameLower.contains('كتب') || nameLower.contains('book')) {
      return Icons.book;
    } else if (nameLower.contains('سيارات') || nameLower.contains('car')) {
      return Icons.directions_car;
    }
    return Icons.category;
  }
}

class HomeProvider with ChangeNotifier {
  final ProductApiService _productService = ProductApiService();
  final StoreApiService _storeService = StoreApiService();

  // Categories
  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  // Featured Stores
  List<Store> _featuredStores = [];
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

  List<Store> get featuredStores => _featuredStores;
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

  bool get isLoading => _isLoadingCategories || _isLoadingStores ||
                         _isLoadingProducts || _isLoadingHotDeals || _isLoadingPacks;

  /// Load all home data
  Future<void> loadHomeData() async {
    await Future.wait([
      loadCategories(),
      loadFeaturedStores(),
      loadRecentProducts(),
      loadHotDeals(),
      loadFeaturedPacks(),
    ]);
  }

  /// Load categories from API
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final data = await _productService.getCategories();
      _categories = data.map((json) => Category.fromJson(json)).toList();

      // If no categories from API, use defaults
      if (_categories.isEmpty) {
        _categories = _getDefaultCategories();
      }
    } catch (e) {
      _categoriesError = e.toString();
      // Use defaults on error
      _categories = _getDefaultCategories();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Load featured stores from API
  Future<void> loadFeaturedStores() async {
    _isLoadingStores = true;
    _storesError = null;
    notifyListeners();

    try {
      final response = await _storeService.getStores(page: 1);
      _featuredStores = response.take(5).toList();
    } catch (e) {
      _storesError = e.toString();
    } finally {
      _isLoadingStores = false;
      notifyListeners();
    }
  }

  /// Load recent products from API
  Future<void> loadRecentProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final response = await _productService.getProducts(
        ordering: '-created_at',
        page: 1,
      );
      _recentProducts = response.results.take(10).toList();
    } catch (e) {
      _productsError = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load hot deals (products with discounts)
  Future<void> loadHotDeals() async {
    _isLoadingHotDeals = true;
    _hotDealsError = null;
    notifyListeners();

    try {
      final response = await _productService.getProducts(page: 1);
      // Filter products with discounts
      _hotDeals = response.results
          .where((p) => (p.discountPercentage ?? 0) > 0 || p.isHotDeal)
          .take(10)
          .toList();
    } catch (e) {
      _hotDealsError = e.toString();
    } finally {
      _isLoadingHotDeals = false;
      notifyListeners();
    }
  }

  /// Load featured packs
  Future<void> loadFeaturedPacks() async {
    _isLoadingPacks = true;
    _packsError = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/api/catalog/packs/');
      
      if (data is Map<String, dynamic> && data['results'] != null) {
        // API returns {count: X, results: [...]}
        _featuredPacks = (data['results'] as List)
            .map((json) => Pack.fromJson(json as Map<String, dynamic>))
            .take(10) // Limit to 10 packs
            .toList();
      } else if (data is List) {
        // Fallback: API returns a direct list
        _featuredPacks = data
            .map((json) => Pack.fromJson(json as Map<String, dynamic>))
            .take(10) // Limit to 10 packs
            .toList();
      } else {
        _featuredPacks = [];
      }
      _packsError = null;
    } catch (e) {
      _featuredPacks = [];
      _packsError = 'فشل في تحميل الحزم: ${e.toString()}';
    } finally {
      _isLoadingPacks = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadHomeData();
  }

  /// Get default categories when API fails or returns empty
  List<Category> _getDefaultCategories() {
    return const [
      Category(id: 1, name: 'إلكترونيات'),
      Category(id: 2, name: 'أزياء'),
      Category(id: 3, name: 'منزل'),
      Category(id: 4, name: 'رياضة'),
      Category(id: 5, name: 'تجميل'),
      Category(id: 6, name: 'طعام'),
    ];
  }
}
