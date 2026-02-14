import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_rewards.dart';
import '../models/level.dart';
import '../models/badge.dart';
import '../models/contribution_history.dart';
import '../models/leaderboard_entry.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

/// Service pour gérer les récompenses et les interactions avec l'API backend
class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final String _baseUrl = AppConstants.baseUrl;
  final StorageService _storageService = StorageService();

  String? _authToken;

  /// Charge le token d'authentification
  Future<void> loadAuthToken() async {
    _authToken = await _storageService.getAuthToken();
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// Récupère les récompenses de l'utilisateur actuellement connecté
  Future<UserRewards> getMyRewards() async {
    if (_authToken == null) await loadAuthToken();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/my-rewards'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserRewards.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous connecter.');
      } else {
        throw Exception(
          'Erreur lors de la récupération des récompenses: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les récompenses d'un utilisateur spécifique
  Future<UserRewards> getUserRewards(String userId) async {
    if (_authToken == null) await loadAuthToken();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/user/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserRewards.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous connecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else {
        throw Exception(
          'Erreur lors de la récupération des récompenses: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère l'historique des contributions de l'utilisateur connecté
  Future<ContributionHistoryPage> getMyContributionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) await loadAuthToken();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/my-history?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ContributionHistoryPage.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous connecter.');
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'historique: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère l'historique des contributions d'un utilisateur spécifique
  Future<ContributionHistoryPage> getUserContributionHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) await loadAuthToken();

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/rewards/history/$userId?page=$page&limit=$limit',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ContributionHistoryPage.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous connecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'historique: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère le classement des utilisateurs
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    // Le classement est public, pas besoin de token obligatoire
    if (_authToken == null) await loadAuthToken();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/leaderboard?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaderboardData = data['data'] as List<dynamic>;
        return leaderboardData
            .map(
              (entry) =>
                  LeaderboardEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération du classement: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère tous les niveaux disponibles
  Future<List<Level>> getAllLevels() async {
    // Les niveaux sont publics
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/levels'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final levelsData = data['data'] as List<dynamic>;
        return levelsData
            .map((level) => Level.fromJson(level as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des niveaux: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère tous les badges disponibles
  Future<List<Badge>> getAllBadges() async {
    // Les badges sont publics
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rewards/badges'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final badgesData = data['data'] as List<dynamic>;
        return badgesData
            .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des badges: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Méthode pour rafraîchir le token d'authentification
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Méthode pour nettoyer le token
  void clearAuthToken() {
    _authToken = null;
  }
}
