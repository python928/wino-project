import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDistanceSearchService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upserts store coordinates into Firestore so they can be reused in distance workflows.
  static Future<void> syncStoreCoordinates({
    required List<Map<String, dynamic>> stores,
  }) async {
    if (stores.isEmpty) return;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final store in stores) {
      final dynamic rawId = store['store_id'];
      if (rawId == null) continue;

      final storeId = rawId.toString();
      final docRef = _db.collection('store_coordinates').doc(storeId);

      batch.set(
          docRef,
          {
            'store_id': rawId,
            'store_name': store['store_name'] ?? '',
            'latitude': store['latitude'],
            'longitude': store['longitude'],
            'allow_nearby_visibility': store['allow_nearby_visibility'] ?? true,
            'updated_at': now,
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Logs each distance search action for analytics/auditing.
  static Future<void> logDistanceSearch({
    required String sourceScreen,
    required double userLatitude,
    required double userLongitude,
    required double radiusKm,
    required int storesCount,
  }) async {
    await _db.collection('distance_search_logs').add({
      'source_screen': sourceScreen,
      'user_latitude': userLatitude,
      'user_longitude': userLongitude,
      'radius_km': radiusKm,
      'stores_count': storesCount,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
