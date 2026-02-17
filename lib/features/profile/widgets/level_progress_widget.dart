import 'package:flutter/material.dart';
import '../../../core/models/level.dart';
import '../../../core/theme/app_theme.dart';

/// Widget pour afficher le niveau actuel et la progression vers le suivant
class LevelProgressWidget extends StatelessWidget {
  final Level currentLevel;
  final Level? nextLevel;
  final int totalPoints;
  final double progressPercentage;
  final int pointsToNextLevel;

  const LevelProgressWidget({
    Key? key,
    required this.currentLevel,
    this.nextLevel,
    required this.totalPoints,
    required this.progressPercentage,
    required this.pointsToNextLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getColorFromHex(currentLevel.color ?? '#96D0EE'),
              _getColorFromHex(
                currentLevel.color ?? '#96D0EE',
              ).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec niveau actuel
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    currentLevel.icon ?? '⭐',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLevel.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalPoints points',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (currentLevel.description != null) ...[
              const SizedBox(height: 12),
              Text(
                currentLevel.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withOpacity(0.9),
                ),
              ),
            ],

            // Progression vers le niveau suivant
            if (nextLevel != null) ...[
              const SizedBox(height: 20),
              const Divider(color: AppColors.primary),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prochain niveau',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    nextLevel!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barre de progression
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      minHeight: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plus que $pointsToNextLevel points !',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white54),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      'Niveau maximum atteint !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary; // Couleur par défaut
    }
  }
}

/// Widget compact pour afficher le niveau dans le profil
class LevelBadgeWidget extends StatelessWidget {
  final Level level;
  final int points;
  final double size;

  const LevelBadgeWidget({
    Key? key,
    required this.level,
    required this.points,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getColorFromHex(level.color ?? '#96D0EE'),
            _getColorFromHex(level.color ?? '#96D0EE').withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getColorFromHex(level.color ?? '#96D0EE').withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(level.icon ?? '⭐', style: TextStyle(fontSize: size * 0.35)),
            Text(
              '${level.id}',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
