import 'post_model.dart';
import 'user_model.dart';

class Offer {
  final int id;
  final Post product;
  final int discountPercentage;
  final double newPrice;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? endDate;
  final int? maxImpressions;
  final int? uniqueViewersCount;
  final int? remainingImpressions;

  Offer({
    required this.id,
    required this.product,
    required this.discountPercentage,
    required this.newPrice,
    required this.isAvailable,
    required this.createdAt,
    this.endDate,
    this.maxImpressions,
    this.uniqueViewersCount,
    this.remainingImpressions,
  });

  bool get hasImpressionLimit => maxImpressions != null;

  bool get isNearEnding {
    if (endDate == null) return false;
    final now = DateTime.now();
    if (endDate!.isBefore(now)) return false;
    return endDate!.difference(now).inHours <= 48;
  }

  factory Offer.fromJson(Map<String, dynamic> json,
      {Map<String, String>? storeNames}) {
    // Ensure product is a Post
    late Post product;

    final productData = json['product'];
    if (productData is Post) {
      product = productData;
    } else if (productData is Map<String, dynamic>) {
      product = Post.fromBackend(productData,
          storesById: const {}, categoriesById: const {});
    } else if (productData is int) {
      // If product is just an ID, create a minimal Post
      product = Post(
        id: productData,
        title: json['title'] ?? 'Product',
        description: json['description'] ?? '',
        category: json['category']?.toString() ?? 'Uncategorized',
        categoryId: null,
        storeId: json['store'] ?? 0,
        storeName: storeNames?[json['store']] ?? 'Store',
        author: User(
          id: json['store'] ?? 0,
          username: storeNames?[json['store']] ?? 'Store',
          email: '',
          name: storeNames?[json['store']] ?? 'Store',
          profileImage: null,
          dateJoined: DateTime.now(),
        ),
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        oldPrice: null,
        discountPercentage: json['discount_percentage'] ?? json['percentage'],
        isAvailable: true,
        rating: 4.5,
        isHotDeal: true,
        isFeatured: false,
        createdAt: DateTime.now(),
        images: const [],
      );
    } else {
      // Fallback
      product = Post(
        id: 0,
        title: json['title'] ?? 'Product',
        description: json['description'] ?? '',
        category: 'Uncategorized',
        categoryId: null,
        storeId: 0,
        storeName: 'Store',
        author: User(
          id: 0,
          username: 'Store',
          email: '',
          name: 'Store',
          profileImage: null,
          dateJoined: DateTime.now(),
        ),
        price: 0,
        oldPrice: null,
        discountPercentage: 0,
        isAvailable: true,
        rating: 0,
        isHotDeal: false,
        isFeatured: false,
        createdAt: DateTime.now(),
        images: const [],
      );
    }

    final pct = int.tryParse(
            (json['discount_percentage'] ?? json['percentage'] ?? 0)
                .toString()) ??
        0;
    final newPrice = double.tryParse(json['new_price']?.toString() ?? '') ??
        (product.price * (1 - pct / 100));

    return Offer(
      id: json['id'] ?? 0,
      product: product,
      discountPercentage: pct,
      newPrice: newPrice,
      isAvailable: json['is_available'] ?? json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse((json['end_date'] ?? '').toString()),
      maxImpressions: int.tryParse((json['max_impressions'] ?? '').toString()),
      uniqueViewersCount:
          int.tryParse((json['unique_viewers_count'] ?? '').toString()),
      remainingImpressions:
          int.tryParse((json['remaining_impressions'] ?? '').toString()),
    );
  }
}
