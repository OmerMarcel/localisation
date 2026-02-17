import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../core/theme/app_theme.dart';

/// Page du classement des utilisateurs
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (leaderboard) {
        if (leaderboard.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  size: 80,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun classement disponible',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderboardProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return _buildLeaderboardTile(context, entry, ref);
            },
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
              onPressed: () => ref.invalidate(leaderboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    LeaderboardEntry entry,
    WidgetRef ref,
  ) {
    // Couleurs spéciales pour le top 3
    Color? rankColor;
    Widget? rankIcon;

    if (entry.rank == 1) {
      rankColor = AppColors.primary;
      rankIcon = const Icon(
        Icons.emoji_events,
        color: AppColors.primary,
        size: 32,
      );
    } else if (entry.rank == 2) {
      rankColor = AppColors.secondary;
      rankIcon = const Icon(
        Icons.emoji_events,
        color: AppColors.secondary,
        size: 28,
      );
    } else if (entry.rank == 3) {
      rankColor = AppColors.accent;
      rankIcon = const Icon(
        Icons.emoji_events,
        color: AppColors.accent,
        size: 28,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: entry.rank <= 3 ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: entry.rank <= 3
            ? BorderSide(color: rankColor!, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Rang
        leading: SizedBox(
          width: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (rankIcon != null)
                rankIcon
              else
                Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        // Avatar et nom
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: entry.userProfileImage != null
                  ? NetworkImage(entry.userProfileImage!)
                  : null,
              child: entry.userProfileImage == null
                  ? Text(
                      entry.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: entry.rank <= 3
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.levelName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.badgesCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Points
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: entry.rank <= 3
                ? rankColor!.withOpacity(0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      entry.rank <= 3 ? rankColor : AppColors.textSecondary,
                ),
              ),
              Text(
                'points',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
