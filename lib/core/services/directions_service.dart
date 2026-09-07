import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DirectionsService {
  /// Indicateur si la facturation Google Maps est bloquée (pour basculer directement sur OSRM)
  static bool _googleBillingDenied = false;

  /// Obtenir les directions entre deux points (Google Maps avec fallback transparent sur OSRM)
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'DRIVING',
  }) async {
    if (ApiConfig.isDebugMode) {
      print('🚀 Recherche d\'itinéraire...');
      print('📍 Origine: ${origin.latitude}, ${origin.longitude}');
      print('🎯 Destination: ${destination.latitude}, ${destination.longitude}');
      print('🚗 Mode: $travelMode');
    }

    // 1. Tenter Google Maps Directions si la clé est configurée et la facturation non bloquée
    if (!_googleBillingDenied &&
        ApiConfig.googleMapsApiKey.isNotEmpty &&
        ApiConfig.googleMapsApiKey != 'VOTRE_VRAIE_CLE_API_ICI') {
      try {
        final result = await _getGoogleDirections(
          origin: origin,
          destination: destination,
          travelMode: travelMode,
        );
        if (result != null) {
          return result;
        }
      } catch (e) {
        print('⚠️ Erreur Google Directions, bascule vers OSRM: $e');
      }
    }

    // 2. Fallback automatique et gratuit : OSRM (Open Source Routing Machine)
    print('🔄 Utilisation du service d\'itinéraire OSRM (OpenStreetMap)...');
    return await _getOsrmDirections(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }

  /// Appel de l'API Google Maps Directions
  static Future<DirectionsResult?> _getGoogleDirections({
    required LatLng origin,
    required LatLng destination,
    required String travelMode,
  }) async {
    try {
      final String url =
          '${ApiConfig.googleMapsBaseUrl}/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${travelMode.toLowerCase()}'
          '&key=${ApiConfig.googleMapsApiKey}'
          '&language=fr'
          '&units=metric';

      final Map<String, String> headers = {
        'User-Agent': 'LocalisationApp/1.0',
        'Accept': 'application/json',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              throw Exception('Timeout Google Directions');
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String status = data['status'] ?? 'UNKNOWN_ERROR';

        if (status == 'OK') {
          return _parseDirectionsResponse(data);
        }

        if (status == 'REQUEST_DENIED') {
          _googleBillingDenied = true;
          print('⚠️ Google Directions REQUEST_DENIED (Facturation requise sur Google Cloud).');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Google Directions indisponible: $e');
      return null;
    }
  }

  /// Moteur de calcul d'itinéraire OSRM (100% gratuit, OpenStreetMap)
  static Future<DirectionsResult?> _getOsrmDirections({
    required LatLng origin,
    required LatLng destination,
    required String travelMode,
  }) async {
    try {
      // Mapper le mode de transport pour OSRM (driving, bike, foot)
      String profile = 'driving';
      final modeLower = travelMode.toLowerCase();
      if (modeLower.contains('bicycl') || modeLower.contains('bike')) {
        profile = 'bike';
      } else if (modeLower.contains('walk') || modeLower.contains('foot')) {
        profile = 'foot';
      }

      // OSRM attend les coordonnées au format {longitude},{latitude}
      final coordinates =
          '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final String url =
          'https://router.project-osrm.org/route/v1/$profile/$coordinates?overview=full&geometries=polyline&steps=true';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw Exception('Timeout OSRM');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final result = _parseOsrmResponse(data, origin, destination);
          print('✅ Itinéraire OSRM calculé avec succès (${result.distance}, ${result.duration}) !');
          return result;
        }
      }

      // Si le profil spécifique (ex: bike) échoue, tenter en mode 'driving' par défaut
      if (profile != 'driving') {
        return await _getOsrmDirections(
          origin: origin,
          destination: destination,
          travelMode: 'driving',
        );
      }

      print('❌ Aucun itinéraire trouvé par OSRM');
      return null;
    } catch (e) {
      print('💥 Erreur lors du calcul d\'itinéraire OSRM: $e');
      return null;
    }
  }

  /// Parse la réponse OSRM en format unifié DirectionsResult
  static DirectionsResult _parseOsrmResponse(
    Map<String, dynamic> data,
    LatLng origin,
    LatLng destination,
  ) {
    final route = data['routes'][0];
    final String polylineEncoded = route['geometry'] as String? ?? '';
    final double distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
    final double durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;

    // Décodage de la polyline
    List<LatLng> polylinePoints = [];
    if (polylineEncoded.isNotEmpty) {
      polylinePoints = decodePolyline(polylineEncoded);
    }
    if (polylinePoints.isEmpty) {
      polylinePoints = [origin, destination];
    }

    // Formatage texte de la distance
    String distanceText;
    if (distanceMeters < 1000) {
      distanceText = '${distanceMeters.round()} m';
    } else {
      distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }

    // Formatage texte de la durée
    String durationText;
    if (durationSeconds < 60) {
      durationText = '< 1 min';
    } else if (durationSeconds < 3600) {
      durationText = '${(durationSeconds / 60).round()} min';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600 ~/ 60);
      durationText = '$hours h ${minutes > 0 ? '$minutes min' : ''}'.trim();
    }

    // Extraire les étapes
    List<DirectionStep> steps = [];
    if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
      final leg = route['legs'][0];
      if (leg['steps'] != null) {
        for (var s in leg['steps']) {
          final stepDistanceMeters = (s['distance'] as num?)?.toDouble() ?? 0.0;
          final stepDurationSec = (s['duration'] as num?)?.toDouble() ?? 0.0;
          final name = s['name'] as String? ?? '';
          final maneuverType = s['maneuver']?['type'] as String? ?? '';
          final modifier = s['maneuver']?['modifier'] as String? ?? '';
          final loc = s['maneuver']?['location'] as List?;

          LatLng stepLoc = origin;
          if (loc != null && loc.length >= 2) {
            stepLoc = LatLng(
              (loc[1] as num).toDouble(),
              (loc[0] as num).toDouble(),
            );
          }

          String instruction = name.isNotEmpty ? 'Suivre $name' : 'Continuer tout droit';
          if (maneuverType == 'depart') {
            instruction = name.isNotEmpty ? 'Prendre la direction de $name' : 'Démarrer l\'itinéraire';
          } else if (maneuverType == 'turn') {
            if (modifier == 'right' || modifier == 'sharp right') {
              instruction = name.isNotEmpty ? 'Tourner à droite sur $name' : 'Tourner à droite';
            } else if (modifier == 'slight right') {
              instruction = name.isNotEmpty ? 'Prendre légèrement à droite sur $name' : 'Prendre légèrement à droite';
            } else if (modifier == 'left' || modifier == 'sharp left') {
              instruction = name.isNotEmpty ? 'Tourner à gauche sur $name' : 'Tourner à gauche';
            } else if (modifier == 'slight left') {
              instruction = name.isNotEmpty ? 'Prendre légèrement à gauche sur $name' : 'Prendre légèrement à gauche';
            } else if (modifier == 'uturn') {
              instruction = 'Faire demi-tour';
            } else {
              instruction = name.isNotEmpty ? 'Tourner sur $name' : 'Tourner';
            }
          } else if (maneuverType == 'roundabout' || maneuverType == 'rotary') {
            instruction = name.isNotEmpty ? 'Au rond-point, suivre $name' : 'Au rond-point, prendre la sortie';
          } else if (maneuverType == 'fork') {
            instruction = modifier.contains('left') ? 'À la bifurcation, rester à gauche' : 'À la bifurcation, rester à droite';
          } else if (maneuverType == 'arrive') {
            instruction = 'Vous êtes arrivé à votre destination';
          } else if (maneuverType == 'new name' || maneuverType == 'continue') {
            instruction = name.isNotEmpty ? 'Continuer sur $name' : 'Continuer tout droit';
          }

          steps.add(
            DirectionStep(
              instruction: instruction,
              distance: stepDistanceMeters < 1000
                  ? '${stepDistanceMeters.round()} m'
                  : '${(stepDistanceMeters / 1000).toStringAsFixed(1)} km',
              duration: stepDurationSec < 60 ? '< 1 min' : '${(stepDurationSec / 60).round()} min',
              startLocation: stepLoc,
              endLocation: destination,
              maneuver: maneuverType,
            ),
          );
        }
      }
    }

    return DirectionsResult(
      polylineEncoded: polylineEncoded,
      polylinePoints: polylinePoints,
      distance: distanceText,
      duration: durationText,
      startAddress: 'Point de départ',
      endAddress: 'Destination',
      steps: steps,
    );
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
