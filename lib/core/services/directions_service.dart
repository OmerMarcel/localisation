import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DirectionsService {
  /// Obtenir les directions entre deux points
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'DRIVING',
  }) async {
    // Validation des paramètres
    if (ApiConfig.googleMapsApiKey.isEmpty ||
        ApiConfig.googleMapsApiKey == 'VOTRE_VRAIE_CLE_API_ICI') {
      print('❌ Erreur: Clé API Google Maps non configurée dans ApiConfig');
      return null;
    }

    if (ApiConfig.isDebugMode) {
      print('🧪 Test de l\'API Directions...');
      print('📍 Origine: ${origin.latitude}, ${origin.longitude}');
      print(
        '🎯 Destination: ${destination.latitude}, ${destination.longitude}',
      );
    }

    try {
      final String url =
          '${ApiConfig.googleMapsBaseUrl}/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${travelMode.toLowerCase()}'
          '&key=${ApiConfig.googleMapsApiKey}'
          '&language=fr'
          '&units=metric';

      if (ApiConfig.isDebugMode) {
        print(
          '🔗 URL de l\'API Directions: ${url.replaceAll(ApiConfig.googleMapsApiKey, 'HIDDEN_API_KEY')}',
        );
      }

      // Headers améliorés
      final Map<String, String> headers = {
        'User-Agent': 'LocalisationApp/1.0',
        'Accept': 'application/json',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            ApiConfig.apiTimeout,
            onTimeout: () {
              throw Exception('Timeout: L\'API met trop de temps à répondre');
            },
          );

      print('📡 Statut de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _parseDirectionsResponse(data);
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('📄 Corps de la réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('� Erreur lors de la récupération des directions: $e');
      return null;
    }
  }

  /// Parse la réponse de l'API avec gestion d'erreurs robuste
  static DirectionsResult? _parseDirectionsResponse(Map<String, dynamic> data) {
    try {
      print('�📋 Statut de l\'API: ${data['status']}');

      final String status = data['status'] ?? 'UNKNOWN_ERROR';

      switch (status) {
        case 'OK':
          if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
            print('✅ Directions trouvées avec succès!');
            final result = DirectionsResult.fromJson(data);
            print('🗺️ Points de polyline: ${result.polylinePoints.length}');
            return result;
          } else {
            print('❌ Aucune route trouvée');
            return null;
          }

        case 'NOT_FOUND':
          print('❌ Impossible de trouver une route entre ces points');
          break;

        case 'ZERO_RESULTS':
          print('❌ Aucun résultat trouvé pour cette requête');
          break;

        case 'MAX_WAYPOINTS_EXCEEDED':
          print('❌ Trop de points de passage dans la requête');
          break;

        case 'INVALID_REQUEST':
          print('❌ Requête invalide - vérifiez les paramètres');
          break;

        case 'OVER_DAILY_LIMIT':
        case 'OVER_QUERY_LIMIT':
          print('❌ Quota API dépassé - contactez l\'administrateur');
          break;

        case 'REQUEST_DENIED':
          print('❌ Requête refusée - vérifiez la clé API et les restrictions');
          break;

        default:
          print('❌ Erreur API inconnue: $status');
          if (data['error_message'] != null) {
            print('� Message d\'erreur: ${data['error_message']}');
          }
      }

      // Log détaillé pour déboguer (sans exposer la clé API)
      print('🔍 Réponse complète API:');
      final debugData = Map<String, dynamic>.from(data);
      print(json.encode(debugData));

      return null;
    } catch (e) {
      print('💥 Erreur lors du parsing de la réponse: $e');
      return null;
    }
  }

  /// Décoder une polyline encodée en liste de points
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      polylineCoordinates.add(p);
    }
    return polylineCoordinates;
  }
}

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

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    try {
      // Vérifications de sécurité
      if (json['routes'] == null || (json['routes'] as List).isEmpty) {
        throw Exception('Aucune route trouvée dans la réponse');
      }

      final route = json['routes'][0] as Map<String, dynamic>;

      if (route['legs'] == null || (route['legs'] as List).isEmpty) {
        throw Exception('Aucun segment de route trouvé');
      }

      final leg = route['legs'][0] as Map<String, dynamic>;

      // Vérifier la présence de la polyline
      if (route['overview_polyline'] == null ||
          route['overview_polyline']['points'] == null) {
        throw Exception('Polyline manquante dans la réponse');
      }

      final polylineEncoded = route['overview_polyline']['points'] as String;

      // Décoder la polyline avec gestion d'erreur
      List<LatLng> polylinePoints = [];
      try {
        polylinePoints = DirectionsService.decodePolyline(polylineEncoded);
      } catch (e) {
        print('⚠️ Erreur lors du décodage de la polyline: $e');
        // Continuer avec une liste vide plutôt que de planter
      }

      // Extraire les étapes avec vérification
      List<DirectionStep> steps = [];
      if (leg['steps'] != null) {
        try {
          steps = (leg['steps'] as List)
              .map(
                (step) => DirectionStep.fromJson(step as Map<String, dynamic>),
              )
              .toList();
        } catch (e) {
          print('⚠️ Erreur lors du parsing des étapes: $e');
          // Continuer avec une liste vide
        }
      }

      return DirectionsResult(
        polylineEncoded: polylineEncoded,
        polylinePoints: polylinePoints,
        distance: leg['distance']?['text'] ?? 'Distance inconnue',
        duration: leg['duration']?['text'] ?? 'Durée inconnue',
        startAddress: leg['start_address'] ?? 'Adresse de départ inconnue',
        endAddress: leg['end_address'] ?? 'Adresse d\'arrivée inconnue',
        steps: steps,
      );
    } catch (e) {
      print('💥 Erreur lors du parsing de DirectionsResult: $e');
      rethrow;
    }
  }
}

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

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    try {
      // Extraction sécurisée des coordonnées
      LatLng startLocation = const LatLng(0, 0);
      LatLng endLocation = const LatLng(0, 0);

      if (json['start_location'] != null) {
        final startLoc = json['start_location'];
        startLocation = LatLng(
          (startLoc['lat'] as num?)?.toDouble() ?? 0.0,
          (startLoc['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }

      if (json['end_location'] != null) {
        final endLoc = json['end_location'];
        endLocation = LatLng(
          (endLoc['lat'] as num?)?.toDouble() ?? 0.0,
          (endLoc['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }

      return DirectionStep(
        instruction: _removeHtmlTags(
          json['html_instructions'] ?? 'Instruction non disponible',
        ),
        distance: json['distance']?['text'] ?? 'Distance inconnue',
        duration: json['duration']?['text'] ?? 'Durée inconnue',
        startLocation: startLocation,
        endLocation: endLocation,
        maneuver: json['maneuver'] ?? '',
      );
    } catch (e) {
      print('⚠️ Erreur lors du parsing de DirectionStep: $e');
      // Retourner un step par défaut plutôt que de planter
      return DirectionStep(
        instruction: 'Erreur lors du chargement de l\'instruction',
        distance: 'N/A',
        duration: 'N/A',
        startLocation: const LatLng(0, 0),
        endLocation: const LatLng(0, 0),
        maneuver: '',
      );
    }
  }

  static String _removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
