import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Géolocalisation Cotonou';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Géolocalisation des infrastructures de services publics à Cotonou';

  // Base URL - Backend déployé sur Render
  // ⚠️ IMPORTANT : Backend en production sur Render
  // Pour développement local, remplacez par :
  // - Émulateur Android : 'http://10.0.2.2:5000'
  // - Appareil physique (même WiFi) : 'http://VOTRE_IP_LOCALE:5000'
  static const String baseUrl =
      'https://backend-cotonav.onrender.com'; // Backend production sur Render

  /// Supabase Auth (OTP, mot de passe oublié). Même projet que le backend.
  /// Override via --dart-define=SUPABASE_URL=... et SUPABASE_ANON_KEY=... si besoin.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yejligyctalvhrzesjrb.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllamxpZ3ljdGFsdmhyemVzanJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MTE5MjQsImV4cCI6MjA3ODk4NzkyNH0.1tRmISHmictTP1VW4XTBTY9ehDZsTRUcGIfObazUJ9o',
  );

  /// Vérifie si une chaîne est encodée en Base64 ou en Data URI
  static bool isBase64(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    final trimmed = str.trim();
    if (trimmed.startsWith('data:image')) return true;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('/uploads')) {
      return false;
    }
    // Si la chaîne est longue et contient des caractères base64 sans URL http
    if (trimmed.length > 50 && !trimmed.startsWith('/')) {
      try {
        final clean = trimmed.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
        final decoded = base64Decode(clean);
        return decoded.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Normalise les URL d'images (convertit les chemins relatifs /uploads/... en URL absolues avec le backend)
  static String? normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return url;
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image') || isBase64(trimmed)) {
      return trimmed;
    }
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    var base = baseUrl;
    final prefix = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$prefix$path';
  }

  /// Retourne un ImageProvider adapté (CachedNetworkImage, MemoryImage pour base64, ou FileImage pour fichier local)
  static ImageProvider? getImageProvider(String? imageSource) {
    if (imageSource == null || imageSource.trim().isEmpty) return null;
    final trimmed = imageSource.trim();

    try {
      // 1. Data URI Base64 (data:image/...;base64,XXXX)
      if (trimmed.startsWith('data:image')) {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = trimmed.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', ''));
          return MemoryImage(bytes);
        }
      }

      // 2. Pure Base64 (longue chaîne sans protocole)
      if (isBase64(trimmed)) {
        final cleanBase64 = trimmed.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
        final bytes = base64Decode(cleanBase64);
        if (bytes.isNotEmpty) {
          return MemoryImage(bytes);
        }
      }

      // 3. Fichier local existant
      if (trimmed.startsWith('/') && File(trimmed).existsSync()) {
        return FileImage(File(trimmed));
      }

      // 4. URL HTTP / HTTPS distante
      final normalizedUrl = normalizeImageUrl(trimmed);
      if (normalizedUrl != null &&
          (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://'))) {
        return CachedNetworkImageProvider(normalizedUrl);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur getImageProvider: $e');
    }

    return null;
  }

  // Endpoints
  static const String infrastructuresEndpoint = '/api/infrastructures';
  static const String contributionsEndpoint = '/api/contributions';
  static const String signalementsEndpoint = '/api/signalements';
  static const String authLoginEndpoint = '/api/auth/login';
  static const String authRegisterEndpoint = '/api/auth/register';
  static const String userContributionsEndpoint = '/api/propositions/mine';
  static const String uploadImageEndpoint = '/api/upload';
  static const String favoritesEndpoint = '/api/favorites';
  static const String healthEndpoint = '/health';
  static const String rewardsEndpoint = '/api/rewards';
  static const String myRewardsEndpoint = '/api/rewards/my-rewards';
  static const String leaderboardEndpoint = '/api/rewards/leaderboard';
  static const String badgesEndpoint = '/api/rewards/badges';
  static const String levelsEndpoint = '/api/rewards/levels';
  static const String exchangeConfigEndpoint = '/api/rewards/exchange-config';
  static const String exchangeEndpoint = '/api/rewards/exchange';
  static const String myExchangesEndpoint = '/api/rewards/exchanges/my';

  // Map Configuration
  static const double defaultLatitude = 6.3654; // Cotonou latitude
  static const double defaultLongitude = 2.4183; // Cotonou longitude
  static const double defaultZoom = 12.0;
  static const double searchRadius = 5000; // 5km radius

  // Infrastructure Categories - Structure hiérarchique
  static const Map<String, List<String>> infrastructureServices = {
    'Services Administratifs': [
      'Mairie',
      'Préfecture',
      'Bureau de poste',
      'Centre des impôts',
      'Pôle emploi',
    ],
    'Services Éducatifs': [
      'École primaire',
      'Collège',
      'Lycée',
      'Université',
      'Bibliothèque',
    ],
    'Services de Santé': [
      'Hôpital',
      'Clinique',
      'Pharmacie',
      'Cabinet médical',
      'Dentiste',
    ],
    'Services Culturels et Récréatifs': [
      'Musée',
      'Théâtre',
      'Cinéma',
      'Parc',
      'Salle de sport',
    ],
    'Services Commerciaux': [
      'Supermarché',
      'Centre commercial',
      'Marché',
      'Banque',
      'Restaurant',
    ],
    'Services de Transport': [
      'Gare',
      'Aéroport',
      'Arrêt de bus',
      'Station de taxi',
    ],
    'Services Religieux': ['Église', 'Mosquée', 'Temple'],
    'Services d\'Urgence et de Sécurité': [
      'Commissariat',
      'Caserne de pompiers',
      'Hôpital d\'urgence',
      'Centre de secours',
    ],
    'Services Publics et Infrastructure': [
      'Eau et assainissement',
      'Centrale électrique',
      'Gestion des déchets et salubrité urbaine',
      'Station-service',
      'Parking public',
    ],
    'Services Sociaux et Communautaires': [
      'Centre social',
      'Crèche',
      'Centre de loisirs',
      'Association caritative',
    ],
  };

  // Getter pour maintenir la compatibilité avec le code existant
  static List<String> get infrastructureCategories =>
      infrastructureServices.keys.toList();

  // Couleurs pour chaque catégorie principale
  static const Map<String, Color> categoryColors = {
    'Services Administratifs': Color(0xFF2196F3),
    'Services Éducatifs': Color(0xFF2196F3),
    'Services de Santé': Color(0xFF2196F3),
    'Services Culturels et Récréatifs': Color(0xFF2196F3),
    'Services Commerciaux': Color(0xFF2196F3),
    'Services de Transport': Color(0xFF2196F3),
    'Services Religieux': Color(0xFF2196F3),
    'Services d\'Urgence et de Sécurité': Color(0xFF2196F3),
    'Services Publics et Infrastructure': Color(0xFF2196F3),
    'Services Sociaux et Communautaires': Color(0xFF2196F3),
  };

  // Icônes pour chaque catégorie principale
  static const Map<String, IconData> categoryIcons = {
    'Services Administratifs': Icons.account_balance,
    'Services Éducatifs': Icons.school,
    'Services de Santé': Icons.local_hospital,
    'Services Culturels et Récréatifs': Icons.museum,
    'Services Commerciaux': Icons.shopping_cart,
    'Services de Transport': Icons.directions_bus,
    'Services Religieux': Icons.place,
    'Services d\'Urgence et de Sécurité': Icons.emergency,
    'Services Publics et Infrastructure': Icons.build,
    'Services Sociaux et Communautaires': Icons.people,
  };

  // Icônes pour les sous-services
  static const Map<String, IconData> subServiceIcons = {
    // Services Administratifs
    'Mairie': Icons.location_city,
    'Préfecture': Icons.account_balance,
    'Bureau de poste': Icons.mail,
    'Centre des impôts': Icons.receipt,
    'Pôle emploi': Icons.work,

    // Services Éducatifs
    'École primaire': Icons.school,
    'Collège': Icons.school_outlined,
    'Lycée': Icons.school_sharp,
    'Université': Icons.account_balance,
    'Bibliothèque': Icons.library_books,

    // Services de Santé
    'Hôpital': Icons.local_hospital,
    'Clinique': Icons.medical_services,
    'Pharmacie': Icons.local_pharmacy,
    'Cabinet médical': Icons.medical_information,
    'Dentiste': Icons.healing,

    // Services Culturels et Récréatifs
    'Musée': Icons.museum,
    'Théâtre': Icons.theater_comedy,
    'Cinéma': Icons.movie,
    'Parc': Icons.park,
    'Salle de sport': Icons.fitness_center,

    // Services Commerciaux
    'Supermarché': Icons.shopping_cart,
    'Centre commercial': Icons.shopping_bag,
    'Marché': Icons.storefront,
    'Banque': Icons.account_balance,
    'Restaurant': Icons.restaurant,

    // Services de Transport
    'Gare': Icons.train,
    'Aéroport': Icons.flight,
    'Arrêt de bus': Icons.directions_bus,
    'Station de taxi': Icons.local_taxi,

    // Services Religieux
    'Église': Icons.church,
    'Mosquée': Icons.mosque,
    'Temple': Icons.temple_buddhist,

    // Services d'Urgence et de Sécurité
    'Commissariat': Icons.local_police,
    'Caserne de pompiers': Icons.fire_truck,
    'Hôpital d\'urgence': Icons.emergency,
    'Centre de secours': Icons.health_and_safety,

    // Services Publics et Infrastructure
    'Eau et assainissement': Icons.water_drop,
    'Centrale électrique': Icons.electrical_services,
    'Gestion des déchets et salubrité urbaine': Icons.cleaning_services,
    'Station-service': Icons.local_gas_station,
    'Parking public': Icons.local_parking,

    // Services Sociaux et Communautaires
    'Centre social': Icons.people,
    'Crèche': Icons.child_care,
    'Centre de loisirs': Icons.sports_esports,
    'Association caritative': Icons.volunteer_activism,
  };

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userProfileKey = 'user_profile';
  static const String userAvatarKey = 'user_avatar_url';
  static const String favoritesKey = 'favorites';
  static const String offlineDataKey = 'offline_data';
  static const String languageKey = 'language';

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 50;

  // Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'fr', 'name': 'Français'},
    {'code': 'en', 'name': 'Anglais'},
    {'code': 'fon', 'name': 'Fon'},
    {'code': 'yo', 'name': 'Yoruba'},
    {'code': 'guw', 'name': 'Goun'},
  ];

  // Validation
  static const int maxDescriptionLength = 500;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // Notification Types
  static const String newInfrastructureNotification = 'new_infrastructure';
  static const String maintenanceNotification = 'maintenance';
  static const String eventNotification = 'event';
}
