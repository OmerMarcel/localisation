import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/wallet_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/wallet.dart';
import 'withdrawal_qr_page.dart';

/// Page du portefeuille utilisateur
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final transactionHistoryAsync = ref.watch(
      transactionHistoryProvider(_currentPage),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletProvider);
        ref.invalidate(transactionHistoryProvider(_currentPage));
      },
      child: walletAsync.when(
        data: (wallet) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildBalanceCard(wallet),
              SizedBox(height: AppDimensions.spacingM),
              _buildQuickActionsCard(context),
              SizedBox(height: AppDimensions.spacingM),
              _buildTransactionHistoryCard(context, transactionHistoryAsync),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  /// Card affichant le solde en détail
  Widget _buildBalanceCard(Wallet wallet) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return Container(
      margin: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mon Portefeuille',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                Icon(Icons.wallet, color: Colors.white, size: 28),
              ],
            ),
            SizedBox(height: AppDimensions.spacingL),

            // Solde total
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde Total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  currencyFormat.format(wallet.totalBalance),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimensions.spacingL),

            // Soldes disponible et en attente
            Row(
              children: [
                Expanded(
                  child: _buildBalanceInfo(
                    label: 'Disponible',
                    amount: wallet.availableBalance,
                    icon: Icons.check_circle,
                    color: Colors.greenAccent,
                  ),
                ),
                SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: _buildBalanceInfo(
                    label: 'En attente',
                    amount: wallet.pendingBalance,
                    icon: Icons.schedule,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimensions.spacingM),

            // Dernière mise à jour
            Text(
              'Mis à jour: ${DateFormat('dd/MM/yyyy HH:mm').format(wallet.lastUpdated)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour afficher info de solde (disponible/en attente)
  Widget _buildBalanceInfo({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppDimensions.spacingS),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingS),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Card avec les actions rapides (retrait via QR)
  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Retrait par QR',
                  icon: Icons.qr_code_2,
                  color: AppColors.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WithdrawalQRPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Historique',
                  icon: Icons.history,
                  color: AppColors.secondary,
                  onPressed: () {
                    // Scroll to transactions
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bouton d'action
  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }

  /// Card affichant l'historique des transactions
  Widget _buildTransactionHistoryCard(
    BuildContext context,
    AsyncValue<List<Transaction>> transactionHistoryAsync,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique des Transactions',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(label: const Text('Voir plus'), onDeleted: () {}),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM),
          transactionHistoryAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        SizedBox(height: AppDimensions.spacingM),
                        Text(
                          'Aucune transaction pour le moment',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: AppDimensions.spacingS),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionTile(transaction);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: EdgeInsets.all(AppDimensions.spacingM),
              child: Text('Erreur: $error'),
            ),
          ),
        ],
      ),
    );
  }

  /// Tile affichant une transaction
  Widget _buildTransactionTile(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icon avec couleur selon le type
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTransactionTypeColor(
                transaction.type,
              ).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTransactionTypeIcon(transaction.type),
              color: _getTransactionTypeColor(transaction.type),
            ),
          ),

          SizedBox(width: AppDimensions.spacingM),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.getTypeLabel(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  transaction.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: AppDimensions.spacingM),

          // Montant et statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormat.format(transaction.amount)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTransactionTypeColor(transaction.type),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: AppDimensions.spacingS),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: transaction.getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.getStatusLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: transaction.getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error.withOpacity(0.5),
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text('Erreur lors du chargement', style: AppTextStyles.h3),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                // Retry logic
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'contribution':
        return Colors.blue;
      case 'exchange':
        return Colors.purple;
      case 'withdrawal':
        return Colors.orange;
      case 'refund':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type) {
      case 'contribution':
        return Icons.add_location;
      case 'exchange':
        return Icons.currency_exchange;
      case 'withdrawal':
        return Icons.payments;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }
}
