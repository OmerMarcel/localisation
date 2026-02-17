import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/infrastructure.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  List<Infrastructure>? _cachedInfrastructures;

  /// Charge les données d'exemple depuis les assets
  Future<List<Infrastructure>> loadSampleInfrastructures() async {
    if (_cachedInfrastructures != null) {
      return _cachedInfrastructures!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/sample_infrastructures.json',
      );
      if (jsonString.trim().isEmpty) {
        print(
          'Erreur lors du chargement des donnees d\'exemple: fichier JSON vide',
        );
        return [];
      }
      final dynamic decoded = json.decode(jsonString);
      final List<dynamic> jsonList =
          decoded is List ? decoded : (decoded['data'] as List? ?? []);

      _cachedInfrastructures = jsonList
          .map((json) => Infrastructure.fromJson(json))
          .toList();

      return _cachedInfrastructures!;
    } catch (e) {
      print('Erreur lors du chargement des données d\'exemple: $e');
      return [];
    }
  }

  /// Filtre les infrastructures par catégorie
  List<Infrastructure> filterByCategory(
    List<Infrastructure> infrastructures,
    String category,
  ) {
    return infrastructures
        .where((infrastructure) => infrastructure.category == category)
        .toList();
  }

  /// Recherche d'infrastructures par nom ou description
  List<Infrastructure> searchInfrastructures(
    List<Infrastructure> infrastructures,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();
    return infrastructures.where((infrastructure) {
      return infrastructure.name.toLowerCase().contains(lowerQuery) ||
          infrastructure.description.toLowerCase().contains(lowerQuery) ||
          infrastructure.address.toLowerCase().contains(lowerQuery) ||
          infrastructure.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Trie les infrastructures par distance (nécessite la position de l'utilisateur)
  List<Infrastructure> sortByDistance(
    List<Infrastructure> infrastructures,
    double userLatitude,
    double userLongitude,
  ) {
    infrastructures.sort((a, b) {
      final distanceA = _calculateDistance(
        userLatitude,
        userLongitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = _calculateDistance(
        userLatitude,
        userLongitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    return infrastructures;
  }

  /// Calcule la distance entre deux points (formule de Haversine simplifiée)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLon = (lon2 - lon1) * (3.14159 / 180);

    final double a =
        (dLat / 2).abs() * (dLat / 2).abs() +
        (lat1 * 3.14159 / 180).abs() *
            (lat2 * 3.14159 / 180).abs() *
            (dLon / 2).abs() *
            (dLon / 2).abs();

    final double c = 2 * (a.abs()).abs();
    return earthRadius * c;
  }

  /// Simule l'ajout d'une nouvelle infrastructure
  Future<bool> addInfrastructure(Infrastructure infrastructure) async {
    // Simulation d'un délai réseau
    await Future.delayed(const Duration(seconds: 2));

    if (_cachedInfrastructures != null) {
      _cachedInfrastructures!.add(infrastructure);
    }

    // Simulation d'un succès à 90%
    return DateTime.now().millisecond % 10 != 0;
  }

  /// Simule la mise à jour d'une infrastructure
  Future<bool> updateInfrastructure(Infrastructure infrastructure) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_cachedInfrastructures != null) {
      final index = _cachedInfrastructures!.indexWhere(
        (i) => i.id == infrastructure.id,
      );
      if (index != -1) {
        _cachedInfrastructures![index] = infrastructure;
        return true;
      }
    }

    return false;
  }

  /// Simule la suppression d'une infrastructure
  Future<bool> deleteInfrastructure(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_cachedInfrastructures != null) {
      _cachedInfrastructures!.removeWhere((i) => i.id == id);
      return true;
    }

    return false;
  }

  /// Nettoie le cache
  void clearCache() {
    _cachedInfrastructures = null;
  }

  /// Obtient une infrastructure par ID
  Infrastructure? getInfrastructureById(String id) {
    if (_cachedInfrastructures == null) return null;

    try {
      return _cachedInfrastructures!.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les infrastructures dans un rayon donné
  List<Infrastructure> getInfrastructuresInRadius(
    List<Infrastructure> infrastructures,
    double centerLatitude,
    double centerLongitude,
    double radiusInMeters,
  ) {
    return infrastructures.where((infrastructure) {
      final distance = _calculateDistance(
        centerLatitude,
        centerLongitude,
        infrastructure.latitude,
        infrastructure.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Simule des statistiques d'utilisation
  Map<String, dynamic> getUsageStats() {
    return {
      'total_infrastructures': _cachedInfrastructures?.length ?? 0,
      'categories_count': _getCategoriesCount(),
      'average_rating': _getAverageRating(),
      'most_popular_category': _getMostPopularCategory(),
    };
  }

  Map<String, int> _getCategoriesCount() {
    if (_cachedInfrastructures == null) return {};

    final Map<String, int> counts = {};
    for (final infrastructure in _cachedInfrastructures!) {
      counts[infrastructure.category] =
          (counts[infrastructure.category] ?? 0) + 1;
    }
    return counts;
  }

  double _getAverageRating() {
    if (_cachedInfrastructures == null || _cachedInfrastructures!.isEmpty)
      return 0.0;

    final total = _cachedInfrastructures!.fold<double>(
      0.0,
      (sum, infrastructure) => sum + infrastructure.rating,
    );
    return total / _cachedInfrastructures!.length;
  }

  String _getMostPopularCategory() {
    final counts = _getCategoriesCount();
    if (counts.isEmpty) return 'Aucune';

    String mostPopular = counts.keys.first;
    int maxCount = counts.values.first;

    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostPopular = entry.key;
      }
    }

    return mostPopular;
  }
}
