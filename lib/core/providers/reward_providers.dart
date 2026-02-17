import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:riverpod/riverpod.dart';
import '../models/user_rewards.dart';
import '../models/level.dart';
import '../models/badge.dart';
import '../models/contribution_history.dart';
import '../models/leaderboard_entry.dart';
import '../models/exchange_config.dart';
import '../models/reward_exchange.dart';
import '../services/reward_service.dart';

/// Provider pour l'instance du RewardService
final rewardServiceProvider = Provider<RewardService>((ref) {
  return RewardService();
});

/// Provider pour récupérer les récompenses de l'utilisateur connecté
final userRewardsProvider = FutureProvider<UserRewards>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return await rewardService.getMyRewards();
});

/// Provider pour récupérer l'historique des contributions
final contributionHistoryProvider =
    FutureProvider.family<ContributionHistoryPage, int>((ref, page) async {
      final rewardService = ref.watch(rewardServiceProvider);
      return await rewardService.getMyContributionHistory(
        page: page,
        limit: 20,
      );
    });

/// Provider pour récupérer le classement
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return await rewardService.getLeaderboard(limit: 50);
});

/// Provider pour récupérer tous les niveaux
final allLevelsProvider = FutureProvider<List<Level>>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return await rewardService.getAllLevels();
});

/// Provider pour récupérer tous les badges
final allBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return await rewardService.getAllBadges();
});

/// Provider pour récupérer la configuration d'echange
final exchangeConfigProvider = FutureProvider<ExchangeConfig>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return await rewardService.getExchangeConfig();
});

/// Provider pour récupérer l'historique des echanges
final exchangeHistoryProvider =
    FutureProvider.family<PaginatedExchangeHistory, int>((ref, page) async {
      final rewardService = ref.watch(rewardServiceProvider);
      return await rewardService.getMyExchanges(page: page, limit: 20);
    });

/// Provider pour savoir si l'utilisateur a progressé de niveau récemment
/// (peut être utilisé pour afficher une animation)
final levelUpNotificationProvider = StateProvider<bool>((ref) => false);

/// Provider pour le filtre d'historique de contributions
final contributionHistoryFilterProvider = StateProvider<String?>((ref) => null);

/// Provider pour la page courante de l'historique
final contributionHistoryPageProvider = StateProvider<int>((ref) => 1);
