/// Modèle représentant un badge de récompense
class Badge {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? imageUrl;
  final String category;
  final int requiredCount;
  final String? color;
  final bool isActive;

  Badge({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.imageUrl,
    required this.category,
    required this.requiredCount,
    this.color,
    this.isActive = true,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['id'] ?? json['badge_code'] ?? json['badgeId'] ?? json['code'];
    final criteria = json['criteria_json'] as Map<String, dynamic>?;

    return Badge(
      id: rawId?.toString() ?? (json['name']?.toString() ?? 'unknown'),
      name: (json['name'] ?? json['badge_name']).toString(),
      description: json['description'] as String?,
      icon: (json['icon'] ?? json['badge_icon']) as String?,
      imageUrl: json['image_url'] as String?,
      category: (json['category'] ?? criteria?['type'] ?? 'general').toString(),
      requiredCount: _parseInt(json['required_count'] ?? criteria?['count']),
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'image_url': imageUrl,
      'category': category,
      'required_count': requiredCount,
      'color': color,
      'is_active': isActive,
    };
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    String? category,
    int? requiredCount,
    String? color,
    bool? isActive,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      requiredCount: requiredCount ?? this.requiredCount,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}
