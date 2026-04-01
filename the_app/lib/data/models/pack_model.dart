import 'package:equatable/equatable.dart';

import '../../core/config/api_config.dart';

class Pack extends Equatable {
  final int id;
  final String name;
  final String description;
  final List<PackProduct> products;
  final double totalPrice;
  final double discountPrice;
  final bool isAvailable;
  final String createdAt;
  final String updatedAt;
  final int merchantId;
  final String merchantName;
  final String merchantAddress;
  final double merchantRating;
  final int merchantReviewCount;
  final double? merchantLatitude;
  final double? merchantLongitude;
  final bool merchantNearbyVisible;
  final bool merchantIsVerified;
  final bool deliveryAvailable;
  final List<String> deliveryWilayas;

  const Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.products,
    required this.totalPrice,
    required this.discountPrice,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    required this.merchantId,
    required this.merchantName,
    this.merchantAddress = '',
    this.merchantRating = 0.0,
    this.merchantReviewCount = 0,
    this.merchantLatitude,
    this.merchantLongitude,
    this.merchantNearbyVisible = true,
    this.merchantIsVerified = false,
    this.deliveryAvailable = false,
    this.deliveryWilayas = const [],
  });

  factory Pack.fromJson(Map<String, dynamic> json,
      {Map<int, String>? storesById}) {
    // Extract merchant/store ID
    int merchantId = 0;
    if (json['merchant_id'] != null) {
      merchantId = json['merchant_id'] as int;
    } else if (json['store'] != null) {
      merchantId =
          json['store'] is int ? json['store'] : (json['store']['id'] ?? 0);
    }

    // Extract merchant name from various possible sources
    String merchantName = '';
    String merchantAddress = '';
    double merchantRating = 0.0;
    int merchantReviewCount = 0;
    bool merchantIsVerified = false;

    // 1. Try merchant_name field
    if (json['merchant_name'] != null &&
        json['merchant_name'].toString().trim().isNotEmpty) {
      merchantName = json['merchant_name'].toString().trim();
    }
    // 2. Try store object
    else if (json['store'] is Map && json['store']['name'] != null) {
      merchantName = json['store']['name'].toString().trim();
    }
    // 3. Try storesById map if provided
    else if (storesById != null && merchantId > 0) {
      merchantName = storesById[merchantId] ?? '';
    }

    if (json['merchant'] is Map<String, dynamic>) {
      final merchant = json['merchant'] as Map<String, dynamic>;
      merchantAddress =
          (merchant['address'] ?? merchant['city'] ?? '').toString().trim();
      merchantRating = _parseDouble(
          merchant['average_rating'] ?? merchant['rating'] ?? merchantRating);
      merchantReviewCount =
          int.tryParse((merchant['review_count'] ?? '').toString()) ??
              merchantReviewCount;
      merchantIsVerified =
          (json['merchant']['is_verified'] as bool?) ?? merchantIsVerified;
    }
    if (json['store'] is Map<String, dynamic>) {
      final store = json['store'] as Map<String, dynamic>;
      if (merchantAddress.isEmpty) {
        merchantAddress =
            (store['address'] ?? store['city'] ?? '').toString().trim();
      }
      if (merchantRating <= 0) {
        merchantRating =
            _parseDouble(store['average_rating'] ?? store['rating']);
      }
      merchantReviewCount =
          int.tryParse((store['review_count'] ?? '').toString()) ??
              merchantReviewCount;
      merchantIsVerified =
          (store['is_verified'] as bool?) ?? merchantIsVerified;
    }
    merchantIsVerified =
        (json['merchant_is_verified'] as bool?) ?? merchantIsVerified;
    merchantAddress =
        (json['merchant_address'] ?? json['store_address'] ?? merchantAddress)
            .toString()
            .trim();
    merchantRating = _parseDouble(
      json['merchant_average_rating'] ??
          json['average_rating'] ??
          json['merchant_rating'] ??
          merchantRating,
    );
    merchantReviewCount =
        int.tryParse((json['merchant_review_count'] ?? '').toString()) ??
            merchantReviewCount;

    return Pack(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      products: ((json['products'] ?? json['pack_products']) as List<dynamic>)
          .map((e) => PackProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: _parseDouble(json['total_price']),
      discountPrice: _parseDouble(json['discount_price']),
      isAvailable: (json['available_status'] ??
              json['status'] ??
              json['is_available'] ??
              'available') ==
          'available',
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String? ?? '',
      merchantId: merchantId,
      merchantName: merchantName,
      merchantAddress: merchantAddress,
      merchantRating: merchantRating,
      merchantReviewCount: merchantReviewCount,
      merchantLatitude: json['merchant_latitude'] != null
          ? double.tryParse(json['merchant_latitude'].toString())
          : null,
      merchantLongitude: json['merchant_longitude'] != null
          ? double.tryParse(json['merchant_longitude'].toString())
          : null,
      merchantNearbyVisible: json['merchant_nearby_visible'] as bool? ?? true,
      merchantIsVerified: merchantIsVerified,
      deliveryAvailable: json['delivery_available'] as bool? ?? false,
      deliveryWilayas: _parseWilayas(json['delivery_wilayas']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String> _parseWilayas(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'products': products.map((e) => e.toJson()).toList(),
      'total_price': totalPrice,
      'discount_price': discountPrice,
      'available_status': isAvailable ? 'available' : 'unavailable',
      'created_at': createdAt,
      'updated_at': updatedAt,
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'merchant_address': merchantAddress,
      'merchant_average_rating': merchantRating,
      'merchant_review_count': merchantReviewCount,
      'merchant_latitude': merchantLatitude,
      'merchant_longitude': merchantLongitude,
      'merchant_nearby_visible': merchantNearbyVisible,
      'merchant_is_verified': merchantIsVerified,
      'delivery_available': deliveryAvailable,
      'delivery_wilayas': deliveryWilayas.join(','),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        products,
        totalPrice,
        discountPrice,
        isAvailable,
        createdAt,
        updatedAt,
        merchantId,
        merchantName,
        merchantAddress,
        merchantRating,
        merchantReviewCount,
        merchantLatitude,
        merchantLongitude,
        merchantNearbyVisible,
        merchantIsVerified,
        deliveryAvailable,
        deliveryWilayas,
      ];
}

class PackProduct extends Equatable {
  final int productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final int quantity;

  const PackProduct({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.quantity,
  });

  factory PackProduct.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['product_image'] ?? '').toString();
    final imageUrl = rawImage.isEmpty ? '' : ApiConfig.getImageUrl(rawImage);

    return PackProduct(
      productId: (json['product_id'] ?? json['product']) as int,
      productName: json['product_name'] as String,
      productImage: imageUrl,
      productPrice: Pack._parseDouble(json['product_price']),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'product_price': productPrice,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        productPrice,
        quantity,
      ];
}
