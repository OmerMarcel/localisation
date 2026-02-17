import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/notification_badge.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../contribute/contribute_screen.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/providers/notifications_provider.dart';
import '../notifications/services/notification_initializer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _proximityMode = false;
  String? _searchCategory;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialiser les notifications FCM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationInitializer.initialize(ref);
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      // Désactiver le mode proximité si on change d'onglet
      if (index != 1) {
        _proximityMode = false;
        _searchCategory = null;
      }
    });
  }

  void _navigateToMapWithProximity() {
    setState(() {
      _currentIndex =
          1; // Index de la carte (corrigé pour correspondre à la bottom nav)
      _proximityMode = true; // Activer le mode proximité
      _searchCategory = null;
    });
  }

  void _navigateToMapWithCategory(String category) {
    setState(() {
      _currentIndex = 1; // Naviguer vers la carte
      _proximityMode = false;
      _searchCategory = category; // Définir la catégorie à rechercher
    });
  }

  void onNavigateToProfile() {
    setState(() {
      _currentIndex =
          3; // Index du profil (corrigé pour correspondre à la bottom nav)
      _proximityMode = false;
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          onNavigateToMap: () => _navigateToTab(1),
          onNavigateToProfile: () => _navigateToTab(3),
          onNavigateToMapWithProximity: () => _navigateToMapWithProximity(),
          onNavigateToMapWithCategory: (category) =>
              _navigateToMapWithCategory(category),
          expandedCategories: _expandedCategories,
          onCategoryExpanded: (category, isExpanded) {
            setState(() {
              if (isExpanded) {
                _expandedCategories.add(category);
              } else {
                _expandedCategories.remove(category);
              }
            });
          },
        );
      case 1:
        return MapScreen(
          proximityMode: _proximityMode,
          searchCategory: _searchCategory,
          key: ValueKey(
            'map_$_searchCategory',
          ), // Force rebuild quand la catégorie change
        );
      case 2:
        return const ContributeScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Si on n'est pas sur l'onglet Accueil, y revenir
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _proximityMode = false;
            _searchCategory = null;
          });
          return;
        }

        // Si on est sur l'Accueil, demander confirmation pour quitter
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter l\'application'),
            content: const Text(
              'Voulez-vous vraiment quitter l\'application ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Non'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Oui'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _getScreen(_currentIndex),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              // Désactiver le mode proximité si on change d'onglet manuellement
              if (index != 1) {
                _proximityMode = false;
              }
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location),
              label: 'Contribuer',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToMapWithProximity;
  final Function(String)? onNavigateToMapWithCategory;
  final Set<String> expandedCategories;
  final Function(String, bool) onCategoryExpanded;

  const DashboardScreen({
    super.key,
    this.onNavigateToMap,
    this.onNavigateToProfile,
    this.onNavigateToMapWithProximity,
    this.onNavigateToMapWithCategory,
    required this.expandedCategories,
    required this.onCategoryExpanded,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo1.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: Text(
                'KutonouTché',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return NotificationIcon(
                unreadCount: unreadCount,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onNavigateToProfile: onNavigateToProfile,
        onNavigateToMapWithProximity: onNavigateToMapWithProximity,
      ),
      body: Column(
        children: [
          // Section de bienvenue - FIXE
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(AppDimensions.spacingM),
            padding: EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue à Cotonou !',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textLight),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  'Découvrez les infrastructures et services publics près de vous',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingM),
                ElevatedButton.icon(
                  onPressed: () {
                    // Naviguer vers la carte
                    onNavigateToMap?.call();
                  },
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Voir la carte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Titre des catégories - FIXE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
            child: Text(
              'Catégories d\'infrastructures',
              style: AppTextStyles.h4,
            ),
          ),
          SizedBox(height: AppDimensions.spacingM),

          // Section des catégories - DÉFILABLE
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liste des catégories avec sous-services
                  ...AppConstants.infrastructureServices.entries.map((entry) {
                    final category = entry.key;
                    final subServices = entry.value;
                    final isExpanded = expandedCategories.contains(category);
                    final categoryColor =
                        AppConstants.categoryColors[category] ??
                        AppColors.primary;
                    final categoryIcon =
                        AppConstants.categoryIcons[category] ??
                        Icons.location_on;

                    return Column(
                      children: [
                        // Catégorie principale
                        Container(
                          margin: EdgeInsets.only(
                            bottom: AppDimensions.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusL,
                            ),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(AppDimensions.spacingS),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                categoryIcon,
                                color: categoryColor,
                                size: AppDimensions.iconM,
                              ),
                            ),
                            title: Text(
                              category,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                            subtitle: Text(
                              '${subServices.length} services disponibles',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: categoryColor.withOpacity(0.7),
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: categoryColor,
                            ),
                            onTap: () {
                              onCategoryExpanded(category, !isExpanded);
                            },
                          ),
                        ),

                        // Sous-services (si la catégorie est étendue)
                        if (isExpanded) ...[
                          Container(
                            margin: EdgeInsets.only(
                              left: AppDimensions.spacingL,
                              bottom: AppDimensions.spacingM,
                            ),
                            padding: EdgeInsets.all(AppDimensions.spacingS),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: subServices.map((subService) {
                                final subServiceIcon =
                                    AppConstants.subServiceIcons[subService] ??
                                    Icons.circle;

                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    subServiceIcon,
                                    color: categoryColor.withOpacity(0.8),
                                    size: AppDimensions.iconS,
                                  ),
                                  title: Text(
                                    subService,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: categoryColor.withOpacity(0.9),
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.map,
                                    color: categoryColor.withOpacity(0.6),
                                    size: AppDimensions.iconS,
                                  ),
                                  onTap: () {
                                    // Naviguer vers la carte pour voir ce type de lieu avec catégorie
                                    onNavigateToMapWithCategory?.call(
                                      subService,
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
