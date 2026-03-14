import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/jwt_validator.dart';
import '../../core/utils/app_logger.dart';
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
        final isActiveRaw = promo['is_active'] ??
            promo['isActive'] ??
            promo['is_available'] ??
            promo['active'] ??
            true;
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

      final productsResp =
          await ApiService.get('${ApiConfig.products}$queryString');

      final list = _extractList(productsResp);
      return list
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  static Future<Post> getPost(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.productDetail(id));
      return Post.fromJson(response as Map<String, dynamic>);
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

    final created =
        await ApiService.post(ApiConfig.categories, {'name': categoryName});
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
    required List<XFile> images,
    bool isAvailable = true,
    bool isNegotiable = false,
    bool hidePrice = false,
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
  }) async {
    try {
      final categoryId =
          await _ensureCategory(category.isEmpty ? 'General' : category);
      final userId = await _ensureStoreForCurrentUser();

      final productPayload = {
        'store': userId,
        'category': categoryId,
        'name': title,
        'description': description,
        'price': price.toString(),
        'negotiable': isNegotiable,
        'hide_price': hidePrice,
        'available_status': isAvailable ? 'available' : 'out_of_stock',
        'delivery_available': deliveryAvailable,
        // Empty string = use store.address as default (handled in serializer)
        'delivery_wilayas': deliveryWilayas.join(','),
      };

      final productResponse =
          await ApiService.post(ApiConfig.products, productPayload);
      final productId = productResponse['id'];

      // Upload main + secondary images
      for (int i = 0; i < images.length; i++) {
        final isMain = i == 0;
        try {
          AppLogger.info(
              'Repository: Uploading image ${i + 1}/${images.length}, isMain: $isMain');
          await ApiService.postMultipart(
            ApiConfig.productImages,
            {
              'product': productId.toString(),
              'is_main': isMain ? 'True' : 'False',
            },
            images[i],
            'image',
          );
          AppLogger.info('Repository: Image ${i + 1} uploaded successfully');
        } catch (imageError) {
          AppLogger.info(
              'Repository: Failed to upload image ${i + 1}: $imageError');
          if (i == images.length - 1 && images.length == 1) {
            rethrow;
          }
        }
      }

      // Explicitly trigger notification now that the post and images are fully saved
      try {
        await ApiService.post(ApiConfig.notificationsTrigger, {
          'post_id': productId,
          'post_type': 'product',
          'post_title': title,
        });
      } catch (e) {
        AppLogger.info(
            'Repository: Warning: Failed to trigger follower notification: $e');
      }

      return await getPost(productId);
    } catch (e) {
      AppLogger.error('Repository: Error creating product', error: e);
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
    List<XFile> newImages = const [],
    List<int> removeImageIds = const [],
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
  }) async {
    try {
      final categoryId =
          await _ensureCategory(category.isEmpty ? 'General' : category);
      final fields = {
        'name': title,
        'description': description,
        'price': price.toString(),
        'category': categoryId,
        'available_status': isAvailable ? 'available' : 'out_of_stock',
        'hide_price': hidePrice,
        'delivery_available': deliveryAvailable,
        'delivery_wilayas': deliveryWilayas.join(','),
      };

      await ApiService.patch(ApiConfig.productDetail(id), fields);

      for (final imageId in removeImageIds) {
        try {
          await ApiService.delete('${ApiConfig.productImages}$imageId/');
        } catch (deleteError) {
          AppLogger.info(
              'Repository: Failed to delete image $imageId: $deleteError');
        }
      }

      for (int i = 0; i < newImages.length; i++) {
        final isMain = i == 0;
        try {
          AppLogger.info(
              'Repository: Uploading new image ${i + 1}/${newImages.length}, isMain: $isMain');
          await ApiService.postMultipart(
            ApiConfig.productImages,
            {
              'product': id.toString(),
              'is_main': isMain ? 'True' : 'False',
            },
            newImages[i],
            'image',
          );
          AppLogger.info('Repository: New image ${i + 1} uploaded successfully');
        } catch (imageError) {
          AppLogger.info(
              'Repository: Failed to upload new image ${i + 1}: $imageError');
        }
      }

      return await getPost(id);
    } catch (e) {
      AppLogger.error('Repository: Error updating product', error: e);
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<List<Offer>> getOffers({
    String? authorId,
    int? storeId,
    bool includeInactive = false,
    String? kind,
    String? placement,
    String? wilayaCode,
  }) async {
    try {
      final query = <String, String>{};
      if (kind != null && kind.isNotEmpty) query['kind'] = kind;
      if (placement != null && placement.isNotEmpty) {
        query['placement'] = placement;
      }
      if (wilayaCode != null && wilayaCode.isNotEmpty) {
        query['wilaya_code'] = wilayaCode;
      }
      final url = query.isEmpty
          ? ApiConfig.promotions
          : '${ApiConfig.promotions}?${Uri(queryParameters: query).query}';
      final promotionsResp = await ApiService.get(url);
      AppLogger.info('Repository: Promotions response: $promotionsResp');
      final promos = _extractList(promotionsResp);
      AppLogger.info('Repository: Found ${promos.length} promotions');
      if (promos.isEmpty) return [];

      int? parseProductId(Map<String, dynamic> promo) {
        final raw =
            promo['product'] ?? promo['product_id'] ?? promo['productId'];
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

      final bool shouldIncludeInactive =
          includeInactive || (authorId != null && authorId.isNotEmpty);

      for (final promo in promos) {
        if (promo is! Map<String, dynamic>) continue;
        AppLogger.info('Repository: Processing promo: $promo');

        // Check if promo is active - be more lenient
        final isActiveRaw = promo['is_active'] ??
            promo['isActive'] ??
            promo['is_available'] ??
            promo['active'] ??
            true;
        final bool isActive = isActiveRaw != false;
        AppLogger.info('Repository: Promo ${promo['id']} isActive=$isActive');

        // Public offers feed: hide inactive promos
        if (!shouldIncludeInactive && !isActive) {
          AppLogger.info(
              'Repository: Skipping promo ${promo['id']} - not active');
          continue;
        }

        if (filterStoreId != null) {
          final rawStore =
              promo['store'] ?? promo['store_id'] ?? promo['storeId'];
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
        AppLogger.info('Repository: Promo ${promo['id']} productId=$productId');
        if (productId == null) {
          AppLogger.info(
              'Repository: Skipping promo ${promo['id']} - no product ID');
          continue;
        }

        Post? product;
        try {
          product = productCache[productId] ?? await getPost(productId);
          productCache[productId] = product;
          AppLogger.info(
              'Repository: Loaded product ${product.title} for promo ${promo['id']}');
        } catch (e) {
          // If a single product fetch fails, skip this promo rather than failing all offers.
          AppLogger.info(
              'Repository: Skipping promo ${promo['id']} - failed to load product $productId: $e');
          continue;
        }

        int percentage = int.tryParse(
              (promo['percentage'] ??
                      promo['discount_percentage'] ??
                      promo['discountPercentage'] ??
                      promo['discount'] ??
                      0)
                  .toString(),
            ) ??
            0;
        AppLogger.info('Repository: Promo ${promo['id']} percentage=$percentage');
        final promoKind = (promo['kind'] ?? 'promotion').toString();
        if (percentage < 0) percentage = 0;
        if (percentage > 100) percentage = 100;

        // Allow 0% discounts to still show (some promotions might have other benefits)
        // But default to at least showing something
        if (percentage == 0 && promoKind != 'advertising') {
          AppLogger.info(
              'Repository: Promo ${promo['id']} has 0% discount, setting to 10%');
          percentage = 10; // Default discount if not specified
        }

        final double newPrice =
            (product.price * (1 - (percentage / 100))).toDouble();

        offers.add(
          Offer(
            id: promo['id'] ?? 0,
            product: product,
            discountPercentage: percentage,
            newPrice: newPrice,
            isAvailable: isActive,
            createdAt: DateTime.tryParse(
                    (promo['start_date'] ?? promo['created_at'] ?? '')
                        .toString()) ??
                DateTime.now(),
            endDate: DateTime.tryParse((promo['end_date'] ?? '').toString()),
            maxImpressions:
                int.tryParse((promo['max_impressions'] ?? '').toString()),
            uniqueViewersCount:
                int.tryParse((promo['unique_viewers_count'] ?? '').toString()),
            remainingImpressions:
                int.tryParse((promo['remaining_impressions'] ?? '').toString()),
          ),
        );
        AppLogger.info(
            'Repository: Added offer ${promo['id']} for product ${product.title}');
      }

      AppLogger.info('Repository: Total offers loaded: ${offers.length}');
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return offers;
    } catch (e) {
      AppLogger.error('Repository: Error fetching offers', error: e);
      throw Exception('Failed to load offers: $e');
    }
  }

  static Future<Offer> createOffer({
    int? productId,
    required int discountPercentage,
    bool isAvailable = true,
    String kind = 'promotion',
    String placement = 'home_top',
    String audienceMode = 'all',
    List<String> targetWilayas = const [],
    List<String> targetCategories = const [],
    List<int> targetUserIds = const [],
    int? priorityBoost,
    int? maxImpressions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (productId == null) {
        throw Exception('productId is required for promotions');
      }
      final storeId = await _ensureStoreForCurrentUser();
      final now = DateTime.now();
      final start = startDate ?? now;
      final end = endDate ?? now.add(const Duration(days: 30)); // Default 30 days

      final payload = {
        'store': storeId,
        if (productId != null) 'product': productId,
        'name': kind == 'advertising'
            ? 'Ad for Product $productId'
            : 'Promotion for Product $productId', // Required by backend
        'percentage': discountPercentage,
        'kind': kind,
        'placement': placement,
        'audience_mode': audienceMode,
        'target_wilayas': targetWilayas,
        'target_categories': targetCategories,
        'target_user_ids': targetUserIds,
        if (priorityBoost != null) 'priority_boost': priorityBoost,
        if (maxImpressions != null) 'max_impressions': maxImpressions,
        'is_active': isAvailable,
        'start_date': start.toIso8601String().split('T')[0], // YYYY-MM-DD
        'end_date': end.toIso8601String().split('T')[0],
      };
      final resp = await ApiService.post(ApiConfig.promotions, payload);

      // Refresh related product to compute discounted price
      final product = productId != null ? await getPost(productId) : null;
      final double newPrice = product != null
          ? (product.price * (1 - (discountPercentage / 100))).toDouble()
          : 0.0;

      // Trigger notification for the promotion
      final offerId = resp['id'] ?? 0;
      final title = product != null
          ? '$discountPercentage% OFF on ${product.title}'
          : 'New promotion';
      try {
        await ApiService.post(ApiConfig.notificationsTrigger, {
          'post_id': offerId,
          'post_type': 'promotion',
          'post_title': title,
        });
      } catch (e) {
        AppLogger.info(
            'Repository: Warning: Failed to trigger follower notification: $e');
      }

      return Offer(
        id: offerId,
        product: product ?? await getPost(productId ?? 0),
        discountPercentage: discountPercentage,
        newPrice: newPrice,
        isAvailable: isAvailable,
        createdAt:
            DateTime.tryParse(resp['start_date'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse((resp['end_date'] ?? '').toString()),
        maxImpressions:
            int.tryParse((resp['max_impressions'] ?? '').toString()),
        uniqueViewersCount:
            int.tryParse((resp['unique_viewers_count'] ?? '').toString()),
        remainingImpressions:
            int.tryParse((resp['remaining_impressions'] ?? '').toString()),
        kind: (resp['kind'] ?? kind).toString(),
        placement: (resp['placement'] ?? placement).toString(),
        audienceMode: (resp['audience_mode'] ?? audienceMode).toString(),
        priorityBoost:
            int.tryParse((resp['priority_boost'] ?? '').toString()) ?? 0,
        impressionsCount:
            int.tryParse((resp['impressions_count'] ?? '').toString()) ?? 0,
        clicksCount:
            int.tryParse((resp['clicks_count'] ?? '').toString()) ?? 0,
      );
    } catch (e) {
      AppLogger.error('Repository: Error creating offer', error: e);
      throw Exception('Failed to create offer: $e');
    }
  }

  static Future<Offer> updateOffer({
    required int offerId,
    int? discountPercentage,
    bool? isAvailable,
    String? kind,
    String? placement,
    String? audienceMode,
    List<String>? targetWilayas,
    List<String>? targetCategories,
    List<int>? targetUserIds,
    int? priorityBoost,
    int? maxImpressions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (discountPercentage != null) {
        payload['percentage'] = discountPercentage;
      }
      if (isAvailable != null) payload['is_active'] = isAvailable;
      if (kind != null) payload['kind'] = kind;
      if (placement != null) payload['placement'] = placement;
      if (audienceMode != null) payload['audience_mode'] = audienceMode;
      if (targetWilayas != null) payload['target_wilayas'] = targetWilayas;
      if (targetCategories != null) {
        payload['target_categories'] = targetCategories;
      }
      if (targetUserIds != null) payload['target_user_ids'] = targetUserIds;
      if (priorityBoost != null) payload['priority_boost'] = priorityBoost;
      if (maxImpressions != null) payload['max_impressions'] = maxImpressions;
      if (startDate != null) {
        payload['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        payload['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final resp =
          await ApiService.patch('${ApiConfig.promotions}$offerId/', payload);

      final productId = resp['product'] ?? resp['product_id'];
      final product = productId != null ? await getPost(productId) : null;
      final pct = discountPercentage ??
          int.tryParse(resp['percentage'].toString()) ??
          0;
      final double newPrice = product != null
          ? (product.price * (1 - (pct / 100))).toDouble()
          : 0.0;

      return Offer(
        id: resp['id'] ?? offerId,
        product: product ?? await getPost(offerId),
        discountPercentage: pct,
        newPrice: newPrice,
        isAvailable: isAvailable ?? resp['is_active'] ?? true,
        createdAt:
            DateTime.tryParse(resp['start_date'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse((resp['end_date'] ?? '').toString()),
        maxImpressions:
            int.tryParse((resp['max_impressions'] ?? '').toString()),
        uniqueViewersCount:
            int.tryParse((resp['unique_viewers_count'] ?? '').toString()),
        remainingImpressions:
            int.tryParse((resp['remaining_impressions'] ?? '').toString()),
        kind: (resp['kind'] ?? 'promotion').toString(),
        placement: (resp['placement'] ?? 'home_top').toString(),
        audienceMode: (resp['audience_mode'] ?? 'all').toString(),
        priorityBoost:
            int.tryParse((resp['priority_boost'] ?? '').toString()) ?? 0,
        impressionsCount:
            int.tryParse((resp['impressions_count'] ?? '').toString()) ?? 0,
        clicksCount:
            int.tryParse((resp['clicks_count'] ?? '').toString()) ?? 0,
      );
    } catch (e) {
      AppLogger.error('Repository: Error updating offer', error: e);
      throw Exception('Failed to update offer: $e');
    }
  }

  static Future<void> deleteOffer(int offerId) async {
    try {
      await ApiService.delete('${ApiConfig.promotions}$offerId/');
    } catch (e) {
      AppLogger.error('Repository: Error deleting offer', error: e);
      throw Exception('Failed to delete offer: $e');
    }
  }

  static Future<void> registerPromotionClick(int promotionId) async {
    try {
      await ApiService.post(
          '${ApiConfig.promotions}$promotionId/register-click/', {});
    } catch (e) {
      AppLogger.error('Repository: Failed to register promo click', error: e);
    }
  }
}
