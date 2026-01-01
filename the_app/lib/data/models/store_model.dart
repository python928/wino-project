import 'package:equatable/equatable.dart';
import '../../core/config/api_config.dart';

class Store extends Equatable {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String bannerUrl;
  final String category;
  final double rating;
  final int totalProducts;
  final int followers;
  final bool isOpen;
  final double distance;
  final String email;
  final String phone;
  final String website;
  final String? address;
  final String? city;
  final String? wilaya;
  final double? latitude;
  final double? longitude;
  final String? storeType;
  final bool isVerified;
  final List<StoreProduct> products;
  final List<StoreReview> reviews;
  final String createdAt;
  final String updatedAt;

  const Store({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.bannerUrl,
    required this.category,
    required this.rating,
    required this.totalProducts,
    required this.followers,
    required this.isOpen,
    required this.distance,
    required this.email,
    required this.phone,
    required this.website,
    this.address,
    this.city,
    this.wilaya,
    this.latitude,
    this.longitude,
    this.storeType,
    this.isVerified = false,
    required this.products,
    required this.reviews,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper to get full image URL
  static String _getImageUrl(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.isEmpty) return '';
    if (str.startsWith('http')) return str;
    return ApiConfig.getImageUrl(str);
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    // Parse products - may be nested or separate
    List<StoreProduct> products = [];
    if (json['products'] != null && json['products'] is List) {
      products = (json['products'] as List)
          .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse reviews - may be nested or separate
    List<StoreReview> reviews = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      reviews = (json['reviews'] as List)
          .map((e) => StoreReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Category can be an int ID or a string name or an object
    String categoryName = '';
    final cat = json['category'];
    if (cat is String) {
      categoryName = cat;
    } else if (cat is int) {
      categoryName = 'Category $cat';
    } else if (cat is Map) {
      categoryName = cat['name']?.toString() ?? '';
    }

    return Store(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: _getImageUrl(json['logo'] ?? json['image_url'] ?? json['image']),
      bannerUrl: _getImageUrl(json['cover_image'] ?? json['banner_url'] ?? json['banner']),
      category: categoryName,
      rating: _parseDouble(json['rating'] ?? json['average_rating']),
      totalProducts: json['total_products'] as int? ?? json['products_count'] as int? ?? 0,
      followers: json['followers'] as int? ?? json['followers_count'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
      distance: _parseDouble(json['distance']),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      wilaya: json['wilaya']?.toString(),
      latitude: _parseDoubleNullable(json['latitude']),
      longitude: _parseDoubleNullable(json['longitude']),
      storeType: json['type']?.toString() ?? json['store_type']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      products: products,
      reviews: reviews,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'category': category,
      'rating': rating,
      'total_products': totalProducts,
      'followers': followers,
      'is_open': isOpen,
      'distance': distance,
      'email': email,
      'phone': phone,
      'website': website,
      'products': products.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convenience getters for backwards compatibility
  String? get logo => imageUrl.isNotEmpty ? imageUrl : null;
  String? get coverImage => bannerUrl.isNotEmpty ? bannerUrl : null;
  int get followersCount => followers;
  int get productsCount => totalProducts;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        bannerUrl,
        category,
        rating,
        totalProducts,
        followers,
        isOpen,
        distance,
        email,
        phone,
        website,
        products,
        reviews,
        createdAt,
        updatedAt,
      ];
}

class StoreProduct extends Equatable {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? oldPrice;
  final int? discountPercentage;
  final String description;
  final bool isAvailable;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.oldPrice,
    this.discountPercentage,
    required this.description,
    this.isAvailable = true,
  });

  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    String imageUrl = '';
    // Handle images array or direct image_url
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final firstImage = (json['images'] as List).first;
      if (firstImage is Map) {
        imageUrl = firstImage['image']?.toString() ?? '';
      } else {
        imageUrl = firstImage.toString();
      }
    }
    imageUrl = imageUrl.isEmpty ? (json['image_url']?.toString() ?? json['image']?.toString() ?? '') : imageUrl;

    // Make URL absolute if needed
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = ApiConfig.getImageUrl(imageUrl);
    }

    return StoreProduct(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      imageUrl: imageUrl,
      price: Store._parseDouble(json['price']),
      oldPrice: Store._parseDoubleNullable(json['old_price']),
      discountPercentage: json['discount_percentage'] as int?,
      description: json['description']?.toString() ?? '',
      isAvailable: (json['available_status'] ?? 'available') == 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'old_price': oldPrice,
      'discount_percentage': discountPercentage,
      'description': description,
      'is_available': isAvailable,
    };
  }

  @override
  List<Object?> get props => [id, name, imageUrl, price, oldPrice, discountPercentage, description, isAvailable];
}

class StoreReview extends Equatable {
  final int id;
  final String userName;
  final String? userAvatar;
  final String comment;
  final double rating;
  final String createdAt;

  const StoreReview({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory StoreReview.fromJson(Map<String, dynamic> json) {
    // User may be a nested object or just a name
    String userName = '';
    String? userAvatar;
    if (json['user'] is Map) {
      userName = json['user']['display_name']?.toString() ??
                 json['user']['username']?.toString() ??
                 json['user']['name']?.toString() ?? '';
      userAvatar = json['user']['profile_image']?.toString();
    } else {
      userName = json['user_name']?.toString() ?? json['user']?.toString() ?? '';
    }

    return StoreReview(
      id: json['id'] as int? ?? 0,
      userName: userName,
      userAvatar: userAvatar,
      comment: json['comment']?.toString() ?? json['content']?.toString() ?? '',
      rating: Store._parseDouble(json['rating']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_avatar': userAvatar,
      'comment': comment,
      'rating': rating,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, userName, userAvatar, comment, rating, createdAt];
}