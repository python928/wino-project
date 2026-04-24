import '../config/api_config.dart';
import './api_service.dart';

/// Handles communication with the analytics recommendations endpoint.
///
/// Endpoint:
///   GET /api/analytics/recommendations/ — personalized product list
///
/// Event logging is handled server-side (ProductViewSet.retrieve/list + signals).
/// This service only fetches recommendations.
class AnalyticsApiService {
  static final List<Map<String, dynamic>> _eventQueue = [];
  static bool _isFlushing = false;

  /// Fetch personalized product recommendations for the logged-in user.
  ///
  /// Returns [] if the user is not authenticated or on any error.
  Future<List<dynamic>> getRecommendedProducts({
    int limit = 20,
    int? categoryId,
  }) async {
    try {
      String endpoint = '${ApiConfig.analyticsRecommendations}?limit=$limit';
      if (categoryId != null) endpoint += '&category_id=$categoryId';

      final response = await ApiService.get(endpoint);
      if (response is List) return response;
      if (response is Map && response.containsKey('results')) {
        return response['results'] as List;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> logInteraction({
    required String action,
    int? productId,
    int? storeId,
    int? categoryId,
    Map<String, dynamic>? metadata,
    String? sessionId,
    bool flushNow = false,
  }) async {
    try {
      final payload = <String, dynamic>{
        'action': action,
      };
      if (productId != null) payload['product'] = productId;
      if (storeId != null) payload['store'] = storeId;
      if (categoryId != null) payload['category'] = categoryId;
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      if (sessionId != null && sessionId.trim().isNotEmpty) {
        payload['session_id'] = sessionId.trim();
      }
      _eventQueue.add(payload);
      if (flushNow || _eventQueue.length >= 5) {
        await flushQueuedEvents();
      }
    } catch (_) {
      // Best effort only. Analytics must never break UX.
    }
  }

  Future<void> logDiscoveryClick({
    required int productId,
    int? storeId,
    int? categoryId,
    required String discoveryMode,
    double? distanceKm,
    String? wilayaCode,
    String? searchQuery,
    String? sessionId,
  }) async {
    await logInteraction(
      action: 'click',
      productId: productId,
      storeId: storeId,
      categoryId: categoryId,
      metadata: {
        'discovery_mode': discoveryMode,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (wilayaCode != null && wilayaCode.trim().isNotEmpty)
          'wilaya_code': wilayaCode.trim(),
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'search_query': searchQuery.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logPromotionClick({
    required int promotionId,
    int? productId,
    int? storeId,
    String placement = 'home_top',
    String? discoveryMode,
    double? distanceKm,
    String? wilayaCode,
    String? searchQuery,
    String? sessionId,
  }) async {
    await logInteraction(
      action: 'promotion_click',
      productId: productId,
      storeId: storeId,
      metadata: {
        'promotion_id': promotionId,
        'placement': placement,
        if (discoveryMode != null) 'discovery_mode': discoveryMode,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (wilayaCode != null && wilayaCode.trim().isNotEmpty)
          'wilaya_code': wilayaCode.trim(),
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'search_query': searchQuery.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logSearchQuery({
    required String query,
    String discoveryMode = 'none',
    double? distanceKm,
    String? wilayaCode,
    String? sessionId,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;
    await logInteraction(
      action: 'search',
      metadata: {
        'search_query': normalized,
        'keyword': normalized,
        'discovery_mode': discoveryMode,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (wilayaCode != null && wilayaCode.trim().isNotEmpty)
          'wilaya_code': wilayaCode.trim(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logPriceFilter({
    required double min,
    required double max,
    String discoveryMode = 'none',
    String? query,
    String? sessionId,
  }) async {
    await logInteraction(
      action: 'filter_price',
      metadata: {
        'price_min': min,
        'price_max': max,
        'price_range': _priceBandFromRange(min, max),
        'discovery_mode': discoveryMode,
        if (query != null && query.trim().isNotEmpty)
          'search_query': query.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logDistanceFilter({
    required double distanceKm,
    String? query,
    String? sessionId,
  }) async {
    await logInteraction(
      action: 'filter_dist',
      metadata: {
        'discovery_mode': 'nearby',
        'distance_km': distanceKm,
        if (query != null && query.trim().isNotEmpty)
          'search_query': query.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logWilayaFilter({
    required String wilayaCode,
    String? baladiya,
    String? query,
    String? sessionId,
  }) async {
    final code = wilayaCode.trim();
    if (code.isEmpty) return;
    await logInteraction(
      action: 'filter_wilaya',
      metadata: {
        'discovery_mode': 'location',
        'wilaya_code': code,
        if (baladiya != null && baladiya.trim().isNotEmpty)
          'baladiya': baladiya.trim(),
        if (query != null && query.trim().isNotEmpty)
          'search_query': query.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  Future<void> logRatingFilter({
    required double minRating,
    String discoveryMode = 'none',
    String? query,
    String? sessionId,
  }) async {
    await logInteraction(
      action: 'filter_rating',
      metadata: {
        'min_rating': minRating,
        'discovery_mode': discoveryMode,
        if (query != null && query.trim().isNotEmpty)
          'search_query': query.trim().toLowerCase(),
      },
      sessionId: sessionId,
    );
  }

  String _priceBandFromRange(double min, double max) {
    if (max <= 2000) return 'very_low';
    if (min >= 2000 && max <= 5000) return 'low';
    if (min >= 5000 && max <= 30000) return 'medium';
    if (min >= 30000 && max <= 100000) return 'high';
    if (min >= 100000) return 'very_high';
    final mid = (min + max) / 2;
    if (mid < 2000) return 'very_low';
    if (mid < 5000) return 'low';
    if (mid < 30000) return 'medium';
    if (mid < 100000) return 'high';
    return 'very_high';
  }

  Future<void> flushQueuedEvents() async {
    if (_isFlushing || _eventQueue.isEmpty) return;
    _isFlushing = true;
    final batch = List<Map<String, dynamic>>.from(_eventQueue);
    try {
      _eventQueue.clear();
      await ApiService.post(ApiConfig.analyticsEvents, {'events': batch});
    } catch (_) {
      // Requeue failed batch at the front so events are not lost.
      // Keep buffer bounded to avoid memory growth.
      _eventQueue.insertAll(0, batch);

      while (_eventQueue.length > 100) {
        _eventQueue.removeAt(0);
      }
    } finally {
      _isFlushing = false;
    }
  }
}
