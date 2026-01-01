import '../config/api_config.dart';
import './api_service.dart';
import '../../data/models/store_model.dart';
import '../../data/models/post_model.dart';

class StoreApiService {
  StoreApiService();

  // Simple in-memory cache for store details
  final Map<int, Store> _storeCache = {};

  Future<Store> getStoreDetails(int storeId, {int retries = 2, bool forceRefresh = false}) async {
    if (!forceRefresh && _storeCache.containsKey(storeId)) {
      return _storeCache[storeId]!;
    }
    int attempt = 0;
    while (true) {
      try {
        final data = await ApiService.get('${ApiConfig.stores}$storeId/');
        if (data is Map<String, dynamic>) {
          final store = Store.fromJson(data);
          _storeCache[storeId] = store;
          return store;
        }
        throw Exception('Unexpected response when fetching store details');
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
        } else {
          throw Exception('Error fetching store details: $e');
        }
      }
    }
  }

  /// Get products for a specific store
  Future<List<Post>> getStoreProducts(int storeId, {int page = 1, int retries = 2}) async {
    int attempt = 0;
    while (true) {
      try {
        final data = await ApiService.get('${ApiConfig.products}?store=$storeId&page=$page');
        if (data is Map<String, dynamic> && data['results'] != null) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
        } else {
          throw Exception('Error fetching store products: $e');
        }
      }
    }
  }

  Future<List<Store>> getStores({
    int? categoryId,
    String? searchQuery,
    String? wilaya,
    String? city,
    int page = 1,
    int retries = 2,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final params = <String, String>{};
        if (categoryId != null) params['category'] = categoryId.toString();
        if (searchQuery != null && searchQuery.isNotEmpty) params['search'] = searchQuery;
        if (wilaya != null && wilaya.isNotEmpty) params['wilaya'] = wilaya;
        if (city != null && city.isNotEmpty) params['city'] = city;
        params['page'] = page.toString();

        String url = ApiConfig.stores;
        if (params.isNotEmpty) {
          url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
        }

        final data = await ApiService.get(url);

        if (data is Map<String, dynamic> && data['results'] != null) {
          return (data['results'] as List)
              .map((json) => Store.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data.map((json) => Store.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
        } else {
          throw Exception('Error fetching stores: $e');
        }
      }
    }
  }

  Future<void> followStore(int storeId, {int retries = 1}) async {
    int attempt = 0;
    while (true) {
      try {
        await ApiService.post('${ApiConfig.followers}', {'store': storeId});
        return;
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
        } else {
          throw Exception('Error following store: $e');
        }
      }
    }
  }

  Future<void> unfollowStore(int storeId, {int retries = 1}) async {
    int attempt = 0;
    while (true) {
      try {
        // Need to find the follower ID first or use a dedicated endpoint
        await ApiService.delete('${ApiConfig.followers}?store=$storeId');
        return;
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
        } else {
          throw Exception('Error unfollowing store: $e');
        }
      }
    }
  }

  /// Check if user is following a store
  Future<bool> isFollowing(int storeId) async {
    try {
      final data = await ApiService.get('${ApiConfig.followers}?store=$storeId');
      if (data is Map<String, dynamic> && data['results'] != null) {
        return (data['results'] as List).isNotEmpty;
      } else if (data is List) {
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearCache() {
    _storeCache.clear();
  }
}