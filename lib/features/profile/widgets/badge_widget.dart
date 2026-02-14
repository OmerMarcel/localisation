import 'package:flutter/material.dart';
import '../../../core/models/badge.dart' as model;

/// Widget pour afficher un badge
class BadgeWidget extends StatelessWidget {
  final model.Badge badge;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final double size;

  const BadgeWidget({
    Key? key,
    required this.badge,
    required this.isUnlocked,
    this.onTap,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? _getColorFromHex(badge.color ?? '#FFD700')
                  : Colors.grey[300],
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: _getColorFromHex(
                          badge.color ?? '#FFD700',
                        ).withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Stack(
                children: [
                  // Icône ou emoji du badge
                  Center(
                    child: Text(
                      badge.icon ?? '🏆',
                      style: TextStyle(
                        fontSize: size * 0.5,
                        color: isUnlocked ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                  // Cadenas si non débloqué
                  if (!isUnlocked)
                    Positioned(
                      bottom: size * 0.1,
                      right: size * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock,
                          size: size * 0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size * 1.2,
            child: Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: isUnlocked ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.amber; // Couleur par défaut
    }
  }
}

/// Widget pour afficher une grille de badges
class BadgeGridWidget extends StatelessWidget {
  final List<model.Badge> allBadges;
  final List<model.Badge> unlockedBadges;
  final Function(model.Badge)? onBadgeTap;

  const BadgeGridWidget({
    Key? key,
    required this.allBadges,
    required this.unlockedBadges,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final isUnlocked = unlockedBadges.any((b) => b.id == badge.id);

        return BadgeWidget(
          badge: badge,
          isUnlocked: isUnlocked,
          onTap: () {
            if (onBadgeTap != null) {
              onBadgeTap!(badge);
            } else {
              _showBadgeDetails(context, badge, isUnlocked);
            }
          },
        );
      },
    );
  }

  void _showBadgeDetails(
    BuildContext context,
    model.Badge badge,
    bool isUnlocked,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon ?? '🏆', style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(badge.name, style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge.description != null) ...[
              Text(badge.description!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock_outline,
                  color: isUnlocked ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isUnlocked ? 'Badge débloqué !' : 'Badge verrouillé',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Condition: ${badge.requiredCount} ${badge.category}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
