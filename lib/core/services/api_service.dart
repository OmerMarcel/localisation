import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/infrastructure.dart';
import '../models/contribution.dart';
import '../models/avis.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    print('DEBUG ApiService initialisé avec baseUrl=${AppConstants.baseUrl}');
  }

  // REMPLACE l’ancienne ligne:
  // final String _baseUrl = AppConstants.baseUrl;
  // par un getter dynamique (plus de mise en cache)
  String get _baseUrl => AppConstants.baseUrl;

  String? _authToken;
  final StorageService _storageService = StorageService();

  Map<String, String> get _headers {
    // Utiliser le token en cache si disponible
    // Le token est chargé au démarrage via loadAuthToken() dans main.dart
    // Si _authToken est null, on essaie de le récupérer depuis StorageService
    // (mais normalement il devrait déjà être chargé)
    if (_authToken == null) {
      // Essayer de récupérer depuis StorageService (synchrone pour compatibilité avec getter)
      // Note: Si StorageService n'est pas initialisé, cela retournera null
      // mais cela ne devrait jamais arriver car init() est appelé dans main.dart
      _authToken = _storageService.getAuthTokenSync();
    }
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  bool? get headersWithoutContentType => null;

  void setAuthToken(String token) {
    _authToken = token;
    _storageService.saveAuthToken(token);
  }

  void clearAuthToken() {
    _authToken = null;
    _storageService.removeAuthToken();
  }

  /// Charge le token depuis StorageService
  Future<void> loadAuthToken() async {
    _authToken = await _storageService.getAuthToken();
    if (_authToken != null) {
      print('✅ Token d\'authentification chargé depuis StorageService');
    } else {
      print('⚠️ Aucun token d\'authentification trouvé dans StorageService');
    }
  }

  /// Récupère toutes les infrastructures
  Future<List<Infrastructure>> getInfrastructures({
    String? category,
    double? latitude,
    double? longitude,
    double? radius,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$_baseUrl${AppConstants.infrastructuresEndpoint}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('🌐 [API] Requête GET: $uri');
      print('🔑 [API] Headers: $_headers');

      final response = await http.get(uri, headers: _headers);

      print('📡 [API] Statut: ${response.statusCode}');
      print(
        '📦 [API] Body (200 premiers chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List ? data : data['data']) as List;
        print('✅ [API] ${list.length} infrastructures reçues');
        return list.map((e) => Infrastructure.fromJson(e)).toList();
      } else {
        print('❌ [API] Erreur: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 [API] Exception: $e');
      print('📍 [API] StackTrace: $stackTrace');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère une infrastructure spécifique
  Future<Infrastructure> getInfrastructure(String id) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.infrastructuresEndpoint}/$id',
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Infrastructure.fromJson(
          data is Map && data['data'] != null ? data['data'] : data,
        );
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'infrastructure: $e');
    }
  }

  /// Recherche d'infrastructures
  Future<List<Infrastructure>> searchInfrastructures(String query) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.infrastructuresEndpoint}?q=$query',
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List ? data : data['data']) as List;
        return list.map((e) => Infrastructure.fromJson(e)).toList();
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de recherche: $e');
    }
  }

  /// Soumet une nouvelle contribution
  Future<Contribution> submitContribution(Contribution contribution) async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.contributionsEndpoint}');
      print('DEBUG submitContribution URI=$uri');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(contribution.toJson()),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Contribution.fromJson(
          data is Map && data['data'] != null ? data['data'] : data,
        );
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la soumission: $e');
    }
  }

  /// Récupère les contributions de l'utilisateur
  Future<List<Contribution>> getUserContributions() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.userContributionsEndpoint}',
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List ? data : data['data']) as List;
        return list.map((e) => Contribution.fromJson(e)).toList();
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Upload d'image
  Future<String> uploadImage(String imagePath) async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.uploadImageEndpoint}');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers);

      // Déterminer le type MIME à partir de l'extension du fichier
      String contentType;
      final extension = imagePath.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Par défaut
      }

      // Lire le fichier et créer le MultipartFile avec le contentType explicite
      final fileBytes = await File(imagePath).readAsBytes();
      final fileName = imagePath.split('/').last;

      final file = http.MultipartFile(
        'image',
        http.ByteStream.fromBytes(fileBytes),
        fileBytes.length,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(file);

      print('📤 Upload image - ContentType: $contentType');
      print('📤 Upload image - FileName: $fileName');

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();

      print('📤 Upload image - Status: ${streamed.statusCode}');
      print('📤 Upload image - Response: $responseBody');

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final url =
            data['url'] ??
            data['data']?['url'] ??
            data['imageUrl'] ??
            data['data']?['imageUrl'];

        if (url == null || url.toString().isEmpty) {
          throw Exception(
            'L\'URL de l\'image n\'a pas été retournée par le serveur. Réponse: $responseBody',
          );
        }

        return url.toString();
      } else {
        throw Exception(
          'Erreur upload (${streamed.statusCode}): $responseBody',
        );
      }
    } catch (e) {
      print('❌ Erreur upload image: $e');
      throw Exception('Erreur d\'upload: $e');
    }
  }

  /// Authentification
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.authLoginEndpoint}');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) setAuthToken(data['token']);
        return data;
      } else {
        throw Exception(
          'Erreur login (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Connexion mobile (pour utilisateurs Firebase)
  Future<Map<String, dynamic>> loginMobile(String email) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.authLoginEndpoint}/mobile',
      );
      print('📱 loginMobile: POST $uri');
      print('📱 loginMobile: email=$email');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'email': email, 'firebaseAuth': true}),
      );
      print('📱 loginMobile: status=${response.statusCode}');
      print('📱 loginMobile: body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) setAuthToken(data['token']);
        return data;
      } else {
        throw Exception(
          'Erreur login mobile (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('📱 loginMobile: ERREUR $e');
      throw Exception('Erreur de connexion mobile: $e');
    }
  }

  /// Envoyer un code de vérification par email
  Future<void> sendVerificationCode(String email) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/send-verification-code');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Erreur envoi code (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du code de vérification: $e');
    }
  }

  /// Vérifier le code de vérification
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/verify-code');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Code de vérification invalide (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de vérification: $e');
    }
  }

  /// Inscription
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String? password, {
    bool firebaseAuth = false,
    String? verificationCode,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.authRegisterEndpoint}');
      final body = {
        'name': name,
        'email': email,
        if (password != null) 'password': password,
        if (firebaseAuth) 'firebaseAuth': true,
        if (verificationCode != null) 'verificationCode': verificationCode,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
          // Sauvegarder aussi dans StorageService
          final storageService = StorageService();
          await storageService.saveAuthToken(data['token']);
        }
        return data;
      } else {
        throw Exception(
          'Erreur inscription (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  /// Inscription via Supabase (après OTP vérifié). Envoie name, email, accessToken.
  Future<Map<String, dynamic>> registerSupabase({
    required String name,
    required String email,
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/register/supabase');
      final body = {'name': name, 'email': email, 'accessToken': accessToken};
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
          final storageService = StorageService();
          await storageService.saveAuthToken(data['token']);
        }
        return data;
      }
      throw Exception(
        'Inscription Supabase (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      throw Exception('Erreur inscription Supabase: $e');
    }
  }

  /// Connexion via Supabase. Envoie accessToken (obtenu après signInWithPassword).
  Future<Map<String, dynamic>> loginSupabase(String accessToken) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login/supabase');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': accessToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
          final storageService = StorageService();
          await storageService.saveAuthToken(data['token']);
        }
        return data;
      }
      throw Exception(
        'Connexion Supabase (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      throw Exception('Erreur connexion Supabase: $e');
    }
  }

  /// Valide si une chaîne est un UUID valide
  bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  /// Ajouter aux favoris
  Future<void> addToFavorites(String infrastructureId) async {
    try {
      // Valider que l'ID est un UUID valide (seulement pour l'envoi au backend)
      if (!_isValidUUID(infrastructureId)) {
        throw Exception(
          'ID d\'infrastructure invalide. L\'ID doit être un UUID valide pour être synchronisé avec le backend. Reçu: "$infrastructureId"',
        );
      }

      // S'assurer que le token est chargé
      if (_authToken == null) {
        loadAuthToken();
      }

      if (_authToken == null) {
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous connecter.',
        );
      }

      final uri = Uri.parse('$_baseUrl${AppConstants.favoritesEndpoint}');
      print('📤 Ajout du favori $infrastructureId au backend...');
      print('🔗 URL: $uri');
      print(
        '🔑 Token présent: ${_authToken != null ? "Oui (${_authToken!.length} caractères)" : "Non"}',
      );

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'infrastructureId': infrastructureId}),
      );

      print('📥 Réponse du backend: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Erreur lors de l\'ajout du favori: ${response.body}');
        throw Exception(
          'Erreur favoris (${response.statusCode}): ${response.body}',
        );
      }

      print('✅ Favori ajouté avec succès au backend');
    } catch (e) {
      print('❌ Erreur ajout favoris: $e');
      throw Exception('Erreur ajout favoris: $e');
    }
  }

  /// Retirer des favoris
  Future<void> removeFromFavorites(String infrastructureId) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.favoritesEndpoint}/$infrastructureId',
      );
      final response = await http.delete(uri, headers: _headers);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Erreur suppression favoris (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur suppression favoris: $e');
    }
  }

  /// Récupère les infrastructures favorites de l'utilisateur
  Future<List<Infrastructure>> getUserFavorites() async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.favoritesEndpoint}');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List ? data : data['data']) as List;
        return list.map((e) => Infrastructure.fromJson(e)).toList();
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère toutes les contributions
  Future<List<Contribution>> getContributions() async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.contributionsEndpoint}');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List ? data : data['data']) as List;
        return list.map((e) => Contribution.fromJson(e)).toList();
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Envoyer un signalement de problème pour une infrastructure
  /// [photos] : liste d’URLs d’images (obtenues via uploadImage) jointes au signalement
  Future<void> reportProblem({
    required String infrastructureId,
    required String type,
    required String description,
    List<String>? photos,
  }) async {
    try {
      // Valider que l'ID est un UUID valide (pour la synchro backend)
      if (!_isValidUUID(infrastructureId)) {
        throw Exception(
          'ID d\'infrastructure invalide. L\'ID doit être un UUID valide. Reçu: "$infrastructureId"',
        );
      }

      // S'assurer que le token est chargé
      if (_authToken == null) {
        loadAuthToken();
      }
      if (_authToken == null) {
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous connecter.',
        );
      }

      final uri = Uri.parse('$_baseUrl${AppConstants.signalementsEndpoint}');
      print('📤 Envoi du signalement pour $infrastructureId au backend...');
      print('🔗 URL: $uri');

      final body = <String, dynamic>{
        'infrastructureId': infrastructureId,
        'type': type,
        'description': description,
      };
      if (photos != null && photos.isNotEmpty) {
        body['photos'] = photos;
      }

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Réponse du backend (signalement): ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Erreur lors de l\'envoi du signalement: ${response.body}');
        throw Exception(
          'Erreur signalement (${response.statusCode}): ${response.body}',
        );
      }

      print('✅ Signalement enregistré avec succès dans le backend');
    } catch (e) {
      print('❌ Erreur envoi signalement: $e');
      throw Exception('Erreur envoi signalement: $e');
    }
  }

  /// Créer une nouvelle contribution
  Future<void> createContribution(Contribution contribution) async {
    await submitContribution(contribution);
  }

  /// Mettre à jour une contribution
  Future<void> updateContribution(String id, Contribution contribution) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.contributionsEndpoint}/$id',
      );
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(contribution.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Erreur mise à jour (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur update: $e');
    }
  }

  /// Supprimer une contribution
  Future<void> deleteContribution(String id) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${AppConstants.contributionsEndpoint}/$id',
      );
      final response = await http.delete(uri, headers: _headers);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Erreur suppression (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur suppression: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.healthEndpoint}');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère le profil de l'utilisateur connecté
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/me');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Le backend retourne directement l'objet utilisateur
        return data is Map ? data : data['data'] ?? data;
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Met à jour le profil de l'utilisateur connecté
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/profile');
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (avatarUrl != null) body['avatar'] = avatarUrl;

      print('📤 Mise à jour profil - URL: $uri');
      print('📤 Mise à jour profil - Body: $body');

      final response = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Mise à jour profil - Status: ${response.statusCode}');
      print('📥 Mise à jour profil - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? data : data['data'] ?? data;
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Enregistre le token FCM pour recevoir les notifications push
  Future<void> registerFcmToken(
    String token, {
    String platform = 'android',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/notifications/fcm-token');
      final body = {'token': token, 'platform': platform};

      print('📤 Enregistrement token FCM - URL: $uri');
      print('📤 Enregistrement token FCM - Platform: $platform');
      print(
        '📤 Enregistrement token FCM - Token: ${token.substring(0, 50)}...',
      );

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Enregistrement token FCM - Status: ${response.statusCode}');
      print('📥 Enregistrement token FCM - Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token FCM enregistré avec succès');
      } else {
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur enregistrement token FCM: $e');
      // Ne pas bloquer l'application si l'enregistrement du token échoue
      // Les notifications push sont optionnelles
    }
  }

  /// Vérifie si le token FCM est bien enregistré et le réenregistre si nécessaire
  Future<void> verifyAndRegisterFcmToken() async {
    try {
      // Obtenir le token FCM actuel
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Impossible d\'obtenir le token FCM');
        return;
      }

      print('🔍 Vérification du token FCM: ${fcmToken.substring(0, 50)}...');

      // Réenregistrer le token (l'API fera un upsert)
      final platform = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : 'web');

      await registerFcmToken(fcmToken, platform: platform);
      print('✅ Token FCM vérifié et réenregistré si nécessaire');
    } catch (e) {
      print('❌ Erreur lors de la vérification du token FCM: $e');
    }
  }

  /// Récupère les avis d'une infrastructure
  Future<List<Avis>> getAvis(String infrastructureId) async {
    try {
      print(
        '🔍 [AVIS] Récupération des avis pour infrastructure: $infrastructureId',
      );
      final uri = Uri.parse(
        '$_baseUrl/api/avis?infrastructure_id=$infrastructureId',
      );
      print('📍 [AVIS] URL: $uri');
      final response = await http.get(uri, headers: _headers);
      print('📡 [AVIS] Statut: ${response.statusCode}');
      print(
        '📦 [AVIS] Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list =
            (data is List ? data : (data['data'] ?? data['avis'] ?? []))
                as List;
        print('✅ [AVIS] ${list.length} avis trouvés');
        return list.map((e) => Avis.fromJson(e)).toList();
      } else {
        print('❌ [AVIS] Erreur: ${response.statusCode}');
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 [AVIS] Exception: $e');
      print('📍 [AVIS] StackTrace: $stackTrace');
      throw Exception('Erreur lors du chargement des avis: $e');
    }
  }

  /// Crée un nouvel avis (note + commentaire)
  Future<Avis> createAvis({
    required String infrastructureId,
    required int note,
    String? commentaire,
    List<String>? photos,
  }) async {
    try {
      print(
        '📝 [AVIS] Création d\'avis pour infrastructure: $infrastructureId',
      );
      final commentDisplay = (commentaire != null && commentaire.isNotEmpty)
          ? commentaire.substring(
              0,
              commentaire.length > 30 ? 30 : commentaire.length,
            )
          : 'vide';
      print('⭐ [AVIS] Note: $note, Commentaire: $commentDisplay');

      if (_authToken == null) {
        print('🔐 [AVIS] Token null, chargement...');
        await loadAuthToken();
      }
      if (_authToken == null) {
        print('❌ [AVIS] Token toujours null après chargement');
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous connecter.',
        );
      }
      print('✅ [AVIS] Token présent: ${_authToken?.substring(0, 20)}...');

      final uri = Uri.parse('$_baseUrl/api/avis');
      final body = {
        'infrastructureId': infrastructureId,
        'note': note,
        if (commentaire != null && commentaire.isNotEmpty)
          'commentaire': commentaire,
        if (photos != null && photos.isNotEmpty) 'photos': photos,
      };
      print('📤 [AVIS] Corps de la requête: $body');

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📡 [AVIS] Statut réponse: ${response.statusCode}');
      print('📦 [AVIS] Body réponse: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [AVIS] Avis créé avec succès');
        return Avis.fromJson(data['data'] ?? data);
      } else {
        print('❌ [AVIS] Erreur: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 [AVIS] Exception lors de la création: $e');
      print('📍 [AVIS] StackTrace: $stackTrace');
      throw Exception('Erreur lors de la création de l\'avis: $e');
    }
  }
}
