import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/infrastructure.dart';

/// Service de directions utilisant OpenRouteService (GRATUIT)
/// 2000 requêtes/jour sans carte de crédit requise
class OpenRouteDirectionsService {
  // Clé API publique de démonstration (limitée mais fonctionnelle)
  static const String _apiKey =
      '5b3ce3597851110001cf6248d4c6c8e1ed684feab054e1d08b3e93e5';

  /// Obtenir les directions entre deux points avec OpenRouteService
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode =
        'driving-car', // driving-car, foot-walking, cycling-regular
  }) async {
    try {
      // Convertir le mode de transport
      String orsMode = _convertTravelMode(travelMode);

      final String url =
          'https://api.openrouteservice.org/v2/directions/$orsMode'
          '?start=${origin.longitude},${origin.latitude}'
          '&end=${destination.longitude},${destination.latitude}';

      print('🔗 URL OpenRouteService: $url');

      final Map<String, String> headers = {
        'Authorization': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      print('📡 Statut OpenRoute: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          print('✅ Itinéraire OpenRoute trouvé!');
          final result = _createDirectionsResultFromOpenRoute(
            data,
            origin,
            destination,
          );
          print('🗺️ Points de tracé: ${result.polylinePoints.length}');
          return result;
        } else {
          print('❌ Aucun itinéraire trouvé');
          return null;
        }
      } else {
        print('❌ Erreur HTTP OpenRoute: ${response.statusCode}');
        print('📄 Réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 Erreur OpenRouteService: $e');
      return null;
    }
  }

  /// Convertir les modes de transport
  static String _convertTravelMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'driving':
        return 'driving-car';
      case 'walking':
        return 'foot-walking';
      case 'bicycling':
        return 'cycling-regular';
      case 'transit':
        return 'driving-car'; // Pas de transport public dans OpenRoute gratuit
      default:
        return 'driving-car';
    }
  }

  /// Ouvrir Google Maps pour l'itinéraire (fallback)
  static void openInGoogleMaps(Infrastructure destination, {LatLng? origin}) {
    // Implementation pour ouvrir Google Maps externe
    print('🗺️ Ouverture Google Maps externe pour ${destination.name}');
  }

  /// Créer un DirectionsResult depuis la réponse OpenRouteService
  DirectionsResult _createDirectionsResultFromOpenRoute(
    Map<String, dynamic> json,
    LatLng origin,
    LatLng destination,
  ) {
    final feature = json['features'][0];
    final geometry = feature['geometry'];
    final properties = feature['properties'];
    final summary = properties['summary'];

    // Extraire les coordonnées de la géométrie
    final List<dynamic> coordinates = geometry['coordinates'];
    List<LatLng> polylinePoints = coordinates
        .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
        .toList();

    // Extraire les segments (étapes)
    final List<dynamic> segments = properties['segments'] ?? [];
    List<DirectionStep> steps = [];

    if (segments.isNotEmpty) {
      final segment = segments[0];
      final List<dynamic> stepsData = segment['steps'] ?? [];

      steps = stepsData.map((stepData) {
        return DirectionStep(
          instruction: stepData['instruction'] ?? 'Continuer',
          distance: '${(stepData['distance'] ?? 0).round()} m',
          duration: '${((stepData['duration'] ?? 0) / 60).round()} min',
          startLocation: polylinePoints.isNotEmpty
              ? polylinePoints.first
              : origin,
          endLocation: polylinePoints.isNotEmpty
              ? polylinePoints.last
              : destination,
          maneuver: stepData['name'] ?? '',
        );
      }).toList();
    }

    return DirectionsResult(
      polylineEncoded: '', // OpenRoute n'utilise pas de polyline encodée
      polylinePoints: polylinePoints,
      distance: '${(summary['distance'] / 1000).toStringAsFixed(1)} km',
      duration: '${(summary['duration'] / 60).round()} min',
      startAddress: 'Départ', // OpenRoute ne retourne pas d'adresses lisibles
      endAddress: 'Arrivée',
      steps: steps,
    );
  }
}

/// Classe pour les étapes de direction (réutilisée du service Google)
class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });
}

/// Classe pour les résultats de directions (réutilisée du service Google)
class DirectionsResult {
  final String polylineEncoded;
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String startAddress;
  final String endAddress;
  final List<DirectionStep> steps;

  DirectionsResult({
    required this.polylineEncoded,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.startAddress,
    required this.endAddress,
    required this.steps,
  });
}
