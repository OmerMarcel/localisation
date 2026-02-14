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
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userProfileImage: json['user_profile_image'] as String?,
      totalPoints: json['total_points'] as int,
      currentLevel: json['current_level'] as int,
      levelName: json['level_name'] as String,
      badgesCount: json['badges_count'] as int,
    );
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
