class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? displayName;
  final String? phone;
  final String role;
  final String? profileImage;
  final DateTime dateJoined;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.phone,
    required this.role,
    this.profileImage,
    required this.dateJoined,
  });

  String get fullName {
    final combined = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!.trim();
    if (combined.isNotEmpty) return combined;
    return username;
  }

  bool get isMerchant => role.toUpperCase() == 'STORE';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      displayName: json['display_name'],
      phone: json['phone'],
      role: json['role'] ?? 'USER',
      profileImage: json['profile_image'],
      dateJoined: DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'phone': phone,
      'role': role,
      'profile_image': profileImage,
      'date_joined': dateJoined.toIso8601String(),
    };
  }
}