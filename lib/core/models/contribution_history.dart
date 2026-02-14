/// Modèle représentant l'historique des contributions d'un utilisateur
class ContributionHistory {
  final int id;
  final int userId;
  final String contributionType;
  final int pointsEarned;
  final String? relatedEntityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ContributionHistory({
    required this.id,
    required this.userId,
    required this.contributionType,
    required this.pointsEarned,
    this.relatedEntityId,
    this.details,
    required this.createdAt,
  });

  factory ContributionHistory.fromJson(Map<String, dynamic> json) {
    return ContributionHistory(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      contributionType: json['contribution_type'] as String,
      pointsEarned: json['points_earned'] as int,
      relatedEntityId: json['related_entity_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contribution_type': contributionType,
      'points_earned': pointsEarned,
      'related_entity_id': relatedEntityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Retourne une description lisible du type de contribution
  String get typeLabel {
    switch (contributionType) {
      case 'avis':
        return 'Avis';
      case 'proposition':
        return 'Proposition';
      case 'signalement':
        return 'Signalement';
      case 'proposition_approuvee':
        return 'Proposition approuvée';
      case 'bonus_admin':
        return 'Bonus administrateur';
      default:
        return contributionType;
    }
  }

  /// Retourne une icône appropriée pour le type de contribution
  String get icon {
    switch (contributionType) {
      case 'avis':
        return '⭐';
      case 'proposition':
        return '💡';
      case 'signalement':
        return '⚠️';
      case 'proposition_approuvee':
        return '✅';
      case 'bonus_admin':
        return '🎁';
      default:
        return '📝';
    }
  }

  ContributionHistory copyWith({
    int? id,
    int? userId,
    String? contributionType,
    int? pointsEarned,
    String? relatedEntityId,
    Map<String, dynamic>? details,
    DateTime? createdAt,
  }) {
    return ContributionHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contributionType: contributionType ?? this.contributionType,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Modèle pour la pagination de l'historique
class ContributionHistoryPage {
  final List<ContributionHistory> contributions;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  ContributionHistoryPage({
    required this.contributions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory ContributionHistoryPage.fromJson(Map<String, dynamic> json) {
    return ContributionHistoryPage(
      contributions: (json['contributions'] as List<dynamic>)
          .map(
            (item) =>
                ContributionHistory.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contributions': contributions.map((c) => c.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}
