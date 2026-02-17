import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/backend_store_model.dart';

class StoreRepository {
  static List<dynamic> _extractList(dynamic response) {
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List<dynamic>;
    }
    if (response is List) return response;
    return [];
  }

  static String userDetail(int id) => '${ApiConfig.users}$id/';

  static Future<BackendStore?> getStore(int userId) async {
    try {
      final resp = await ApiService.get('${ApiConfig.users}$userId/');
      if (resp is Map<String, dynamic>) {
        return BackendStore.fromJson(resp);
      }
    } catch (_) {}

    try {
      final resp = await ApiService.get(ApiConfig.users);
      final list = _extractList(resp);
      for (final item in list) {
        if (item is Map<String, dynamic> && item['id'] == userId) {
          return BackendStore.fromJson(item);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Search users/stores by query
  static Future<List<BackendStore>> searchStores({String? query}) async {
    try {
      final url = query != null && query.isNotEmpty
          ? '${ApiConfig.users}?search=$query'
          : ApiConfig.users;

      final resp = await ApiService.get(url);
      final list = _extractList(resp);

      return list
          .where((item) => item is Map<String, dynamic>)
          .map((item) => BackendStore.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get followed stores (users that current user follows)
  static Future<List<BackendStore>> getFollowedStores() async {
    try {
      final resp = await ApiService.get(ApiConfig.followers);
      final list = _extractList(resp);

      final storesById = <int, BackendStore>{};
      final idsToFetch = <int>{};

      for (final item in list) {
        if (item is int) {
          idsToFetch.add(item);
          continue;
        }

        if (item is! Map<String, dynamic>) continue;

        // Some backends return a full object, others return an id.
        final dynamic followed =
            item['followed_user_detail'] ?? item['followed_user'] ?? item['store'];

        if (followed is Map<String, dynamic>) {
          final store = BackendStore.fromJson(followed);
          storesById[store.id] = store;
          continue;
        }

        if (followed is int) {
          idsToFetch.add(followed);
          continue;
        }

        // Fallback: sometimes the item itself is the store object.
        if (item.containsKey('id') && item.containsKey('name')) {
          final store = BackendStore.fromJson(item);
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
}
