import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../models/infrastructure.dart';
import '../models/contribution.dart';
import '../models/avis.dart';
import '../models/user_activity.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/mock_data_service.dart';
import '../services/infrastructure_cache_service.dart';
import '../../features/profile/profile_screen.dart'
    show userProvider, UserState;

// Provider pour le service de localisation
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Provider pour le service de données de test
final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService();
});

// Provider pour le service de cache local
final infrastructureCacheServiceProvider = Provider<InfrastructureCacheService>(
  (ref) {
    return InfrastructureCacheService();
  },
);

// Provider pour la position actuelle
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentPosition();
});

// Provider pour le stream de position
final positionStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
});

// Provider pour les infrastructures
class InfrastructuresNotifier
    extends StateNotifier<AsyncValue<List<Infrastructure>>> {
  InfrastructuresNotifier(
    this._apiService,
    this._storageService,
    this._mockDataService,
    this._cacheService,
  ) : super(const AsyncValue.loading()) {
    loadInfrastructures();
  }

  final ApiService _apiService;
  final StorageService _storageService;
  final MockDataService _mockDataService;
  final InfrastructureCacheService _cacheService;

  Future<void> loadInfrastructures({
    String? category,
    double? latitude,
    double? longitude,
    double? radius,
    int? limit,
    bool preserveState = false, // Ne pas vider l'état si true
  }) async {
    try {
      // Ne pas passer en loading si on veut préserver l'état (pour éviter de supprimer les marqueurs)
      if (!preserveState) {
        state = const AsyncValue.loading();
      }

      List<Infrastructure> infrastructures;

      try {
        // 1. Essayer de charger depuis l'API
        print('🌐 [Provider] Tentative de chargement depuis API backend...');
        infrastructures = await _apiService.getInfrastructures(
          category: category,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          limit: limit,
        );

        // 2. ✅ SAUVEGARDER AUTOMATIQUEMENT EN CACHE LOCAL
        if (infrastructures.isNotEmpty) {
          await _cacheService.saveInfrastructures(infrastructures);
          print(
            '💾 ${infrastructures.length} marqueurs sauvegardés automatiquement en cache local',
          );
        }
      } catch (e, stackTrace) {
        print('⚠️ API non disponible: $e');
        print('📍 StackTrace: $stackTrace');
        print('🔄 Tentative de chargement depuis le cache local...');

        // 3. Charger depuis le cache local Hive en priorité
        if (latitude != null && longitude != null && radius != null) {
          infrastructures = await _cacheService.getInfrastructuresInRadius(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radius,
          );
        } else if (category != null) {
          infrastructures = await _cacheService.getInfrastructuresByCategory(
            category,
          );
        } else {
          infrastructures = await _cacheService.getAllInfrastructures();
        }

        // 4. Si le cache est vide, utiliser les données de test
        if (infrastructures.isEmpty) {
          print('📋 Cache vide, utilisation des données de test...');
          infrastructures = await _mockDataService.loadSampleInfrastructures();

          // Appliquer les filtres localement
          if (category != null) {
            infrastructures = _mockDataService.filterByCategory(
              infrastructures,
              category,
            );
          }

          if (latitude != null && longitude != null && radius != null) {
            infrastructures = _mockDataService.getInfrastructuresInRadius(
              infrastructures,
              latitude,
              longitude,
              radius,
            );
          }
        } else {
          print(
            '✅ ${infrastructures.length} marqueurs chargés depuis le cache local (MODE HORS LIGNE)',
          );
        }
      }

      // Sauvegarder pour un usage hors ligne (ancien système, conservé en backup)
      await _storageService.saveOfflineData(infrastructures);

      state = AsyncValue.data(infrastructures);
    } catch (error, stackTrace) {
      // En cas d'erreur, essayer de charger les données hors ligne
      final offlineData = _storageService.getOfflineData();
      if (offlineData.isNotEmpty) {
        state = AsyncValue.data(offlineData);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> searchInfrastructures(String query) async {
    try {
      state = const AsyncValue.loading();

      List<Infrastructure> infrastructures;

      try {
        // Essayer la recherche via l'API
        infrastructures = await _apiService.searchInfrastructures(query);
      } catch (e) {
        // En cas d'erreur, recherche locale
        print('Recherche API non disponible, recherche locale: $e');
        final allInfrastructures = await _mockDataService
            .loadSampleInfrastructures();
        infrastructures = _mockDataService.searchInfrastructures(
          allInfrastructures,
          query,
        );
      }

      state = AsyncValue.data(infrastructures);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void filterByCategory(String category) {
    state.whenData((infrastructures) {
      final filtered = infrastructures
          .where((i) => i.category == category)
          .toList();
      state = AsyncValue.data(filtered);
    });
  }

  void filterByDistance(Position userPosition, double maxDistance) {
    state.whenData((infrastructures) {
      final locationService = LocationService();
      final filtered = infrastructures.where((infrastructure) {
        final distance = locationService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          infrastructure.latitude,
          infrastructure.longitude,
        );
        return distance <= maxDistance;
      }).toList();

      // Trier par distance
      filtered.sort((a, b) {
        final distanceA = locationService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = locationService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      state = AsyncValue.data(filtered);
    });
  }

  Future<void> refresh() async {
    await loadInfrastructures();
  }
}

final infrastructuresProvider =
    StateNotifierProvider<
      InfrastructuresNotifier,
      AsyncValue<List<Infrastructure>>
    >((ref) {
      final apiService = ref.read(apiServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final mockDataService = ref.read(mockDataServiceProvider);
      final cacheService = ref.read(infrastructureCacheServiceProvider);
      return InfrastructuresNotifier(
        apiService,
        storageService,
        mockDataService,
        cacheService,
      );
    });

// Provider pour les services
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final avisProvider = FutureProvider.family<List<Avis>, String>((
  ref,
  infrastructureId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAvis(infrastructureId);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider pour les favoris
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier(this._storageService, this._apiService, this._ref)
    : super([]) {
    _loadFavorites();
    // Écouter les changements d'utilisateur pour recharger les favoris
    _ref.listen<UserState>(userProvider, (previous, next) {
      // Si l'utilisateur a changé (connexion/déconnexion), recharger les favoris
      if (previous?.uid != next.uid) {
        _loadFavorites();
        // Invalider le provider des infrastructures favorites
        _ref.invalidate(favoriteInfrastructuresProvider);
      }
    });
  }

  final StorageService _storageService;
  final ApiService _apiService;
  final Ref _ref;

  String? get _userId {
    final userState = _ref.read(userProvider);
    return userState.uid;
  }

  void _loadFavorites() {
    state = _storageService.getFavorites(userId: _userId);
  }

  /// Recharge les favoris depuis le stockage (utile après changement d'utilisateur)
  void reloadFavorites() {
    _loadFavorites();
  }

  Future<void> toggleFavorite(String infrastructureId) async {
    if (state.contains(infrastructureId)) {
      await removeFavorite(infrastructureId);
    } else {
      await addFavorite(infrastructureId);
    }
  }

  Future<void> addFavorite(String infrastructureId) async {
    try {
      final isValidUUID = _isValidUUID(infrastructureId);
      print(
        '❤️ Ajout du favori $infrastructureId... (UUID valide: $isValidUUID)',
      );

      // Ajouter au backend seulement si l'ID est un UUID valide et l'utilisateur est connecté
      final userState = _ref.read(userProvider);
      if (userState.isLoggedIn && isValidUUID) {
        try {
          print('📤 Envoi au backend pour l\'utilisateur ${userState.uid}...');
          await _apiService.addToFavorites(infrastructureId);
          print('✅ Favori ajouté au backend avec succès');
        } catch (e) {
          print('⚠️ Erreur lors de l\'envoi au backend: $e');
          // Continuer pour ajouter localement même en cas d'erreur backend
        }
      } else if (userState.isLoggedIn && !isValidUUID) {
        print(
          '⚠️ ID "$infrastructureId" n\'est pas un UUID valide. Ajout local uniquement (non synchronisé avec le backend).',
        );
      } else {
        print('⚠️ Utilisateur non connecté, ajout local uniquement');
      }

      // Toujours ajouter localement (même si ce n'est pas un UUID)
      await _storageService.addToFavorites(infrastructureId, userId: _userId);
      state = [...state, infrastructureId];
      print('✅ Favori ajouté localement (total: ${state.length})');

      // Invalider le provider des infrastructures favorites pour forcer le rafraîchissement
      // Utiliser un délai pour éviter la dépendance circulaire
      Future.microtask(() {
        _ref.invalidate(favoriteInfrastructuresProvider);
      });
      print('🔄 Provider des favoris invalidé pour rafraîchissement');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du favori: $e');
      // En cas d'erreur inattendue, essayer quand même d'ajouter localement
      try {
        await _storageService.addToFavorites(infrastructureId, userId: _userId);
        state = [...state, infrastructureId];
        print('⚠️ Favori ajouté localement malgré l\'erreur');
        Future.microtask(() {
          _ref.invalidate(favoriteInfrastructuresProvider);
        });
      } catch (localError) {
        print('❌ Erreur critique lors de l\'ajout local: $localError');
        rethrow;
      }
    }
  }

  Future<void> removeFavorite(String infrastructureId) async {
    try {
      print('💔 Retrait du favori $infrastructureId...');

      // Retirer du backend si l'utilisateur est connecté
      final userState = _ref.read(userProvider);
      if (userState.isLoggedIn && _isValidUUID(infrastructureId)) {
        print('📤 Envoi de la suppression au backend...');
        await _apiService.removeFromFavorites(infrastructureId);
        print('✅ Favori retiré du backend avec succès');
      }

      // Retirer localement
      await _storageService.removeFromFavorites(
        infrastructureId,
        userId: _userId,
      );
      state = state.where((id) => id != infrastructureId).toList();
      print('✅ Favori retiré localement (total: ${state.length})');

      // Invalider le provider des infrastructures favorites pour forcer le rafraîchissement
      // Utiliser un délai pour éviter la dépendance circulaire
      Future.microtask(() {
        _ref.invalidate(favoriteInfrastructuresProvider);
      });
      print('🔄 Provider des favoris invalidé pour rafraîchissement');
    } catch (e) {
      print('❌ Erreur lors du retrait du favori: $e');
      // En cas d'erreur, retirer localement quand même
      await _storageService.removeFromFavorites(
        infrastructureId,
        userId: _userId,
      );
      state = state.where((id) => id != infrastructureId).toList();
      print('⚠️ Favori retiré localement malgré l\'erreur réseau');
      // Invalider le provider des infrastructures favorites pour forcer le rafraîchissement
      // Utiliser un délai pour éviter la dépendance circulaire
      Future.microtask(() {
        _ref.invalidate(favoriteInfrastructuresProvider);
      });
    }
  }

  bool isFavorite(String infrastructureId) {
    return state.contains(infrastructureId);
  }

  void clearAllFavorites() {
    // Supprimer tous les favoris
    state = [];
    final favorites = _storageService.getFavorites(userId: _userId);
    for (final id in favorites) {
      _storageService.removeFromFavorites(id, userId: _userId);
    }
    // Invalider le provider des infrastructures favorites pour forcer le rafraîchissement
    // Utiliser un délai pour éviter la dépendance circulaire
    Future.microtask(() {
      _ref.invalidate(favoriteInfrastructuresProvider);
    });
  }

  /// Valide si une chaîne est un UUID valide
  bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
      final storageService = ref.read(storageServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      return FavoritesNotifier(storageService, apiService, ref);
    });

// Provider pour les infrastructures favorites complètes
// Ce provider se rafraîchit automatiquement quand la liste des IDs de favoris change
final favoriteInfrastructuresProvider = FutureProvider<List<Infrastructure>>((
  ref,
) async {
  final apiService = ref.read(apiServiceProvider);
  final storageService = ref.read(storageServiceProvider);
  final mockDataService = ref.read(mockDataServiceProvider);
  final userState = ref.watch(userProvider);

  // Récupérer les IDs des favoris (utiliser read au lieu de watch pour éviter la dépendance circulaire)
  // Le rafraîchissement sera déclenché manuellement via invalidate dans les méthodes addFavorite/removeFavorite
  final favoriteIds = ref.read(favoritesProvider);

  if (favoriteIds.isEmpty) {
    print('📭 Aucun favori trouvé');
    return [];
  }

  print('🔍 Recherche de ${favoriteIds.length} favori(s)...');

  // Liste pour combiner toutes les sources d'infrastructures
  List<Infrastructure> allInfrastructures = [];
  Set<String> foundIds = {};

  // 1. Si l'utilisateur est connecté, essayer de charger depuis le backend
  if (userState.isLoggedIn) {
    try {
      final backendFavorites = await apiService.getUserFavorites();
      allInfrastructures.addAll(backendFavorites);
      foundIds.addAll(backendFavorites.map((infra) => infra.id));
      print(
        '✅ ${backendFavorites.length} favori(s) chargé(s) depuis le backend',
      );
    } catch (error) {
      print(
        '⚠️ Erreur lors du chargement des favoris depuis le backend: $error',
      );
    }
  }

  // 2. Charger depuis l'API toutes les infrastructures pour trouver celles qui manquent
  try {
    final apiInfrastructures = await apiService.getInfrastructures();
    for (final infra in apiInfrastructures) {
      if (favoriteIds.contains(infra.id) && !foundIds.contains(infra.id)) {
        allInfrastructures.add(infra);
        foundIds.add(infra.id);
      }
    }
    print(
      '✅ ${apiInfrastructures.length} infrastructure(s) chargée(s) depuis l\'API',
    );
  } catch (e) {
    print('⚠️ Erreur lors du chargement depuis l\'API: $e');
  }

  // 3. Charger depuis les données hors ligne
  try {
    final offlineData = storageService.getOfflineData();
    for (final infra in offlineData) {
      if (favoriteIds.contains(infra.id) && !foundIds.contains(infra.id)) {
        allInfrastructures.add(infra);
        foundIds.add(infra.id);
      }
    }
    if (offlineData.isNotEmpty) {
      print(
        '✅ ${offlineData.length} infrastructure(s) chargée(s) depuis les données hors ligne',
      );
    }
  } catch (e) {
    print('⚠️ Erreur lors du chargement des données hors ligne: $e');
  }

  // 4. Charger depuis les données mockées
  try {
    final mockInfrastructures = await mockDataService
        .loadSampleInfrastructures();
    for (final infra in mockInfrastructures) {
      if (favoriteIds.contains(infra.id) && !foundIds.contains(infra.id)) {
        allInfrastructures.add(infra);
        foundIds.add(infra.id);
      }
    }
    if (mockInfrastructures.isNotEmpty) {
      print(
        '✅ ${mockInfrastructures.length} infrastructure(s) chargée(s) depuis les données mockées',
      );
    }
  } catch (e) {
    print('⚠️ Erreur lors du chargement des données mockées: $e');
  }

  // 5. Créer des infrastructures "fantômes" pour les IDs non trouvés
  final missingIds = favoriteIds.where((id) => !foundIds.contains(id)).toList();
  if (missingIds.isNotEmpty) {
    print(
      '⚠️ ${missingIds.length} favori(s) non trouvé(s) dans les sources, création d\'infrastructures fantômes',
    );
    for (final id in missingIds) {
      allInfrastructures.add(
        Infrastructure(
          id: id,
          name: 'Infrastructure #$id',
          description:
              'Cette infrastructure a été ajoutée en favori mais n\'est plus disponible.',
          category: 'Non catégorisé',
          latitude: 0.0,
          longitude: 0.0,
          address: 'Adresse non disponible',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  print(
    '✅ Total: ${allInfrastructures.length} infrastructure(s) favorite(s) trouvée(s)',
  );
  return allInfrastructures;
});

// Provider pour la recherche
class SearchNotifier extends StateNotifier<String> {
  SearchNotifier(this._storageService) : super('');

  final StorageService _storageService;

  void updateQuery(String query) {
    state = query;
    if (query.isNotEmpty) {
      _storageService.addRecentSearch(query);
    }
  }

  void clearQuery() {
    state = '';
  }

  List<String> getRecentSearches() {
    return _storageService.getRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    await _storageService.clearRecentSearches();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, String>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return SearchNotifier(storageService);
});

// Provider pour les filtres
class FiltersNotifier extends StateNotifier<Map<String, dynamic>> {
  FiltersNotifier()
    : super({
        'category': null,
        'maxDistance': 5000.0, // 5km par défaut
        'sortBy': 'distance',
        'showOnlyAccessible': false,
        'showOnlyOpen': false,
      });

  void updateCategory(String? category) {
    state = {...state, 'category': category};
  }

  void updateMaxDistance(double distance) {
    state = {...state, 'maxDistance': distance};
  }

  void updateSortBy(String sortBy) {
    state = {...state, 'sortBy': sortBy};
  }

  void updateShowOnlyAccessible(bool value) {
    state = {...state, 'showOnlyAccessible': value};
  }

  void updateShowOnlyOpen(bool value) {
    state = {...state, 'showOnlyOpen': value};
  }

  void resetFilters() {
    state = {
      'category': null,
      'maxDistance': 5000.0,
      'sortBy': 'distance',
      'showOnlyAccessible': false,
      'showOnlyOpen': false,
    };
  }
}

final filtersProvider =
    StateNotifierProvider<FiltersNotifier, Map<String, dynamic>>((ref) {
      return FiltersNotifier();
    });

// Provider pour la connectivité
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Ici vous pouvez implémenter la logique de connectivité
  // Pour l'instant, on assume une connexion
  yield true;
});

// Provider pour les contributions de l'utilisateur
class UserContributionsNotifier
    extends StateNotifier<AsyncValue<List<Contribution>>> {
  UserContributionsNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    loadContributions();
  }

  final ApiService _apiService;

  Future<void> loadContributions() async {
    try {
      state = const AsyncValue.loading();
      final contributions = await _apiService.getUserContributions();
      state = AsyncValue.data(contributions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadContributions();
  }
}

final userContributionsProvider =
    StateNotifierProvider<
      UserContributionsNotifier,
      AsyncValue<List<Contribution>>
    >((ref) {
      final apiService = ref.read(apiServiceProvider);
      return UserContributionsNotifier(apiService);
    });

// Provider pour l'historique des activités utilisateur
class UserActivitiesNotifier extends StateNotifier<List<UserActivity>> {
  UserActivitiesNotifier(this._storageService, this._ref) : super([]) {
    _loadActivities();
    // Écouter les changements d'utilisateur pour recharger l'historique
    _ref.listen<UserState>(userProvider, (previous, next) {
      if (previous?.uid != next.uid) {
        _loadActivities();
      }
    });
  }

  final StorageService _storageService;
  final Ref _ref;

  String? get _userId {
    final userState = _ref.read(userProvider);
    return userState.uid;
  }

  void _loadActivities() {
    state = _storageService.getActivities(userId: _userId);
  }

  Future<void> addActivity(UserActivity activity) async {
    await _storageService.addActivity(activity);
    _loadActivities();
  }

  Future<void> recordInfrastructureView(
    String infrastructureId,
    String infrastructureName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.infrastructureViewed,
      targetId: infrastructureId,
      targetName: infrastructureName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordFavoriteAdded(
    String infrastructureId,
    String infrastructureName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.favoriteAdded,
      targetId: infrastructureId,
      targetName: infrastructureName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordFavoriteRemoved(
    String infrastructureId,
    String infrastructureName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.favoriteRemoved,
      targetId: infrastructureId,
      targetName: infrastructureName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordSearch(String query) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.searchPerformed,
      targetName: query,
      metadata: {'query': query},
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordContribution(
    String contributionId,
    String contributionName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.contributionCreated,
      targetId: contributionId,
      targetName: contributionName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordComment(
    String infrastructureId,
    String infrastructureName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.commentAdded,
      targetId: infrastructureId,
      targetName: infrastructureName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordReport(
    String infrastructureId,
    String infrastructureName,
  ) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.reportSubmitted,
      targetId: infrastructureId,
      targetName: infrastructureName,
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> recordRoute(String from, String to) async {
    final activity = UserActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: UserActivityType.routeCalculated,
      metadata: {'from': from, 'to': to},
      createdAt: DateTime.now(),
    );
    await addActivity(activity);
  }

  Future<void> clearAllActivities() async {
    await _storageService.clearActivities(userId: _userId);
    state = [];
  }

  List<UserActivity> getActivitiesByType(UserActivityType type) {
    return state.where((activity) => activity.type == type).toList();
  }
}

final userActivitiesProvider =
    StateNotifierProvider<UserActivitiesNotifier, List<UserActivity>>((ref) {
      final storageService = ref.read(storageServiceProvider);
      return UserActivitiesNotifier(storageService, ref);
    });

// Provider pour le thème (mode sombre)
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(this._storageService) : super(false) {
    _loadTheme();
  }

  final StorageService _storageService;

  void _loadTheme() {
    state = _storageService.isDarkModeEnabled();
  }

  Future<void> toggleTheme() async {
    final newValue = !state;
    await _storageService.setDarkMode(newValue);
    state = newValue;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _storageService.setDarkMode(enabled);
    state = enabled;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return ThemeNotifier(storageService);
});

// Provider pour la langue
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier(this._storageService) : super(const Locale('fr')) {
    _loadLanguage();
  }

  final StorageService _storageService;

  void _loadLanguage() {
    final languageCode = _storageService.getLanguage();
    state = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await _storageService.saveLanguage(languageCode);
    state = Locale(languageCode);
  }

  String get currentLanguageCode => state.languageCode;
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return LanguageNotifier(storageService);
});

// Provider pour le nombre de visites (se met à jour automatiquement)
class VisitCountNotifier extends StateNotifier<int> {
  VisitCountNotifier(this._storageService, this._ref) : super(0) {
    _loadVisitCount();
    // Écouter les changements d'utilisateur pour recharger le nombre de visites
    _ref.listen<UserState>(userProvider, (previous, next) {
      if (previous?.uid != next.uid) {
        _loadVisitCount();
      }
    });
  }

  final StorageService _storageService;
  final Ref _ref;

  void _loadVisitCount() {
    state = _storageService.getVisitCount();
  }

  void refresh() {
    _loadVisitCount();
  }
}

final visitCountProvider = StateNotifierProvider<VisitCountNotifier, int>((
  ref,
) {
  final storageService = ref.read(storageServiceProvider);
  return VisitCountNotifier(storageService, ref);
});
