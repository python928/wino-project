import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/user_model.dart';

class StoreRepository {
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
      items.addAll(_extractList(response));

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

  static String userDetail(int id) => '${ApiConfig.users}$id/';

  static Future<User?> getStore(int userId) async {
    try {
      final resp = await ApiService.get('${ApiConfig.users}$userId/');
      if (resp is Map<String, dynamic>) {
        return User.fromJson(resp);
      }
    } catch (_) {}

    try {
      final resp = await ApiService.get(ApiConfig.users);
      final list = _extractList(resp);
      for (final item in list) {
        if (item is Map<String, dynamic> && item['id'] == userId) {
          return User.fromJson(item);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Search users/stores by query
  static Future<List<User>> searchStores({
    String? query,
    String? wilayaCode,
    String? baladiya,
    double? userLat,
    double? userLng,
    double? radiusKm,
    bool fetchAllPages = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'has_posts': 'true',
      };
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (wilayaCode != null && wilayaCode.isNotEmpty) {
        queryParams['wilaya_code'] = wilayaCode;
      }
      if (baladiya != null && baladiya.isNotEmpty) {
        queryParams['baladiya'] = baladiya;
      }
      if (userLat != null && userLng != null) {
        queryParams['lat'] = userLat.toStringAsFixed(6);
        queryParams['lng'] = userLng.toStringAsFixed(6);
      }
      if (radiusKm != null) {
        queryParams['radius_km'] = radiusKm.toStringAsFixed(2);
      }
      final url =
          '${ApiConfig.users}?${Uri(queryParameters: queryParams).query}';

      final list = await _fetchList(url, fetchAllPages: fetchAllPages);

      return list.whereType<Map<String, dynamic>>().map(User.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get followed stores (users that current user follows)
  static Future<List<User>> getFollowedStores() async {
    try {
      final resp = await ApiService.get(ApiConfig.followers);
      final list = _extractList(resp);

      final storesById = <int, User>{};
      final idsToFetch = <int>{};

      for (final item in list) {
        if (item is int) {
          idsToFetch.add(item);
          continue;
        }

        if (item is! Map<String, dynamic>) continue;

        // Some backends return a full object, others return an id.
        final dynamic followed = item['followed_user_detail'] ??
            item['followed_user'] ??
            item['store'];

        if (followed is Map<String, dynamic>) {
          final store = User.fromJson(followed);
          storesById[store.id] = store;
          continue;
        }

        if (followed is int) {
          idsToFetch.add(followed);
          continue;
        }

        // Fallback: sometimes the item itself is the store object.
        if (item.containsKey('id') && item.containsKey('name')) {
          final store = User.fromJson(item);
          storesById[store.id] = store;
        }
      }

      if (idsToFetch.isNotEmpty) {
        for (final id in idsToFetch) {
          if (storesById.containsKey(id)) continue;
          final store = await getStore(id);
          if (store != null) {
            storesById[store.id] = store;
          }
        }
      }

      return storesById.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// Get recommended stores with comprehensive scoring
  /// NO filtering by post count - includes ALL stores
  static Future<List<User>> getRecommendedStores({int limit = 8}) async {
    try {
      final resp = await ApiService.get(
          '${ApiConfig.users}recommended-stores/?has_posts=true');
      final list = _extractList(resp);

      return list.whereType<Map<String, dynamic>>().map(User.fromJson).toList();
    } catch (e) {
      // Fallback to all stores if recommended endpoint fails
      return await searchStores();
    }
  }
}
