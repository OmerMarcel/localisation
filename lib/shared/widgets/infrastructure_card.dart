import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/infrastructure.dart';
import '../../core/providers/app_providers.dart';

class InfrastructureCard extends ConsumerWidget {
  final Infrastructure infrastructure;
  final VoidCallback? onTap;
  final bool showDistance;

  const InfrastructureCard({
    super.key,
    required this.infrastructure,
    this.onTap,
    this.showDistance = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(infrastructure.id);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône de catégorie
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[infrastructure.category]
                          ?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(infrastructure.category),
                      color: AppColors.categoryColors[infrastructure.category],
                      size: AppDimensions.iconL,
                    ),
                  ),

                  SizedBox(width: AppDimensions.spacingM),

                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          infrastructure.name,
                          style: AppTextStyles.h4,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppDimensions.spacingXs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingS,
                            vertical: AppDimensions.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors
                                .categoryColors[infrastructure.category]
                                ?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            infrastructure.category,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors
                                  .categoryColors[infrastructure.category],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bouton favori
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(infrastructure.id);
                      } catch (e) {
                        print('❌ Erreur lors du toggle du favori: $e');
                        // Afficher un message informatif
                        if (context.mounted) {
                          final isUUIDError =
                              e.toString().contains('UUID') ||
                              e.toString().contains('invalide');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isUUIDError
                                    ? 'Favori ajouté localement (non synchronisé).'
                                    : 'Erreur de synchronisation. Favori ajouté localement.',
                              ),
                              backgroundColor: isUUIDError
                                  ? Colors.orange
                                  : Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Adresse
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: AppDimensions.iconS,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppDimensions.spacingXs),
                  Expanded(
                    child: Text(
                      infrastructure.address,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (showDistance) ...[
                SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppDimensions.spacingXs),
                    Text(
                      'Distance calculée...', // TODO: Calculer la distance réelle
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: AppDimensions.spacingM),

              // Description (tronquée)
              Text(
                infrastructure.description,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Ouvrir itinéraire
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Itinéraire'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Partager
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.share),
                  ),
                ],
              ),

              // Indicateurs de statut
              if (!infrastructure.isActive || !infrastructure.isVerified) ...[
                SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    if (!infrastructure.isActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                        child: Text(
                          'Temporairement fermé',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!infrastructure.isVerified) ...[
                      if (!infrastructure.isActive)
                        SizedBox(width: AppDimensions.spacingS),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                        child: Text(
                          'En attente de vérification',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Toilettes publiques':
        return Icons.wc;
      case 'Aires de jeux':
        return Icons.child_friendly;
      case 'Terrains de sport':
        return Icons.sports_soccer;
      case 'Centres de santé':
        return Icons.local_hospital;
      case 'Écoles':
        return Icons.school;
      case 'Mairies':
        return Icons.account_balance;
      case 'Commissariats':
        return Icons.local_police;
      case 'Marchés':
        return Icons.store;
      case 'Espaces verts':
        return Icons.park;
      case 'Centres culturels':
        return Icons.theater_comedy;
      default:
        return Icons.location_on;
    }
  }
}

class InfrastructureListTile extends ConsumerWidget {
  final Infrastructure infrastructure;
  final VoidCallback? onTap;

  const InfrastructureListTile({
    super.key,
    required this.infrastructure,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(infrastructure.id);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.categoryColors[infrastructure.category]
            ?.withOpacity(0.1),
        child: Icon(
          _getCategoryIcon(infrastructure.category),
          color: AppColors.categoryColors[infrastructure.category],
        ),
      ),
      title: Text(
        infrastructure.name,
        style: AppTextStyles.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            infrastructure.category,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.categoryColors[infrastructure.category],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            infrastructure.address,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.accent : AppColors.textSecondary,
        ),
        onPressed: () async {
          try {
            await ref
                .read(favoritesProvider.notifier)
                .toggleFavorite(infrastructure.id);
          } catch (e) {
            print('❌ Erreur lors du toggle du favori: $e');
            // Afficher un message informatif
            if (context.mounted) {
              final isUUIDError =
                  e.toString().contains('UUID') ||
                  e.toString().contains('invalide');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isUUIDError
                        ? 'Favori ajouté localement (non synchronisé).'
                        : 'Erreur de synchronisation. Favori ajouté localement.',
                  ),
                  backgroundColor: isUUIDError ? Colors.orange : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
      onTap: onTap,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Toilettes publiques':
        return Icons.wc;
      case 'Aires de jeux':
        return Icons.child_friendly;
      case 'Terrains de sport':
        return Icons.sports_soccer;
      case 'Centres de santé':
        return Icons.local_hospital;
      case 'Écoles':
        return Icons.school;
      case 'Mairies':
        return Icons.account_balance;
      case 'Commissariats':
        return Icons.local_police;
      case 'Marchés':
        return Icons.store;
      case 'Espaces verts':
        return Icons.park;
      case 'Centres culturels':
        return Icons.theater_comedy;
      default:
        return Icons.location_on;
    }
  }
}
