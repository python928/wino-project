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
  final String storeType;
  final String? coverImage;
  final int followersCount;
  final double averageRating;

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
    this.storeType = 'physical',
    this.coverImage,
    this.followersCount = 0,
    this.averageRating = 0.0,
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
      dateJoined: DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime.now(),
    gender: json['gender']?.toString(),
    birthday: json['birthday'] != null
      ? DateTime.tryParse(json['birthday'].toString())
      : null,
      role: json['role']?.toString(), // <-- added (optional)
      storeDescription: json['store_description'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      storeType: json['store_type'] ?? 'physical',
      coverImage: json['cover_image'],
      followersCount: json['followers_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
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
      'store_type': storeType,
      'cover_image': coverImage,
      'followers_count': followersCount,
      'average_rating': averageRating,
    };
  }
}
