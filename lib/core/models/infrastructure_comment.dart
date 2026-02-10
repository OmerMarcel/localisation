class InfrastructureComment {
  final String id;
  final String infrastructureId;
  final String authorId;
  final String authorName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final int likes;
  final int dislikes;

  InfrastructureComment({
    required this.id,
    required this.infrastructureId,
    required this.authorId,
    required this.authorName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.likes = 0,
    this.dislikes = 0,
  });

  factory InfrastructureComment.fromJson(Map<String, dynamic> json) {
    return InfrastructureComment(
      id: json['id'] ?? '',
      infrastructureId: json['infrastructure_id'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? 'Utilisateur anonyme',
      comment: json['comment'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isVerified: json['is_verified'] ?? false,
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'infrastructure_id': infrastructureId,
      'author_id': authorId,
      'author_name': authorName,
      'comment': comment,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_verified': isVerified,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  InfrastructureComment copyWith({
    String? id,
    String? infrastructureId,
    String? authorId,
    String? authorName,
    String? comment,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    int? likes,
    int? dislikes,
  }) {
    return InfrastructureComment(
      id: id ?? this.id,
      infrastructureId: infrastructureId ?? this.infrastructureId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }

  @override
  String toString() {
    return 'InfrastructureComment(id: $id, infrastructureId: $infrastructureId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfrastructureComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
