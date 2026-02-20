class Contribution {
  final String? id;
  final String userId;
  final String name;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> images;
  final Map<String, dynamic> openingHours;
  final List<String> equipments;
  final String? phone;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? status; // 'pending', 'validated', 'rejected'

  Contribution({
    this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.images,
    required this.openingHours,
    required this.equipments,
    this.phone,
    this.website,
    required this.createdAt,
    required this.updatedAt,
    this.status,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final localisationRaw =
        (json['localisation'] ?? json['coordonnees'])
            as Map<String, dynamic>? ??
        <String, dynamic>{};
    final coordinates = localisationRaw['coordinates'];
    final List<dynamic> coordinatesList = coordinates is List
        ? List<dynamic>.from(coordinates)
        : <dynamic>[];

    final double latitude =
        _toDouble(json['latitude']) ??
        _toDouble(coordinatesList.length > 1 ? coordinatesList[1] : null) ??
        _toDouble(localisationRaw['latitude']) ??
        0.0;

    final double longitude =
        _toDouble(json['longitude']) ??
        _toDouble(coordinatesList.isNotEmpty ? coordinatesList[0] : null) ??
        _toDouble(localisationRaw['longitude']) ??
        0.0;

    final address =
        json['quartier'] ??
        localisationRaw['quartier'] ??
        json['address'] ??
        localisationRaw['adresse'] ??
        localisationRaw['address'] ??
        json['adresse'] ??
        '';

    final dynamic rawImages = json['images'] ?? json['photos'] ?? [];
    final images = rawImages is List
        ? rawImages.map((image) => image.toString()).toList()
        : <String>[];

    final openingHoursSource = json['openingHours'] ?? json['horaires'];
    final openingHoursRaw = openingHoursSource is Map
        ? Map<String, dynamic>.from(openingHoursSource)
        : <String, dynamic>{};

    final contactSource = json['contact'];
    final Map<String, dynamic> contact = contactSource is Map
        ? Map<String, dynamic>.from(contactSource)
        : <String, dynamic>{};

    final dynamic rawEquipments =
        json['equipements'] ?? json['equipments'] ?? [];
    final equipments = rawEquipments is List
        ? rawEquipments.map((equip) => equip.toString()).toList()
        : <String>[];

    final userSource =
        json['userId'] ??
        json['proposePar'] ??
        (json['propose_par'] is Map
            ? json['propose_par']['id']
            : json['propose_par']);

    return Contribution(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: userSource?.toString() ?? '',
      name: json['name'] ?? json['nom'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? json['type'] ?? '',
      latitude: latitude,
      longitude: longitude,
      address: address,
      images: images,
      openingHours: openingHoursRaw,
      equipments: equipments,
      phone: json['phone']?.toString() ?? contact['telephone']?.toString(),
      website: json['website']?.toString() ?? contact['website']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? json['statut']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final localisationPayload = {
      'type': 'Point',
      'coordinates': [longitude, latitude],
      'adresse': address,
      'quartier': address,
    };

    final contactPayload = <String, dynamic>{
      if (phone != null && phone!.isNotEmpty) 'telephone': phone,
      if (website != null && website!.isNotEmpty) 'website': website,
    };

    return {
      if (id != null) 'id': id,
      'userId': userId,
      'propose_par': userId,
      'name': name,
      'nom': name,
      'description': description,
      'category': category,
      'type': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'quartier': address,
      'localisation': localisationPayload,
      'images': images,
      'photos': images,
      'openingHours': openingHours,
      'horaires': openingHours,
      'equipements': equipments,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (contactPayload.isNotEmpty) 'contact': contactPayload,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (status != null) 'status': status,
    };
  }
}
