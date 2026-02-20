import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import '../core/models/contribution.dart';
import '../core/constants/app_constants.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Action non autorisée (401).']);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ContributionService {
  String get _baseUrl => AppConstants.baseUrl;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Créer une nouvelle proposition (pour le formulaire de contribution)
  Future<Contribution> createProposition({
    required String userId,
    required String name,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String quartier,
    List<File>? imageFiles,
    String? phone,
    String? website,
    Map<String, dynamic>? openingHours,
    List<String>? equipments,
    String? authToken,
  }) async {
    try {
      // Vérifier le token d'authentification
      String? token = authToken;
      if (token == null || token.isEmpty) {
        // Essayer de récupérer depuis StorageService
        final storageService = StorageService();
        token = await storageService.getAuthToken();
        if (token == null || token.isEmpty) {
          _log(
            '❌ Token manquant - StorageService.getAuthToken() retourne null',
          );
          throw UnauthorizedException(
            'Token d\'authentification manquant. Veuillez vous connecter.',
          );
        }
        _log('✅ Token récupéré depuis StorageService');
      } else {
        _log('✅ Token fourni en paramètre');
      }

      // Convertir les catégories Flutter vers le format backend
      final String backendCategory = _mapCategoryToBackend(category);

      // Upload des images d'abord si présentes (tous formats : jpg, png, gif, webp, heic, etc.)
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        _log('📤 Upload de ${imageFiles.length} image(s)...');
        for (final file in imageFiles) {
          try {
            final url = await _uploadImage(file, token);
            if (url.isNotEmpty) {
              imageUrls.add(url);
              _log('✅ Image uploadée: $url');
            }
          } catch (e) {
            _log('⚠️ Erreur upload image: $e');
            // Continuer même si une image échoue
          }
        }
      }

      // Préparer les données pour l'API backend (format attendu)
      final propositionData = {
        'name': name,
        'category': backendCategory,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'quartier': quartier,
        'images': imageUrls, // toujours un tableau JSON (même vide)
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (website != null && website.isNotEmpty) 'website': website,
        if (openingHours != null && openingHours.isNotEmpty) ...{
          'openingHours': openingHours,
          'horaires': openingHours,
        },
        if (equipments != null && equipments.isNotEmpty)
          'equipements': equipments,
      };

      _log('📤 Envoi de la proposition au backend...');
      _log('🔗 URL: $_baseUrl/api/propositions');
      _log('👤 Token présent: ${token.isNotEmpty}');
      _log('📋 Données: ${jsonEncode(propositionData)}');

      // Envoyer la proposition à l'API
      final uri = Uri.parse('$_baseUrl/api/propositions');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(propositionData),
      );

      _log('📥 Réponse du serveur: ${response.statusCode}');
      _log('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 401) {
        throw UnauthorizedException(
          'Veuillez vous authentifier avant d\'envoyer une proposition.',
        );
      }

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = response.body;
        throw Exception('Erreur (${response.statusCode}): $errorBody');
      }

      final responseData = jsonDecode(response.body);
      final data = responseData['data'] ?? responseData;

      final dynamic responseOpeningHours =
          data['horaires'] ?? data['openingHours'];
      final Map<String, dynamic> openingHoursPayload =
          responseOpeningHours is Map
          ? Map<String, dynamic>.from(responseOpeningHours)
          : (openingHours ?? {});

      final dynamic responseEquipments =
          data['equipements'] ?? data['equipments'];
      final List<String> equipmentPayload = responseEquipments is List
          ? responseEquipments.map((e) => e.toString()).toList()
          : (equipments ?? []);

      final List<String> responseImages = _parseImages(data['images']);
      final normalizedResponseImages = responseImages
          .map(_normalizeImageUrl)
          .toList();
      final normalizedUploadedImages = imageUrls
          .map(_normalizeImageUrl)
          .toList();

      final contribution = Contribution(
        id: data['id'],
        userId: userId,
        name: name,
        description: description,
        category: category,
        latitude: latitude,
        longitude: longitude,
        address: quartier,
        images: normalizedResponseImages.isNotEmpty
            ? normalizedResponseImages
            : normalizedUploadedImages,
        openingHours: openingHoursPayload,
        equipments: equipmentPayload,
        phone: phone,
        website: website,
        createdAt:
            DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
      );

      _log('✅ Proposition créée avec succès');
      return contribution;
    } catch (e) {
      if (e is UnauthorizedException) {
        rethrow;
      }
      _log('❌ Erreur lors de la création de la proposition : $e');
      throw Exception('Erreur lors de la soumission: ${e.toString()}');
    }
  }

  /// Recuperer la localisation administrative depuis le backend
  Future<Map<String, dynamic>?> fetchAdministrativeLocation({
    required double latitude,
    required double longitude,
    String? authToken,
  }) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        final storageService = StorageService();
        token = await storageService.getAuthToken();
      }

      final uri = Uri.parse(
        '$_baseUrl/api/administrative-location?latitude=$latitude&longitude=$longitude',
      );

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode != 200) {
        _log('❌ Erreur localisation administrative: ${response.body}');
        return null;
      }

      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      return data is Map<String, dynamic>
          ? Map<String, dynamic>.from(data)
          : null;
    } catch (e) {
      _log('❌ Erreur lors de la recuperation de la localisation: $e');
      return null;
    }
  }

  /// Déduit le type MIME à partir du chemin (tous formats: jpg, png, gif, webp, heic, bmp, etc.)
  String _getMimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'bmp') return 'image/bmp';
    if (ext == 'heic' || ext == 'heif') return 'image/heic';
    return 'image/jpeg'; // jpg, jpeg ou défaut
  }

  /// Upload une image vers l'API (tous formats image, Content-Type explicite pour stockage fiable)
  Future<String> _uploadImage(File imageFile, String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mime = _getMimeTypeFromPath(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mime),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Erreur upload (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      return (data['url'] ?? data['data']?['url'] ?? '').toString();
    } catch (e) {
      _log('❌ Erreur upload image: $e');
      rethrow;
    }
  }

  /// Mapper les catégories Flutter vers le format backend
  String _mapCategoryToBackend(String flutterCategory) {
    // Mapping vers les types attendus par le backend
    final categoryLower = flutterCategory.toLowerCase();

    // Types supportés par le backend: toilettes_publiques, parc_jeux, centre_sante,
    // installation_sportive, espace_divertissement, autre

    if (categoryLower.contains('toilette') || categoryLower.contains('wc')) {
      return 'toilettes_publiques';
    } else if (categoryLower.contains('parc') ||
        categoryLower.contains('jeu')) {
      return 'parc_jeux';
    } else if (categoryLower.contains('santé') ||
        categoryLower.contains('hôpital') ||
        categoryLower.contains('clinique') ||
        categoryLower.contains('pharmacie')) {
      return 'centre_sante';
    } else if (categoryLower.contains('sport') ||
        categoryLower.contains('terrain') ||
        categoryLower.contains('stade')) {
      return 'installation_sportive';
    } else if (categoryLower.contains('culture') ||
        categoryLower.contains('musée') ||
        categoryLower.contains('théâtre') ||
        categoryLower.contains('cinéma')) {
      return 'espace_divertissement';
    } else {
      return 'autre';
    }
  }

  /// Créer une nouvelle contribution
  Future<Contribution> createContribution({
    required String userId,
    required String name,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? images,
    Map<String, dynamic>? openingHours,
    List<String>? equipments,
    String? phone,
    String? website,
  }) async {
    try {
      // Créer l'objet Contribution
      final contribution = Contribution(
        userId: userId,
        name: name,
        description: description,
        category: category,
        latitude: latitude,
        longitude: longitude,
        address: address,
        images: images ?? [],
        openingHours: openingHours ?? {},
        equipments: equipments ?? [],
        phone: phone,
        website: website,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Envoyer vers l'API backend
      final apiService = ApiService();
      await apiService.submitContribution(contribution);

      _log('✅ Contribution créée avec succès');
      return contribution;
    } catch (e) {
      _log('❌ Erreur lors de la création : $e');
      rethrow;
    }
  }

  /// Récupérer toutes les contributions
  Future<List<Contribution>> getAllContributions() async {
    try {
      final apiService = ApiService();
      return await apiService.getContributions();
    } catch (e) {
      _log('❌ Erreur récupération : $e');
      return [];
    }
  }

  /// Rechercher des contributions près d'une position
  Future<List<Contribution>> getNearbyContributions({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Utiliser l'API pour rechercher par géolocalisation
      final apiService = ApiService();
      final allContributions = await apiService.getContributions();

      // Filtrer localement par distance
      return allContributions.where((contribution) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          contribution.latitude,
          contribution.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      _log('❌ Erreur recherche géolocalisée : $e');
      return [];
    }
  }

  /// Mettre à jour une contribution
  Future<Contribution?> updateContribution(
    String id,
    Contribution contribution,
  ) async {
    try {
      final apiService = ApiService();
      await apiService.updateContribution(id, contribution);
      return contribution;
    } catch (e) {
      _log('❌ Erreur mise à jour : $e');
      return null;
    }
  }

  /// Calculer la distance entre deux points (Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  List<String> _parseImages(dynamic images) {
    if (images == null) return [];
    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }
    if (images is Map) {
      return images.values.map((e) => e.toString()).toList();
    }
    if (images is String && images.isNotEmpty) {
      try {
        final decoded = jsonDecode(images);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map) {
          return decoded.values.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return [images];
      }
    }
    return [];
  }

  String _normalizeImageUrl(String url) {
    if (url.isEmpty || url.startsWith('data:')) return url;
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return url;
    }
    var base = _baseUrl;
    if (Platform.isAndroid &&
        (base.contains('localhost') || base.contains('127.0.0.1'))) {
      base = base
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    final prefix = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final path = url.startsWith('/') ? url : '/$url';
    return '$prefix$path';
  }
} // <-- fermer la classe ContributionService ici

/// Widget exemple pour créer une contribution
class CreateContributionWidget extends StatefulWidget {
  const CreateContributionWidget({super.key});

  @override
  State<CreateContributionWidget> createState() =>
      _CreateContributionWidgetState();
}

class _CreateContributionWidgetState extends State<CreateContributionWidget> {
  final ContributionService _contributionService = ContributionService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;

  /// Envoyer les données vers l'API backend
  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _contributionService.createContribution(
        userId: "user123", // À remplacer par l'ID utilisateur réel
        name: _nameController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        latitude: 48.8566, // À remplacer par la vraie position
        longitude: 2.3522,
        address: _addressController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Contribution envoyée vers l\'API!')),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _addressController.clear();
        _categoryController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une contribution')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du lieu'),
                validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
                validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitContribution,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('📤 Envoyer vers l\'API'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
