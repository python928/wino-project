import '../../core/config/api_config.dart';

class BackendStore {
  final int id;
  final int ownerId;
  final String name;
  final String description;
  final String address;
  final String type;
  final String profileImageUrl;
  final String coverImageUrl;

  const BackendStore({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.type,
    required this.profileImageUrl,
    required this.coverImageUrl,
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
      type: json['type']?.toString() ?? 'physical',
      profileImageUrl: ApiConfig.getImageUrl(profileRaw),
      coverImageUrl: ApiConfig.getImageUrl(coverRaw),
    );
  }
}
