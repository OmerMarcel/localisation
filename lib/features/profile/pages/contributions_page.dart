import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:CotoNav/features/contribute/contribute_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/contribution.dart';

class ContributionsPage extends ConsumerWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(userContributionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContributeScreen(),
                ),
              ).then((_) {
                // Rafraîchir les contributions après avoir ajouté une nouvelle
                ref.read(userContributionsProvider.notifier).refresh();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userContributionsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: contributionsAsync.when(
        data: (contributions) {
          if (contributions.isEmpty) {
            return _buildEmptyState(context);
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await ref.read(userContributionsProvider.notifier).refresh();
                },
                child: ListView(
                  padding: EdgeInsets.only(
                    left: AppDimensions.spacingM,
                    right: AppDimensions.spacingM,
                    top: AppDimensions.spacingM,
                    bottom: 100, // Espace pour le menu simulé
                  ),
                  children: [
                    _buildStatsSection(contributions),
                    SizedBox(height: AppDimensions.spacingL),
                    _buildContributionsList(context, contributions),
                  ],
                ),
              ),
              // Dégradé pour simuler un menu de navigation en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(1.0),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: AppColors.textSecondary),
          SizedBox(height: AppDimensions.spacingL),
          Text('Aucune contribution', style: AppTextStyles.h3),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'Vous n\'avez pas encore soumis de contribution.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingXl),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContributeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une contribution'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
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
                ref.read(userContributionsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(List<Contribution> contributions) {
    final total = contributions.length;
    final validated = contributions
        .where(
          (c) =>
              c.status?.toLowerCase() == 'validated' ||
              c.status?.toLowerCase() == 'validée' ||
              c.status?.toLowerCase() == 'approved',
        )
        .length;
    final pending = contributions
        .where(
          (c) =>
              c.status == null ||
              c.status?.toLowerCase() == 'pending' ||
              c.status?.toLowerCase() == 'en attente' ||
              c.status?.toLowerCase() == 'pending_validation',
        )
        .length;
    final rejected = contributions
        .where(
          (c) =>
              c.status?.toLowerCase() == 'rejected' ||
              c.status?.toLowerCase() == 'rejetée' ||
              c.status?.toLowerCase() == 'refused',
        )
        .length;

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
                _buildStatItem('Total', total.toString(), AppColors.primary),
                _buildStatItem(
                  'Validées',
                  validated.toString(),
                  AppColors.success,
                ),
                _buildStatItem(
                  'En attente',
                  pending.toString(),
                  AppColors.warning,
                ),
                _buildStatItem(
                  'Rejetées',
                  rejected.toString(),
                  AppColors.error,
                ),
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

  Widget _buildContributionsList(
    BuildContext context,
    List<Contribution> contributions,
  ) {
    // Trier par date de création (plus récentes en premier)
    final sortedContributions = List<Contribution>.from(contributions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mes contributions', style: AppTextStyles.h4),
        SizedBox(height: AppDimensions.spacingM),
        ...sortedContributions.map(
          (contribution) => _buildContributionCard(context, contribution),
        ),
      ],
    );
  }

  Widget _buildContributionCard(
    BuildContext context,
    Contribution contribution,
  ) {
    final statusInfo = _getStatusInfo(contribution.status);

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: ListTile(
        leading: Icon(
          statusInfo['icon'] as IconData,
          color: statusInfo['color'] as Color,
        ),
        title: Text(contribution.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusInfo['label'] as String),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              'Soumis le ${_formatDate(contribution.createdAt)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            _showContributionDetails(context, contribution, statusInfo),
      ),
    );
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

  String _formatDate(DateTime date) {
    // Formatage manuel pour éviter l'initialisation de locale
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

  void _showContributionDetails(
    BuildContext context,
    Contribution contribution,
    Map<String, dynamic> statusInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              statusInfo['icon'] as IconData,
              color: statusInfo['color'] as Color,
              size: 24,
            ),
            SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                'Détails de la contribution',
                style: AppTextStyles.h4,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de l'infrastructure
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  contribution.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingM),

              // Description
              if (contribution.description.isNotEmpty) ...[
                Text(
                  'Description:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(contribution.description, style: AppTextStyles.bodySmall),
                SizedBox(height: AppDimensions.spacingM),
              ],

              // Catégorie
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  Text(
                    'Catégorie: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(contribution.category, style: AppTextStyles.bodyMedium),
                ],
              ),
              SizedBox(height: AppDimensions.spacingM),

              // Adresse
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      contribution.address,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingM),

              // Images de la contribution
              if (contribution.images.isNotEmpty) ...[
                Text(
                  'Images:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Container(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contribution.images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = contribution.images[index];
                      return Container(
                        width: 150,
                        margin: EdgeInsets.only(right: AppDimensions.spacingS),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: AppDimensions.spacingXs),
                                    Text(
                                      'Image\nindisponible',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: AppDimensions.spacingM),
              ],

              // Statut avec couleur
              Row(
                children: [
                  Text(
                    'Statut: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: (statusInfo['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      child: Text(
                        statusInfo['label'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: statusInfo['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingM),

              // Date de soumission
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppDimensions.spacingS),
                  Text(
                    'Soumis le: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(contribution.createdAt),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingM),

              // Informations supplémentaires selon le statut
              if (statusInfo['label'].toString().contains('Rejetée')) ...[
                Divider(),
                SizedBox(height: AppDimensions.spacingS),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.error, size: 16),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raison du rejet:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingXs),
                          Text(
                            'Les informations fournies étaient insuffisantes pour valider cette infrastructure. Veuillez resoummettre avec plus de détails.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else if (statusInfo['label'].toString().contains(
                'En attente',
              )) ...[
                Divider(),
                SizedBox(height: AppDimensions.spacingS),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En cours de validation:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingXs),
                          Text(
                            'Votre contribution est en cours de vérification par notre équipe. Vous recevrez une notification une fois validée.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else if (statusInfo['label'].toString().contains(
                'Validée',
              )) ...[
                Divider(),
                SizedBox(height: AppDimensions.spacingS),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contribution validée:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingXs),
                          Text(
                            'Félicitations ! Votre contribution a été validée et est maintenant visible sur la carte pour tous les utilisateurs.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
