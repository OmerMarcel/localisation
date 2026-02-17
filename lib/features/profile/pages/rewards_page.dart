import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/models/level.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/level_progress_widget.dart';
import '../widgets/badge_widget.dart';
import 'leaderboard_page.dart';
import 'contribution_history_page.dart';
import 'exchange_points_page.dart';

/// Écran principal des récompenses
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRewardsAsync = ref.watch(userRewardsProvider);
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final allLevelsAsync = ref.watch(allLevelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Récompenses'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textLight,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
            Tab(icon: Icon(Icons.currency_exchange), text: 'Echange'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Vue d'ensemble
          _buildOverviewTab(userRewardsAsync, allLevelsAsync),

          // Onglet 2: Badges
          _buildBadgesTab(userRewardsAsync, allBadgesAsync),

          // Onglet 3: Classement
          const LeaderboardPage(),

          // Onglet 4: Echange de points
          const ExchangePointsPage(),
        ],
      ),
    );
  }

  /// Onglet Vue d'ensemble
  Widget _buildOverviewTab(
    AsyncValue userRewardsAsync,
    AsyncValue allLevelsAsync,
  ) {
    return userRewardsAsync.when(
      data: (userRewards) {
        // Trouver le niveau suivant
        Level? nextLevel;
        if (allLevelsAsync.hasValue) {
          final allLevels = allLevelsAsync.value as List<Level>;
          final sortedLevels = List<Level>.from(allLevels)
            ..sort((a, b) => a.minPoints.compareTo(b.minPoints));

          final currentIndex = sortedLevels.indexWhere(
            (l) => l.id == userRewards.currentLevel.id,
          );

          if (currentIndex >= 0 && currentIndex < sortedLevels.length - 1) {
            nextLevel = sortedLevels[currentIndex + 1];
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRewardsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progression du niveau
                LevelProgressWidget(
                  currentLevel: userRewards.currentLevel,
                  nextLevel: nextLevel,
                  totalPoints: userRewards.totalPoints,
                  progressPercentage: userRewards.progressPercentage,
                  pointsToNextLevel: userRewards.pointsToNextLevel,
                ),

                const SizedBox(height: 24),

                // Statistiques rapides
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.emoji_events,
                        label: 'Badges',
                        value: '${userRewards.badges.length}',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.whatshot,
                        label: 'Points',
                        value: '${userRewards.totalPoints}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildExchangeCtaCard(),

                const SizedBox(height: 24),

                // Badges récents
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Badges débloqués',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (userRewards.badges.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun badge débloqué pour le moment',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continuez à contribuer pour débloquer des badges !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: userRewards.badges.length,
                      itemBuilder: (context, index) {
                        final badge = userRewards.badges[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: BadgeWidget(
                            badge: badge,
                            isUnlocked: true,
                            size: 90,
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Historique des contributions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historique récent',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ContributionHistoryPage(),
                          ),
                        );
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildRecentHistory(),
              ],
            ),
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
              onPressed: () => ref.invalidate(userRewardsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet Badges
  Widget _buildBadgesTab(
    AsyncValue userRewardsAsync,
    AsyncValue allBadgesAsync,
  ) {
    return allBadgesAsync.when(
      data: (allBadges) {
        return userRewardsAsync.when(
          data: (userRewards) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allBadgesProvider);
                ref.invalidate(userRewardsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé
                    Card(
                      color: AppColors.primary.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${userRewards.badges.length}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text('Débloqués'),
                              ],
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${allBadges.length - userRewards.badges.length}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Text('Restants'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Tous les badges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    BadgeGridWidget(
                      allBadges: allBadges,
                      unlockedBadges: userRewards.badges,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }

  /// Widget pour les cartes de statistiques
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeCtaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.currency_exchange,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Echanger mes points',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transformez vos points en argent',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(3),
              child: const Text('Ouvrir'),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour l'historique récent
  Widget _buildRecentHistory() {
    final historyAsync = ref.watch(contributionHistoryProvider(1));

    return historyAsync.when(
      data: (historyPage) {
        if (historyPage.contributions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Aucune contribution pour le moment',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyPage.contributions.take(5).length,
          itemBuilder: (context, index) {
            final contribution = historyPage.contributions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(contribution.icon),
              ),
              title: Text(contribution.typeLabel),
              subtitle: Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(contribution.createdAt),
              ),
              trailing: Text(
                '+${contribution.pointsEarned} pts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Erreur de chargement de l\'historique',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
