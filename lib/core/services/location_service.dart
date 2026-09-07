import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isLocationServiceEnabled = false;

  Position? get currentPosition => _currentPosition;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  /// Vérifie et demande l'activation du GPS et des permissions dès le lancement de l'application
  Future<bool> ensureLocationReady(BuildContext context) async {
    try {
      // 1. Vérifier si les permissions sont déjà accordées ou les demander
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 2. Vérifier si le GPS / Service de localisation est allumé sur le téléphone
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled && context.mounted) {
        final bool? shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Activer la localisation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Pour vous localiser sur la carte et afficher les infrastructures et services publics autour de vous à Cotonou, veuillez allumer votre GPS.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Allumer le GPS'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldOpen == true) {
          await Geolocator.openLocationSettings();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('⚠️ Erreur ensureLocationReady: $e');
      return false;
    }
  }

  /// Vérifie et demande les permissions de localisation
  Future<bool> requestLocationPermission() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Les permissions sont définitivement refusées
        await openAppSettings();
        return false;
      }

      // Vérifier si le service de localisation est activé
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        return false;
      }

      return true;
    } catch (e) {
      print('Erreur lors de la demande de permission de localisation: $e');
      return false;
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return _currentPosition;
    } catch (e) {
      print('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Écoute les changements de position
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    );
  }

  /// Calcule la distance entre deux points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calcule le bearing entre deux points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Vérifie si une position est dans un rayon donné
  bool isWithinRadius(
    Position userPosition,
    double targetLatitude,
    double targetLongitude,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInMeters;
  }

  /// Ouvre les paramètres de localisation du système
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Formate la distance pour l'affichage
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
