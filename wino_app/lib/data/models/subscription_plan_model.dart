class SubscriptionPlanModel {
  final int id;
  final String name;
  final String slug;
  final int maxProducts;
  final double price;
  final int durationDays;
  final String benefits;
  final Map<String, dynamic> planFeatures;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.maxProducts,
    required this.price,
    required this.durationDays,
    required this.benefits,
    required this.planFeatures,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      maxProducts: (json['max_products'] as num?)?.toInt() ?? 0,
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      benefits: (json['benefits'] ?? '').toString(),
      planFeatures: (json['plan_features'] as Map?)?.cast<String, dynamic>() ??
          const {},
    );
  }
}
