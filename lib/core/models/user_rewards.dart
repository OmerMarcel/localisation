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
    final currentLevelJson =
        (json['current_level'] as Map<String, dynamic>?) ?? {};
    final pointsToNextLevel =
        json['points_to_next_level'] ?? currentLevelJson['points_to_next_level'];
    final progressPercentage =
        json['progress_percentage'] ?? currentLevelJson['progress_percentage'];

    return UserRewards(
      totalPoints: json['total_points'] as int,
      currentLevel: Level.fromJson(currentLevelJson),
      pointsToNextLevel: pointsToNextLevel is int
          ? pointsToNextLevel
          : int.tryParse(pointsToNextLevel.toString()) ?? 0,
      progressPercentage: _parseDouble(progressPercentage),
        badges: ((json['badges'] as List<dynamic>?) ?? [])
          .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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
