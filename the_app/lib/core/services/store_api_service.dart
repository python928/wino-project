import '../config/api_config.dart';
import './api_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';

class StoreApiService {
  StoreApiService();

  final Map<int, User> _storeCache = {};

  Future<User?> getMyStore(int userId) async {
    try {
      final data = await ApiService.get('${ApiConfig.users}$userId/');
      if (data is Map<String, dynamic>) {
        final store = User.fromJson(data);
        _storeCache[store.id] = store;
        return store;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User> getStoreDetails(int storeId, {int retries = 2, bool forceRefresh = false}) async {
    if (!forceRefresh && _storeCache.containsKey(storeId)) {
      return _storeCache[storeId]!;
    }
    int attempt = 0;
    while (true) {
      try {
        final data = await ApiService.get('${ApiConfig.users}$storeId/');
        if (data is Map<String, dynamic>) {
          final store = User.fromJson(data);
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

  Future<List<Post>> getStoreProducts(int storeId, {int page = 1, int retries = 2}) async {
    int attempt = 0;
    while (true) {
      try {
        final data = await ApiService.get('${ApiConfig.products}?store=$storeId&page=$page');
        if (data is Map<String, dynamic> && data['results'] != null) {
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

  Future<List<User>> getStores({
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
        if (searchQuery != null && searchQuery.isNotEmpty) params['search'] = searchQuery;
        params['page'] = page.toString();

        String url = ApiConfig.users;
        if (params.isNotEmpty) {
          url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
        }

        final data = await ApiService.get(url);

        if (data is Map<String, dynamic> && data['results'] != null) {
          return (data['results'] as List)
              .map((json) => User.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
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
        final resp = await ApiService.post(ApiConfig.followersToggle, {'store': storeId});
        final isFollowing = (resp is Map && resp['is_following'] == true);
        if (!isFollowing) {
          await ApiService.post(ApiConfig.followersToggle, {'store': storeId});
        }
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
        final resp = await ApiService.post(ApiConfig.followersToggle, {'store': storeId});
        final isFollowing = (resp is Map && resp['is_following'] == true);
        if (isFollowing) {
          await ApiService.post(ApiConfig.followersToggle, {'store': storeId});
        }
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

  Future<bool> isFollowing(int storeId) async {
    try {
      final data = await ApiService.get(ApiConfig.followers);
      final list = (data is Map && data['results'] is List)
          ? (data['results'] as List)
          : (data is List ? data : const []);
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final followed = item['followed_user'];
          if (followed is int && followed == storeId) return true;
          if (followed is Map && followed['id'] == storeId) return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void clearCache() {
    _storeCache.clear();
  }
}
