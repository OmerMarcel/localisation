import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../models/infrastructure.dart';

enum TravelMode { driving, walking, bicycling, transit }

class GoogleMapsService {
  static const String _baseUrl = 'https://www.google.com/maps';

  // Clé pour l'API Directions (appels web)
  static const String _directionsApiKey = 'VOTRE_CLE_API_DIRECTIONS';

  // Clé pour Maps SDK (à garder dans AndroidManifest.xml)
  // static const String _mapsApiKey = 'VOTRE_CLE_API_MAPS_SDK';

  /// Ouvre Google Maps avec l'itinéraire vers une infrastructure
  static Future<void> openDirections(
    Infrastructure infrastructure, {
    double? fromLatitude,
    double? fromLongitude,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    String url;
    String mode = _getTravelModeString(travelMode);

    if (fromLatitude != null && fromLongitude != null) {
      // Itinéraire depuis la position actuelle
      url =
          '$_baseUrl/dir/?api=1&origin=$fromLatitude,$fromLongitude&destination=${infrastructure.latitude},${infrastructure.longitude}&travelmode=$mode';
    } else {
      // Juste la destination
      url =
          '$_baseUrl/?q=${infrastructure.latitude},${infrastructure.longitude}';
    }

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Impossible d\'ouvrir Google Maps');
    }
  }

  /// Convertit le mode de transport en string pour Google Maps
  static String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }

  /// Estime le temps de trajet selon le mode de transport
  static String estimateTravelTime(double distanceKm, TravelMode mode) {
    double timeMinutes;

    switch (mode) {
      case TravelMode.driving:
        timeMinutes = distanceKm * 2.5; // ~24 km/h en ville
        break;
      case TravelMode.walking:
        timeMinutes = distanceKm * 12; // ~5 km/h
        break;
      case TravelMode.bicycling:
        timeMinutes = distanceKm * 4; // ~15 km/h
        break;
      case TravelMode.transit:
        timeMinutes = distanceKm * 3.5; // ~17 km/h avec attentes
        break;
    }

    if (timeMinutes < 60) {
      return '${timeMinutes.round()} min';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = (timeMinutes % 60).round();
      return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}';
    }
  }

  /// Retourne l'icône appropriée pour le mode de transport
  static String getTravelModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return '🚗';
      case TravelMode.walking:
        return '🚶';
      case TravelMode.bicycling:
        return '🚴';
      case TravelMode.transit:
        return '🚌';
    }
  }

  /// Ouvre Google Maps avec une recherche pour une infrastructure
  static Future<void> searchLocation(Infrastructure infrastructure) async {
    final query = Uri.encodeComponent(
      '${infrastructure.name} ${infrastructure.address}',
    );
    final url = '$_baseUrl/search/?api=1&query=$query';

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Impossible d\'ouvrir Google Maps');
    }
  }

  /// Partage une localisation via l'infrastructure
  static String generateShareText(Infrastructure infrastructure) {
    return '''
📍 ${infrastructure.name}
🏷️ ${infrastructure.category}
📍 ${infrastructure.address}
🗺️ Voir sur Google Maps: https://www.google.com/maps/?q=${infrastructure.latitude},${infrastructure.longitude}

Via l'app Géolocalisation Cotonou 🇧🇯
''';
  }

  /// Génère une URL Google Maps statique pour une image de carte
  static String generateStaticMapUrl(
    Infrastructure infrastructure, {
    int width = 400,
    int height = 400,
    int zoom = 15,
    String? apiKey,
  }) {
    final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    final params = [
      'center=${infrastructure.latitude},${infrastructure.longitude}',
      'zoom=$zoom',
      'size=${width}x$height',
      'markers=color:red%7C${infrastructure.latitude},${infrastructure.longitude}',
      'maptype=roadmap',
      // Utilise la clé Directions pour les appels web
      'key=${apiKey ?? _directionsApiKey}',
    ];

    return '$baseUrl?${params.join('&')}';
  }

  /// Calcule la distance entre deux points (formule Haversine)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
