import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// Service pour gérer le portefeuille utilisateur
class WalletService {
  static const String _tag = '💰 WalletService';

  final String _baseUrl = AppConstants.baseUrl;
  String? _authToken;

  final StorageService _storageService = StorageService();

  WalletService() {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    _authToken = await _storageService.getAuthToken();
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('$_tag $message');
  }

  /// Récupérer le portefeuille de l'utilisateur actuellement connecté
  Future<Wallet> getMyWallet() async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('📥 Récupération du portefeuille...');

      final response = await http
          .get(Uri.parse('$_baseUrl/api/wallet/my-wallet'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('✅ Portefeuille récupéré');
        return Wallet.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié. Veuillez vous connecter.');
      } else {
        throw Exception(
          'Erreur lors de la récupération du portefeuille: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('❌ Erreur: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer le solde disponible
  Future<double> getAvailableBalance() async {
    try {
      final wallet = await getMyWallet();
      return wallet.availableBalance;
    } catch (e) {
      _log('❌ Erreur récupération solde: $e');
      rethrow;
    }
  }

  /// Demander un retrait
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method, // 'mobile_money', 'bank_account'
    String? phone,
    String? accountNumber,
    String? bankCode,
  }) async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('💸 Demande de retrait: $amount FCFA via $method');

      final payload = {
        'amount': amount,
        'method': method,
        if (phone != null) 'phone': phone,
        if (accountNumber != null) 'account_number': accountNumber,
        if (bankCode != null) 'bank_code': bankCode,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/wallet/request-withdrawal'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _log('✅ Retrait demandé: ${data['data']['reference_id']}');
        return data['data'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la demande de retrait',
        );
      }
    } catch (e) {
      _log('❌ Erreur retrait: $e');
      throw Exception('Erreur lors du retrait: $e');
    }
  }

  /// Générer un code QR pour retrait
  Future<Map<String, dynamic>> generateWithdrawalQR({
    required double amount,
  }) async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('🎫 Génération du code QR pour retrait: $amount FCFA');

      final payload = {'amount': amount};

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/wallet/generate-withdrawal-qr'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _log('✅ Code QR généré');
        return data['data'];
      } else {
        throw Exception('Erreur lors de la génération du code QR');
      }
    } catch (e) {
      _log('❌ Erreur QR: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer l'historique des transactions
  Future<List<Transaction>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type, // 'contribution', 'exchange', 'withdrawal', 'refund'
  }) async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('📜 Récupération de l\'historique (page $page)');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/api/wallet/transactions',
            ).replace(queryParameters: queryParams),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = ((data['data'] as List<dynamic>?) ?? [])
            .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
            .toList();
        _log('✅ ${transactions.length} transactions récupérées');
        return transactions;
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      _log('❌ Erreur historique: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// Vérifier l'état d'une transaction
  Future<Transaction> getTransactionStatus(String transactionId) async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('🔍 Vérification transaction: $transactionId');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/wallet/transactions/$transactionId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('✅ Statut récupéré');
        return Transaction.fromJson(data['data']);
      } else {
        throw Exception('Transaction introuvable');
      }
    } catch (e) {
      _log('❌ Erreur statut: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// Annuler une demande de retrait (si en attente)
  Future<bool> cancelWithdrawalRequest(String withdrawalId) async {
    if (_authToken == null) await _loadAuthToken();

    try {
      _log('❌ Annulation du retrait: $withdrawalId');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/wallet/cancel-withdrawal/$withdrawalId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _log('✅ Retrait annulé');
        return true;
      } else {
        throw Exception('Impossible d\'annuler ce retrait');
      }
    } catch (e) {
      _log('❌ Erreur annulation: $e');
      throw Exception('Erreur: $e');
    }
  }
}
