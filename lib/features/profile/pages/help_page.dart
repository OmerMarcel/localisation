import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              left: AppDimensions.spacingM,
              right: AppDimensions.spacingM,
              top: AppDimensions.spacingL,
              bottom: AppDimensions.spacingM + 48, // Espace pour le masquage
            ),
            children: [_buildFaqSection()],
          ),
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
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.all(AppDimensions.spacingM),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          SizedBox(height: AppDimensions.spacingS),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqItems = [
      {
        'question': 'Comment utiliser la carte ?',
        'answer':
            'Naviguez sur la carte en faisant glisser votre doigt. Appuyez sur une infrastructure pour voir ses détails. Utilisez les boutons de zoom pour ajuster la vue.',
        'category': 'Navigation',
      },
      {
        'question': 'Comment ajouter aux favoris ?',
        'answer':
            'Sur la page de détail d\'une infrastructure, appuyez sur l\'icône cœur pour l\'ajouter à vos favoris. Vous pouvez retrouver tous vos favoris dans votre profil.',
        'category': 'Favoris',
      },
      {
        'question': 'Comment contribuer ?',
        'answer':
            'Utilisez l\'onglet "Contribuer" pour signaler de nouvelles infrastructures. Ajoutez des photos, une description détaillée et votre position sera automatiquement détectée.',
        'category': 'Contribution',
      },
      {
        'question': 'Recherche par proximité',
        'answer':
            'Activez la géolocalisation dans les paramètres pour trouver automatiquement les infrastructures les plus proches de votre position actuelle.',
        'category': 'Localisation',
      },
      {
        'question': 'Mode hors ligne',
        'answer':
            'Téléchargez les cartes dans les paramètres pour utiliser l\'application sans connexion internet. Idéal pour économiser vos données mobiles.',
        'category': 'Hors ligne',
      },
      {
        'question': 'Notifications de proximité',
        'answer':
            'Activez les notifications de proximité dans les paramètres pour être alerté quand vous vous approchez d\'infrastructures utiles.',
        'category': 'Notifications',
      },
      {
        'question': 'Mes contributions sont-elles vérifiées ?',
        'answer':
            'Oui, toutes les contributions sont examinées par notre équipe avant d\'être publiées. Vous recevrez une notification du statut de votre contribution.',
        'category': 'Contribution',
      },
      {
        'question': 'Comment modifier mes informations ?',
        'answer':
            'Allez dans votre profil et appuyez sur l\'icône paramètres pour modifier vos informations personnelles et préférences.',
        'category': 'Profil',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Questions fréquentes', style: AppTextStyles.h4),
        SizedBox(height: AppDimensions.spacingM),
        ...faqItems.map(
          (item) => Card(
            margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
            child: ExpansionTile(
              leading: Icon(
                _getCategoryIcon(item['category'] as String),
                color: AppColors.primary,
              ),
              title: Text(item['question'] as String),
              subtitle: Text(
                item['category'] as String,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(AppDimensions.spacingM),
                  child: Text(
                    item['answer'] as String,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Navigation':
        return Icons.map;
      case 'Favoris':
        return Icons.favorite;
      case 'Contribution':
        return Icons.add_location;
      case 'Localisation':
        return Icons.location_on;
      case 'Hors ligne':
        return Icons.cloud_off;
      case 'Notifications':
        return Icons.notifications;
      case 'Profil':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher dans l\'aide'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Tapez votre question...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            // TODO: Implémenter la recherche
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
