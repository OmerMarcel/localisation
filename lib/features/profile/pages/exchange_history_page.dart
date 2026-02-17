import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/reward_exchange.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/theme/app_theme.dart';

class ExchangeHistoryPage extends ConsumerStatefulWidget {
  const ExchangeHistoryPage({super.key});

  @override
  ConsumerState<ExchangeHistoryPage> createState() =>
      _ExchangeHistoryPageState();
}

class _ExchangeHistoryPageState extends ConsumerState<ExchangeHistoryPage> {
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    final historyAsync = ref.read(exchangeHistoryProvider(_currentPage));
    await historyAsync.when(
      data: (historyPage) {
        if (_currentPage < historyPage.totalPages) {
          setState(() {
            _currentPage++;
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(exchangeHistoryProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des echanges'),
        backgroundColor: AppColors.primary,
      ),
      body: historyAsync.when(
        data: (historyPage) {
          if (historyPage.exchanges.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _currentPage = 1;
              });
              ref.invalidate(exchangeHistoryProvider(_currentPage));
            },
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total des echanges',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${historyPage.totalCount}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Page ${historyPage.currentPage} sur ${historyPage.totalPages}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: historyPage.exchanges.length + 1,
                    itemBuilder: (context, index) {
                      if (index == historyPage.exchanges.length) {
                        if (_currentPage < historyPage.totalPages) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox();
                      }

                      return _buildExchangeTile(historyPage.exchanges[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage = 1;
                  });
                  ref.invalidate(exchangeHistoryProvider(_currentPage));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(Icons.currency_exchange, color: statusColor),
        ),
        title: Text(
          '${exchange.pointsExchanged} pts = ${amountFormat.format(exchange.amountCfa)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.currency_exchange,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun echange',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Effectuez un echange pour voir votre historique',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
