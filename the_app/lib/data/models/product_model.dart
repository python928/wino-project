import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String description;
  final List<String> images; // Primary + 3 secondary
  final double price;
  final double rating;
  final int reviewCount;
  final String category;
  final int storeId;
  final String storeName;
  final String storeImage;
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.storeId,
    required this.storeName,
    required this.storeImage,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      images: List<String>.from(json['images'] as List),
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      category: json['category'] as String,
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String,
      storeImage: json['store_image'] as String,
      isFavorite: json['is_favorite'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'rating': rating,
      'review_count': reviewCount,
      'category': category,
      'store_id': storeId,
      'store_name': storeName,
      'store_image': storeImage,
      'is_favorite': isFavorite,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        images,
        price,
        rating,
        reviewCount,
        category,
        storeId,
        storeName,
        storeImage,
        isFavorite,
        createdAt,
        updatedAt,
      ];
}