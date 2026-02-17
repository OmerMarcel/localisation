import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/exchange_config.dart';
import '../../../core/models/user_rewards.dart';
import '../../../core/models/reward_exchange.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/services/reward_service.dart';
import '../../../core/theme/app_theme.dart';
import 'exchange_history_page.dart';

class ExchangePointsPage extends ConsumerStatefulWidget {
  const ExchangePointsPage({super.key});

  @override
  ConsumerState<ExchangePointsPage> createState() => _ExchangePointsPageState();
}

class _ExchangePointsPageState extends ConsumerState<ExchangePointsPage> {
  final TextEditingController _pointsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRewardsAsync = ref.watch(userRewardsProvider);
    final exchangeConfigAsync = ref.watch(exchangeConfigProvider);

    return userRewardsAsync.when(
      data: (userRewards) {
        return exchangeConfigAsync.when(
          data: (config) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userRewardsProvider);
                ref.invalidate(exchangeConfigProvider);
                ref.invalidate(exchangeHistoryProvider(1));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(userRewards, config),
                  const SizedBox(height: 16),
                  _buildExchangeForm(userRewards, config),
                  const SizedBox(height: 24),
                  _buildRecentExchanges(),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(
            'Erreur configuration',
            error.toString(),
            () => ref.invalidate(exchangeConfigProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(
        'Erreur récompenses',
        error.toString(),
        () => ref.invalidate(userRewardsProvider),
      ),
    );
  }

  Widget _buildSummaryCard(UserRewards userRewards, ExchangeConfig config) {
    final amountFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Echange de points',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Solde actuel'),
                Text(
                  '${userRewards.totalPoints} pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Taux'),
                Text('${config.ratePerPoint} F / pt'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seuil minimum'),
                Text(
                  '${config.minPoints} pts (${amountFormat.format(config.minAmountCfa)})',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeForm(UserRewards userRewards, ExchangeConfig config) {
    final points = int.tryParse(_pointsController.text) ?? 0;
    final amount = points * config.ratePerPoint;
    final amountFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demander un echange',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nombre de points',
                border: const OutlineInputBorder(),
                helperText: 'Minimum ${config.minPoints} points',
                errorText: _errorMessage,
              ),
              onChanged: (_) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant estime'),
                Text(
                  amountFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitExchange(userRewards, config),
                icon: const Icon(Icons.currency_exchange),
                label: Text(
                  _isSubmitting ? 'Traitement...' : 'Echanger maintenant',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExchanges() {
    final exchangesAsync = ref.watch(exchangeHistoryProvider(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Echanges recents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExchangeHistoryPage(),
                  ),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        exchangesAsync.when(
          data: (history) {
            if (history.exchanges.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: history.exchanges
                  .take(5)
                  .map(_buildExchangeTile)
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(
            'Erreur echanges',
            error.toString(),
            () => ref.invalidate(exchangeHistoryProvider(1)),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeTile(RewardExchange exchange) {
    final amountFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    switch (exchange.status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.warning;
        break;
      case 'failed':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(Icons.currency_exchange, color: statusColor),
        ),
        title: Text(
          '${exchange.pointsExchanged} pts = ${amountFormat.format(exchange.amountCfa)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateFormat.format(exchange.createdAt)),
        trailing: Text(
          exchange.statusLabel,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.currency_exchange,
            size: 48,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun echange pour le moment',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitExchange(
    UserRewards userRewards,
    ExchangeConfig config,
  ) async {
    final raw = _pointsController.text.trim();
    final points = int.tryParse(raw) ?? 0;

    if (points <= 0) {
      setState(() {
        _errorMessage = 'Entrez un nombre valide.';
      });
      return;
    }

    if (points < config.minPoints) {
      setState(() {
        _errorMessage = 'Minimum ${config.minPoints} points.';
      });
      return;
    }

    if (points > userRewards.totalPoints) {
      setState(() {
        _errorMessage = 'Points insuffisants.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final rewardService = RewardService();
      final result = await rewardService.requestExchange(points: points);

      if (!mounted) return;

      _pointsController.clear();
      ref.invalidate(userRewardsProvider);
      ref.invalidate(exchangeHistoryProvider(1));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Echange reussi: ${result.pointsExchanged} pts = ${result.amountCfa} F CFA',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
