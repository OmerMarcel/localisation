abstract class Favorite {
  String get id;
  String get name;
  String? get address;
  String? get category;
  double? get latitude;
  double? get longitude;
}

class FavoriteImpl implements Favorite {
  @override
  final String id;

  @override
  final String name;

  @override
  final String? address;

  @override
  final String? category;

  @override
  final double? latitude;

  @override
  final double? longitude;

  const FavoriteImpl({
    required this.id,
    required this.name,
    this.address,
    this.category,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory FavoriteImpl.fromJson(Map<String, dynamic> json) {
    return FavoriteImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      category: json['category'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }
}
