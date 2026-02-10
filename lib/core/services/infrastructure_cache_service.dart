import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/infrastructure.dart';
import '../models/infrastructure_hive.dart';

/// Service de cache local pour les infrastructures avec Hive
/// Permet le stockage automatique et l'accès hors ligne aux marqueurs
class InfrastructureCacheService {
  static const String _boxName = 'infrastructures_cache';
  static const int _maxCacheAgeDays = 30; // Cache valide pendant 30 jours

  Box<InfrastructureHive>? _box;

  /// Initialiser le service de cache
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<InfrastructureHive>(_boxName);
      print(
        '✅ Cache Hive initialisé: ${_box!.length} infrastructures en cache',
      );
    }
  }

  /// Sauvegarder une liste d'infrastructures en cache
  Future<void> saveInfrastructures(List<Infrastructure> infrastructures) async {
    await init();

    try {
      // Convertir et sauvegarder chaque infrastructure
      final Map<String, InfrastructureHive> toSave = {};

      for (final infrastructure in infrastructures) {
        toSave[infrastructure.id] = InfrastructureHive.fromInfrastructure(
          infrastructure,
        );
      }

      // Sauvegarder en batch pour améliorer les performances
      await _box!.putAll(toSave);

      print(
        '✅ ${infrastructures.length} infrastructures sauvegardées en cache',
      );
      print('📊 Total en cache: ${_box!.length} infrastructures');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde en cache: $e');
    }
  }

  /// Sauvegarder une seule infrastructure
  Future<void> saveInfrastructure(Infrastructure infrastructure) async {
    await init();

    try {
      final hiveInfrastructure = InfrastructureHive.fromInfrastructure(
        infrastructure,
      );
      await _box!.put(infrastructure.id, hiveInfrastructure);
      print('✅ Infrastructure "${infrastructure.name}" sauvegardée en cache');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  /// Récupérer toutes les infrastructures du cache
  Future<List<Infrastructure>> getAllInfrastructures() async {
    await init();

    try {
      final List<Infrastructure> infrastructures = [];

      for (final hiveInfra in _box!.values) {
        // Vérifier si le cache n'est pas expiré
        if (_isCacheValid(hiveInfra.cachedAt)) {
          infrastructures.add(hiveInfra.toInfrastructure());
        }
      }

      print('✅ ${infrastructures.length} infrastructures récupérées du cache');
      return infrastructures;
    } catch (e) {
      print('❌ Erreur lors de la récupération du cache: $e');
      return [];
    }
  }

  /// Récupérer une infrastructure par ID
  Future<Infrastructure?> getInfrastructureById(String id) async {
    await init();

    try {
      final hiveInfra = _box!.get(id);
      if (hiveInfra != null && _isCacheValid(hiveInfra.cachedAt)) {
        return hiveInfra.toInfrastructure();
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Récupérer les infrastructures par catégorie
  Future<List<Infrastructure>> getInfrastructuresByCategory(
    String category,
  ) async {
    await init();

    try {
      final List<Infrastructure> infrastructures = [];

      for (final hiveInfra in _box!.values) {
        if (hiveInfra.category == category &&
            _isCacheValid(hiveInfra.cachedAt)) {
          infrastructures.add(hiveInfra.toInfrastructure());
        }
      }

      return infrastructures;
    } catch (e) {
      print('❌ Erreur lors du filtrage par catégorie: $e');
      return [];
    }
  }

  /// Récupérer les infrastructures dans un rayon donné
  Future<List<Infrastructure>> getInfrastructuresInRadius({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    await init();

    try {
      final List<Infrastructure> infrastructures = [];

      for (final hiveInfra in _box!.values) {
        if (!_isCacheValid(hiveInfra.cachedAt)) continue;

        final distance = _calculateDistance(
          latitude,
          longitude,
          hiveInfra.latitude,
          hiveInfra.longitude,
        );

        if (distance <= radiusKm) {
          infrastructures.add(hiveInfra.toInfrastructure());
        }
      }

      return infrastructures;
    } catch (e) {
      print('❌ Erreur lors du filtrage par rayon: $e');
      return [];
    }
  }

  /// Nettoyer le cache expiré
  Future<void> cleanExpiredCache() async {
    await init();

    try {
      final List<String> keysToDelete = [];

      for (final entry in _box!.toMap().entries) {
        if (!_isCacheValid(entry.value.cachedAt)) {
          keysToDelete.add(entry.key);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _box!.deleteAll(keysToDelete);
        print(
          '🧹 ${keysToDelete.length} infrastructures expirées supprimées du cache',
        );
      }
    } catch (e) {
      print('❌ Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Vider complètement le cache
  Future<void> clearAllCache() async {
    await init();

    try {
      await _box!.clear();
      print('🗑️ Cache complètement vidé');
    } catch (e) {
      print('❌ Erreur lors du vidage du cache: $e');
    }
  }

  /// Obtenir les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    await init();

    int totalCount = _box!.length;
    int validCount = 0;
    int expiredCount = 0;

    for (final hiveInfra in _box!.values) {
      if (_isCacheValid(hiveInfra.cachedAt)) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'total': totalCount,
      'valid': validCount,
      'expired': expiredCount,
      'categories': _getCategoriesCount(),
    };
  }

  /// Vérifier si le cache est valide
  bool _isCacheValid(DateTime cachedAt) {
    final now = DateTime.now();
    final difference = now.difference(cachedAt);
    return difference.inDays <= _maxCacheAgeDays;
  }

  /// Calculer la distance entre deux points (formule de Haversine simplifiée)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  /// Obtenir le nombre d'infrastructures par catégorie
  Map<String, int> _getCategoriesCount() {
    final Map<String, int> categories = {};

    for (final hiveInfra in _box!.values) {
      if (_isCacheValid(hiveInfra.cachedAt)) {
        categories[hiveInfra.category] =
            (categories[hiveInfra.category] ?? 0) + 1;
      }
    }

    return categories;
  }

  /// Vérifier si le cache est disponible
  bool get isCacheAvailable => _box != null && _box!.isOpen && _box!.isNotEmpty;

  /// Obtenir le nombre d'infrastructures en cache
  int get cacheCount => _box?.length ?? 0;

  /// Fermer le cache
  Future<void> dispose() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      print('🔒 Cache Hive fermé');
    }
  }
}
