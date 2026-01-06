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
}
