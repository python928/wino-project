class Store {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int followers;
  final double distance;
  final String imageUrl;
  final bool isOpen;
  final String? description;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.followers,
    required this.distance,
    required this.imageUrl,
    this.isOpen = true,
    this.description,
  });
}
