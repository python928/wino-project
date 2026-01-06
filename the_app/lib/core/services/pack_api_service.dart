import './api_service.dart';
import '../../data/models/pack_model.dart';

class PackApiService {
  PackApiService();

  Future<List<Pack>> getMerchantPacks(int merchantId) async {
    try {
      // Load stores for name enrichment
      Map<int, String> storesById = {};
      try {
        final storesResp = await ApiService.get('/api/stores/stores/');
        final storesList = storesResp is Map && storesResp.containsKey('results')
            ? storesResp['results'] as List
            : (storesResp is List ? storesResp : []);
        for (final item in storesList) {
          if (item is Map<String, dynamic>) {
            storesById[item['id']] = item['name'] ?? 'Store';
          }
        }
      } catch (e) {
        // If stores loading fails, continue without enrichment
      }

      final data = await ApiService.get('/api/catalog/packs/?store=$merchantId');

      if (data is Map<String, dynamic> && data['results'] != null) {
        // API returns {count: X, results: [...]}
        return (data['results'] as List)
            .map((json) => Pack.fromJson(json as Map<String, dynamic>, storesById: storesById))
            .toList();
      } else if (data is List) {
        // Fallback: API returns a direct list
        return data.map((json) => Pack.fromJson(json as Map<String, dynamic>, storesById: storesById)).toList();
      }
      throw Exception('Unexpected response format when fetching merchant packs');
    } catch (e) {
      throw Exception('Error fetching packs: $e');
    }
  }

  Future<Pack> createPack({
    required String name,
    required String description,
    required List<PackProduct> products,
    required double discountPrice,
    required int merchantId,
  }) async {
    try {
      final body = {
        'name': name,
        'description': description,
        'products': products.map((p) => p.toJson()).toList(),
        'discount_price': discountPrice,
        'merchant_id': merchantId,
      };

      final data = await ApiService.post('/api/catalog/packs/', body);
      if (data is Map<String, dynamic>) {
        return Pack.fromJson(data);
      }
      throw Exception('Unexpected response when creating pack');
    } catch (e) {
      throw Exception('Error creating pack: $e');
    }
  }

  Future<Pack> updatePack(int packId, Map<String, dynamic> updates) async {
    try {
      final data = await ApiService.put('/api/catalog/packs/$packId/', updates);
      if (data is Map<String, dynamic>) {
        return Pack.fromJson(data);
      }
      throw Exception('Unexpected response when updating pack');
    } catch (e) {
      throw Exception('Error updating pack: $e');
    }
  }

  Future<void> deletePack(int packId) async {
    try {
      await ApiService.delete('/api/catalog/packs/$packId/');
      return;
    } catch (e) {
      throw Exception('Error deleting pack: $e');
    }
  }
}