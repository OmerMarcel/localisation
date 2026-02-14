import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../widgets/level_progress_widget.dart';

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
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun classement disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
      rankColor = Colors.amber[700];
      rankIcon = const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
    } else if (entry.rank == 2) {
      rankColor = Colors.grey[400];
      rankIcon = Icon(Icons.emoji_events, color: Colors.grey[400], size: 28);
    } else if (entry.rank == 3) {
      rankColor = Colors.brown[400];
      rankIcon = Icon(Icons.emoji_events, color: Colors.brown[400], size: 28);
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
                    color: Colors.grey[700],
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
              backgroundColor: Colors.indigo[100],
              backgroundImage: entry.userProfileImage != null
                  ? NetworkImage(entry.userProfileImage!)
                  : null,
              child: entry.userProfileImage == null
                  ? Text(
                      entry.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
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
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.levelName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.badgesCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                ? rankColor!.withOpacity(0.1)
                : Colors.grey[100],
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
                  color: entry.rank <= 3 ? rankColor : Colors.grey[700],
                ),
              ),
              Text(
                'points',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
