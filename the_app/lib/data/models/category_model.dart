import 'package:flutter/material.dart';

/// Parsed icon data from the server for a category.
class CategoryIconData {
  final int codePoint;
  final String fontFamily;
  final String? fontPackage;

  const CategoryIconData({
    required this.codePoint,
    required this.fontFamily,
    this.fontPackage,
  });

  factory CategoryIconData.fromJson(Map<String, dynamic> json) {
    return CategoryIconData(
      codePoint: json['codePoint'] as int,
      fontFamily: json['fontFamily'] as String? ?? 'MaterialIcons',
      fontPackage: json['fontPackage'] as String?,
    );
  }

  /// Reconstruct Flutter [IconData] from server-provided values.
  IconData toIconData() {
    // Force usage of our embedded font to ensure codes match the website
    final family = (fontFamily == 'MaterialIcons')
        ? 'MaterialIconsRegular'
        : fontFamily;

    return IconData(
      codePoint,
      fontFamily: family,
      fontPackage: fontPackage,
    );
  }
}

/// Category model.
/// [serverIcon] is parsed from the server JSON {codePoint, fontFamily, fontPackage}.
/// [iconData] uses it when available, otherwise falls back to a name-based lookup.
class Category {
  final int id;
  final String name;
  final int productCount;
  final CategoryIconData? serverIcon;

  const Category({
    required this.id,
    required this.name,
    this.productCount = 0,
    this.serverIcon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    CategoryIconData? serverIcon;
    final iconJson = json['icon'];
    if (iconJson is Map<String, dynamic> && iconJson['codePoint'] != null) {
      serverIcon = CategoryIconData.fromJson(iconJson);
    }
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productCount: json['product_count'] ?? json['products_count'] ?? 0,
      serverIcon: serverIcon,
    );
  }

  /// Returns server icon if set, otherwise falls back to a name-based Material Icon.
  IconData get iconData {
    if (serverIcon != null) return serverIcon!.toIconData();
    final n = name.toLowerCase();
    if (n.contains('electronic')) return Icons.smartphone;
    if (n.contains('fashion') || n.contains('clothing')) return Icons.checkroom;
    if (n.contains('home')) return Icons.chair;
    if (n.contains('sport')) return Icons.sports_basketball;
    if (n.contains('beauty')) return Icons.face;
    if (n.contains('food')) return Icons.restaurant;
    if (n.contains('book')) return Icons.book;
    if (n.contains('car')) return Icons.directions_car;
    if (n.contains('fruit')) return Icons.local_florist;
    if (n.contains('vegetable') || n.contains('veggie')) return Icons.eco;
    return Icons.category;
  }
}
