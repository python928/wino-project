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
}
