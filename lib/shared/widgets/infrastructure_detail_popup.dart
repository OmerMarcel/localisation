import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../../core/models/infrastructure.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/google_maps_service.dart';
import '../../core/services/storage_service.dart';
import '../../features/route/route_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Widget détaillé pour afficher toutes les informations d'un lieu
class InfrastructureDetailPopup extends ConsumerStatefulWidget {
  final Infrastructure infrastructure;
  final Position? currentPosition;

  const InfrastructureDetailPopup({
    super.key,
    required this.infrastructure,
    this.currentPosition,
  });

  @override
  ConsumerState<InfrastructureDetailPopup> createState() =>
      _InfrastructureDetailPopupState();
}

class _InfrastructureDetailPopupState
    extends ConsumerState<InfrastructureDetailPopup>
    with TickerProviderStateMixin {
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteAnimation;
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  @override
  void initState() {
    super.initState();
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _favoriteAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    // Enregistrer la visite de cette infrastructure
    _recordVisit();
  }

  /// Enregistre une visite de l'infrastructure
  Future<void> _recordVisit() async {
    try {
      final storageService = StorageService();
      await storageService.recordInfrastructureVisit(widget.infrastructure.id);

      // Mettre à jour le provider pour rafraîchir le nombre de visites dans le profil
      ref.read(visitCountProvider.notifier).refresh();

      // Enregistrer aussi dans l'historique des activités
      final userState = ref.read(userProvider);
      if (userState.isLoggedIn) {
        ref
            .read(userActivitiesProvider.notifier)
            .recordInfrastructureView(
              widget.infrastructure.id,
              widget.infrastructure.name,
            );
      }
    } catch (e) {
      _log('⚠️ Erreur lors de l\'enregistrement de la visite: $e');
    }
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final userState = ref.read(userProvider);

    if (!userState.isLoggedIn) {
      _showAuthenticationDialog();
      return;
    }

    try {
      // Lancer l'animation
      _favoriteAnimationController.forward().then((_) {
        _favoriteAnimationController.reverse();
      });

      // Toggle le favori de manière asynchrone
      await ref
          .read(favoritesProvider.notifier)
          .toggleFavorite(widget.infrastructure.id);
    } catch (e) {
      // Gérer les erreurs silencieusement ou afficher un message
      _log('❌ Erreur lors du toggle du favori: $e');

      // Afficher un message informatif à l'utilisateur
      if (mounted) {
        final isUUIDError =
            e.toString().contains('UUID') || e.toString().contains('invalide');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUUIDError
                  ? 'Favori ajouté localement. Non synchronisé avec le serveur (ID non-UUID).'
                  : 'Erreur lors de la synchronisation. Le favori a été ajouté localement.',
            ),
            backgroundColor: isUUIDError ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.primary),
            SizedBox(width: AppDimensions.spacingS),
            Text('Connexion requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'Vous devez être connecté pour ajouter des lieux en favoris, ajouter des commentaires ou contribuer.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              'Créez un compte pour personnaliser votre expérience !',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Fermer le popup des détails
              // Naviguer vers l'écran de profil pour se connecter
              Navigator.pushNamed(context, '/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? distance;
    if (widget.currentPosition != null) {
      final distanceInMeters = ref
          .read(locationServiceProvider)
          .calculateDistance(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
            widget.infrastructure.latitude,
            widget.infrastructure.longitude,
          );
      distance = ref
          .read(locationServiceProvider)
          .formatDistance(distanceInMeters);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildImageCarousel(),
              _buildMainInfo(distance),
              _buildRatingSection(),
              _buildOpeningHours(),
              _buildDescription(),
              _buildContactInfo(),
              _buildCommentsSection(),
              _buildActionButtons(),
              SizedBox(height: AppDimensions.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          // Handle de glissement
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: AppDimensions.spacingM),

          // Titre et bouton favori
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.infrastructure.name,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _favoriteAnimation,
                builder: (context, child) {
                  final favorites = ref.watch(favoritesProvider);
                  final isFavorite = favorites.contains(
                    widget.infrastructure.id,
                  );

                  return Transform.scale(
                    scale: _favoriteAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? AppColors.accent.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingS),

          // Catégorie
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color:
                    AppColors.categoryColors[widget.infrastructure.category]
                        ?.withOpacity(0.1) ??
                    AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color:
                      AppColors.categoryColors[widget.infrastructure.category]
                          ?.withOpacity(0.3) ??
                      AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.infrastructure.category,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      AppColors.categoryColors[widget
                          .infrastructure
                          .category] ??
                      AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images =
        (widget.infrastructure.images.isNotEmpty
                ? widget.infrastructure.images
                : ['https://via.placeholder.com/400x200?text=Aucune+Image'])
            .where((u) => u.toString().trim().isNotEmpty)
            .map(_normalizeImageUrl)
            .toList();

    return Container(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final url = images[index];
              final isDataImage = url.startsWith('data:image/');
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: isDataImage
                      ? Image.memory(_decodeDataImage(url), fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            _log('❌ Image non disponible: $url | $error');
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: AppDimensions.spacingS),
                                  Text(
                                    'Image non disponible',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          ),

          // Indicateurs de page
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Bouton pour ajouter des images
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate,
                  color: AppColors.primary,
                ),
                onPressed: () => _showAddImagesDialog(),
                tooltip: 'Ajouter des images',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeImageUrl(String url) {
    if (url.isEmpty || url.startsWith('data:')) return url;
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return url;
    }
    var base = AppConstants.baseUrl;
    if (Platform.isAndroid &&
        (base.contains('localhost') || base.contains('127.0.0.1'))) {
      base = base
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    final prefix = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final path = url.startsWith('/') ? url : '/$url';
    return '$prefix$path';
  }

  Uint8List _decodeDataImage(String dataUrl) {
    try {
      final base64Part = dataUrl.split('base64,').last;
      return base64Decode(base64Part);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _buildMainInfo(String? distance) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance
          if (distance != null)
            Container(
              margin: EdgeInsets.only(bottom: AppDimensions.spacingM),
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: AppDimensions.iconS,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppDimensions.spacingXs),
                  Text(
                    'À $distance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Adresse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_city,
                size: AppDimensions.iconM,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  widget.infrastructure.address,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Container(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Note moyenne
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: _getRatingColor(widget.infrastructure.rating),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                widget.infrastructure.rating.toStringAsFixed(1),
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(width: AppDimensions.spacingM),

            // Étoiles
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.infrastructure.rating.floor()
                      ? Icons.star
                      : index < widget.infrastructure.rating
                      ? Icons.star_half
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),

            SizedBox(width: AppDimensions.spacingS),

            // Nombre d'avis
            Text(
              '(${widget.infrastructure.reviewCount} avis)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildOpeningHours() {
    if (widget.infrastructure.openingHours.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horaires d\'ouverture',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppDimensions.spacingM),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(children: _buildOpeningHoursList()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOpeningHoursList() {
    final daysOfWeek = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return daysOfWeek.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final dayName = dayNames[index];
      final hours = widget.infrastructure.openingHours[day];
      final isToday = _isToday(index);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary.withOpacity(0.05) : null,
          border: index < daysOfWeek.length - 1
              ? Border(bottom: BorderSide(color: Colors.grey[200]!))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.primary : null,
              ),
            ),
            Text(
              _formatOpeningHours(hours),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  bool _isToday(int dayIndex) {
    // Convertir l'index (0 = lundi) en jour de la semaine DateTime (1 = lundi)
    final today = DateTime.now().weekday;
    return today == dayIndex + 1;
  }

  String _formatOpeningHours(dynamic hours) {
    if (hours == null) return 'Fermé';
    if (hours is String) return hours;
    if (hours is Map) {
      final open = hours['open'];
      final close = hours['close'];
      if (open != null && close != null) {
        return '$open - $close';
      }
    }
    return 'Non renseigné';
  }

  Widget _buildDescription() {
    if (widget.infrastructure.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppDimensions.spacingM),

          Container(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.infrastructure.description,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final hasPhone = widget.infrastructure.phone?.isNotEmpty == true;
    final hasWebsite = widget.infrastructure.website?.isNotEmpty == true;

    if (!hasPhone && !hasWebsite) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppDimensions.spacingM),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                if (hasPhone)
                  ListTile(
                    leading: Icon(Icons.phone, color: AppColors.primary),
                    title: Text(widget.infrastructure.phone!),
                    onTap: () {
                      // TODO: Implémenter l'appel téléphonique
                    },
                  ),
                if (hasPhone && hasWebsite)
                  Divider(color: Colors.grey[200], height: 1),
                if (hasWebsite)
                  ListTile(
                    leading: Icon(Icons.language, color: AppColors.primary),
                    title: Text(widget.infrastructure.website!),
                    onTap: () {
                      // TODO: Implémenter l'ouverture du site web
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commentaires (${widget.infrastructure.reviewCount})',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implémenter l'ajout de commentaire
                  _showAddCommentDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM),

          // Pour l'instant, affichage de commentaires simulés
          _buildSampleComments(),
        ],
      ),
    );
  }

  Widget _buildSampleComments() {
    // Commentaires simulés pour la démonstration
    final sampleComments = [
      {
        'author': 'Marie D.',
        'rating': 5.0,
        'comment': 'Excellent service, très bien situé !',
        'date': '2 jours',
      },
      {
        'author': 'Jean-Claude K.',
        'rating': 4.0,
        'comment': 'Bon accueil, mais l\'attente peut être longue.',
        'date': '1 semaine',
      },
    ];

    return Column(
      children: sampleComments.map((comment) {
        return Container(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingM),
          padding: EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      comment['author'].toString().substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['author'].toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                final rating = comment['rating'] as double;
                                return Icon(
                                  index < rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            SizedBox(width: AppDimensions.spacingS),
                            Text(
                              'Il y a ${comment['date']}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingS),
              Text(
                comment['comment'].toString(),
                style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAddCommentDialog() {
    final userState = ref.read(userProvider);

    if (!userState.isLoggedIn) {
      _showAuthenticationDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Votre commentaire...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                      ), // réduit l'espacement
                      child: IconButton(
                        icon: const Icon(Icons.star_border),
                        iconSize: 24, // optionnel: réduit la taille de l'icône
                        padding: EdgeInsets.all(10), // réduit la zone cliquable
                        constraints:
                            const BoxConstraints(), // enlève les contraintes par défaut
                        onPressed: () {
                          // TODO: Gérer la notation
                        },
                      ),
                    );
                  }),
                ),
              ],
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
              // TODO: Sauvegarder le commentaire
              Navigator.pop(context);
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          // Boutons principaux
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openRoute(),
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingM,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareLocation(),
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingM,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingM),

          // Boutons secondaires
          Row(
            children: [
              if (widget.infrastructure.phone?.isNotEmpty == true)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Appeler le lieu
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingS,
                      ),
                    ),
                  ),
                ),
              if (widget.infrastructure.phone?.isNotEmpty == true)
                SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReportDialog(),
                  icon: const Icon(Icons.report, color: Colors.red),
                  label: const Text('Signaler un problème'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS,
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteScreen(
          destination: widget.infrastructure,
          currentPosition: widget.currentPosition,
          travelMode: TravelMode.driving,
        ),
      ),
    );
  }

  void _shareLocation() {
    final shareText = GoogleMapsService.generateShareText(
      widget.infrastructure,
    );
    Share.share(shareText);
  }

  void _showReportDialog() {
    final userState = ref.read(userProvider);

    if (!userState.isLoggedIn) {
      _showAuthenticationDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          _ReportDialog(infrastructure: widget.infrastructure, ref: ref),
    );
  }

  void _showAddImagesDialog() {
    final userState = ref.read(userProvider);

    if (!userState.isLoggedIn) {
      _showAuthenticationDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          _AddImagesDialog(infrastructure: widget.infrastructure, ref: ref),
    );
  }
}

/// Dialogue de formulaire de signalement
class _ReportDialog extends StatefulWidget {
  final Infrastructure infrastructure;
  final WidgetRef ref;

  const _ReportDialog({required this.infrastructure, required this.ref});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImages = 3;

  String? _selectedProblemType;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  bool get _canAddImages => _selectedImages.length < _maxImages;

  final List<Map<String, String>> _problemTypes = [
    {'value': 'damage', 'label': 'Dégât ou dommage'},
    {'value': 'closure', 'label': 'Fermeture inattendue'},
    {'value': 'maintenance', 'label': 'Besoin de maintenance'},
    {'value': 'safety', 'label': 'Problème de sécurité'},
    {'value': 'accessibility', 'label': 'Problème d\'accessibilité'},
    {'value': 'incorrect_info', 'label': 'Informations incorrectes'},
    {'value': 'other', 'label': 'Autre'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (!_canAddImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 3 photos par signalement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (!_canAddImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 3 photos par signalement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        final remaining = _maxImages - _selectedImages.length;
        setState(() {
          final selected = images.take(remaining).map((img) => File(img.path));
          _selectedImages.addAll(selected);
        });
        if (images.length > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 3 photos par signalement.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedProblemType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de problème'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Enregistrer l'activité de signalement (historique local)
      await widget.ref
          .read(userActivitiesProvider.notifier)
          .recordReport(widget.infrastructure.id, widget.infrastructure.name);

      // Préparer le type pour le backend (mapper vers les types attendus)
      // Types backend: 'equipement_degrade', 'fermeture_temporaire', 'information_incorrecte', 'autre'
      String backendType;
      switch (_selectedProblemType) {
        case 'damage':
        case 'maintenance':
        case 'safety':
        case 'accessibility':
          backendType = 'equipement_degrade';
          break;
        case 'closure':
          backendType = 'fermeture_temporaire';
          break;
        case 'incorrect_info':
          backendType = 'information_incorrecte';
          break;
        default:
          backendType = 'autre';
      }

      // Envoyer le signalement au backend
      final apiService = widget.ref.read(apiServiceProvider);
      List<String>? photoUrls;
      if (_selectedImages.isNotEmpty) {
        photoUrls = [];
        for (final image in _selectedImages) {
          final uploadedUrl = await apiService.uploadImage(image.path);
          photoUrls.add(uploadedUrl);
        }
      }

      await apiService.reportProblem(
        infrastructureId: widget.infrastructure.id,
        type: backendType,
        description: _descriptionController.text.trim(),
        photos: photoUrls,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Signalement envoyé avec succès. Merci pour votre contribution !',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du signalement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Icon(Icons.report, color: AppColors.error, size: 28),
                      SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Text(
                          'Signaler un problème',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.spacingM),
                  Text(
                    widget.infrastructure.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingL),

                  // Type de problème
                  Text(
                    'Type de problème *',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingS),
                  DropdownButtonFormField<String>(
                    value: _selectedProblemType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      hintText: 'Sélectionnez un type',
                    ),
                    items: _problemTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProblemType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un type de problème';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppDimensions.spacingL),

                  // Description
                  Text(
                    'Description du problème *',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingS),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Décrivez le problème en détail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez décrire le problème';
                      }
                      if (value.trim().length < 10) {
                        return 'La description doit contenir au moins 10 caractères';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppDimensions.spacingL),

                  // Photos
                  Text(
                    'Photos du problème * - ${_selectedImages.length}/$_maxImages',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingS),
                  if (_selectedImages.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _canAddImages ? _pickImageFromGallery : null,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galerie'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.spacingS,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _canAddImages ? _pickImage : null,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Caméra'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.spacingS,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _canAddImages
                                    ? _pickImageFromGallery
                                    : null,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Ajouter depuis la galerie'),
                              ),
                            ),
                            SizedBox(width: AppDimensions.spacingS),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _canAddImages ? _pickImage : null,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Ajouter via la caméra'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDimensions.spacingM),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM,
                                    ),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM,
                                    ),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 16,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: AppDimensions.spacingL),

                  // Date de signalement (automatique)
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: AppDimensions.spacingS),
                        Text(
                          'Date: ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingL),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingM,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Envoyer le signalement'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Dialogue pour ajouter des images à une infrastructure
class _AddImagesDialog extends StatefulWidget {
  final Infrastructure infrastructure;
  final WidgetRef ref;

  const _AddImagesDialog({required this.infrastructure, required this.ref});

  @override
  State<_AddImagesDialog> createState() => _AddImagesDialogState();
}

class _AddImagesDialogState extends State<_AddImagesDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Enregistrer l'activité
      await widget.ref
          .read(userActivitiesProvider.notifier)
          .recordContribution(
            widget.infrastructure.id,
            widget.infrastructure.name,
          );

      // TODO: Envoyer les images au backend
      // Pour l'instant, on simule juste l'envoi
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_selectedImages.length} image(s) ajoutée(s) avec succès. Merci pour votre contribution !',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout des images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Text(
                        'Ajouter des images',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  widget.infrastructure.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingL),

                // Boutons de sélection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImagesFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galerie'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Caméra'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacingL),

                // Images sélectionnées
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'Images sélectionnées (${_selectedImages.length})',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingM),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
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
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _removeImage(index),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingL),
                ],

                // Message si aucune image
                if (_selectedImages.isEmpty)
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: AppDimensions.spacingM),
                        Text(
                          'Aucune image sélectionnée',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppDimensions.spacingS),
                        Text(
                          'Sélectionnez des images depuis votre galerie ou prenez des photos avec la caméra',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: AppDimensions.spacingL),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _selectedImages.isEmpty
                            ? null
                            : _submitImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Ajouter ${_selectedImages.isEmpty ? '' : '(${_selectedImages.length})'}',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
