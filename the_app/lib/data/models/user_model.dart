class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final DateTime dateJoined;

  // New registration/profile fields
  final String? gender;
  final DateTime? birthday;

  // Legacy compat (old code still passes role:)
  final String? role;

  // Store fields (merged from Store model)
  final String storeDescription;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool allowNearbyVisibility;
  final String storeType;
  final bool isVerified;
  final String? city;
  final String? country;
  final String? coverImage;
  final int followersCount;
  final double averageRating;
  final String? facebook;
  final String? instagram;
  final String? whatsapp;
  final String? tiktok;
  final String? youtube;
  final bool showPhonePublic;
  final bool showSocialPublic;
  final DateTime? locationUpdatedAt;
  final double? distance;
  final bool isOpen;
  final int productCount;
  final int reviewCount;
  final List<String> categories;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    required this.dateJoined,
    this.gender,
    this.birthday,
    this.role, // <-- added
    this.storeDescription = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.allowNearbyVisibility = true,
    this.storeType = 'physical',
    this.isVerified = false,
    this.city,
    this.country,
    this.coverImage,
    this.followersCount = 0,
    this.averageRating = 0.0,
    this.facebook,
    this.instagram,
    this.whatsapp,
    this.tiktok,
    this.youtube,
    this.showPhonePublic = true,
    this.showSocialPublic = true,
    this.locationUpdatedAt,
    this.distance,
    this.isOpen = true,
    this.productCount = 0,
    this.reviewCount = 0,
    this.categories = const [],
  });

  String get fullName => name.isNotEmpty ? name : username;

  bool get isMerchant => true; // All users are merchants now

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      dateJoined:
          DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime.now(),
      gender: json['gender']?.toString(),
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
      role: json['role']?.toString(), // <-- added (optional)
      storeDescription: json['store_description'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      allowNearbyVisibility: json['allow_nearby_visibility'] as bool? ?? true,
      storeType: json['store_type'] ?? 'physical',
      coverImage: json['cover_image'],
      followersCount: json['followers_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      facebook: json['facebook'],
      instagram: json['instagram'],
      whatsapp: json['whatsapp'],
      tiktok: json['tiktok'],
      youtube: json['youtube'],
      showPhonePublic: json['show_phone_public'] as bool? ?? true,
      showSocialPublic: json['show_social_public'] as bool? ?? true,
      isVerified: json['is_verified'] ?? false,
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'].toString())
          : null,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      isOpen: json['is_open'] ?? true,
      productCount: json['product_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      categories: (json['categories'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'phone': phone,
      'profile_image': profileImage,
      'date_joined': dateJoined.toIso8601String(),
      'gender': gender,
      'birthday': birthday?.toIso8601String().split('T').first,
      'role': role, // <-- added (optional)
      'store_description': storeDescription,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'allow_nearby_visibility': allowNearbyVisibility,
      'store_type': storeType,
      'cover_image': coverImage,
      'followers_count': followersCount,
      'average_rating': averageRating,
      'facebook': facebook,
      'instagram': instagram,
      'whatsapp': whatsapp,
      'tiktok': tiktok,
      'youtube': youtube,
      'show_phone_public': showPhonePublic,
      'show_social_public': showSocialPublic,
      'is_verified': isVerified,
      'city': city,
      'country': country,
      'location_updated_at': locationUpdatedAt?.toIso8601String(),
      'distance': distance,
      'is_open': isOpen,
      'product_count': productCount,
      'review_count': reviewCount,
      'categories': categories,
    };
  }
}
