/// Modèle représentant un niveau de récompense
class Level {
  final int id;
  final String name;
  final String? description;
  final int minPoints;
  final int? maxPoints;
  final String? icon;
  final String? color;

  Level({
    required this.id,
    required this.name,
    this.description,
    required this.minPoints,
    this.maxPoints,
    this.icon,
    this.color,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      minPoints: json['min_points'] as int,
      maxPoints: json['max_points'] as int?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'min_points': minPoints,
      'max_points': maxPoints,
      'icon': icon,
      'color': color,
    };
  }

  Level copyWith({
    int? id,
    String? name,
    String? description,
    int? minPoints,
    int? maxPoints,
    String? icon,
    String? color,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minPoints: minPoints ?? this.minPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
