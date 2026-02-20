import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

final walletServiceProvider = Provider((ref) => WalletService());

/// Provider pour récupérer le portefeuille de l'utilisateur
final walletProvider = FutureProvider((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getMyWallet();
});

/// Provider pour récupérer le solde disponible
final availableBalanceProvider = FutureProvider((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getAvailableBalance();
});

/// Provider pour l'historique des transactions avec pagination
final transactionHistoryProvider =
    FutureProvider.family<List<Transaction>, int>((ref, page) async {
      final service = ref.watch(walletServiceProvider);
      return service.getTransactionHistory(page: page, limit: 20);
    });

/// Provider pour générer un code QR de retrait
final generateWithdrawalQRProvider =
    FutureProvider.family<Map<String, dynamic>, double>((ref, amount) async {
      final service = ref.watch(walletServiceProvider);
      return service.generateWithdrawalQR(amount: amount);
    });

/// Provider pour demander un retrait
final requestWithdrawalProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final service = ref.watch(walletServiceProvider);
      return service.requestWithdrawal(
        amount: params['amount'] as double,
        method: params['method'] as String,
        phone: params['phone'] as String?,
        accountNumber: params['account_number'] as String?,
        bankCode: params['bank_code'] as String?,
      );
    });
