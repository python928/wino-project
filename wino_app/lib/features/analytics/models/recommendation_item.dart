/// Represents one item returned by GET /api/analytics/recommendations/
///
/// API shape:
/// {
///   "product": {
///     "id": 1, "name": "Samsung A54", "price": "45000",
///     "hide_price": false, "negotiable": true,
///     "category_id": 3, "store_id": 12,
///     "store_name": "Tech Store Alger",
///     "image_url": "http://..."
///   },
///   "score": 72.4,
///   "match_reasons": ["Matches your interests", "Price negotiable"]
/// }
class RecommendationItem {
  final int productId;
  final String name;
  final double? price;
  final bool hidePrice;
  final bool negotiable;
  final int? categoryId;
  final int? storeId;
  final String storeName;
  final String? imageUrl;
  final double score;
  final List<String> matchReasons;

  const RecommendationItem({
    required this.productId,
    required this.name,
    this.price,
    this.hidePrice = false,
    this.negotiable = false,
    this.categoryId,
    this.storeId,
    this.storeName = '',
    this.imageUrl,
    required this.score,
    required this.matchReasons,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final reasons = (json['match_reasons'] as List<dynamic>?)?.cast<String>() ?? [];
    return RecommendationItem(
      productId: product['id'] as int? ?? 0,
      name: product['name'] as String? ?? '',
      price: product['price'] != null ? double.tryParse(product['price'].toString()) : null,
      hidePrice: product['hide_price'] as bool? ?? false,
      negotiable: product['negotiable'] as bool? ?? false,
      categoryId: product['category_id'] as int?,
      storeId: product['store_id'] as int?,
      storeName: product['store_name'] as String? ?? '',
      imageUrl: product['image_url'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      matchReasons: reasons,
    );
  }
}
