import 'package:hive/hive.dart';
import 'infrastructure.dart';

/// Adaptateur Hive pour Infrastructure (écrit manuellement sans code generation)
class InfrastructureHiveAdapter extends TypeAdapter<InfrastructureHive> {
  @override
  final int typeId = 0;

  @override
  InfrastructureHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InfrastructureHive(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      address: fields[6] as String,
      images: (fields[7] as List?)?.cast<String>() ?? [],
      openingHours: (fields[8] as Map?)?.cast<dynamic, dynamic>() ?? {},
      phone: fields[9] as String?,
      website: fields[10] as String?,
      rating: fields[11] as double,
      reviewCount: fields[12] as int,
      isAccessible: fields[13] as bool,
      isActive: fields[14] as bool,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      submittedBy: fields[17] as String?,
      isVerified: fields[18] as bool,
      cachedAt: fields[19] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InfrastructureHive obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.images)
      ..writeByte(8)
      ..write(obj.openingHours)
      ..writeByte(9)
      ..write(obj.phone)
      ..writeByte(10)
      ..write(obj.website)
      ..writeByte(11)
      ..write(obj.rating)
      ..writeByte(12)
      ..write(obj.reviewCount)
      ..writeByte(13)
      ..write(obj.isAccessible)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.submittedBy)
      ..writeByte(18)
      ..write(obj.isVerified)
      ..writeByte(19)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfrastructureHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: 0)
class InfrastructureHive extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late double latitude;

  @HiveField(5)
  late double longitude;

  @HiveField(6)
  late String address;

  @HiveField(7)
  late List<String> images;

  @HiveField(8)
  late Map<dynamic, dynamic> openingHours;

  @HiveField(9)
  String? phone;

  @HiveField(10)
  String? website;

  @HiveField(11)
  late double rating;

  @HiveField(12)
  late int reviewCount;

  @HiveField(13)
  late bool isAccessible;

  @HiveField(14)
  late bool isActive;

  @HiveField(15)
  late DateTime createdAt;

  @HiveField(16)
  late DateTime updatedAt;

  @HiveField(17)
  String? submittedBy;

  @HiveField(18)
  late bool isVerified;

  @HiveField(19)
  late DateTime cachedAt; // Date de mise en cache

  InfrastructureHive({
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
    required this.cachedAt,
  });

  // Convertir depuis Infrastructure vers InfrastructureHive
  factory InfrastructureHive.fromInfrastructure(Infrastructure infrastructure) {
    return InfrastructureHive(
      id: infrastructure.id,
      name: infrastructure.name,
      description: infrastructure.description,
      category: infrastructure.category,
      latitude: infrastructure.latitude,
      longitude: infrastructure.longitude,
      address: infrastructure.address,
      images: infrastructure.images,
      openingHours: infrastructure.openingHours,
      phone: infrastructure.phone,
      website: infrastructure.website,
      rating: infrastructure.rating,
      reviewCount: infrastructure.reviewCount,
      isAccessible: infrastructure.isAccessible,
      isActive: infrastructure.isActive,
      createdAt: infrastructure.createdAt,
      updatedAt: infrastructure.updatedAt,
      submittedBy: infrastructure.submittedBy,
      isVerified: infrastructure.isVerified,
      cachedAt: DateTime.now(),
    );
  }

  // Convertir depuis InfrastructureHive vers Infrastructure
  Infrastructure toInfrastructure() {
    return Infrastructure(
      id: id,
      name: name,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address,
      images: images,
      openingHours: Map<String, dynamic>.from(openingHours),
      phone: phone,
      website: website,
      rating: rating,
      reviewCount: reviewCount,
      isAccessible: isAccessible,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      submittedBy: submittedBy,
      isVerified: isVerified,
    );
  }
}
