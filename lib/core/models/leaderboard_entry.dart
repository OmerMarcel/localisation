/// Modèle représentant une entrée du classement
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final int totalPoints;
  final int currentLevel;
  final String levelName;
  final int badgesCount;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.totalPoints,
    required this.currentLevel,
    required this.levelName,
    required this.badgesCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['id'];
    final rawUserName = json['user_name'] ?? _buildName(json);
    final rawBadgesCount = json['badges_count'] ?? json['badge_count'];

    return LeaderboardEntry(
      rank: _parseInt(json['rank']),
      userId: rawUserId?.toString() ?? 'unknown',
      userName: rawUserName.toString(),
      userProfileImage:
          (json['user_profile_image'] ?? json['avatar']) as String?,
      totalPoints: _parseInt(json['total_points']),
      currentLevel: _parseInt(json['current_level']),
      levelName: (json['level_name'] ?? 'Niveau').toString(),
      badgesCount: _parseInt(rawBadgesCount),
    );
  }

  static String _buildName(Map<String, dynamic> json) {
    final prenom = json['prenom']?.toString().trim();
    final nom = json['nom']?.toString().trim();
    final fullName = [prenom, nom]
        .where((value) => value?.isNotEmpty == true)
        .whereType<String>();
    return fullName.isEmpty ? 'Utilisateur' : fullName.join(' ');
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'user_name': userName,
      'user_profile_image': userProfileImage,
      'total_points': totalPoints,
      'current_level': currentLevel,
      'level_name': levelName,
      'badges_count': badgesCount,
    };
  }
}
