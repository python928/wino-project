import 'user_model.dart';
import '../../core/config/api_config.dart';

class ProductImageData {
  final int id;
  final String url;
  final bool isMain;

  const ProductImageData({
    required this.id,
    required this.url,
    required this.isMain,
  });

  factory ProductImageData.fromJson(Map<String, dynamic> json) {
    String url = json['image'] ?? '';
    if (url.isNotEmpty && !url.startsWith('http')) {
      // If it's a relative path, prepend the media URL
      // But first check if it already has /media/ prefix to avoid doubling
      if (url.startsWith('/media/')) {
        url = '${ApiConfig.baseUrl}$url';
      } else {
        url = ApiConfig.getImageUrl(url);
      }
    }
    
    return ProductImageData(
      id: json['id'],
      url: url,
      isMain: json['is_main'] ?? false,
    );
  }
}

class Post {
  final int id;
  final String title;
  final String description;
  final String category;
  final int? categoryId;
  final int storeId;
  final String storeName;
  final User author;
  final double price;
  final double? oldPrice;
  final int? discountPercentage;
  final bool isAvailable;
  final bool isNegotiable;
  final bool hidePrice;
  final double rating;
  final int reviewCount;
  final bool isFavorited;
  final bool isHotDeal;
  final bool isFeatured;
  final DateTime createdAt;
  final List<ProductImageData> images;

  const Post({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.storeId,
    required this.storeName,
    required this.author,
    required this.price,
    this.oldPrice,
    this.discountPercentage,
    required this.isAvailable,
    this.isNegotiable = false,
    this.hidePrice = false,
    required this.rating,
    this.reviewCount = 0,
    this.isFavorited = false,
    required this.isHotDeal,
    required this.isFeatured,
    required this.createdAt,
    required this.images,
  });

  String? get image {
    if (images.isEmpty) return null;
    final main = images.where((img) => img.isMain).toList();
    if (main.isNotEmpty) return main.first.url;
    return images.first.url;
  }

  List<String> get gallery => images.map((e) => e.url).toList();

