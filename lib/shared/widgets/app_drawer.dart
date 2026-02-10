import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../features/test/directions_test_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/pages/favorites_page.dart';
import '../../features/profile/pages/contributions_page.dart';
import '../../features/profile/pages/history_page.dart';
import '../../features/profile/pages/offline_settings_page.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToMapWithProximity;

  const AppDrawer({
    super.key,
    this.onNavigateToProfile,
    this.onNavigateToMapWithProximity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesCount = favorites.length;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête personnalisé du drawer
          Container(
            height: 135,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateToProfile?.call();
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.textLight.withOpacity(
                              0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(width: AppDimensions.spacingXs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userState.isLoggedIn
                                      ? (userState.name ?? 'Utilisateur')
                                      : 'Visiteur',
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: AppDimensions.spacingXs),
                                Text(
                                  userState.isLoggedIn
                                      ? (userState.email ?? 'Compte connecté')
                                      : 'Explorez Cotonou',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textLight.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.textLight.withOpacity(0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section Services (toujours visible)
          _buildSection('Services populaires', [
            _buildMenuItem(
              context,
              Icons.near_me,
              'Proximité',
              subtitle: 'Infrastructures près de moi (1km)',
              onTap: () {
                Navigator.pop(context);
                onNavigateToMapWithProximity?.call();
              },
            ),
            // Favoris uniquement si connecté
            if (userState.isLoggedIn)
              _buildMenuItem(
                context,
                Icons.star,
                'Favoris',
                subtitle: 'Mes lieux préférés',
                trailing: favoritesCount > 0
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          favoritesCount.toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                },
              ),
            _buildMenuItem(
              context,
              Icons.download,
              'Mode hors ligne',
              subtitle: 'Cartes téléchargées',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineSettingsPage(),
                  ),
                );
              },
            ),
          ]),

          // Section Mon activité (uniquement si connecté)
          if (userState.isLoggedIn)
            _buildSection('Mon activité', [
              _buildMenuItem(
                context,
                Icons.add_location,
                'Mes contributions',
                subtitle: 'Lieux que j\'ai proposés',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContributionsPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                Icons.history,
                'Historique',
                subtitle: 'Mes activités récentes',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
                },
              ),
            ]),

          // Section Paramètres
          _buildSection('Paramètres', [
            _buildMenuItem(
              context,
              Icons.settings,
              'Paramètres',
              onTap: () {
                Navigator.pop(context);
                _showSettingsBottomSheet(context, ref);
              },
            ),
            // Notifications uniquement si connecté
            /*if (userState.isLoggedIn)
              _buildMenuItem(
                context,
                Icons.notifications,
                'Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    _showSnackBar(
                      context,
                      'Notifications ${value ? 'activées' : 'désactivées'}',
                    );
                  },
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),*/
          ]),

          // Section Aide & Support
          _buildSection('Aide & Support', [
            _buildMenuItem(
              context,
              Icons.help,
              'Centre d\'aide',
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Centre d\'aide');
              },
            ),
            /*_buildMenuItem(
              context,
              Icons.bug_report,
              'Test API Directions',
              subtitle: 'Diagnostiquer les itinéraires',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DirectionsTestScreen(),
                  ),
                );
              },
            ),*/
            _buildMenuItem(
              context,
              Icons.feedback,
              'Commentaires',
              onTap: () {
                Navigator.pop(context);
                _showFeedbackDialog(context);
              },
            ),
            _buildMenuItem(
              context,
              Icons.info,
              'À propos',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ]),

          // Bouton de connexion/déconnexion
          Container(
            margin: EdgeInsets.all(AppDimensions.spacingS),
            child: userState.isLoggedIn
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, ref);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textLight,
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigateToProfile?.call();
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                    ),
                  ),
          ),

          SizedBox(height: AppDimensions.spacingS),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: AppColors.textSecondary.withOpacity(0.2),
          thickness: 1,
          height: 1,
        ),
        SizedBox(
          height: AppDimensions.spacingXs,
        ), // Réduit de spacingM à spacingS
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: AppDimensions.spacingXs,
        ), // Réduit de spacingS à spacingXs
        ...children,
        SizedBox(
          height: AppDimensions.spacingXs,
        ), // Réduit de spacingS à spacingXs
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 0, // Réduit de 2 à 1
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: AppDimensions.iconM,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: 0, // Réduit de spacingXs à 0.5
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final isDarkMode = ref.watch(themeProvider);
          return Container(
            padding: EdgeInsets.all(
              AppDimensions.spacingL,
            ), // Réduit de spacingL à spacingM
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: AppDimensions.spacingXs,
                ), // Réduit de spacingL à spacingM
                Text('Paramètres', style: AppTextStyles.h3),
                SizedBox(
                  height: AppDimensions.spacingM,
                ), // Réduit de spacingL à spacingM
                _buildMenuItem(
                  context,
                  Icons.language,
                  'Langue',
                  subtitle: _getLanguageName(
                    ref.read(languageProvider).languageCode,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _showLanguageDialog(context, ref);
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.dark_mode,
                  'Thème sombre',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).setDarkMode(value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  onTap: () {
                    ref.read(themeProvider.notifier).setDarkMode(!isDarkMode);
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.location_on,
                  'Localisation',
                  subtitle: 'Toujours autorisée',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(
                  height: AppDimensions.spacingL,
                ), // Réduit de spacingL à spacingM
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    final language = AppConstants.supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'code': 'fr', 'name': 'Français'},
    );
    return language['name'] ?? 'Français';
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(languageProvider).languageCode;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            title: const Text('Choisir la langue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppConstants.supportedLanguages.map((lang) {
                return RadioListTile<String>(
                  title: Text(lang['name'] ?? ''),
                  value: lang['code'] ?? 'fr',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(languageProvider.notifier).setLanguage(value);
                      Navigator.pop(context);
                      // Afficher un message informatif
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Langue changée en ${lang['name']}. Redémarrez l\'application pour appliquer les changements.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primary, size: 24),
            SizedBox(width: AppDimensions.spacingS),
            const Expanded(child: Text('Géolocalisation Cotonou')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: AppTextStyles.bodySmall),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'Application de géolocalisation des infrastructures publiques de Cotonou.',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'Développée pour faciliter l\'accès aux services publics et améliorer la qualité de vie des citoyens.',
              style: AppTextStyles.bodySmall,
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

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vos commentaires'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Que pensez-vous de cette application ?'),
            SizedBox(height: AppDimensions.spacingM),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Écrivez vos commentaires ici...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Merci pour vos commentaires !');
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              Navigator.pop(context);
              _showSnackBar(context, 'Déconnexion réussie');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textLight,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: AppDimensions.iconM),
        SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
