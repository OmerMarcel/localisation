import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class DirectionsResult {
  final String distance;
  final String duration;
  final String startAddress;
  final String endAddress;
  final List<LatLng> polylinePoints;
  final List<DirectionStep> steps;

  DirectionsResult({
    required this.distance,
    required this.duration,
    required this.startAddress,
    required this.endAddress,
    required this.polylinePoints,
    required this.steps,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final leg = route['legs'][0];

    // Décoder les points de la polyline
    final points = decodePolyline(route['overview_polyline']['points']);
    final polylinePoints = points
        .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
        .toList();

    // Extraire les étapes
    final steps = (leg['steps'] as List)
        .map((step) => DirectionStep.fromJson(step))
        .toList();

    return DirectionsResult(
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      polylinePoints: polylinePoints,
      steps: steps,
    );
  }
}

class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    return DirectionStep(
      instruction: json['html_instructions'],
      distance: json['distance']['text'],
      duration: json['duration']['text'],
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
    );
  }
}
