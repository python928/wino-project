import 'post_model.dart';
import 'user_model.dart';

class Offer {
  final int id;
  final Post product;
  final int discountPercentage;
  final double newPrice;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxImpressions;
  final int? uniqueViewersCount;
  final int? remainingImpressions;
  final String kind;
  final String placement;
  final List<int> displayHours;
  final String audienceMode;
  final int impressionsCount;
  final int clicksCount;
  final List<String> targetWilayas;
  final List<String> targetCategories;
  final int? ageFrom;
  final int? ageTo;
  final String geoMode;
  final int? targetRadiusKm;
  final String targetType;
  final int? targetPackId;
  final String? targetPackName;

  Offer({
    required this.id,
    required this.product,
    required this.discountPercentage,
    required this.newPrice,
    required this.isAvailable,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.maxImpressions,
    this.uniqueViewersCount,
    this.remainingImpressions,
    this.kind = 'promotion',
    this.placement = 'home_top',
    this.displayHours = const [],
    this.audienceMode = 'all',
    this.impressionsCount = 0,
    this.clicksCount = 0,
    this.targetWilayas = const [],
    this.targetCategories = const [],
    this.ageFrom,
    this.ageTo,
    this.geoMode = 'all',
    this.targetRadiusKm,
    this.targetType = 'product',
    this.targetPackId,
    this.targetPackName,
  });

  bool get hasImpressionLimit => maxImpressions != null;
  int? get displayHour => displayHours.isNotEmpty ? displayHours.first : null;

  bool get isNearEnding {
    if (endDate == null) return false;
    final now = DateTime.now();
    if (endDate!.isBefore(now)) return false;
    return endDate!.difference(now).inHours <= 48;
  }

  static int _parsePercentage(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    final text = raw.toString().trim();
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(text) ?? 0;
  }

  static DateTime? _parseDateTimeToLocal(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  /// Check if promotion is available (within start/end time window)
  bool get isAvailableNow {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) {
      return false; // Not started yet
    }
    if (endDate != null && now.isAfter(endDate!)) {
      return false; // Expired
    }
    return true; // Available
  }

  /// Get formatted remaining duration (e.g., "1 day 2:10:10")
  String? getDurationString() {
    if (endDate == null || !isAvailableNow) return null;
    try {
      final duration = endDate!.difference(DateTime.now());
      if (duration.isNegative) return null;

      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      final hhmmss =
          '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      if (days <= 0) return hhmmss;
      final dayLabel = days == 1 ? '1 day' : '$days days';
      return '$dayLabel $hhmmss';
    } catch (_) {
      return null;
    }
  }

  /// Get status message for the promotion.
  String? getStatusMessage() {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) {
      final diff = startDate!.difference(now);
      if (diff.inDays >= 1) {
        return 'Available in ${diff.inDays}d';
      } else if (diff.inHours >= 1) {
        return 'Available in ${diff.inHours}h';
      } else {
        return 'Available in ${diff.inMinutes.clamp(1, 59)}m';
      }
    }
    if (endDate != null && now.isAfter(endDate!)) {
      return 'Duration ended';
    }
    return null;
  }

  factory Offer.fromJson(Map<String, dynamic> json,
      {Map<String, String>? storeNames}) {
    // Ensure product is a Post
    late Post product;

    final productData = json['product'];
    if (productData is Post) {
      product = productData;
    } else if (productData is Map<String, dynamic>) {
      product = Post.fromBackend(productData,
          storesById: const {}, categoriesById: const {});
    } else if (productData is int) {
      // If product is just an ID, create a minimal Post
      product = Post(
        id: productData,
        title: json['title'] ?? 'Product',
        description: json['description'] ?? '',
        category: json['category']?.toString() ?? 'Uncategorized',
        categoryId: null,
        storeId: json['store'] ?? 0,
        storeName: storeNames?[json['store']] ?? 'Store',
        author: User(
          id: json['store'] ?? 0,
          username: storeNames?[json['store']] ?? 'Store',
          email: '',
          name: storeNames?[json['store']] ?? 'Store',
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
    } else {
      // Fallback
      product = Post(
        id: 0,
        title: json['title'] ?? 'Product',
        description: json['description'] ?? '',
        category: 'Uncategorized',
        categoryId: null,
        storeId: 0,
        storeName: 'Store',
        author: User(
          id: 0,
          username: 'Store',
          email: '',
          name: 'Store',
          profileImage: null,
          dateJoined: DateTime.now(),
        ),
        price: 0,
        oldPrice: null,
        discountPercentage: 0,
        isAvailable: true,
        rating: 0,
        isHotDeal: false,
        isFeatured: false,
        createdAt: DateTime.now(),
        images: const [],
      );
    }

    final pct = _parsePercentage(
      json['discount_percentage'] ?? json['percentage'] ?? 0,
    );
    final newPrice = double.tryParse(json['new_price']?.toString() ?? '') ??
        (product.price * (1 - pct / 100));

    return Offer(
      id: json['id'] ?? 0,
      product: product,
      discountPercentage: pct,
      newPrice: newPrice,
      isAvailable: json['is_available'] ?? json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      startDate: _parseDateTimeToLocal(
        json['start_date'] ??
            json['startDate'] ??
            json['start_time'] ??
            json['startTime'] ??
            json['starts_at'] ??
            json['startsAt'],
      ),
      endDate: _parseDateTimeToLocal(
        json['end_date'] ??
            json['endDate'] ??
            json['end_time'] ??
            json['endTime'] ??
            json['expires_at'] ??
            json['expiresAt'] ??
            json['ends_at'] ??
            json['endsAt'],
      ),
      maxImpressions: int.tryParse((json['max_impressions'] ?? '').toString()),
      uniqueViewersCount:
          int.tryParse((json['unique_viewers_count'] ?? '').toString()),
      remainingImpressions:
          int.tryParse((json['remaining_impressions'] ?? '').toString()),
      kind: (json['kind'] ?? 'promotion').toString(),
      placement: (json['placement'] ?? 'home_top').toString(),
      displayHours: ((json['display_hours'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          const []),
      audienceMode: (json['audience_mode'] ?? 'all').toString(),
      impressionsCount:
          int.tryParse((json['impressions_count'] ?? '').toString()) ?? 0,
      clicksCount: int.tryParse((json['clicks_count'] ?? '').toString()) ?? 0,
      targetWilayas: (json['target_wilayas'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetCategories: (json['target_categories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ageFrom: int.tryParse((json['age_from'] ?? '').toString()),
      ageTo: int.tryParse((json['age_to'] ?? '').toString()),
      geoMode: (json['geo_mode'] ?? 'all').toString(),
      targetRadiusKm: int.tryParse((json['target_radius_km'] ?? '').toString()),
      targetType:
          (json['target_type'] ?? (json['pack'] != null ? 'pack' : 'product'))
              .toString(),
      targetPackId: json['pack'] is int
          ? json['pack'] as int
          : (json['pack'] is Map<String, dynamic>
              ? (json['pack']['id'] as int?)
              : int.tryParse((json['pack'] ?? '').toString())),
      targetPackName: json['pack'] is Map<String, dynamic>
          ? (json['pack']['name']?.toString())
          : json['pack_name']?.toString(),
    );
  }
}
