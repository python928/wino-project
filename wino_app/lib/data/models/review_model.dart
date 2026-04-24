class Review {
  final int id;
  final int userId;
  final int storeId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? userProfileImage;

  Review({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.userProfileImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      storeId: json['store'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userName: json['user_name'],
      userProfileImage: json['user_profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'store': storeId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
