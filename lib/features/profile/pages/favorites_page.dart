import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/infrastructure.dart';
import '../../map/map_screen.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteInfrastructuresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(favoriteInfrastructuresProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70),
            onPressed: () => _handleClearAllFavorites(context, ref),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteInfrastructuresProvider);
            },
            child: _buildFavoritesList(context, favorites, ref),
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
          Icon(
            Icons.favorite_border,
            size: 100,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.spacingL),
          Text(
            'Aucun favori pour le moment',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'Ajoutez des infrastructures à vos favoris depuis la carte pour les retrouver facilement ici.',
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
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Explorer la carte'),
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
                ref.invalidate(favoriteInfrastructuresProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    List<Infrastructure> favorites,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.location_on, color: AppColors.textLight),
            ),
            title: Text(favorite.name, style: AppTextStyles.bodyLarge),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.address.isNotEmpty
                      ? favorite.address
                      : 'Adresse non disponible',
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppDimensions.spacingXs),
                    Text(
                      favorite.category.isNotEmpty
                          ? favorite.category
                          : 'Non catégorisé',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _viewOnMap(context, favorite);
                    break;
                  case 'remove':
                    ref
                        .read(favoritesProvider.notifier)
                        .removeFavorite(favorite.id);
                    // Le provider se rafraîchit automatiquement via invalidate dans removeFavorite
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${favorite.name} retiré des favoris'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.map),
                    title: Text('Voir sur la carte'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _viewOnMap(context, favorite),
          ),
        );
      },
    );
  }

  void _viewOnMap(BuildContext context, Infrastructure favorite) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(selectedInfrastructure: favorite),
      ),
    );
  }

  void _handleClearAllFavorites(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.read(favoriteInfrastructuresProvider);

    favoritesAsync.whenData((favorites) {
      if (favorites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun favori disponible'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showClearAllDialog(context, ref);
      }
    });
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les favoris'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes vos infrastructures favorites ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(favoritesProvider.notifier).clearAllFavorites();
              Navigator.pop(context);
              // Rafraîchir la liste après suppression
              ref.invalidate(favoriteInfrastructuresProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Toutes les infrastructures favorites ont été supprimées',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