  /// Standard fromJson constructor for API responses
  factory Post.fromJson(Map<String, dynamic> json) {
    final productId = json['id'] as int? ?? 0;

    // Handle store - can be an int ID or an object
    int storeId = 0;
    String storeName = 'Local Store';
    if (json['store'] is int) {
      storeId = json['store'];
    } else if (json['store'] is Map) {
      storeId = json['store']['id'] ?? 0;
      storeName = json['store']['name'] ?? 'Local Store';
    }

    // Handle category - can be an int ID, string, or object
    int? categoryId;
    String categoryName = 'Uncategorized';
    if (json['category'] is int) {
      categoryId = json['category'];
      categoryName = 'Category $categoryId';
    } else if (json['category'] is String) {
      categoryName = json['category'];
    } else if (json['category'] is Map) {
      categoryId = json['category']['id'];
      categoryName = json['category']['name'] ?? 'Uncategorized';
    }

    // Parse price
    final double price = _parseDouble(json['price']);
    final double? oldPrice = json['old_price'] != null ? _parseDouble(json['old_price']) : null;

    // Calculate discount percentage if not provided
    int? discountPct = json['discount_percentage'] as int?;
    if (discountPct == null && oldPrice != null && oldPrice > price && oldPrice > 0) {
      discountPct = ((oldPrice - price) / oldPrice * 100).round();
    }

    // Parse images
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((img) => ProductImageData.fromJson(img as Map<String, dynamic>))
        .toList();

    // Parse owner/author
    User author;
    if (json['owner'] is Map) {
      author = User.fromJson(json['owner']);
    } else {
      author = User(
        id: json['owner'] ?? storeId,
        username: storeName,
        email: '',
        name: storeName,
        profileImage: null,
        dateJoined: DateTime.now(),
      );
    }

    return Post(
      id: productId,
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: categoryName,
      categoryId: categoryId,
      storeId: storeId,
      storeName: storeName,
      author: author,
      price: price,
      oldPrice: oldPrice,
      discountPercentage: discountPct,
      isAvailable: (json['available_status'] ?? json['status'] ?? 'available') == 'available',
      isNegotiable: json['negotiable'] as bool? ?? false,
      hidePrice: json['hide_price'] as bool? ?? false,
      rating: _parseDouble(json['average_rating'] ?? json['rating'] ?? 0.0),
      reviewCount: json['review_count'] as int? ?? 0,
      isFavorited: json['is_favorited'] as bool? ?? false,
      isHotDeal: (discountPct ?? 0) > 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      images: images,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Post.fromBackend(
    Map<String, dynamic> json, {
    Map<int, User>? usersById,
    Map<int, String>? storesById,
    Map<int, String>? categoriesById,
    Map<int, int>? promoPercentageByProduct,
  }) {
    final productId = json['id'] as int;
    final storeId = json['store'] as int;
    final storeName = storesById?[storeId] ?? 'Local Store';

    final user = usersById != null
        ? usersById[json['owner_id'] ?? storeId] // owner_id is not present; fall back to storeId
        : null;

    final categoryId = json['category'] as int?;
    final categoryName = categoriesById?[categoryId] ?? (categoryId?.toString() ?? 'Uncategorized');

    final discountPct = promoPercentageByProduct?[productId];
    final double price = double.tryParse(json['price'].toString()) ?? 0;
    final double? oldPrice = (discountPct != null && discountPct > 0)
        ? double.parse((price / (1 - (discountPct / 100))).toStringAsFixed(2))
        : null;

    final images = (json['images'] as List<dynamic>? ?? [])
        .map((img) => ProductImageData.fromJson(img as Map<String, dynamic>))
        .toList();

    return Post(
      id: productId,
      title: json['name'] ?? '',
      description: json['description'] ?? '',
      category: categoryName,
      categoryId: categoryId,
      storeId: storeId,
      storeName: storeName,
      author: user ??
          User(
            id: json['store_owner'] ?? storeId,
            username: storeName,
            email: json['store_owner_email'] ?? '',
            name: storeName,
            profileImage: null,
            dateJoined: DateTime.now(),
          ),
      price: price,
      oldPrice: oldPrice,
      discountPercentage: discountPct,
      isAvailable: (json['available_status'] ?? 'available') == 'available',
      isNegotiable: json['negotiable'] as bool? ?? false,
      hidePrice: json['hide_price'] as bool? ?? false,
      rating: double.tryParse((json['average_rating'] ?? json['rating'] ?? 0.0).toString()) ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isFavorited: json['is_favorited'] as bool? ?? false,
      isHotDeal: (discountPct ?? 0) > 0,
      isFeatured: false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      images: images,
    );
  }

  /// Create a copy of this Post with modified fields
  Post copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    int? categoryId,
    int? storeId,
    String? storeName,
    User? author,
    double? price,
    double? oldPrice,
    int? discountPercentage,
    bool? isAvailable,
    bool? isNegotiable,
    bool? hidePrice,
    double? rating,
    int? reviewCount,
    bool? isFavorited,
    bool? isHotDeal,
    bool? isFeatured,
    DateTime? createdAt,
    List<ProductImageData>? images,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      author: author ?? this.author,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isAvailable: isAvailable ?? this.isAvailable,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      hidePrice: hidePrice ?? this.hidePrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorited: isFavorited ?? this.isFavorited,
      isHotDeal: isHotDeal ?? this.isHotDeal,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'description': description,
      'category': categoryId,
      'store': storeId,
      'price': price,
      'old_price': oldPrice,
      'discount_percentage': discountPercentage,
      'available_status': isAvailable ? 'available' : 'out_of_stock',
      'negotiable': isNegotiable,
      'hide_price': hidePrice,
      'rating': rating,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'images': images.map((i) => {'id': i.id, 'image': i.url, 'is_main': i.isMain}).toList(),
    };
  }
}
