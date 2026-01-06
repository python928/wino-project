import '../../core/config/api_config.dart';

class BackendStore {
  final int id;
  final int ownerId;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final double? latitude;
  final double? longitude;
  final String type;
  final String profileImageUrl;
  final String coverImageUrl;
  final int followersCount;
  final double averageRating;

  const BackendStore({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.type,
    required this.profileImageUrl,
    required this.coverImageUrl,
    this.followersCount = 0,
    this.averageRating = 0,
  });

  factory BackendStore.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['profile_image']?.toString() ?? '';
    final coverRaw = json['cover_image']?.toString() ?? '';

    return BackendStore(
      id: json['id'] as int,
      ownerId: (json['owner'] as int?) ?? 0,
      name: (json['name']?.toString().trim().isNotEmpty ?? false)
          ? json['name'].toString()
          : 'متجر',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      type: json['type']?.toString() ?? 'physical',
      profileImageUrl: ApiConfig.getImageUrl(profileRaw),
      coverImageUrl: ApiConfig.getImageUrl(coverRaw),
      followersCount: json['followers_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
