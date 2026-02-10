import 'package:flutter/material.dart';

/// Modèle pour les activités utilisateur
enum UserActivityType {
  infrastructureViewed,
  favoriteAdded,
  favoriteRemoved,
  contributionCreated,
  contributionUpdated,
  searchPerformed,
  commentAdded,
  reportSubmitted,
  routeCalculated,
}

extension UserActivityTypeExtension on UserActivityType {
  String get label {
    switch (this) {
      case UserActivityType.infrastructureViewed:
        return 'Infrastructure consultée';
      case UserActivityType.favoriteAdded:
        return 'Favori ajouté';
      case UserActivityType.favoriteRemoved:
        return 'Favori retiré';
      case UserActivityType.contributionCreated:
        return 'Contribution créée';
      case UserActivityType.contributionUpdated:
        return 'Contribution modifiée';
      case UserActivityType.searchPerformed:
        return 'Recherche effectuée';
      case UserActivityType.commentAdded:
        return 'Commentaire ajouté';
      case UserActivityType.reportSubmitted:
        return 'Signalement soumis';
      case UserActivityType.routeCalculated:
        return 'Itinéraire calculé';
    }
  }

  IconData get icon {
    switch (this) {
      case UserActivityType.infrastructureViewed:
        return Icons.location_on;
      case UserActivityType.favoriteAdded:
        return Icons.star;
      case UserActivityType.favoriteRemoved:
        return Icons.star_border;
      case UserActivityType.contributionCreated:
        return Icons.add_location;
      case UserActivityType.contributionUpdated:
        return Icons.edit_location;
      case UserActivityType.searchPerformed:
        return Icons.search;
      case UserActivityType.commentAdded:
        return Icons.comment;
      case UserActivityType.reportSubmitted:
        return Icons.report;
      case UserActivityType.routeCalculated:
        return Icons.directions;
    }
  }
}

class UserActivity {
  final String id;
  final String? userId;
  final UserActivityType type;
  final String? targetId; // ID de l'infrastructure, contribution, etc.
  final String? targetName; // Nom de l'infrastructure, contribution, etc.
  final Map<String, dynamic>? metadata; // Données supplémentaires
  final DateTime createdAt;

  UserActivity({
    required this.id,
    this.userId,
    required this.type,
    this.targetId,
    this.targetName,
    this.metadata,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      type: UserActivityType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => UserActivityType.infrastructureViewed,
      ),
      targetId: json['targetId'] as String?,
      targetName: json['targetName'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'type': type.toString(),
      if (targetId != null) 'targetId': targetId,
      if (targetName != null) 'targetName': targetName,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserActivity copyWith({
    String? id,
    String? userId,
    UserActivityType? type,
    String? targetId,
    String? targetName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

