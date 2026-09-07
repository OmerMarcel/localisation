import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/infrastructure.dart';
import '../models/user_activity.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialise SharedPreferences (appelé automatiquement au démarrage dans main.dart)
  /// Cette méthode est idempotente : elle peut être appelée plusieurs fois sans problème
  Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      print('✅ StorageService initialisé avec succès');
    }
  }

  /// Gestion du token d'authentification
  Future<void> saveAuthToken(String token) async {
    if (_prefs == null) {
      await init();
    }
    if (token.isEmpty) {
      print('⚠️ Tentative de sauvegarder un token vide');
      return;
    }
    final success = await _prefs?.setString(AppConstants.userTokenKey, token);
    if (success == true) {
      // Vérifier que le token a bien été sauvegardé
      final saved = await getAuthToken();
      if (saved == token) {
        print('✅ Token sauvegardé avec succès (${token.length} caractères)');
      } else {
        print('⚠️ Token sauvegardé mais vérification échouée');
      }
    } else {
      print('❌ Échec de la sauvegarde du token');
    }
  }

  /// Récupère le token d'authentification (initialise automatiquement si nécessaire)
  Future<String?> getAuthToken() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs?.getString(AppConstants.userTokenKey);
  }

  /// Récupère le token d'authentification de manière synchrone (pour compatibilité)
  /// ⚠️ Utilisez getAuthToken() async de préférence
  ///
  /// Note: Cette méthode retourne null si _prefs n'est pas initialisé.
  /// Pour garantir la récupération du token, utilisez getAuthToken() async qui
  /// initialise automatiquement SharedPreferences si nécessaire.
  String? getAuthTokenSync() {
    // Retourne null de manière sûre si _prefs n'est pas initialisé
    // L'initialisation est garantie au démarrage dans main.dart
    return _prefs?.getString(AppConstants.userTokenKey);
  }

  /// Vérifie si StorageService est initialisé
  bool get isInitialized => _prefs != null;

  Future<void> removeAuthToken() async {
    if (_prefs == null) {
      await init();
    }
    await _prefs?.remove(AppConstants.userTokenKey);
  }

  /// Gestion du profil utilisateur
  Future<void> saveUserProfile(User user) async {
    await _prefs?.setString(
      AppConstants.userProfileKey,
      json.encode(user.toJson()),
    );
  }

  User? getUserProfile() {
    final userJson = _prefs?.getString(AppConstants.userProfileKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> removeUserProfile() async {
    await _prefs?.remove(AppConstants.userProfileKey);
  }

  /// Gestion de l'avatar utilisateur
  Future<void> saveUserAvatar(String avatarUrl) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setString(AppConstants.userAvatarKey, avatarUrl);
  }

  String? getUserAvatar() {
    return _prefs?.getString(AppConstants.userAvatarKey);
  }

  Future<void> removeUserAvatar() async {
    if (_prefs == null) {
      await init();
    }
    await _prefs?.remove(AppConstants.userAvatarKey);
  }

  /// Gestion des favoris par utilisateur
  String _getFavoritesKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return AppConstants.favoritesKey; // Clé par défaut pour utilisateur non connecté
    }
    return '${AppConstants.favoritesKey}_$userId';
  }

  Future<void> saveFavorites(List<String> favorites, {String? userId}) async {
    final key = _getFavoritesKey(userId);
    await _prefs?.setStringList(key, favorites);
  }

  List<String> getFavorites({String? userId}) {
    final key = _getFavoritesKey(userId);
    return _prefs?.getStringList(key) ?? [];
  }

  Future<void> addToFavorites(String infrastructureId, {String? userId}) async {
    final favorites = getFavorites(userId: userId);
    if (!favorites.contains(infrastructureId)) {
      favorites.add(infrastructureId);
      await saveFavorites(favorites, userId: userId);
    }
  }

  Future<void> removeFromFavorites(String infrastructureId, {String? userId}) async {
    final favorites = getFavorites(userId: userId);
    favorites.remove(infrastructureId);
    await saveFavorites(favorites, userId: userId);
  }

  bool isFavorite(String infrastructureId, {String? userId}) {
    return getFavorites(userId: userId).contains(infrastructureId);
  }

  /// Supprime tous les favoris d'un utilisateur
  Future<void> clearFavorites({String? userId}) async {
    final key = _getFavoritesKey(userId);
    await _prefs?.remove(key);
  }

  /// Gestion des données hors ligne
  Future<void> saveOfflineData(List<Infrastructure> infrastructures) async {
    final data = infrastructures.map((i) => i.toJson()).toList();
    await _prefs?.setString(AppConstants.offlineDataKey, json.encode(data));
  }

  List<Infrastructure> getOfflineData() {
    final dataJson = _prefs?.getString(AppConstants.offlineDataKey);
    if (dataJson != null) {
      final List<dynamic> data = json.decode(dataJson);
      return data.map((json) => Infrastructure.fromJson(json)).toList();
    }
    return [];
  }

  /// Enregistre une visite d'infrastructure
  Future<void> recordInfrastructureVisit(String infrastructureId) async {
    if (_prefs == null) {
      await init();
    }
    final visitsKey = 'visited_infrastructures';
    final existingVisits = _prefs!.getStringList(visitsKey) ?? [];
    // Ajouter seulement si pas déjà présent (pour éviter les doublons)
    if (!existingVisits.contains(infrastructureId)) {
      existingVisits.add(infrastructureId);
      await _prefs!.setStringList(visitsKey, existingVisits);
    }
  }

  /// Récupère le nombre de visites uniques
  int getVisitCount() {
    if (_prefs == null) return 0;
    final visitsKey = 'visited_infrastructures';
    final visits = _prefs!.getStringList(visitsKey) ?? [];
    return visits.length;
  }

  /// Incrémente le nombre de visites (pour compatibilité avec le provider)
  void incrementVisitCount() {
    // Cette méthode ne fait rien car les visites sont gérées par recordInfrastructureVisit
    // Elle est présente pour compatibilité avec le provider
  }

  /// Récupère la liste des IDs d'infrastructures visitées
  List<String> getVisitedInfrastructureIds() {
    if (_prefs == null) return [];
    final visitsKey = 'visited_infrastructures';
    return _prefs!.getStringList(visitsKey) ?? [];
  }

  /// Gestion de la langue
  Future<void> saveLanguage(String languageCode) async {
    await _prefs?.setString(AppConstants.languageKey, languageCode);
  }

  String getLanguage() {
    return _prefs?.getString(AppConstants.languageKey) ?? 'fr';
  }

  /// Gestion de la première utilisation
  Future<void> setFirstTimeUser(bool isFirstTime) async {
    await _prefs?.setBool('first_time_user', isFirstTime);
  }

  bool isFirstTimeUser() {
    return _prefs?.getBool('first_time_user') ?? true;
  }

  /// Gestion des notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
  }

  bool areNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  /// Gestion du mode sombre
  Future<void> setDarkMode(bool enabled) async {
    await _prefs?.setBool('dark_mode', enabled);
  }

  bool isDarkModeEnabled() {
    return _prefs?.getBool('dark_mode') ?? false;
  }

  /// Gestion de la dernière position connue
  Future<void> saveLastPosition(double latitude, double longitude) async {
    await _prefs?.setDouble('last_latitude', latitude);
    await _prefs?.setDouble('last_longitude', longitude);
  }

  Map<String, double>? getLastPosition() {
    final lat = _prefs?.getDouble('last_latitude');
    final lng = _prefs?.getDouble('last_longitude');

    if (lat != null && lng != null) {
      return {'latitude': lat, 'longitude': lng};
    }
    return null;
  }

  /// Nettoyage de toutes les données
  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  /// Gestion du cache des recherches récentes
  Future<void> saveRecentSearches(List<String> searches) async {
    // Garder seulement les 10 dernières recherches
    final recentSearches = searches.take(10).toList();
    await _prefs?.setStringList('recent_searches', recentSearches);
  }

  List<String> getRecentSearches() {
    return _prefs?.getStringList('recent_searches') ?? [];
  }

  Future<void> addRecentSearch(String search) async {
    final searches = getRecentSearches();
    searches.remove(search); // Retirer s'il existe déjà
    searches.insert(0, search); // Ajouter au début
    await saveRecentSearches(searches);
  }

  Future<void> clearRecentSearches() async {
    await _prefs?.remove('recent_searches');
  }

  /// Gestion des paramètres de localisation
  Future<void> setBackgroundLocationEnabled(bool enabled) async {
    await _prefs?.setBool('background_location_enabled', enabled);
  }

  bool isBackgroundLocationEnabled() {
    return _prefs?.getBool('background_location_enabled') ?? false;
  }

  Future<void> setLocationHistoryEnabled(bool enabled) async {
    await _prefs?.setBool('location_history_enabled', enabled);
  }

  bool isLocationHistoryEnabled() {
    return _prefs?.getBool('location_history_enabled') ?? true;
  }

  Future<void> setPreciseLocationEnabled(bool enabled) async {
    await _prefs?.setBool('precise_location_enabled', enabled);
  }

  bool isPreciseLocationEnabled() {
    return _prefs?.getBool('precise_location_enabled') ?? true;
  }

  /// Gestion de l'historique de localisation
  Future<void> saveLocationHistory(List<Map<String, dynamic>> locations) async {
    await _prefs?.setString('location_history', json.encode(locations));
  }

  List<Map<String, dynamic>> getLocationHistory() {
    final historyJson = _prefs?.getString('location_history');
    if (historyJson != null) {
      final List<dynamic> data = json.decode(historyJson);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  Future<void> addLocationToHistory(double latitude, double longitude) async {
    if (!isLocationHistoryEnabled()) return;
    
    final history = getLocationHistory();
    history.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Garder seulement les 1000 dernières positions
    if (history.length > 1000) {
      history.removeRange(0, history.length - 1000);
    }
    
    await saveLocationHistory(history);
  }

  Future<void> clearLocationHistory() async {
    await _prefs?.remove('location_history');
  }

  /// Gestion des paramètres de cache hors ligne
  Future<void> setAutoDownloadEnabled(bool enabled) async {
    await _prefs?.setBool('auto_download_enabled', enabled);
  }

  bool isAutoDownloadEnabled() {
    return _prefs?.getBool('auto_download_enabled') ?? false;
  }

  Future<void> setWifiOnlyEnabled(bool enabled) async {
    await _prefs?.setBool('wifi_only_enabled', enabled);
  }

  bool isWifiOnlyEnabled() {
    return _prefs?.getBool('wifi_only_enabled') ?? true;
  }

  /// Calcule la taille des données stockées en MB
  double getStoredDataSize() {
    if (_prefs == null) return 0.0;
    
    double size = 0.0;
    
    // Taille des données hors ligne
    final offlineData = _prefs?.getString(AppConstants.offlineDataKey);
    if (offlineData != null) {
      size += offlineData.length / (1024 * 1024); // Convertir en MB
    }
    
    // Taille des favoris
    final favorites = _prefs?.getStringList(AppConstants.favoritesKey);
    if (favorites != null) {
      size += favorites.join('').length / (1024 * 1024);
    }
    
    // Taille du token
    final token = _prefs?.getString(AppConstants.userTokenKey);
    if (token != null) {
      size += token.length / (1024 * 1024);
    }
    
    // Taille du profil utilisateur
    final userProfile = _prefs?.getString(AppConstants.userProfileKey);
    if (userProfile != null) {
      size += userProfile.length / (1024 * 1024);
    }
    
    // Taille des recherches récentes
    final recentSearches = _prefs?.getStringList('recent_searches');
    if (recentSearches != null) {
      size += recentSearches.join('').length / (1024 * 1024);
    }
    
    return size;
  }

  /// Retourne les détails de stockage par catégorie
  Map<String, double> getStorageDetails() {
    // Si rien n'est initialisé, on ne renvoie plus de valeurs "par défaut"
    // afin que l'UI reflète uniquement les vraies données locales.
    if (_prefs == null) {
      return {};
    }
    
    double offlineDataSize = 0.0;
    final offlineData = _prefs?.getString(AppConstants.offlineDataKey);
    if (offlineData != null) {
      offlineDataSize = offlineData.length / (1024 * 1024);
    }
    
    double favoritesSize = 0.0;
    final favorites = _prefs?.getStringList(AppConstants.favoritesKey);
    if (favorites != null) {
      favoritesSize = favorites.join('').length / (1024 * 1024);
    }
    
    double userProfileSize = 0.0;
    final userProfile = _prefs?.getString(AppConstants.userProfileKey);
    if (userProfile != null) {
      userProfileSize = userProfile.length / (1024 * 1024);
    }
    
    // Le cache temporaire sera calculé depuis les fichiers
    double tempCacheSize = 0.0;
    
    return {
      'Données hors ligne': offlineDataSize,
      'Favoris': favoritesSize,
      'Profil utilisateur': userProfileSize,
      'Cache temporaire': tempCacheSize,
    };
  }

  /// Gestion de l'historique des activités utilisateur
  String _getActivityHistoryKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'user_activities';
    }
    return 'user_activities_$userId';
  }

  Future<void> addActivity(UserActivity activity) async {
    if (_prefs == null) {
      await init();
    }
    final key = _getActivityHistoryKey(activity.userId);
    final activities = getActivities(userId: activity.userId);
    
    // Ajouter la nouvelle activité au début
    activities.insert(0, activity);
    
    // Garder seulement les 500 dernières activités
    if (activities.length > 500) {
      activities.removeRange(500, activities.length);
    }
    
    final activitiesJson = activities.map((a) => a.toJson()).toList();
    await _prefs?.setString(key, json.encode(activitiesJson));
  }

  List<UserActivity> getActivities({String? userId}) {
    if (_prefs == null) return [];
    final key = _getActivityHistoryKey(userId);
    final activitiesJson = _prefs?.getString(key);
    
    if (activitiesJson != null) {
      try {
        final List<dynamic> data = json.decode(activitiesJson);
        return data
            .map((json) => UserActivity.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Erreur lors du décodage des activités: $e');
        return [];
      }
    }
    return [];
  }

  Future<void> clearActivities({String? userId}) async {
    final key = _getActivityHistoryKey(userId);
    await _prefs?.remove(key);
  }

  List<UserActivity> getActivitiesByType(
    UserActivityType type, {
    String? userId,
  }) {
    return getActivities(userId: userId)
        .where((activity) => activity.type == type)
        .toList();
  }

  int getActivityCount({String? userId}) {
    return getActivities(userId: userId).length;
  }
}
