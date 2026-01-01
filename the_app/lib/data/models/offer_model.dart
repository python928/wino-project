import 'post_model.dart';
import 'user_model.dart';

class Offer {
  final int id;
  final Post product;
  final int discountPercentage;
  final double newPrice;
  final bool isAvailable;
  final DateTime createdAt;

  Offer({
    required this.id,
    required this.product,
    required this.discountPercentage,
    required this.newPrice,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json, {Map<String, String>? storeNames}) {
    // Fallback parsing when API returns nested product info
    final productJson = json['product'] as Map<String, dynamic>?;
    final product = productJson != null
        ? Post.fromBackend(productJson, storesById: const {}, categoriesById: const {})
        : Post(
            id: json['product'] ?? 0,
            title: json['title'] ?? 'منتج',
            description: json['description'] ?? '',
            category: json['category']?.toString() ?? 'غير مصنف',
            categoryId: null,
            storeId: productJson?['store'] ?? 0,
            storeName: storeNames?[productJson?['store']] ?? 'متجر',
            author: User(
              id: productJson?['store'] ?? 0,
              username: storeNames?[productJson?['store']] ?? 'متجر',
              email: '',
              firstName: storeNames?[productJson?['store']] ?? 'متجر',
              lastName: '',
              role: 'STORE',
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

    final pct = int.tryParse((json['discount_percentage'] ?? json['percentage'] ?? 0).toString()) ?? 0;
    final newPrice = double.tryParse(json['new_price']?.toString() ?? '') ?? (product.price * (1 - pct / 100));

    return Offer(
      id: json['id'] ?? 0,
      product: product,
      discountPercentage: pct,
      newPrice: newPrice,
      isAvailable: json['is_available'] ?? json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
