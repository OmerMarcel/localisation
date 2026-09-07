import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/infrastructure.dart';
import '../../core/services/google_maps_service.dart';
import '../../core/services/search_service.dart';
import '../route/route_screen.dart';
import '../../shared/widgets/infrastructure_detail_popup.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool proximityMode;
  final Infrastructure? selectedInfrastructure;
  final String? searchCategory;

  const MapScreen({
    super.key,
    this.proximityMode = false,
    this.selectedInfrastructure,
    this.searchCategory,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MarkerStyle {
  final IconData icon;
  final Color color;

  const _MarkerStyle({required this.icon, required this.color});
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  final Map<String, BitmapDescriptor> _markerLabelCache = {};
  final Set<String> _markerLabelLoading = {};
  late final Map<String, IconData> _subServiceIconMap = _buildNormalizedIconMap(
    AppConstants.subServiceIcons,
  );
  late final Map<String, IconData> _categoryIconMap = _buildNormalizedIconMap(
    AppConstants.categoryIcons,
  );
  late final Map<String, Color> _categoryColorMap = _buildNormalizedColorMap(
    AppConstants.categoryColors,
  );
  late final Map<String, String> _subServiceParentMap =
      _buildSubServiceParentMap();
  Position? _currentPosition;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  double _searchRadius = 2.0; // Valeur par défaut à 2km
  double _proximityRadius = 1.0;
  MapType _mapType = MapType.normal;
  bool _showRadiusControl = false;
  Circle? _radiusCircle;
  bool _loadAllInfrastructures =
      true; // Charger toutes les infrastructures par défaut

  // 📶 État de connexion pour le mode hors ligne
  bool _isOnline = true;
  int _cachedMarkersCount = 0;

  // Variables pour la recherche
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _suggestions = [];
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Marker? _searchMarker;

  // 🔍 Mots-clés prédéfinis pour l'autocomplétion instantanée
  final List<String> _predefinedKeywords = [
    'Mairie',
    'Mairie de Cotonou',
    'Marché',
    'Marché Dantokpa',
    'Marché Saint Michel',
    'Toilettes publiques',
    'Aires de jeux',
    'Terrains de sport',
    'Centres de santé',
    'Hôpital',
    'Écoles',
    'École primaire',
    'École secondaire',
    'Commissariat',
    'Police',
    'Espaces verts',
    'Parc',
    'Jardin',
    'Centres culturels',
    'Musée',
    'Bibliothèque',
    'Stade',
    'Pharmacie',
    'Banque',
    'Restaurant',
    'Hôtel',
    'Plage',
    'Cotonou',
    'Cadjehoun',
    'Akpakpa',
    'Jonquet',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadInfrastructures();
    _checkConnectivity();
    _listenToConnectivity();

    if (widget.proximityMode) {
      _searchRadius = _proximityRadius;
    }

    // Si une catégorie de recherche est spécifiée, rechercher après le chargement
    if (widget.searchCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchNearestByCategory(widget.searchCategory!);
      });
    }
  }

  Future<void> _focusOnInfrastructure(Infrastructure infrastructure) async {
    if (_mapController == null) {
      // Attendre que le contrôleur soit initialisé
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) return;
    }

    // Animer la caméra vers l'infrastructure
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(infrastructure.latitude, infrastructure.longitude),
          zoom: 16.0,
        ),
      ),
    );

    // Afficher les détails de l'infrastructure
    if (mounted) {
      _showInfrastructureDetails(infrastructure);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 📶 Vérifier l'état de la connexion Internet
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult.first != ConnectivityResult.none;
    });

    if (!_isOnline) {
      await _loadCacheStats();
    }
  }

  // 📶 Écouter les changements de connectivité
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOnline = _isOnline;
      setState(() {
        _isOnline = results.first != ConnectivityResult.none;
      });

      if (!wasOnline && _isOnline) {
        // Reconnexion détectée
        _showConnectionRestoredMessage();
        _loadInfrastructures(); // Recharger depuis l'API
      } else if (wasOnline && !_isOnline) {
        // Perte de connexion
        _showOfflineModeMessage();
        _loadCacheStats();
      }
    });
  }

  // 📊 Charger les statistiques du cache
  Future<void> _loadCacheStats() async {
    final cacheService = ref.read(infrastructureCacheServiceProvider);
    final stats = await cacheService.getCacheStats();
    setState(() {
      _cachedMarkersCount = stats['valid'] ?? 0;
    });
  }

  // 📶 Message de mode hors ligne
  void _showOfflineModeMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 20),
              SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  '📴 Mode hors ligne - $_cachedMarkersCount marqueurs disponibles en cache',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // 📶 Message de reconnexion
  void _showConnectionRestoredMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.white, size: 20),
              SizedBox(width: AppDimensions.spacingS),
              Text('✅ Connexion rétablie - Synchronisation en cours...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Méthodes de recherche
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _suggestions = [];
        _showSearchResults = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      // 1️⃣ D'abord chercher dans les infrastructures locales
      final infrastructures = ref.read(infrastructuresProvider).value ?? [];
      final queryLower = query.toLowerCase().trim();

      final matchingInfrastructures = infrastructures.where((infra) {
        return infra.name.toLowerCase().contains(queryLower) ||
            infra.category.toLowerCase().contains(queryLower) ||
            infra.address.toLowerCase().contains(queryLower);
      }).toList();

      // Si on trouve des infrastructures correspondantes
      if (matchingInfrastructures.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
          _suggestions = [];
        });

        // Afficher la liste de tous les résultats avec distance et temps
        if (mounted) {
          _showSearchResultsList(matchingInfrastructures, query);
        }

        return;
      }

      // 2️⃣ Si aucune infrastructure locale, chercher avec Google Places
      final results = await SearchService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Erreur de recherche: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(child: Text('❌ Aucun résultat trouvé pour "$query"')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final queryLower = query.toLowerCase().trim();
    final normalizedQuery = _normalizeCategory(query);

    // 1. Obtenir les infrastructures locales
    final infrastructures = ref.read(infrastructuresProvider).value ?? [];
    final allSuggestions = <String>{};

    // 2. Suggestions par noms d'infrastructures
    for (final infra in infrastructures) {
      final normalizedName = _normalizeCategory(infra.name);
      if (normalizedName.contains(normalizedQuery)) {
        allSuggestions.add(infra.name);
      }
    }

    // 3. Suggestions par catégories/sous-catégories
    final categories = infrastructures.map((infra) => infra.category).toSet();

    for (final category in categories) {
      final normalizedCategory = _normalizeCategory(category);
      if (normalizedCategory.contains(normalizedQuery)) {
        allSuggestions.add(category);
      }
    }

    // 4. Ajouter quelques mots-clés prédéfinis populaires
    final keywordSuggestions = _predefinedKeywords
        .where(
          (keyword) => _normalizeCategory(keyword).contains(normalizedQuery),
        )
        .take(3)
        .toList();
    allSuggestions.addAll(keywordSuggestions);

    // 5. Si moins de 5 suggestions, chercher avec l'API Google Places
    if (allSuggestions.length < 5 && query.trim().length >= 3) {
      try {
        final apiSuggestions = await SearchService.getSuggestions(query);
        allSuggestions.addAll(apiSuggestions.take(3));
      } catch (e) {
        print('Erreur suggestions API: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _suggestions = allSuggestions.take(10).toList();
    });
  }

  // 🔍 Afficher la liste des résultats de recherche avec distance et temps
  void _showSearchResultsList(List<Infrastructure> results, String query) {
    // Calculer les distances si on a la position actuelle
    if (_currentPosition != null) {
      results.sort((a, b) {
        final distanceA = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
          ),
          child: Column(
            children: [
              // Barre de défilement
              Container(
                margin: EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête
              Padding(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary, size: 28),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résultats pour "$query"',
                            style: AppTextStyles.h4,
                          ),
                          Text(
                            '${results.length} résultat${results.length > 1 ? 's' : ''} trouvé${results.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(height: 1),

              // Liste des résultats
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppDimensions.spacingS),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final infrastructure = results[index];
                    final distance = _currentPosition != null
                        ? _calculateDistance(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            infrastructure.latitude,
                            infrastructure.longitude,
                          )
                        : null;

                    final distanceText = distance != null
                        ? distance < 1.0
                              ? '${(distance * 1000).round()} m'
                              : '${distance.toStringAsFixed(1)} km'
                        : null;

                    final travelTime = distance != null
                        ? GoogleMapsService.estimateTravelTime(
                            distance,
                            TravelMode.walking,
                          )
                        : null;

                    return Card(
                      margin: EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingXs,
                      ),
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);

                          // Centrer la carte sur l'infrastructure
                          if (_mapController != null) {
                            await _mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    infrastructure.latitude,
                                    infrastructure.longitude,
                                  ),
                                  zoom: 17.0,
                                ),
                              ),
                            );
                          }

                          // Afficher les détails
                          _showInfrastructureDetails(infrastructure);
                        },
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.spacingM),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icône de catégorie
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS,
                                  ),
                                ),
                                child: Icon(
                                  _getCategoryIcon(infrastructure.category),
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: AppDimensions.spacingM),

                              // Informations
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      infrastructure.name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: AppDimensions.spacingXs),
                                    Text(
                                      infrastructure.category,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: AppDimensions.spacingXs),
                                    Text(
                                      infrastructure.address,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Distance et temps
                                    if (distanceText != null &&
                                        travelTime != null) ...[
                                      SizedBox(height: AppDimensions.spacingS),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            distanceText,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                          SizedBox(
                                            width: AppDimensions.spacingS,
                                          ),
                                          Icon(
                                            Icons.directions_walk,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            travelTime,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Flèche
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtenir l'icône selon la catégorie
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'toilettes publiques':
        return Icons.wc;
      case 'aires de jeux':
        return Icons.park;
      case 'terrains de sport':
        return Icons.sports_soccer;
      case 'centres de santé':
      case 'hôpital':
        return Icons.local_hospital;
      case 'écoles':
      case 'école primaire':
      case 'école secondaire':
        return Icons.school;
      case 'mairies':
      case 'mairie':
        return Icons.account_balance;
      case 'commissariats':
      case 'police':
        return Icons.local_police;
      case 'marchés':
      case 'marché':
        return Icons.shopping_basket;
      case 'espaces verts':
      case 'parc':
      case 'jardin':
        return Icons.nature;
      case 'centres culturels':
      case 'musée':
      case 'bibliothèque':
        return Icons.museum;
      case 'stade':
        return Icons.stadium;
      case 'pharmacie':
        return Icons.medication;
      case 'banque':
        return Icons.account_balance_wallet;
      case 'restaurant':
        return Icons.restaurant;
      case 'hôtel':
        return Icons.hotel;
      case 'plage':
        return Icons.beach_access;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _selectSearchResult(SearchResult result) async {
    if (_mapController == null) return;

    // Ajouter un marqueur pour le résultat de recherche
    final searchMarker = Marker(
      markerId: const MarkerId('search_result'),
      position: result.location,
      anchor: const Offset(0.5, 1.0),
      infoWindow: InfoWindow(
        title: '📍 ${result.formattedAddress}',
        snippet: 'Résultat de recherche',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      // Retirer l'ancien marqueur de recherche s'il existe
      if (_searchMarker != null) {
        _markers.remove(_searchMarker);
      }
      _markers.add(searchMarker);
      _searchMarker = searchMarker;
      _searchController.text = result.formattedAddress;
      _suggestions = [];
      _searchResults = [];
      _showSearchResults = false;
    });

    // Centrer la carte sur le résultat
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(result.location, 16.0),
    );

    // Fermer le clavier
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _suggestions = [];
      _searchResults = [];
      _showSearchResults = false;
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'search_result',
      );
      _searchMarker = null;
    });
    _searchFocusNode.unfocus();
  }

  /// Attend que `infrastructuresProvider` ait réellement des données (`data`)
  /// pour éviter les différences de timing entre `flutter run` et `flutter build`.
  Future<List<Infrastructure>> _waitForInfrastructuresData({
    required Duration timeout,
  }) async {
    final startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      // `value` est `null` tant que le provider n'est pas en état `data`.
      final data = ref.read(infrastructuresProvider).value;
      if (data != null) return data;

      await Future.delayed(const Duration(milliseconds: 250));
    }

    return ref.read(infrastructuresProvider).value ?? [];
  }

  // 🔍 Rechercher toutes les infrastructures d'une catégorie spécifique
  Future<void> _searchNearestByCategory(String category) async {
    final infrastructures = await _waitForInfrastructuresData(
      timeout: const Duration(seconds: 10),
    );

    if (infrastructures.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(child: Text('❌ Aucune infrastructure disponible')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final normalizedCategory = _normalizeCategory(category);

    // Filtrer par catégorie ou nom (normalisation pour gérer accents/snake_case)
    final matchingInfrastructures = infrastructures.where((infra) {
      final normalizedName = _normalizeCategory(infra.name);
      final normalizedInfraCategory = _normalizeCategory(infra.category);
      return normalizedName.contains(normalizedCategory) ||
          normalizedInfraCategory.contains(normalizedCategory);
    }).toList();

    if (matchingInfrastructures.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'ℹ️ Aucune infrastructure trouvée pour "$category"',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Si on a la position actuelle, trier par distance
    if (_currentPosition != null) {
      matchingInfrastructures.sort((a, b) {
        final distanceA = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    // Attendre que le contrôleur soit prêt
    int retries = 0;
    while (_mapController == null && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (_mapController != null && mounted) {
      // Centrer la carte sur la première infrastructure (la plus proche)
      final nearest = matchingInfrastructures.first;
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(nearest.latitude, nearest.longitude),
            zoom: 15.0, // Zoom un peu moins pour voir plusieurs marqueurs
          ),
        ),
      );

      // Attendre un peu pour que la carte soit centrée
      await Future.delayed(const Duration(milliseconds: 300));

      // Afficher la liste de TOUTES les infrastructures trouvées
      _showSearchResultsList(matchingInfrastructures, category);
    }
  }

  Widget _buildSearchInterface() {
    return Column(
      children: [
        // Barre de recherche avec autocomplétion
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.trim().length < 2) {
                return const Iterable<String>.empty();
              }
              // Obtenir les suggestions
              await _getSuggestions(textEditingValue.text);
              return _suggestions;
            },
            onSelected: (String selection) {
              _searchController.text = selection;
              _performSearch(selection);
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Synchroniser avec notre contrôleur
                  fieldTextEditingController.text = _searchController.text;

                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un lieu...',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: fieldTextEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                fieldTextEditingController.clear();
                                _clearSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingS,
                      ),
                    ),
                    onChanged: (value) {
                      _searchController.text = value;
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      _performSearch(value);
                      onFieldSubmitted();
                    },
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  final infrastructures =
                      ref.read(infrastructuresProvider).value ?? [];
                  final categories = infrastructures
                      .map((i) => i.category)
                      .toSet();

                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        width: MediaQuery.of(context).size.width - 32,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);

                            // Déterminer si c'est une catégorie ou un nom d'infrastructure
                            final isCategory = categories.contains(option);
                            final isInfrastructure = infrastructures.any(
                              (i) => i.name == option,
                            );

                            IconData iconData;
                            Color iconColor;
                            String subtitle = '';

                            if (isInfrastructure) {
                              final infra = infrastructures.firstWhere(
                                (i) => i.name == option,
                              );
                              iconData = _getCategoryIcon(infra.category);
                              iconColor = AppColors.primary;
                              subtitle = infra.category;
                            } else if (isCategory) {
                              iconData = Icons.category;
                              iconColor = AppColors.secondary;
                              final count = infrastructures
                                  .where((i) => i.category == option)
                                  .length;
                              subtitle = '$count lieu${count > 1 ? 'x' : ''}';
                            } else {
                              iconData = Icons.search;
                              iconColor = AppColors.textSecondary;
                            }

                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingM,
                                  vertical: AppDimensions.spacingS,
                                ),
                                child: Row(
                                  children: [
                                    Icon(iconData, color: iconColor, size: 20),
                                    SizedBox(width: AppDimensions.spacingS),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                          if (subtitle.isNotEmpty)
                                            Text(
                                              subtitle,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.north_west,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),

        // Suggestions et résultats
        if (_showSearchResults || _suggestions.isNotEmpty || _isSearching)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Recherche en cours...'),
                      ],
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      // Suggestions locales
                      if (_suggestions.isNotEmpty && !_showSearchResults) ...[
                        Padding(
                          padding: EdgeInsets.all(AppDimensions.spacingS),
                          child: Text(
                            'Suggestions',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        ..._suggestions.map(
                          (suggestion) => ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: AppColors.textSecondary,
                            ),
                            title: Text(suggestion),
                            onTap: () {
                              _searchController.text = suggestion;
                              _performSearch(suggestion);
                            },
                          ),
                        ),
                      ],

                      // Résultats de recherche
                      if (_searchResults.isNotEmpty) ...[
                        if (_suggestions.isNotEmpty) const Divider(),
                        Padding(
                          padding: EdgeInsets.all(AppDimensions.spacingS),
                          child: Text(
                            'Résultats (${_searchResults.length})',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        ..._searchResults.map(
                          (result) => ListTile(
                            leading: Icon(
                              Icons.place,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              result.formattedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          ),
                        ),
                      ],

                      // Message si aucun résultat
                      if (_showSearchResults &&
                          _searchResults.isEmpty &&
                          !_isSearching)
                        Padding(
                          padding: EdgeInsets.all(AppDimensions.spacingM),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_off,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: AppDimensions.spacingS),
                              Text(
                                'Aucun résultat trouvé',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  Future<void> _loadInfrastructures() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // En mode proximité, toujours utiliser le filtre de rayon
      // Sinon, si _loadAllInfrastructures est true, charger toutes les infrastructures sans filtre de rayon
      final useRadiusFilter = widget.proximityMode || !_loadAllInfrastructures;

      await ref
          .read(infrastructuresProvider.notifier)
          .loadInfrastructures(
            category: _selectedCategory,
            latitude: useRadiusFilter ? _currentPosition?.latitude : null,
            longitude: useRadiusFilter ? _currentPosition?.longitude : null,
            radius: useRadiusFilter
                ? (widget.proximityMode ? _proximityRadius : _searchRadius)
                : null,
            limit: useRadiusFilter
                ? null
                : 10000, // Limite élevée pour charger toutes les infrastructures
          );
    } catch (e) {
      print('Erreur lors du chargement des infrastructures: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _updateUserMarker(position);

        // Centrer la carte sur la position actuelle
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
              ),
            ),
          );
        }

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: AppDimensions.spacingS),
                  Text('Position trouvée et centrée'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Afficher un message d'erreur si la position n'est pas trouvée
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: AppDimensions.spacingS),
                  Text('Impossible de trouver votre position'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Afficher un message d'erreur en cas d'exception
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 20),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text('Erreur de localisation: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateUserMarker(Position position) {
    setState(() {
      // Nettoyer tout marqueur statique pour laisser le voyant bleu officiel de Google Maps
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'user_location',
      );

      if (widget.proximityMode) {
        _updateProximityCircle(position);
      } else if (_showRadiusControl) {
        _updateRadiusCircle();
      }
    });
  }

  void _updateProximityCircle(Position position) {
    final proximityCircle = Circle(
      circleId: const CircleId('proximity_circle'),
      center: LatLng(position.latitude, position.longitude),
      radius: _proximityRadius * 1000,
      strokeColor: AppColors.primary.withOpacity(0.8),
      strokeWidth: 2,
      fillColor: AppColors.primary.withOpacity(0.1),
    );

    setState(() {
      _circles.clear();
      _circles.add(proximityCircle);
    });
  }

  void _updateRadiusCircle() {
    if (_currentPosition == null || !_showRadiusControl) {
      setState(() {
        _radiusCircle = null;
        _circles.removeWhere(
          (circle) => circle.circleId.value == 'radius_control',
        );
      });
      return;
    }

    final radiusCircle = Circle(
      circleId: const CircleId('radius_control'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: _searchRadius * 1000,
      strokeColor: AppColors.secondary.withOpacity(0.8),
      strokeWidth: 3,
      fillColor: AppColors.secondary.withOpacity(0.1),
    );

    setState(() {
      _radiusCircle = radiusCircle;
      _circles.removeWhere(
        (circle) => circle.circleId.value == 'radius_control',
      );
      _circles.add(radiusCircle);

      // Animer la caméra pour que le cercle soit visible
      if (_mapController != null) {
        final bounds = _calculateBoundsForRadius(
          _currentPosition!,
          _searchRadius,
        );
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    });
  }

  LatLngBounds _calculateBoundsForRadius(Position center, double radiusKm) {
    // Calculer les coordonnées approximatives des limites du cercle
    const double kmPerDegreeLatitude = 111.0;
    final double kmPerDegreeLongitude =
        111.0 * math.cos(center.latitude * math.pi / 180);

    final double latitudeDelta = radiusKm / kmPerDegreeLatitude;
    final double longitudeDelta = radiusKm / kmPerDegreeLongitude;

    return LatLngBounds(
      southwest: LatLng(
        center.latitude - latitudeDelta,
        center.longitude - longitudeDelta,
      ),
      northeast: LatLng(
        center.latitude + latitudeDelta,
        center.longitude + longitudeDelta,
      ),
    );
  }

  void _toggleRadiusControl() {
    setState(() {
      _showRadiusControl = !_showRadiusControl;
    });
    _updateRadiusCircle();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  List<Infrastructure> _filterInfrastructuresByProximity(
    List<Infrastructure> infrastructures,
    Position userPosition,
  ) {
    return infrastructures.where((infrastructure) {
      final distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        infrastructure.latitude,
        infrastructure.longitude,
      );
      return distance <= _proximityRadius;
    }).toList();
  }

  Future<void> _updateInfrastructureMarkers(
    List<Infrastructure> infrastructures,
  ) async {
    // Ne pas mettre à jour si la liste est vide (pour éviter de supprimer les marqueurs)
    if (infrastructures.isEmpty) {
      print(
        '⚠️ Liste d\'infrastructures vide, conservation des marqueurs existants',
      );
      return;
    }

    List<Infrastructure> filteredInfrastructures = infrastructures;

    if (widget.proximityMode && _currentPosition != null) {
      filteredInfrastructures = _filterInfrastructuresByProximity(
        infrastructures,
        _currentPosition!,
      );
    }

    if (_showFavoritesOnly) {
      final favorites = ref.read(favoritesProvider);
      filteredInfrastructures = filteredInfrastructures
          .where((infrastructure) => favorites.contains(infrastructure.id))
          .toList();
    }

    await Future.wait(filteredInfrastructures.map(_ensureLabeledMarkerIcon));

    if (!mounted) return;

    setState(() {
      // Créer un Set temporaire pour les nouveaux marqueurs
      final Set<Marker> newMarkers = {};

      // Garder les marqueurs de recherche et utilisateur
      for (final marker in _markers) {
        if (marker.markerId.value == 'user_location' ||
            marker.markerId.value == 'search_result') {
          newMarkers.add(marker);
        }
      }

      // Ajouter les marqueurs des infrastructures
      for (final infrastructure in filteredInfrastructures) {
        final isProximityInfrastructure =
            widget.proximityMode &&
            _currentPosition != null &&
            _calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  infrastructure.latitude,
                  infrastructure.longitude,
                ) <=
                _proximityRadius;

        final markerIcon = _getLabeledMarkerIcon(infrastructure);

        final marker = Marker(
          markerId: MarkerId(infrastructure.id),
          position: LatLng(infrastructure.latitude, infrastructure.longitude),
          icon: markerIcon,
          anchor: const Offset(0.5, 0.95),
          infoWindow: InfoWindow(
            title: infrastructure.name,
            snippet: isProximityInfrastructure
                ? '${infrastructure.category} - À proximité'
                : infrastructure.category,
          ),
          onTap: () => _showQuickRouteOptions(infrastructure),
        );
        newMarkers.add(marker);
      }

      // Remplacer tous les marqueurs d'un coup pour éviter les clignotements
      _markers = newMarkers;

      print('✅ ${newMarkers.length} marqueur(s) mis à jour sur la carte');
    });
  }

  // Nouvelle méthode pour afficher les options d'itinéraire rapides
  void _showQuickRouteOptions(Infrastructure infrastructure) {
    if (_currentPosition == null) {
      _showInfrastructureDetails(infrastructure);
      return;
    }

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      infrastructure.latitude,
      infrastructure.longitude,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              infrastructure.name,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              '${infrastructure.category} • ${(distance * 1000).round()}m',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              'Choisir un mode de transport :',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppDimensions.spacingXs),

            // Boutons de transport
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: _buildTransportButton(
                        'Voiture',
                        Icons.directions_car,
                        size: 10,
                        TravelMode.driving,
                        infrastructure,
                        distance,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: _buildTransportButton(
                        'À pied',
                        Icons.directions_walk,
                        size: 10,
                        TravelMode.walking,
                        infrastructure,
                        distance,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: _buildTransportButton(
                        'Vélo',
                        Icons.directions_bike,
                        size: 10,
                        TravelMode.bicycling,
                        infrastructure,
                        distance,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: _buildTransportButton(
                        'Transport',
                        Icons.directions_transit,
                        size: 10,
                        TravelMode.transit,
                        infrastructure,
                        distance,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showInfrastructureDetails(infrastructure);
                },
                child: const Text('Voir tous les détails'),
              ),
            ),
            SizedBox(height: AppDimensions.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportButton(
    String label,
    IconData icon,
    TravelMode mode,
    Infrastructure infrastructure,
    double distanceKm, {
    required int size,
  }) {
    final estimatedTime = GoogleMapsService.estimateTravelTime(
      distanceKm,
      mode,
    );

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Naviguer vers notre écran d'itinéraire intégré
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteScreen(
              destination: infrastructure,
              currentPosition: _currentPosition,
              travelMode: mode,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: EdgeInsets.all(AppDimensions.spacingS),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              estimatedTime,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  BitmapDescriptor _getLabeledMarkerIcon(Infrastructure infrastructure) {
    final cached = _markerLabelCache[infrastructure.id];
    if (cached != null) {
      return cached;
    }

    _ensureLabeledMarkerIcon(infrastructure);
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  Future<void> _ensureLabeledMarkerIcon(Infrastructure infrastructure) async {
    final key = infrastructure.id;
    if (_markerLabelCache.containsKey(key) ||
        _markerLabelLoading.contains(key)) {
      return;
    }

    _markerLabelLoading.add(key);
    final style = _getCategoryStyle(infrastructure.category);
    final icon = await _createLabeledMarkerIcon(style, infrastructure.name);
    _markerLabelCache[key] = icon;
    _markerLabelLoading.remove(key);
  }

  _MarkerStyle _getCategoryStyle(String category) {
    final normalized = _normalizeCategory(category);

    final subIcon = _subServiceIconMap[normalized];
    if (subIcon != null) {
      final parentKey = _subServiceParentMap[normalized];
      final color = parentKey != null
          ? _categoryColorMap[parentKey] ?? AppColors.primary
          : AppColors.primary;
      return _MarkerStyle(icon: subIcon, color: color);
    }

    final categoryIcon = _categoryIconMap[normalized];
    if (categoryIcon != null) {
      final color = _categoryColorMap[normalized] ?? AppColors.primary;
      return _MarkerStyle(icon: categoryIcon, color: color);
    }

    return _MarkerStyle(icon: Icons.location_on, color: AppColors.primary);
  }

  Future<BitmapDescriptor> _createLabeledMarkerIcon(
    _MarkerStyle style,
    String label,
  ) async {
    const double pinWidth = 84;
    const double pinHeight = 108;
    final width = pinWidth;
    final height = pinHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pin
    final pinColor = style.color;
    final fillPaint = Paint()..color = pinColor;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final pinCenter = Offset(pinWidth / 2, pinWidth / 2);
    final radius = pinWidth / 2 - 6;

    canvas.drawCircle(pinCenter, radius, fillPaint);
    canvas.drawCircle(pinCenter, radius, borderPaint);

    final tailPath = Path();
    tailPath.moveTo(pinWidth / 2, pinHeight - 6);
    tailPath.lineTo(pinWidth / 2 - radius * 0.6, pinWidth / 2 + radius * 0.4);
    tailPath.lineTo(pinWidth / 2 + radius * 0.6, pinWidth / 2 + radius * 0.4);
    tailPath.close();
    canvas.drawPath(tailPath, fillPaint);
    canvas.drawPath(tailPath, borderPaint);

    final innerRadius = radius * 0.62;
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pinCenter, innerRadius, innerPaint);

    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    iconPainter.text = TextSpan(
      text: String.fromCharCode(style.icon.codePoint),
      style: TextStyle(
        fontSize: innerRadius * 1.1,
        fontFamily: style.icon.fontFamily,
        package: style.icon.fontPackage,
        color: pinColor,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        pinCenter.dx - iconPainter.width / 2,
        pinCenter.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  String _normalizeCategory(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    return _stripDiacritics(cleaned);
  }

  Map<String, IconData> _buildNormalizedIconMap(Map<String, IconData> source) {
    final map = <String, IconData>{};
    source.forEach((key, value) {
      map[_normalizeCategory(key)] = value;
    });
    return map;
  }

  Map<String, Color> _buildNormalizedColorMap(Map<String, Color> source) {
    final map = <String, Color>{};
    source.forEach((key, value) {
      map[_normalizeCategory(key)] = value;
    });
    return map;
  }

  Map<String, String> _buildSubServiceParentMap() {
    final map = <String, String>{};
    AppConstants.infrastructureServices.forEach((parent, subservices) {
      final normalizedParent = _normalizeCategory(parent);
      for (final subservice in subservices) {
        map[_normalizeCategory(subservice)] = normalizedParent;
      }
    });
    return map;
  }

  String _stripDiacritics(String value) {
    return value
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae');
  }

  void _showInfrastructureDetails(Infrastructure infrastructure) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      builder: (context) => InfrastructureDetailPopup(
        infrastructure: infrastructure,
        currentPosition: _currentPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final infrastructuresAsync = ref.watch(infrastructuresProvider);

    // Mettre à jour les marqueurs uniquement quand on a des données valides
    // et éviter de les supprimer si on passe en état loading
    ref.listen<AsyncValue<List<Infrastructure>>>(infrastructuresProvider, (
      previous,
      next,
    ) {
      // Ne mettre à jour que si on a des données (pas en loading ou error)
      next.whenOrNull(
        data: (infrastructures) {
          // Ne mettre à jour que si on a des infrastructures
          if (infrastructures.isNotEmpty) {
            _updateInfrastructureMarkers(infrastructures);
          } else {
            // Si on n'a pas de données mais qu'on en avait avant, garder les marqueurs
            previous?.whenOrNull(
              data: (previousInfrastructures) {
                if (previousInfrastructures.isNotEmpty) {
                  print(
                    '⚠️ Aucune infrastructure disponible, conservation des marqueurs existants',
                  );
                }
              },
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.proximityMode
                    ? 'Infrastructures à proximité (1km)'
                    : (_selectedCategory ?? 'Carte'),
              ),
            ),
            // 📶 Indicateur de mode hors ligne
            if (!_isOnline)
              Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Hors ligne',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (_showFavoritesOnly)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Favoris',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          // 📊 Bouton info cache (en mode hors ligne)
          if (!_isOnline)
            IconButton(
              icon: Badge(
                label: Text('$_cachedMarkersCount'),
                child: Icon(Icons.storage),
              ),
              onPressed: () => _showCacheInfo(),
              tooltip: 'Informations du cache',
            ),
          IconButton(
            icon: Icon(
              _currentPosition != null
                  ? Icons.my_location
                  : Icons.location_searching,
              color: _currentPosition != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            onPressed: _isLoading ? null : _getCurrentLocation,
            tooltip: _currentPosition != null
                ? 'Centrer sur ma position'
                : 'Rechercher ma position',
          ),
          if (widget.proximityMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Quitter le mode proximité',
            ),
          if (!widget.proximityMode)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInfrastructures,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              if (widget.proximityMode && _currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 15.0,
                    ),
                  ),
                );
              }

              // Si une infrastructure est sélectionnée, centrer la carte dessus
              if (widget.selectedInfrastructure != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _focusOnInfrastructure(widget.selectedInfrastructure!);
                });
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition?.latitude ?? AppConstants.defaultLatitude,
                _currentPosition?.longitude ?? AppConstants.defaultLongitude,
              ),
              zoom: widget.proximityMode ? 15.0 : AppConstants.defaultZoom,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: _mapType,
            onTap: (LatLng position) {
              _mapController?.hideMarkerInfoWindow(const MarkerId('selected'));
              // Fermer les suggestions et résultats de recherche quand on clique sur la carte
              setState(() {
                _suggestions = [];
                _showSearchResults = false;
              });
              _searchFocusNode.unfocus();
            },
          ),

          // Interface de recherche
          if (!widget.proximityMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildSearchInterface(),
            ),

          // Indicateur de chargement
          if (_isLoading || infrastructuresAsync.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

          // Indicateur de mode proximité
          if (widget.proximityMode)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me, color: AppColors.textLight, size: 16),
                    SizedBox(width: AppDimensions.spacingS),
                    Text(
                      'Proximité 1km',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Message si aucune infrastructure en mode proximité
          if (widget.proximityMode &&
              !_isLoading &&
              !infrastructuresAsync.isLoading &&
              _markers
                  .where((m) => m.markerId.value != 'user_location')
                  .isEmpty)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        'Aucune infrastructure trouvée dans un rayon de 1km.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Message si aucun favori trouvé avec le filtre "Favoris uniquement"
          if (_showFavoritesOnly &&
              !widget.proximityMode &&
              !_isLoading &&
              !infrastructuresAsync.isLoading &&
              _markers
                  .where(
                    (m) =>
                        m.markerId.value != 'user_location' &&
                        m.markerId.value != 'search_result',
                  )
                  .isEmpty)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white, size: 20),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aucun lieu en favoris trouvé',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ajoutez des lieux à vos favoris pour les voir ici.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Contrôle de rayon visuel
          if (_showRadiusControl && _currentPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: AppDimensions.spacingS),
                        Text(
                          'Rayon: ${_searchRadius < 1.0 ? '${(_searchRadius * 1000).round()} m' : '${_searchRadius.toStringAsFixed(1)} km'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    Container(
                      width: 200,
                      child: Slider(
                        value: _searchRadius,
                        min: 0.1, // 100 mètres
                        max: 10.0, // 10 kilomètres
                        divisions: 99, // 99 divisions pour une granularité fine
                        activeColor: AppColors.secondary,
                        onChanged: (value) {
                          setState(() {
                            _searchRadius = value;
                          });
                          _updateRadiusCircle();
                        },
                        onChangeEnd: (value) {
                          // Recharger les infrastructures avec le nouveau rayon
                          _loadInfrastructures();
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showRadiusControl = false;
                            });
                            _updateRadiusCircle();
                          },
                          icon: Icon(Icons.check, size: 16),
                          label: Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.textPrimary,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingS),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showRadiusControl = false;
                              _searchRadius =
                                  2.0; // Remettre à la valeur par défaut (2km)
                            });
                            _updateRadiusCircle();
                            _loadInfrastructures();
                          },
                          child: Text('Annuler'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !widget.proximityMode && _currentPosition != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bouton pour activer le contrôle de rayon
                if (!_showRadiusControl)
                  FloatingActionButton(
                    onPressed: _toggleRadiusControl,
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    heroTag: "radius_control",
                    mini: true,
                    child: const Icon(Icons.radio_button_unchecked),
                    tooltip: 'Définir le rayon de recherche',
                  ),
                if (!_showRadiusControl)
                  SizedBox(height: AppDimensions.spacingS),
                // Bouton principal "Plus proche"
                FloatingActionButton.extended(
                  onPressed: _navigateToNearestInfrastructure,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  heroTag: "nearest",
                  label: const Text('Plus proche'),
                  icon: const Icon(Icons.navigation),
                ),
              ],
            )
          : null,
    );
  }

  void _navigateToNearestInfrastructure() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position non disponible.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final infrastructures = ref.read(infrastructuresProvider).value;
    if (infrastructures == null || infrastructures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: AppDimensions.spacingS),
              Text('Aucune infrastructure disponible.'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Infrastructure? nearest;
    double minDistance = double.infinity;

    // Filtrer d'abord les infrastructures dans le rayon sélectionné
    List<Infrastructure> infrastructuresInRange = [];

    for (final infrastructure in infrastructures) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        infrastructure.latitude,
        infrastructure.longitude,
      );

      // Vérifier si l'infrastructure est dans le rayon de recherche sélectionné
      if (distance <= _searchRadius) {
        infrastructuresInRange.add(infrastructure);

        if (distance < minDistance) {
          minDistance = distance;
          nearest = infrastructure;
        }
      }
    }

    // Vérifier s'il y a des infrastructures dans le rayon
    if (infrastructuresInRange.isEmpty) {
      final radiusText = _searchRadius < 1.0
          ? '${(_searchRadius * 1000).round()} mètres'
          : '${_searchRadius.toStringAsFixed(1)} km';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white, size: 20),
              SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'Aucune infrastructure trouvée dans un rayon de $radiusText.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ajuster rayon',
            textColor: Colors.white,
            onPressed: () {
              _toggleRadiusControl();
            },
          ),
        ),
      );
      return;
    }

    if (nearest != null) {
      // Afficher un message de confirmation avec la distance
      final distanceText = minDistance < 1.0
          ? '${(minDistance * 1000).round()} mètres'
          : '${minDistance.toStringAsFixed(1)} km';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.near_me, color: Colors.white, size: 20),
              SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'Infrastructure la plus proche: ${nearest.name} à $distanceText',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _showQuickRouteOptions(nearest);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options d\'affichage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type de carte',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppDimensions.spacingS),
              _buildMapTypeOption('Normal', MapType.normal),
              _buildMapTypeOption('Satellite', MapType.satellite),
              _buildMapTypeOption('Hybride', MapType.hybrid),
              _buildMapTypeOption('Terrain', MapType.terrain),
              SizedBox(height: AppDimensions.spacingM),
              const Text(
                'Filtres avancés',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppDimensions.spacingS),
              CheckboxListTile(
                title: const Text('Favoris uniquement'),
                value: _showFavoritesOnly,
                onChanged: (value) {
                  setState(() {
                    _showFavoritesOnly = value ?? false;
                  });
                  // Mettre à jour les marqueurs immédiatement avec les données existantes
                  final currentInfrastructures = ref
                      .read(infrastructuresProvider)
                      .value;
                  if (currentInfrastructures != null) {
                    _updateInfrastructureMarkers(currentInfrastructures);
                  }
                },
              ),
              const Text('Rayon de recherche'),
              SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _searchRadius,
                      min: 0.1, // 100 mètres
                      max: 10.0, // 10 kilomètres
                      divisions: 99, // 99 divisions pour une granularité fine
                      label: _searchRadius < 1.0
                          ? '${(_searchRadius * 1000).round()} m'
                          : '${_searchRadius.toStringAsFixed(1)} km',
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                        });
                        _updateRadiusCircle();
                      },
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _searchRadius < 1.0
                          ? '${(_searchRadius * 1000).round()} m'
                          : '${_searchRadius.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Checkbox(
                    value: _showRadiusControl,
                    onChanged: (value) {
                      setState(() {
                        _showRadiusControl = value ?? false;
                      });
                      _updateRadiusCircle();
                    },
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      'Afficher le rayon sur la carte',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _showFavoritesOnly = false;
                _searchRadius = 2.0; // Valeur par défaut 2km
                _mapType = MapType.normal;
              });
              _loadInfrastructures();
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _loadInfrastructures();
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeOption(String title, MapType type) {
    return RadioListTile<MapType>(
      title: Text(title),
      value: type,
      groupValue: _mapType,
      onChanged: (MapType? value) {
        if (value != null) {
          setState(() {
            _mapType = value;
          });
        }
      },
    );
  }

  // 📊 Afficher les informations du cache local
  Future<void> _showCacheInfo() async {
    final cacheService = ref.read(infrastructureCacheServiceProvider);
    final stats = await cacheService.getCacheStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.storage, color: AppColors.primary),
            SizedBox(width: AppDimensions.spacingS),
            Text('Cache local'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCacheInfoRow(
                'Total de marqueurs',
                '${stats['total'] ?? 0}',
                Icons.pin_drop,
              ),
              Divider(),
              _buildCacheInfoRow(
                'Marqueurs valides',
                '${stats['valid'] ?? 0}',
                Icons.check_circle,
                color: Colors.green,
              ),
              if ((stats['expired'] ?? 0) > 0) ...[
                Divider(),
                _buildCacheInfoRow(
                  'Marqueurs expirés',
                  '${stats['expired'] ?? 0}',
                  Icons.error,
                  color: Colors.orange,
                ),
              ],
              Divider(),
              SizedBox(height: AppDimensions.spacingM),
              Text(
                'Catégories disponibles:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimensions.spacingS),
              ...(stats['categories'] as Map<String, int>).entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(entry.key)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les marqueurs sont automatiquement sauvegardés et disponibles hors ligne pendant 30 jours.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if ((stats['expired'] ?? 0) > 0)
            TextButton.icon(
              icon: Icon(Icons.cleaning_services),
              label: Text('Nettoyer expirés'),
              onPressed: () async {
                await cacheService.cleanExpiredCache();
                Navigator.pop(context);
                _showCacheInfo(); // Rafraîchir les infos
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          SizedBox(width: AppDimensions.spacingS),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
