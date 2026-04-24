import 'package:flutter/material.dart';
import '../../../core/services/analytics_api_service.dart';

/// Manages the recommendations state.
///
/// Event tracking (view, search, filter_price, favorite, contact) is done
/// server-side in Django views and signals — no logEvent() needed here.
class AnalyticsProvider with ChangeNotifier {
  final AnalyticsApiService _apiService = AnalyticsApiService();

  List<dynamic> _recommendations = [];
  bool _isLoading = false;

  List<dynamic> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  /// Fetch personalized recommendations from the server.
  Future<void> fetchRecommendations({int limit = 20, int? categoryId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _recommendations = await _apiService.getRecommendedProducts(
        limit: limit,
        categoryId: categoryId,
      );
    } catch (_) {
      _recommendations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
