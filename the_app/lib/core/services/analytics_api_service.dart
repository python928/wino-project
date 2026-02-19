import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/analytics/recommendations/').replace(
      queryParameters: {
        'limit': limit.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return [];

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('results')) {
          return decoded['results'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
