import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/jwt_validator.dart';
import '../models/offer_model.dart';
import '../models/post_model.dart';

class PostRepository {
  static List<dynamic> _extractList(dynamic response) {
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List<dynamic>;
    }
    if (response is List) return response;
    return [];
  }

  static Future<Map<int, String>> _loadStoresById() async {
    final resp = await ApiService.get(ApiConfig.users);
    final list = _extractList(resp);
    final map = <int, String>{};
    for (final item in list) {
      final u = item as Map<String, dynamic>;
      map[u['id']] = u['name'] ?? u['username'] ?? 'Store';
    }
    return map;
  }

  static Future<Map<int, String>> _loadCategoriesById() async {
    final resp = await ApiService.get(ApiConfig.categories);
    final list = _extractList(resp);
    final map = <int, String>{};
    for (final item in list) {
      final category = item as Map<String, dynamic>;
      map[category['id']] = category['name'] ?? 'Uncategorized';
    }
    return map;
  }

  static Future<Map<int, int>> _loadPromotionsByProduct() async {
    try {
      final resp = await ApiService.get(ApiConfig.promotions);
      final list = _extractList(resp);
      final map = <int, int>{};
      for (final item in list) {
        final promo = item as Map<String, dynamic>;

		// Only apply active promotions to product pricing.
		final isActiveRaw =
			promo['is_active'] ?? promo['isActive'] ?? promo['is_available'] ?? promo['active'] ?? true;
		final bool isActive = isActiveRaw != false;
		if (!isActive) continue;

        final productId = promo['product'];
        final percentage = int.tryParse(promo['percentage'].toString()) ?? 0;
        if (productId != null) map[productId] = percentage;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<List<Post>> getPosts({
    String? search,
    int? page,
    int? storeId,
    int? categoryId,
	bool availableOnly = true,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page.toString();
      if (storeId != null) queryParams['store'] = storeId.toString();
      if (categoryId != null) queryParams['category'] = categoryId.toString();
		if (availableOnly) queryParams['available_status'] = 'available';

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      final productsResp = await ApiService.get('${ApiConfig.products}$queryString');
      final storesById = await _loadStoresById();
      final categoriesById = await _loadCategoriesById();
      final promotionsByProduct = await _loadPromotionsByProduct();

      final list = _extractList(productsResp);
      return list
          .map((item) => Post.fromBackend(
                item as Map<String, dynamic>,
                storesById: storesById,
                categoriesById: categoriesById,
                promoPercentageByProduct: promotionsByProduct,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  static Future<Post> getPost(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.productDetail(id));
      final storesById = await _loadStoresById();
      final categoriesById = await _loadCategoriesById();
      final promotionsByProduct = await _loadPromotionsByProduct();
      return Post.fromBackend(
        response as Map<String, dynamic>,
        storesById: storesById,
        categoriesById: categoriesById,
        promoPercentageByProduct: promotionsByProduct,
      );
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  static Future<void> deletePost(int id) async {
    try {
      await ApiService.delete(ApiConfig.productDetail(id));
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<int> _ensureCategory(String categoryName) async {
    final categories = await _loadCategoriesById();
    final existing = categories.entries.firstWhere(
      (entry) => entry.value.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => const MapEntry<int, String>(-1, ''),
    );
    if (existing.key != -1) return existing.key;

    final created = await ApiService.post(ApiConfig.categories, {'name': categoryName});
    return created['id'];
  }

  static Future<int> _ensureStoreForCurrentUser() async {
    final token = await StorageService.getAccessToken();
    if (token == null) throw Exception('No active token');
    final decoded = JWTValidator.decodePayload(token) ?? {};
    final userId = decoded['user_id'];
    if (userId == null) throw Exception('Cannot extract user_id from token');

    // Since User now contains store info, we just return the user ID
    // No need to create separate store - user IS the store
    return userId;
  }

  /// Public helper so providers can fetch the current user's store id
  static Future<int> getOrCreateMyStoreId() => _ensureStoreForCurrentUser();

  static Future<Post> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required List<File> images,
    bool isAvailable = true,
    bool isNegotiable = false,
    bool hidePrice = false,
  }) async {
    try {
      final categoryId = await _ensureCategory(category.isEmpty ? 'General' : category);
      final userId = await _ensureStoreForCurrentUser(); // Now returns user ID directly

      final productPayload = {
        'store': userId, // User ID is now the store ID
        'category': categoryId,
        'name': title,
        'description': description,
        'price': price.toString(),
        'negotiable': isNegotiable,
        'hide_price': hidePrice,
        'available_status': isAvailable ? 'available' : 'out_of_stock',
      };

      final productResponse = await ApiService.post(ApiConfig.products, productPayload);
      final productId = productResponse['id'];

      // Upload main + secondary images
      for (int i = 0; i < images.length; i++) {
        final isMain = i == 0;
        try {
          debugPrint('Repository: Uploading image ${i + 1}/${images.length}, isMain: $isMain');
          await ApiService.postMultipart(
            ApiConfig.productImages,
            {
              'product': productId.toString(),
              'is_main': isMain ? 'True' : 'False',
            },
            images[i],
            'image',
          );
          debugPrint('Repository: Image ${i + 1} uploaded successfully');
        } catch (imageError) {
          debugPrint('Repository: Failed to upload image ${i + 1}: $imageError');
          // Continue uploading other images even if one fails
          // but rethrow on the last image to notify user of partial failure
          if (i == images.length - 1 && images.length == 1) {
            rethrow;
          }
        }
      }

      return await getPost(productId);
    } catch (e) {
      debugPrint('Repository: Error creating product: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<Post> updateProduct({
    required int id,
    required String title,
    required String description,
    required double price,
    required String category,
    required bool isAvailable,
    bool hidePrice = false,
    List<File> newImages = const [],
  }) async {
    try {
      final categoryId = await _ensureCategory(category.isEmpty ? 'General' : category);
      final fields = {
        'name': title,
        'description': description,
        'price': price.toString(),
        'category': categoryId,
        'available_status': isAvailable ? 'available' : 'out_of_stock',
        'hide_price': hidePrice,
      };

      await ApiService.patch(ApiConfig.productDetail(id), fields);

      for (int i = 0; i < newImages.length; i++) {
        final isMain = i == 0;
        try {
          debugPrint('Repository: Uploading new image ${i + 1}/${newImages.length}, isMain: $isMain');
          await ApiService.postMultipart(
            ApiConfig.productImages,
            {
              'product': id.toString(),
              'is_main': isMain ? 'True' : 'False',
            },
            newImages[i],
            'image',
          );
          debugPrint('Repository: New image ${i + 1} uploaded successfully');
        } catch (imageError) {
          debugPrint('Repository: Failed to upload new image ${i + 1}: $imageError');
        }
      }

      return await getPost(id);
    } catch (e) {
      debugPrint('Repository: Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<List<Offer>> getOffers({String? authorId, int? storeId, bool includeInactive = false}) async {
    try {
      final promotionsResp = await ApiService.get(ApiConfig.promotions);
      debugPrint('Repository: Promotions response: $promotionsResp');
      final promos = _extractList(promotionsResp);
      debugPrint('Repository: Found ${promos.length} promotions');
      if (promos.isEmpty) return [];

      int? parseProductId(Map<String, dynamic> promo) {
        final raw = promo['product'] ?? promo['product_id'] ?? promo['productId'];
        if (raw == null) return null;
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        if (raw is Map) {
          final id = raw['id'];
          if (id is int) return id;
          if (id is String) return int.tryParse(id);
        }
        return null;
      }

      final offers = <Offer>[];

      // Backwards compat: if authorId looks numeric and storeId wasn't provided, treat it as storeId.
      final int? authorStoreId = int.tryParse(authorId ?? '');
      final int? filterStoreId = storeId ?? authorStoreId;

      final Map<int, Post> productCache = {};

      final bool shouldIncludeInactive = includeInactive || (authorId != null && authorId.isNotEmpty);

      for (final promo in promos) {
        if (promo is! Map<String, dynamic>) continue;
        debugPrint('Repository: Processing promo: $promo');

        // Check if promo is active - be more lenient
        final isActiveRaw = promo['is_active'] ??
            promo['isActive'] ??
            promo['is_available'] ??
            promo['active'] ??
            true;
        final bool isActive = isActiveRaw != false;
        debugPrint('Repository: Promo ${promo['id']} isActive=$isActive');

        // Public offers feed: hide inactive promos
        if (!shouldIncludeInactive && !isActive) {
          debugPrint('Repository: Skipping promo ${promo['id']} - not active');
          continue;
        }

        if (filterStoreId != null) {
          final rawStore = promo['store'] ?? promo['store_id'] ?? promo['storeId'];
          int? promoStoreId;
          if (rawStore is int) promoStoreId = rawStore;
          if (rawStore is String) promoStoreId = int.tryParse(rawStore);
          if (rawStore is Map) {
            final id = rawStore['id'];
            if (id is int) promoStoreId = id;
            if (id is String) promoStoreId = int.tryParse(id);
          }
          if (promoStoreId != null && promoStoreId != filterStoreId) {
            continue;
          }
        }

        final productId = parseProductId(promo);
        debugPrint('Repository: Promo ${promo['id']} productId=$productId');
        if (productId == null) {
          debugPrint('Repository: Skipping promo ${promo['id']} - no product ID');
          continue;
        }

        Post? product;
        try {
          product = productCache[productId] ?? await getPost(productId);
          productCache[productId] = product;
          debugPrint('Repository: Loaded product ${product.title} for promo ${promo['id']}');
        } catch (e) {
          // If a single product fetch fails, skip this promo rather than failing all offers.
          debugPrint('Repository: Skipping promo ${promo['id']} - failed to load product $productId: $e');
          continue;
        }

        int percentage = int.tryParse(
              (promo['percentage'] ?? promo['discount_percentage'] ?? promo['discountPercentage'] ?? promo['discount'] ?? 0).toString(),
            ) ??
            0;
        debugPrint('Repository: Promo ${promo['id']} percentage=$percentage');
        if (percentage < 0) percentage = 0;
        if (percentage > 100) percentage = 100;

        // Allow 0% discounts to still show (some promotions might have other benefits)
        // But default to at least showing something
        if (percentage == 0) {
          debugPrint('Repository: Promo ${promo['id']} has 0% discount, setting to 10%');
          percentage = 10; // Default discount if not specified
        }

        final double newPrice = (product.price * (1 - (percentage / 100))).toDouble();

        offers.add(
          Offer(
            id: promo['id'] ?? 0,
            product: product,
            discountPercentage: percentage,
            newPrice: newPrice,
            isAvailable: isActive,
            createdAt: DateTime.tryParse((promo['start_date'] ?? promo['created_at'] ?? '').toString()) ?? DateTime.now(),
          ),
        );
        debugPrint('Repository: Added offer ${promo['id']} for product ${product.title}');
      }

      debugPrint('Repository: Total offers loaded: ${offers.length}');
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return offers;
    } catch (e) {
      debugPrint('Repository: Error fetching offers: $e');
      throw Exception('Failed to load offers: $e');
    }
  }

  static Future<Offer> createOffer({
    required int productId,
    required int discountPercentage,
    bool isAvailable = true,
  }) async {
    try {
      final storeId = await _ensureStoreForCurrentUser();
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30)); // Default 30 days

      final payload = {
        'store': storeId,
        'product': productId,
        'name': 'Promotion for Product $productId', // Required by backend
        'percentage': discountPercentage,
        'is_active': isAvailable,
        'start_date': now.toIso8601String().split('T')[0], // YYYY-MM-DD
        'end_date': endDate.toIso8601String().split('T')[0],
      };
      final resp = await ApiService.post(ApiConfig.promotions, payload);

      // Refresh related product to compute discounted price
      final product = await getPost(productId);
      final double newPrice = (product.price * (1 - (discountPercentage / 100))).toDouble();

      return Offer(
        id: resp['id'] ?? 0,
        product: product,
        discountPercentage: discountPercentage,
        newPrice: newPrice,
        isAvailable: isAvailable,
        createdAt: DateTime.tryParse(resp['start_date'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Repository: Error creating offer: $e');
      throw Exception('Failed to create offer: $e');
    }
  }

  static Future<Offer> updateOffer({
    required int offerId,
    int? discountPercentage,
    bool? isAvailable,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (discountPercentage != null) payload['percentage'] = discountPercentage;
      if (isAvailable != null) payload['is_active'] = isAvailable;

      final resp = await ApiService.patch('${ApiConfig.promotions}$offerId/', payload);

      final productId = resp['product'] ?? resp['product_id'];
      final product = productId != null ? await getPost(productId) : null;
      final pct = discountPercentage ?? int.tryParse(resp['percentage'].toString()) ?? 0;
      final double newPrice = product != null ? (product.price * (1 - (pct / 100))).toDouble() : 0.0;

      return Offer(
        id: resp['id'] ?? offerId,
        product: product ?? await getPost(offerId),
        discountPercentage: pct,
        newPrice: newPrice,
        isAvailable: isAvailable ?? resp['is_active'] ?? true,
        createdAt: DateTime.tryParse(resp['start_date'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Repository: Error updating offer: $e');
      throw Exception('Failed to update offer: $e');
    }
  }

  static Future<void> deleteOffer(int offerId) async {
    try {
      await ApiService.delete('${ApiConfig.promotions}$offerId/');
    } catch (e) {
      debugPrint('Repository: Error deleting offer: $e');
      throw Exception('Failed to delete offer: $e');
    }
  }
}
