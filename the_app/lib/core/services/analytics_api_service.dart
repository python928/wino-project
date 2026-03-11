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
      String url = '${ApiConfig.baseUrl}/api/analytics/recommendations/'
          '?limit=$limit';
      if (categoryId != null) url += '&category_id=$categoryId';

      final response = await ApiService.get(url);
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

  Future<void> flushQueuedEvents() async {
    if (_isFlushing || _eventQueue.isEmpty) return;
    _isFlushing = true;
    try {
      final batch = List<Map<String, dynamic>>.from(_eventQueue);
      _eventQueue.clear();
      await ApiService.post(ApiConfig.analyticsEvents, {'events': batch});
    } catch (_) {
      // If send failed, keep a bounded buffer to retry later.
      // Avoid unbounded memory growth.
      while (_eventQueue.length > 100) {
        _eventQueue.removeAt(0);
      }
    } finally {
      _isFlushing = false;
    }
  }
}
