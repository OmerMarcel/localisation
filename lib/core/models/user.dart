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

  // Données de récompense
  final int? totalPoints;
  final int? currentLevel;
  final String? levelName;
  final List<Map<String, dynamic>>? badges;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.totalPoints,
    this.currentLevel,
    this.levelName,
    this.badges,
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
      totalPoints: json['total_points'] as int?,
      currentLevel: json['current_level'] as int?,
      levelName: json['level_name'] as String?,
      badges: json['badges'] != null
          ? List<Map<String, dynamic>>.from(json['badges'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'total_points': totalPoints,
      'current_level': currentLevel,
      'level_name': levelName,
      'badges': badges,
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
    int? totalPoints,
    int? currentLevel,
    String? levelName,
    List<Map<String, dynamic>>? badges,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      levelName: levelName ?? this.levelName,
      badges: badges ?? this.badges,
      favoriteInfrastructures:
          favoriteInfrastructures ?? this.favoriteInfrastructures,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      isVerified: isVerified ?? this.isVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
