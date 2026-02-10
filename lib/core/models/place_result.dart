import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceResult {
  final String placeId;
  final String name;
  final String vicinity;
  final LatLng location;
  final double rating;
  final List<String> types;
  final bool isOpen;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.location,
    required this.rating,
    required this.types,
    required this.isOpen,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      placeId: json['place_id'],
      name: json['name'],
      vicinity: json['vicinity'] ?? '',
      location: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      types: List<String>.from(json['types'] ?? []),
      isOpen: json['opening_hours']?['open_now'] ?? false,
    );
  }
}
