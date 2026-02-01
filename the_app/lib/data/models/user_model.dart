class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? profileImage;
  final DateTime dateJoined;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.profileImage,
    required this.dateJoined,
  });

  String get fullName => name.isNotEmpty ? name : username;

  bool get isMerchant => role.toUpperCase() == 'STORE';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
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
      'name': name,
      'phone': phone,
      'role': role,
      'profile_image': profileImage,
      'date_joined': dateJoined.toIso8601String(),
    };
  }
}
