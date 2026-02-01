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

  static String storeDetail(int id) => '${ApiConfig.stores}$id/';

  static Future<BackendStore?> getStore(int id) async {
    // Prefer detail endpoint (DRF router supports it). If that fails,
    // fall back to listing stores and picking by id.
    try {
      final resp = await ApiService.get(storeDetail(id));
      if (resp is Map<String, dynamic>) {
        return BackendStore.fromJson(resp);
      }
    } catch (_) {
      // ignore and fall back
    }

    try {
      final resp = await ApiService.get(ApiConfig.stores);
      final list = _extractList(resp);
      for (final item in list) {
        if (item is Map<String, dynamic> && item['id'] == id) {
          return BackendStore.fromJson(item);
        }
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  /// Search stores by query
  static Future<List<BackendStore>> searchStores({String? query}) async {
    try {
      final url = query != null && query.isNotEmpty
          ? '${ApiConfig.stores}?search=$query'
          : ApiConfig.stores;

      final resp = await ApiService.get(url);
      final list = _extractList(resp);

      return list
          .where((item) => item is Map<String, dynamic>)
          .map((item) => BackendStore.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching stores: $e');
      return [];
    }
  }

  /// Get followed stores
  static Future<List<BackendStore>> getFollowedStores() async {
    try {
      final resp = await ApiService.get(ApiConfig.followers);
      final list = _extractList(resp);
      
      // The response is likely a list of Follow objects which contain the store details
      // Structure assumption: [{ "ok": true, "store": { ...store_data... } }, ...] OR just store objects 
      // But typically a "Followers" endpoint returns relationships.
      // If the backend assumes "My Followed Stores", it might return a list of Stores directly or list of relationships.
      // Based on isFollowing implementation: ApiConfig.followers?store=id returns results.
      // So ApiConfig.followers (GET) likely returns all relationships for current user.
      
      final stores = <BackendStore>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          // Check if item has 'store' key which is the store object
          if (item['store'] is Map<String, dynamic>) {
            stores.add(BackendStore.fromJson(item['store']));
          } else if (item['store_detail'] is Map<String, dynamic>) {
             stores.add(BackendStore.fromJson(item['store_detail']));
          } 
          // If the item itself is a store (unlikely for "followers" endpoint but possible)
          else if (item.containsKey('name') && item.containsKey('id')) {
             stores.add(BackendStore.fromJson(item));
          }
        }
      }
      return stores;
    } catch (e) {
      print('Error getting followed stores: $e');
      return [];
    }
  }
}
