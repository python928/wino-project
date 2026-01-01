import './api_service.dart';
import '../../data/models/pack_model.dart';

class PackApiService {
  PackApiService();

  Future<List<Pack>> getMerchantPacks(int merchantId) async {
    try {
      final data = await ApiService.get('/packs/merchant/$merchantId/');
      if (data is List) {
        return data.map((json) => Pack.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected response when fetching packs');
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

      final data = await ApiService.post('/packs/', body);
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
      final data = await ApiService.put('/packs/$packId/', updates);
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
      await ApiService.delete('/packs/$packId/');
      return;
    } catch (e) {
      throw Exception('Error deleting pack: $e');
    }
  }
}