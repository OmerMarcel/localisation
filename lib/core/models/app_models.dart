/// Modèle pour les favoris des utilisateurs
class Favorite {
  final String? id;
  final String userId;
  final String contributionId;
  final DateTime createdAt;

  Favorite({
    this.id,
    required this.userId,
    required this.contributionId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['_id']?.toString(),
      userId: json['userId'] ?? '',
      contributionId: json['contributionId'] ?? '',
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'contributionId': contributionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modèle pour les commentaires
class Comment {
  final String? id;
  final String contributionId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    this.id,
    required this.contributionId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id']?.toString(),
      contributionId: json['contributionId'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt']
          : DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'contributionId': contributionId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Modèle pour l'historique utilisateur
class UserHistory {
  final String? id;
  final String userId;
  final String action; // 'view', 'search', 'contribute', 'comment', 'favorite'
  final String? targetId; // ID de la contribution ou autre
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  UserHistory({
    this.id,
    required this.userId,
    required this.action,
    this.targetId,
    this.metadata,
    required this.createdAt,
  });

  factory UserHistory.fromJson(Map<String, dynamic> json) {
    return UserHistory(
      id: json['_id']?.toString(),
      userId: json['userId'] ?? '',
      action: json['action'] ?? '',
      targetId: json['targetId'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'action': action,
      if (targetId != null) 'targetId': targetId,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modèle pour les évaluations
class Rating {
  final String? id;
  final String contributionId;
  final String userId;
  final int rating; // 1-5 étoiles
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    this.id,
    required this.contributionId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['_id']?.toString(),
      contributionId: json['contributionId'] ?? '',
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt']
          : DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'contributionId': contributionId,
      'userId': userId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Modèle pour les catégories
class Category {
  final String? id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final bool isActive;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}