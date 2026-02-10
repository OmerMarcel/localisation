class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> favoriteInfrastructures;
  final int contributionsCount;
  final bool isVerified;
  final String preferredLanguage;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.favoriteInfrastructures = const [],
    this.contributionsCount = 0,
    this.isVerified = false,
    this.preferredLanguage = 'fr',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      favoriteInfrastructures: List<String>.from(
        json['favorite_infrastructures'] ?? [],
      ),
      contributionsCount: json['contributions_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      preferredLanguage: json['preferred_language'] ?? 'fr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'favorite_infrastructures': favoriteInfrastructures,
      'contributions_count': contributionsCount,
      'is_verified': isVerified,
      'preferred_language': preferredLanguage,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteInfrastructures,
    int? contributionsCount,
    bool? isVerified,
    String? preferredLanguage,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteInfrastructures:
          favoriteInfrastructures ?? this.favoriteInfrastructures,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      isVerified: isVerified ?? this.isVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
