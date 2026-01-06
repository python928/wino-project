import 'package:equatable/equatable.dart';

class Pack extends Equatable {
  final int id;
  final String name;
  final String description;
  final List<PackProduct> products;
  final double totalPrice;
  final double discountPrice;
  final String createdAt;
  final String updatedAt;
  final int merchantId;
  final String merchantName;

  const Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.products,
    required this.totalPrice,
    required this.discountPrice,
    required this.createdAt,
    required this.updatedAt,
    required this.merchantId,
    required this.merchantName,
  });

  factory Pack.fromJson(Map<String, dynamic> json, {Map<int, String>? storesById}) {
    // Extract merchant/store ID
    int merchantId = 0;
    if (json['merchant_id'] != null) {
      merchantId = json['merchant_id'] as int;
    } else if (json['store'] != null) {
      merchantId = json['store'] is int ? json['store'] : (json['store']['id'] ?? 0);
    }

    // Extract merchant name from various possible sources
    String merchantName = '';

    // 1. Try merchant_name field
    if (json['merchant_name'] != null && json['merchant_name'].toString().trim().isNotEmpty) {
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

    return Pack(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      products: ((json['products'] ?? json['pack_products']) as List<dynamic>)
          .map((e) => PackProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: _parseDouble(json['total_price']),
      discountPrice: _parseDouble(json['discount_price']),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String? ?? '',
      merchantId: merchantId,
      merchantName: merchantName,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'products': products.map((e) => e.toJson()).toList(),
      'total_price': totalPrice,
      'discount_price': discountPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'merchant_id': merchantId,
      'merchant_name': merchantName,
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
        createdAt,
        updatedAt,
        merchantId,
        merchantName,
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
    return PackProduct(
      productId: (json['product_id'] ?? json['product']) as int,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String,
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