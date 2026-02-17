class Infrastructure {
  final String id;
  final String name;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> images;
  final Map<String, dynamic> openingHours;
  final String? phone;
  final String? website;
  final double rating;
  final int reviewCount;
  final bool isAccessible;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? submittedBy;
  final bool isVerified;

  Infrastructure({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.images = const [],
    this.openingHours = const {},
    this.phone,
    this.website,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAccessible = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.submittedBy,
    this.isVerified = false,
  });

  factory Infrastructure.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les images qui peuvent être des strings ou des objets
    List<String> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];

      final List imagesList = imagesData is List ? imagesData : [];
      return imagesList
          .map((item) {
            if (item is String) {
              return item;
            } else if (item is Map) {
              // Si c'est un objet, extraire l'URL
              return (item['url'] ?? item['uri'] ?? '').toString();
            }
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // Helper pour parser opening_hours qui peut être un objet ou null
    Map<String, dynamic> parseOpeningHours(dynamic hoursData) {
      if (hoursData == null) return {};
      if (hoursData is Map<String, dynamic>) return hoursData;
      if (hoursData is Map) return Map<String, dynamic>.from(hoursData);
      return {};
    }

    return Infrastructure(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      images: parseImages(json['images'] ?? json['photos']),
      openingHours: parseOpeningHours(
        json['opening_hours'] ?? json['horaires'],
      ),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      rating: (json['rating'] ?? json['note_moyenne'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? json['nombre_avis'] ?? 0,
      isAccessible:
          json['is_accessible'] ?? json['accessibilite']?['pmr'] ?? true,
      isActive: json['is_active'] ?? json['valide'] ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      submittedBy:
          json['submitted_by']?.toString() ?? json['cree_par']?.toString(),
      isVerified: json['is_verified'] ?? json['valide'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'images': images,
      'opening_hours': openingHours,
      'phone': phone,
      'website': website,
      'rating': rating,
      'review_count': reviewCount,
      'is_accessible': isAccessible,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'submitted_by': submittedBy,
      'is_verified': isVerified,
    };
  }

  Infrastructure copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? images,
    Map<String, dynamic>? openingHours,
    String? phone,
    String? website,
    double? rating,
    int? reviewCount,
    bool? isAccessible,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? submittedBy,
    bool? isVerified,
  }) {
    return Infrastructure(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      images: images ?? this.images,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAccessible: isAccessible ?? this.isAccessible,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'Infrastructure(id: $id, name: $name, category: $category, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Infrastructure && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
