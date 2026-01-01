class Product {
  final String id;
  final String name;
  final String storeName;
  final double price;
  final double? oldPrice;
  final String? discount;
  final double rating;
  final double distance;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final bool isFavorite;

  // Gallery images getter for compatibility
  List<String> get gallery => [imageUrl];

  Product({
    required this.id,
    required this.name,
    required this.storeName,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.isFavorite = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? storeName,
    double? price,
    double? oldPrice,
    String? discount,
    double? rating,
    double? distance,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      discount: discount ?? this.discount,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
