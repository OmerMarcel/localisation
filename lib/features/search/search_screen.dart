import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/infrastructure.dart';
import '../../shared/widgets/infrastructure_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });

      ref.read(searchProvider.notifier).updateQuery(query);
      ref.read(infrastructuresProvider.notifier).searchInfrastructures(query);

      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchProvider);
    final infrastructuresAsync = ref.watch(infrastructuresProvider);
    final recentSearches = ref
        .read(searchProvider.notifier)
        .getRecentSearches();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une infrastructure...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchProvider.notifier).clearQuery();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.isEmpty) {
                  ref.read(searchProvider.notifier).clearQuery();
                }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres rapides
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.infrastructureCategories.length,
              itemBuilder: (context, index) {
                final category = AppConstants.infrastructureCategories[index];
                final color =
                    AppColors.categoryColors[category] ?? AppColors.primary;

                return Container(
                  margin: EdgeInsets.only(right: AppDimensions.spacingS),
                  child: FilterChip(
                    label: Text(category),
                    selected: false, // TODO: Implémenter la sélection
                    onSelected: (selected) {
                      _searchController.text = category;
                      _performSearch(category);
                    },
                    backgroundColor: color.withOpacity(0.1),
                    selectedColor: color.withOpacity(0.3),
                    labelStyle: TextStyle(color: color, fontSize: 12),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : searchQuery.isEmpty
                ? _buildRecentSearches(recentSearches)
                : _buildSearchResults(infrastructuresAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(List<String> recentSearches) {
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.textSecondary),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'Commencez votre recherche',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              'Trouvez rapidement les infrastructures près de vous',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(AppDimensions.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recherches récentes', style: AppTextStyles.h4),
              TextButton(
                onPressed: () {
                  ref.read(searchProvider.notifier).clearRecentSearches();
                  setState(() {});
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final search = recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // TODO: Supprimer cette recherche spécifique
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    AsyncValue<List<Infrastructure>> infrastructuresAsync,
  ) {
    return infrastructuresAsync.when(
      data: (infrastructures) {
        if (infrastructures.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppDimensions.spacingM),
                Text(
                  'Aucun résultat trouvé',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  'Essayez avec d\'autres mots-clés',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(AppDimensions.spacingM),
              child: Text(
                '${infrastructures.length} résultat${infrastructures.length > 1 ? 's' : ''} trouvé${infrastructures.length > 1 ? 's' : ''}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: infrastructures.length,
                itemBuilder: (context, index) {
                  return InfrastructureCard(
                    infrastructure: infrastructures[index],
                    onTap: () =>
                        _showInfrastructureDetails(infrastructures[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'Erreur de recherche',
              style: AppTextStyles.h4.copyWith(color: AppColors.error),
            ),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              'Vérifiez votre connexion internet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingM),
            ElevatedButton(
              onPressed: () {
                _performSearch(_searchController.text);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfrastructureDetails(Infrastructure infrastructure) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: InfrastructureDetailsSheet(infrastructure: infrastructure),
        ),
      ),
    );
  }
}

class InfrastructureDetailsSheet extends ConsumerWidget {
  final Infrastructure infrastructure;

  const InfrastructureDetailsSheet({super.key, required this.infrastructure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(infrastructure.id);

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle de glissement
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          Row(
            children: [
              Expanded(
                child: Text(infrastructure.name, style: AppTextStyles.h3),
              ),
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
                      final isUUIDError = e.toString().contains('UUID') || e.toString().contains('invalide');
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
            ],
          ),

          SizedBox(height: AppDimensions.spacingS),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.categoryColors[infrastructure.category]
                  ?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              infrastructure.category,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.categoryColors[infrastructure.category],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacingM),

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
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingM),

          Text('Description', style: AppTextStyles.h4),
          SizedBox(height: AppDimensions.spacingS),
          Text(infrastructure.description, style: AppTextStyles.bodyMedium),

          SizedBox(height: AppDimensions.spacingL),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir dans Google Maps
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                ),
              ),
              SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Afficher sur la carte
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Sur la carte'),
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingM),

          OutlinedButton.icon(
            onPressed: () {
              // TODO: Partager
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager cette infrastructure'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
