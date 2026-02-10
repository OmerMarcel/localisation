import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/user_activity.dart';
import '../../../core/models/infrastructure.dart';
import '../../../core/models/contribution.dart';
import '../../map/map_screen.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(userActivitiesProvider);
    final recentSearches = ref.watch(searchProvider.notifier).getRecentSearches();
    final favoritesAsync = ref.watch(favoriteInfrastructuresProvider);
    final contributionsAsync = ref.watch(userContributionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userActivitiesProvider);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text('Effacer tout l\'historique'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userActivitiesProvider);
          ref.invalidate(favoriteInfrastructuresProvider);
          ref.invalidate(userContributionsProvider);
        },
        child: favoritesAsync.when(
          data: (favorites) => contributionsAsync.when(
            data: (contributions) {
              if (activities.isEmpty &&
                  recentSearches.isEmpty &&
                  favorites.isEmpty &&
                  contributions.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                children: [
                  _buildStatsSection(
                    context,
                    activities,
                    favorites.length,
                    contributions.length,
                    recentSearches.length,
                  ),
                  SizedBox(height: AppDimensions.spacingL),
                  if (activities.isNotEmpty) ...[
                    _buildSectionTitle('Activités récentes'),
                    SizedBox(height: AppDimensions.spacingM),
                    _buildActivitiesList(context, activities, ref),
                    SizedBox(height: AppDimensions.spacingL),
                  ],
                  if (recentSearches.isNotEmpty) ...[
                    _buildSectionTitle('Recherches récentes'),
                    SizedBox(height: AppDimensions.spacingM),
                    _buildRecentSearchesList(context, recentSearches, ref),
                    SizedBox(height: AppDimensions.spacingL),
                  ],
                  if (favorites.isNotEmpty) ...[
                    _buildSectionTitle('Favoris ajoutés'),
                    SizedBox(height: AppDimensions.spacingM),
                    _buildFavoritesList(context, favorites, ref),
                    SizedBox(height: AppDimensions.spacingL),
                  ],
                  if (contributions.isNotEmpty) ...[
                    _buildSectionTitle('Contributions'),
                    SizedBox(height: AppDimensions.spacingM),
                    _buildContributionsList(context, contributions),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState(context, __, ref),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorState(context, __, ref),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.spacingL),
          Text(
            'Aucun historique',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'Votre historique d\'activités apparaîtra ici au fur et à mesure que vous utilisez l\'application.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    List<UserActivity> activities,
    int favoritesCount,
    int contributionsCount,
    int searchesCount,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          children: [
            Text('Statistiques', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Activités', activities.length.toString(), AppColors.primary),
                _buildStatItem('Favoris', favoritesCount.toString(), AppColors.warning),
                _buildStatItem('Contributions', contributionsCount.toString(), AppColors.success),
                _buildStatItem('Recherches', searchesCount.toString(), AppColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h4.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActivitiesList(
    BuildContext context,
    List<UserActivity> activities,
    WidgetRef ref,
  ) {
    // Grouper les activités par date
    final groupedActivities = <String, List<UserActivity>>{};
    for (final activity in activities) {
      final dateKey = _formatDateKey(activity.createdAt);
      groupedActivities.putIfAbsent(dateKey, () => []).add(activity);
    }

    return Column(
      children: groupedActivities.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
              child: Text(
                entry.key,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...entry.value.map((activity) => _buildActivityCard(context, activity, ref)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    UserActivity activity,
    WidgetRef ref,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.type).withOpacity(0.1),
          child: Icon(
            activity.type.icon,
            color: _getActivityColor(activity.type),
            size: 20,
          ),
        ),
        title: Text(
          activity.type.label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.targetName != null)
              Text(
                activity.targetName!,
                style: AppTextStyles.bodySmall,
              ),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              _formatTime(activity.createdAt),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => _handleActivityTap(context, activity, ref),
      ),
    );
  }

  Widget _buildRecentSearchesList(
    BuildContext context,
    List<String> searches,
    WidgetRef ref,
  ) {
    return Column(
      children: searches.take(10).map((search) {
        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: ListTile(
            leading: const Icon(Icons.search, color: AppColors.primary),
            title: Text(search, style: AppTextStyles.bodyMedium),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                final searches = ref.read(searchProvider.notifier).getRecentSearches();
                searches.remove(search);
                ref.read(searchProvider.notifier).clearRecentSearches();
                for (final s in searches) {
                  ref.read(searchProvider.notifier).updateQuery(s);
                }
              },
            ),
            onTap: () {
              // Naviguer vers la recherche
              ref.read(searchProvider.notifier).updateQuery(search);
              Navigator.pop(context);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    List<Infrastructure> favorites,
    WidgetRef ref,
  ) {
    return Column(
      children: favorites.take(10).map((favorite) {
        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: ListTile(
            leading: const Icon(Icons.star, color: AppColors.warning),
            title: Text(favorite.name, style: AppTextStyles.bodyMedium),
            subtitle: Text(
              favorite.address.isNotEmpty
                  ? favorite.address
                  : 'Adresse non disponible',
              style: AppTextStyles.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContributionsList(
    BuildContext context,
    List<Contribution> contributions,
  ) {
    return Column(
      children: contributions.take(10).map((contribution) {
        final statusInfo = _getStatusInfo(contribution.status);
        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: ListTile(
            leading: Icon(
              statusInfo['icon'] as IconData,
              color: statusInfo['color'] as Color,
            ),
            title: Text(contribution.name, style: AppTextStyles.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusInfo['label'] as String,
                  style: AppTextStyles.bodySmall,
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Soumis le ${_formatDate(contribution.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              // Afficher les détails de la contribution
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            SizedBox(height: AppDimensions.spacingL),
            Text('Erreur de chargement', style: AppTextStyles.h3),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              error.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(userActivitiesProvider);
                ref.invalidate(favoriteInfrastructuresProvider);
                ref.invalidate(userContributionsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(UserActivityType type) {
    switch (type) {
      case UserActivityType.infrastructureViewed:
        return AppColors.primary;
      case UserActivityType.favoriteAdded:
        return AppColors.warning;
      case UserActivityType.favoriteRemoved:
        return AppColors.textSecondary;
      case UserActivityType.contributionCreated:
        return AppColors.success;
      case UserActivityType.contributionUpdated:
        return AppColors.info;
      case UserActivityType.searchPerformed:
        return AppColors.primary;
      case UserActivityType.commentAdded:
        return AppColors.info;
      case UserActivityType.reportSubmitted:
        return AppColors.error;
      case UserActivityType.routeCalculated:
        return AppColors.primary;
    }
  }

  void _handleActivityTap(
    BuildContext context,
    UserActivity activity,
    WidgetRef ref,
  ) {
    switch (activity.type) {
      case UserActivityType.infrastructureViewed:
      case UserActivityType.favoriteAdded:
      case UserActivityType.favoriteRemoved:
        if (activity.targetId != null) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(),
            ),
          );
        }
        break;
      case UserActivityType.contributionCreated:
      case UserActivityType.contributionUpdated:
        // Naviguer vers les contributions
        break;
      case UserActivityType.searchPerformed:
        if (activity.targetName != null) {
          ref.read(searchProvider.notifier).updateQuery(activity.targetName!);
          Navigator.pop(context);
        }
        break;
      default:
        break;
    }
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    final statusLower = status?.toLowerCase() ?? 'pending';

    if (statusLower == 'validated' ||
        statusLower == 'validée' ||
        statusLower == 'approved') {
      return {
        'label': 'Validée',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      };
    } else if (statusLower == 'rejected' ||
        statusLower == 'rejetée' ||
        statusLower == 'refused') {
      return {
        'label': 'Rejetée',
        'icon': Icons.cancel,
        'color': AppColors.error,
      };
    } else {
      return {
        'label': 'En attente de validation',
        'icon': Icons.pending,
        'color': AppColors.warning,
      };
    }
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer tout votre historique d\'activités ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userActivitiesProvider.notifier).clearAllActivities();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historique effacé avec succès'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}

