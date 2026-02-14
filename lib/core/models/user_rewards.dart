import 'level.dart';
import 'badge.dart';

/// Modèle représentant les récompenses d'un utilisateur
class UserRewards {
  final int totalPoints;
  final Level currentLevel;
  final int pointsToNextLevel;
  final double progressPercentage;
  final List<Badge> badges;

  UserRewards({
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.progressPercentage,
    required this.badges,
  });

  factory UserRewards.fromJson(Map<String, dynamic> json) {
    return UserRewards(
      totalPoints: json['total_points'] as int,
      currentLevel: Level.fromJson(
        json['current_level'] as Map<String, dynamic>,
      ),
      pointsToNextLevel: json['points_to_next_level'] as int,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      badges: (json['badges'] as List<dynamic>)
          .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_points': totalPoints,
      'current_level': currentLevel.toJson(),
      'points_to_next_level': pointsToNextLevel,
      'progress_percentage': progressPercentage,
      'badges': badges.map((badge) => badge.toJson()).toList(),
    };
  }

  UserRewards copyWith({
    int? totalPoints,
    Level? currentLevel,
    int? pointsToNextLevel,
    double? progressPercentage,
    List<Badge>? badges,
  }) {
    return UserRewards(
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      badges: badges ?? this.badges,
    );
  }
}
