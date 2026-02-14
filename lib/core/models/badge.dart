/// Modèle représentant un badge de récompense
class Badge {
  final int id;
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
    return Badge(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String,
      requiredCount: json['required_count'] as int,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
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
    int? id,
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
