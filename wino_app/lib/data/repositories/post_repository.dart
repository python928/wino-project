import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/jwt_validator.dart';
import '../models/offer_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostRepository {
  static List<dynamic> _extractList(dynamic response) {
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List<dynamic>;
    }
    if (response is List) return response;
    return [];
  }

  static Future<List<dynamic>> _fetchList(
    String url, {
    bool fetchAllPages = false,
  }) async {
    final items = <dynamic>[];
    final visitedUrls = <String>{};
    String? nextUrl = url;

    while (nextUrl != null && nextUrl.isNotEmpty && visitedUrls.add(nextUrl)) {
      final response = await ApiService.get(nextUrl);
      final pageItems = _extractList(response);
      items.addAll(pageItems);

      if (!fetchAllPages || response is! Map) {
        break;
      }

      final next = response['next']?.toString();
      if (next == null || next.isEmpty) {
        break;
      }
      nextUrl = next;
    }

    return items;
  }

  static String _toUtcIso(DateTime value) {
    // Always send UTC with Z suffix to avoid server interpreting local naive time as UTC.
    return value.toUtc().toIso8601String();
  }

  static int _parsePercentage(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    final text = raw.toString().trim();
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(text) ?? 0;
  }

  static DateTime? _parseDateTimeToLocal(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return parsed.toLocal();
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
        final percentage = _parsePercentage(promo['percentage']);
        if (productId != null) map[productId] = percentage;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> _loadPackById(int packId) async {
    try {
      final resp = await ApiService.get(ApiConfig.packDetail(packId));
      if (resp is Map<String, dynamic>) return resp;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Post>> getPosts({
    String? search,
    int? page,
    int? storeId,
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
    bool availableOnly = true,
    bool fetchAllPages = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page.toString();
      if (storeId != null) queryParams['store'] = storeId.toString();
      if (categoryId != null) queryParams['category'] = categoryId.toString();
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
      if (availableOnly) queryParams['available_status'] = 'available';

      final queryString = queryParams.isNotEmpty
          ? '?${Uri(queryParameters: queryParams).query}'
          : '';

      final list = await _fetchList(
        '${ApiConfig.products}$queryString',
        fetchAllPages: fetchAllPages && page == null,
      );
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

  static Future<int> _ensureCategory(String categoryRef) async {
    final asId = int.tryParse(categoryRef.trim());
    if (asId != null && asId > 0) return asId;

    final categoryName = categoryRef.trim();
    if (categoryName.isEmpty) {
      final categories = await _loadCategoriesById();
      final firstId = categories.keys.isNotEmpty ? categories.keys.first : null;
      if (firstId != null) return firstId;
      final created =
          await ApiService.post(ApiConfig.categories, {'name': 'General'});
      return created['id'];
    }

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
      final categoryId = await _ensureCategory(category);
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
      final categoryId = await _ensureCategory(category);
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
          AppLogger.info(
              'Repository: New image ${i + 1} uploaded successfully');
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
    String? search,
    int? categoryId,
    List<int>? categoryIds,
    String? baladiya,
    String? wilayaCode,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? ordering,
    double? radiusKm,
    double? userLat,
    double? userLng,
    bool homeRank = false,
    bool singleRandomized = false,
    bool fetchAllPages = false,
  }) async {
    try {
      final requestedKind = (kind ?? '').trim().toLowerCase();
      final isAdsRequest = requestedKind == 'advertising';
      final query = <String, String>{};
      // Backwards compat: if authorId looks numeric and storeId wasn't provided, treat it as storeId.
      final int? authorStoreId = int.tryParse(authorId ?? '');
      final int? filterStoreId = storeId ?? authorStoreId;

      if (filterStoreId != null) {
        query['store'] = '$filterStoreId';
      }
      if (includeInactive) {
        query['include_inactive'] = 'true';
      }
      if (!isAdsRequest && kind != null && kind.isNotEmpty)
        query['kind'] = kind;
      if (!isAdsRequest && search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (!isAdsRequest && categoryId != null) {
        query['category'] = '$categoryId';
      }
      if (!isAdsRequest && categoryIds != null && categoryIds.isNotEmpty) {
        query['category_ids'] = categoryIds.join(',');
      }
      if (placement != null && placement.isNotEmpty) {
        query['placement'] = placement;
      }
      if (wilayaCode != null && wilayaCode.isNotEmpty) {
        query['wilaya_code'] = wilayaCode;
      }
      if (!isAdsRequest && baladiya != null && baladiya.isNotEmpty) {
        query['baladiya'] = baladiya;
      }
      if (!isAdsRequest && minPrice != null) {
        query['min_price'] = minPrice.toStringAsFixed(2);
      }
      if (!isAdsRequest && maxPrice != null) {
        query['max_price'] = maxPrice.toStringAsFixed(2);
      }
      if (!isAdsRequest && minRating != null) {
        query['min_rating'] = minRating.toStringAsFixed(1);
      }
      if (!isAdsRequest && ordering != null && ordering.isNotEmpty) {
        query['ordering'] = ordering;
      }
      if (!isAdsRequest && userLat != null && userLng != null) {
        query['lat'] = userLat.toStringAsFixed(6);
        query['lng'] = userLng.toStringAsFixed(6);
      }
      if (!isAdsRequest && radiusKm != null) {
        query['radius_km'] = radiusKm.toStringAsFixed(2);
      }
      if (!isAdsRequest && homeRank) {
        query['home_rank'] = 'true';
      }
      if (isAdsRequest && userLat != null && userLng != null) {
        query['lat'] = userLat.toStringAsFixed(6);
        query['lng'] = userLng.toStringAsFixed(6);
      }
      if (isAdsRequest && singleRandomized) {
        query['single_random'] = 'true';
      }
      final baseUrl =
          isAdsRequest ? ApiConfig.adsCampaigns : ApiConfig.promotions;
      final url = query.isEmpty
          ? baseUrl
          : '$baseUrl?${Uri(queryParameters: query).query}';
      AppLogger.info(
          'Repository: getOffers request url=$url kind=$requestedKind includeInactive=$includeInactive storeId=$filterStoreId');
      final promos = await _fetchList(url, fetchAllPages: fetchAllPages);
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

      int? parsePackId(Map<String, dynamic> promo) {
        final raw = promo['pack'] ?? promo['pack_id'] ?? promo['packId'];
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
        final packId = parsePackId(promo);
        AppLogger.info(
            'Repository: Promo ${promo['id']} productId=$productId, packId=$packId');
        if (productId == null && packId == null) {
          AppLogger.info(
              'Repository: Skipping promo ${promo['id']} - no target ID');
          continue;
        }

        Post? product;
        if (productId != null) {
          try {
            product = productCache[productId] ?? await getPost(productId);
            productCache[productId] = product;
            AppLogger.info(
                'Repository: Loaded product ${product.title} for promo ${promo['id']}');
          } catch (e) {
            AppLogger.info(
                'Repository: Skipping promo ${promo['id']} - failed to load product $productId: $e');
            continue;
          }
        } else if (packId != null) {
          final storeIdFromPromo = int.tryParse(
                  (promo['store'] ?? promo['store_id'] ?? filterStoreId ?? 0)
                      .toString()) ??
              0;
          final packMap = await _loadPackById(packId);
          final packName =
              (packMap?['name'] ?? promo['name'] ?? 'Pack #$packId').toString();
          final packPrice = double.tryParse(
                  (packMap?['discount_price'] ?? promo['price'] ?? 0)
                      .toString()) ??
              0.0;
          final packImage = (packMap?['image'] ?? '').toString();
          product = Post(
            id: -packId,
            title: packName,
            description: '',
            category: 'Pack',
            categoryId: null,
            storeId: storeIdFromPromo,
            storeName: '',
            author: User(
              id: storeIdFromPromo,
              username: '',
              email: '',
              name: '',
              dateJoined: DateTime.now(),
            ),
            price: packPrice,
            isAvailable: true,
            rating: 0,
            isHotDeal: false,
            isFeatured: false,
            createdAt: DateTime.now(),
            images: packImage.isEmpty
                ? const []
                : [ProductImageData(id: 0, url: packImage, isMain: true)],
          );
        }

        if (product == null) {
          continue;
        }

        int percentage = _parsePercentage(
          promo['percentage'] ??
              promo['discount_percentage'] ??
              promo['discountPercentage'] ??
              promo['discount'] ??
              0,
        );
        AppLogger.info(
            'Repository: Promo ${promo['id']} percentage=$percentage');
        final promoKind =
            (promo['kind'] ?? (isAdsRequest ? 'advertising' : 'promotion'))
                .toString()
                .toLowerCase();

        // Enforce strict kind matching to avoid ad/promotion mixing glitches.
        if (requestedKind.isNotEmpty && promoKind != requestedKind) {
          continue;
        }
        if (percentage < 0) percentage = 0;
        if (percentage > 100) percentage = 100;

        final startDate = _parseDateTimeToLocal(
          promo['start_date'] ??
              promo['startDate'] ??
              promo['start_time'] ??
              promo['startTime'] ??
              promo['starts_at'] ??
              promo['startsAt'],
        );
        final endDate = _parseDateTimeToLocal(
          promo['end_date'] ??
              promo['endDate'] ??
              promo['end_time'] ??
              promo['endTime'] ??
              promo['expires_at'] ??
              promo['expiresAt'] ??
              promo['ends_at'] ??
              promo['endsAt'],
        );

        // For public feeds, hide offers outside schedule window on client too.
        // This avoids brief flashes when backend responses race during refresh.
        if (!shouldIncludeInactive) {
          final now = DateTime.now();
          if (startDate != null && now.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && now.isAfter(endDate)) {
            continue;
          }
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
            createdAt:
                DateTime.tryParse((promo['created_at'] ?? '').toString()) ??
                    DateTime.now(),
            startDate: startDate,
            endDate: endDate,
            maxImpressions:
                int.tryParse((promo['max_impressions'] ?? '').toString()),
            uniqueViewersCount:
                int.tryParse((promo['unique_viewers_count'] ?? '').toString()),
            remainingImpressions:
                int.tryParse((promo['remaining_impressions'] ?? '').toString()),
            kind: promoKind,
            placement: (promo['placement'] ?? 'home_top').toString(),
            displayHours: ((promo['display_hours'] as List?)
                    ?.map((e) => int.tryParse(e.toString()))
                    .whereType<int>()
                    .toList() ??
                const []),
            audienceMode: (promo['audience_mode'] ?? 'all').toString(),
            impressionsCount:
                int.tryParse((promo['impressions_count'] ?? '').toString()) ??
                    0,
            clicksCount:
                int.tryParse((promo['clicks_count'] ?? '').toString()) ?? 0,
            targetWilayas: (promo['target_wilayas'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            targetCategories: (promo['target_categories'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            ageFrom: int.tryParse((promo['age_from'] ?? '').toString()),
            ageTo: int.tryParse((promo['age_to'] ?? '').toString()),
            geoMode: (promo['geo_mode'] ?? 'all').toString(),
            targetRadiusKm:
                int.tryParse((promo['target_radius_km'] ?? '').toString()),
            targetType:
                (promo['target_type'] ?? (packId != null ? 'pack' : 'product'))
                    .toString(),
            targetPackId: packId,
            targetPackName: packId != null ? product.title : null,
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
    int? packId,
    required int discountPercentage,
    bool isAvailable = true,
    String kind = 'promotion',
    String placement = 'home_top',
    String audienceMode = 'all',
    List<String> targetWilayas = const [],
    List<String> targetCategories = const [],
    int? maxImpressions,
    int? ageFrom,
    int? ageTo,
    String geoMode = 'all',
    int? targetRadiusKm,
    int? displayHour,
    List<int>? displayHours,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final isAd = kind == 'advertising';
      if (!isAd && productId == null) {
        throw Exception('productId is required for promotions');
      }
      if (isAd && productId == null && packId == null) {
        throw Exception('Either productId or packId is required for ads');
      }
      if (isAd && productId != null && packId != null) {
        throw Exception('Provide only one target for ads: productId or packId');
      }

      final storeId = await _ensureStoreForCurrentUser();
      final payload = <String, dynamic>{
        'store': storeId,
        'percentage': discountPercentage,
        'is_active': isAvailable,
        if (!isAd && startDate != null) 'start_date': _toUtcIso(startDate),
        if (!isAd && endDate != null) 'end_date': _toUtcIso(endDate),
      };

      if (isAd) {
        final resolvedDisplayHours =
            displayHours ?? (displayHour != null ? <int>[displayHour] : null);
        payload.addAll({
          if (productId != null) 'product': productId,
          if (packId != null) 'pack': packId,
          'name': productId != null
              ? 'Ad for Product $productId'
              : 'Ad for Pack $packId',
          if (resolvedDisplayHours != null)
            'display_hours': resolvedDisplayHours,
          'audience_mode': audienceMode,
          'geo_mode': geoMode,
          'target_wilayas': targetWilayas,
          'target_categories': targetCategories,
          if (ageFrom != null) 'age_from': ageFrom,
          if (ageTo != null) 'age_to': ageTo,
          if (targetRadiusKm != null) 'target_radius_km': targetRadiusKm,
          if (maxImpressions != null) 'max_impressions': maxImpressions,
        });
      } else {
        payload.addAll({
          'product': productId,
          'name': 'Promotion for Product $productId',
        });
      }

      final endpoint = isAd ? ApiConfig.adsCampaigns : ApiConfig.promotions;
      final resp = await ApiService.post(endpoint, payload);

      final product = productId != null
          ? await getPost(productId)
          : Post(
              id: -(packId ?? 1),
              title: 'Pack #${packId ?? 0}',
              description: '',
              category: 'Pack',
              categoryId: null,
              storeId: storeId,
              storeName: '',
              author: User(
                id: storeId,
                username: '',
                email: '',
                name: '',
                dateJoined: DateTime.now(),
              ),
              price: 0,
              isAvailable: true,
              rating: 0,
              isHotDeal: false,
              isFeatured: false,
              createdAt: DateTime.now(),
              images: const [],
            );

      final double newPrice =
          (product.price * (1 - (discountPercentage / 100))).toDouble();

      // Trigger follower notification for promotions only.
      final offerId = resp['id'] ?? 0;
      final title = '$discountPercentage% OFF on ${product.title}';
      if (kind != 'advertising') {
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
      }

      return Offer(
        id: offerId,
        product: product,
        discountPercentage: discountPercentage,
        newPrice: newPrice,
        isAvailable: isAvailable,
        createdAt:
            DateTime.tryParse(resp['created_at'] ?? '') ?? DateTime.now(),
        startDate: _parseDateTimeToLocal(resp['start_date']),
        endDate: _parseDateTimeToLocal(resp['end_date']),
        maxImpressions:
            int.tryParse((resp['max_impressions'] ?? '').toString()),
        uniqueViewersCount:
            int.tryParse((resp['unique_viewers_count'] ?? '').toString()),
        remainingImpressions:
            int.tryParse((resp['remaining_impressions'] ?? '').toString()),
        kind: (resp['kind'] ?? kind).toString(),
        placement: (resp['placement'] ?? placement).toString(),
        displayHours: ((resp['display_hours'] as List?)
                ?.map((e) => int.tryParse(e.toString()))
                .whereType<int>()
                .toList() ??
            const []),
        audienceMode: (resp['audience_mode'] ?? audienceMode).toString(),
        impressionsCount:
            int.tryParse((resp['impressions_count'] ?? '').toString()) ?? 0,
        clicksCount: int.tryParse((resp['clicks_count'] ?? '').toString()) ?? 0,
        geoMode: (resp['geo_mode'] ?? geoMode).toString(),
        targetRadiusKm:
            int.tryParse((resp['target_radius_km'] ?? '').toString()),
        ageFrom: int.tryParse((resp['age_from'] ?? '').toString()),
        ageTo: int.tryParse((resp['age_to'] ?? '').toString()),
        targetType:
            (resp['target_type'] ?? (packId != null ? 'pack' : 'product'))
                .toString(),
        targetPackId: packId,
        targetPackName: packId != null ? product.title : null,
      );
    } catch (e) {
      AppLogger.error('Repository: Error creating offer', error: e);
      throw Exception('Failed to create offer: $e');
    }
  }

  static Future<Offer> updateOffer({
    required int offerId,
    int? productId,
    int? packId,
    int? discountPercentage,
    bool? isAvailable,
    String? kind,
    String? placement,
    String? audienceMode,
    List<String>? targetWilayas,
    List<String>? targetCategories,
    int? maxImpressions,
    int? ageFrom,
    int? ageTo,
    String? geoMode,
    int? targetRadiusKm,
    int? displayHour,
    List<int>? displayHours,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final targetKind = (kind ?? '').trim().toLowerCase();
      final isAd = targetKind == 'advertising';
      final payload = <String, dynamic>{};
      if (discountPercentage != null) {
        payload['percentage'] = discountPercentage;
      }
      if (productId != null) payload['product'] = productId;
      if (isAd && packId != null) payload['pack'] = packId;
      if (isAvailable != null) payload['is_active'] = isAvailable;
      if (!isAd && startDate != null)
        payload['start_date'] = _toUtcIso(startDate);
      if (!isAd && endDate != null) payload['end_date'] = _toUtcIso(endDate);

      if (isAd) {
        final resolvedDisplayHours =
            displayHours ?? (displayHour != null ? <int>[displayHour] : null);
        if (resolvedDisplayHours != null) {
          payload['display_hours'] = resolvedDisplayHours;
        }
        if (audienceMode != null) payload['audience_mode'] = audienceMode;
        if (targetWilayas != null) payload['target_wilayas'] = targetWilayas;
        if (targetCategories != null) {
          payload['target_categories'] = targetCategories;
        }
        if (maxImpressions != null) payload['max_impressions'] = maxImpressions;
        if (ageFrom != null) payload['age_from'] = ageFrom;
        if (ageTo != null) payload['age_to'] = ageTo;
        if (geoMode != null) payload['geo_mode'] = geoMode;
        if (targetRadiusKm != null)
          payload['target_radius_km'] = targetRadiusKm;
      }

      final endpoint = targetKind == 'advertising'
          ? ApiConfig.adsCampaigns
          : ApiConfig.promotions;
      final resp = await ApiService.patch('$endpoint$offerId/', payload);

      final resolvedProductId = resp['product'] ?? resp['product_id'];
      final resolvedPackId = resp['pack'] ?? resp['pack_id'] ?? packId;
      final product =
          resolvedProductId != null ? await getPost(resolvedProductId) : null;
      final pct = discountPercentage ?? _parsePercentage(resp['percentage']);
      final double newPrice = product != null
          ? (product.price * (1 - (pct / 100))).toDouble()
          : 0.0;

      final fallbackStoreId = await _ensureStoreForCurrentUser();
      final safePackId = int.tryParse((resolvedPackId ?? '').toString());
      final fallbackPackPost = safePackId != null
          ? Post(
              id: -safePackId,
              title: 'Pack #$safePackId',
              description: '',
              category: 'Pack',
              categoryId: null,
              storeId: fallbackStoreId,
              storeName: '',
              author: User(
                id: fallbackStoreId,
                username: '',
                email: '',
                name: '',
                dateJoined: DateTime.now(),
              ),
              price: 0,
              isAvailable: true,
              rating: 0,
              isHotDeal: false,
              isFeatured: false,
              createdAt: DateTime.now(),
              images: const [],
            )
          : null;

      return Offer(
        id: resp['id'] ?? offerId,
        product: product ?? fallbackPackPost ?? await getPost(offerId),
        discountPercentage: pct,
        newPrice: newPrice,
        isAvailable: isAvailable ?? resp['is_active'] ?? true,
        createdAt:
            DateTime.tryParse(resp['created_at'] ?? '') ?? DateTime.now(),
        startDate: _parseDateTimeToLocal(resp['start_date']),
        endDate: _parseDateTimeToLocal(resp['end_date']),
        maxImpressions:
            int.tryParse((resp['max_impressions'] ?? '').toString()),
        uniqueViewersCount:
            int.tryParse((resp['unique_viewers_count'] ?? '').toString()),
        remainingImpressions:
            int.tryParse((resp['remaining_impressions'] ?? '').toString()),
        kind: (resp['kind'] ?? 'promotion').toString(),
        placement: (resp['placement'] ?? 'home_top').toString(),
        displayHours: ((resp['display_hours'] as List?)
                ?.map((e) => int.tryParse(e.toString()))
                .whereType<int>()
                .toList() ??
            const []),
        audienceMode:
            (resp['audience_mode'] ?? audienceMode ?? 'all').toString(),
        impressionsCount:
            int.tryParse((resp['impressions_count'] ?? '').toString()) ?? 0,
        clicksCount: int.tryParse((resp['clicks_count'] ?? '').toString()) ?? 0,
        geoMode: (resp['geo_mode'] ?? geoMode ?? 'all').toString(),
        targetRadiusKm:
            int.tryParse((resp['target_radius_km'] ?? '').toString()),
        ageFrom: int.tryParse((resp['age_from'] ?? '').toString()),
        ageTo: int.tryParse((resp['age_to'] ?? '').toString()),
        targetType: (resp['target_type'] ??
                (resolvedPackId != null ? 'pack' : 'product'))
            .toString(),
        targetPackId: int.tryParse((resolvedPackId ?? '').toString()),
        targetPackName: resolvedPackId != null ? 'Pack #$resolvedPackId' : null,
      );
    } catch (e) {
      AppLogger.error('Repository: Error updating offer', error: e);
      throw Exception('Failed to update offer: $e');
    }
  }

  static Future<void> deleteOffer(int offerId) async {
    try {
      try {
        await ApiService.delete('${ApiConfig.adsCampaigns}$offerId/');
        return;
      } catch (_) {
        await ApiService.delete('${ApiConfig.promotions}$offerId/');
      }
    } catch (e) {
      AppLogger.error('Repository: Error deleting offer', error: e);
      throw Exception('Failed to delete offer: $e');
    }
  }

  static Future<void> registerPromotionClick(int promotionId,
      {String kind = 'promotion'}) async {
    try {
      final endpoint =
          kind == 'advertising' ? ApiConfig.adsCampaigns : ApiConfig.promotions;
      await ApiService.post('$endpoint$promotionId/register-click/', {});
    } catch (e) {
      AppLogger.error('Repository: Failed to register promo click', error: e);
    }
  }
}
