import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../services/contribution_service.dart';
import '../profile/profile_screen.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _selectedCategory;
  Position? _currentPosition;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  // Ajout du service de contribution
  final ContributionService _contributionService = ContributionService();

  final Map<String, TextEditingController> _openingHoursControllers = {
    'lundi': TextEditingController(),
    'mardi': TextEditingController(),
    'mercredi': TextEditingController(),
    'jeudi': TextEditingController(),
    'vendredi': TextEditingController(),
    'samedi': TextEditingController(),
    'dimanche': TextEditingController(),
  };

  final TextEditingController _equipmentController = TextEditingController();

  static const List<Map<String, String>> _backendCategories = [
    {'value': 'toilettes_publiques', 'label': 'Toilettes publiques'},
    {'value': 'parc_jeux', 'label': 'Parc de jeux'},
    {'value': 'centre_sante', 'label': 'Centre de santé'},
    {'value': 'installation_sportive', 'label': 'Installation sportive'},
    {'value': 'espace_divertissement', 'label': 'Espace de divertissement'},
    {'value': 'autre', 'label': 'Autre infrastructure'},
  ];

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    for (final controller in _openingHoursControllers.values) {
      controller.dispose();
    }
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final position = await ref
        .read(locationServiceProvider)
        .getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 85);

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  List<String> get _equipmentPreview {
    return _equipmentController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String _formatDayLabel(String dayKey) {
    if (dayKey.isEmpty) return dayKey;
    return '${dayKey[0].toUpperCase()}${dayKey.substring(1)}';
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'obtenir votre position')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      _log('🚀 Début de la soumission de la contribution...');
      // Récupérer l'utilisateur connecté
      final userState = ref.read(userProvider);
      _log('👤 Utilisateur: ${userState.uid ?? "non connecté"}');

      if (!userState.isLoggedIn || userState.uid == null) {
        _log('❌ Utilisateur non connecté - Arrêt de la soumission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Vous devez être connecté pour contribuer. Veuillez vous connecter dans votre profil.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Récupérer le token d'authentification
      final storageService = StorageService();
      var authToken = await storageService.getAuthToken();
      _log(
        '🔑 Token récupéré (1ère tentative): ${authToken != null && authToken.isNotEmpty ? "✅ Présent (${authToken.length} caractères)" : "❌ Absent"}',
      );

      // Si le token est manquant mais que l'utilisateur est connecté, forcer la synchronisation
      if ((authToken == null || authToken.isEmpty) && userState.isLoggedIn) {
        _log(
          '🔄 Token manquant mais utilisateur connecté - Tentative de synchronisation...',
        );
        try {
          // Récupérer l'utilisateur Firebase actuel
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null && firebaseUser.email != null) {
            _log(
              '📱 Synchronisation avec Firebase user: ${firebaseUser.email}',
            );
            final apiService = ApiService();

            // Essayer loginMobile d'abord
            try {
              final loginResponse = await apiService.loginMobile(
                firebaseUser.email!,
              );
              if (loginResponse['token'] != null) {
                authToken = loginResponse['token'] as String;
                await storageService.saveAuthToken(authToken);
                apiService.setAuthToken(authToken);
                _log('✅ Token obtenu via loginMobile');
              }
            } catch (e) {
              _log('⚠️ loginMobile échoué: $e');

              // Essayer l'inscription si loginMobile échoue
              try {
                final name =
                    firebaseUser.displayName ??
                    (firebaseUser.email != null
                        ? firebaseUser.email!.split('@')[0]
                        : null) ??
                    'Utilisateur';
                final registerResponse = await apiService.register(
                  name,
                  firebaseUser.email!,
                  null,
                  firebaseAuth: true,
                );
                if (registerResponse['token'] != null) {
                  authToken = registerResponse['token'] as String;
                  await storageService.saveAuthToken(authToken);
                  apiService.setAuthToken(authToken);
                  _log('✅ Token obtenu via register');
                }
              } catch (e2) {
                _log('❌ Register échoué: $e2');
              }
            }
          }
        } catch (e) {
          _log('❌ Erreur lors de la synchronisation: $e');
        }
      }

      // Vérifier à nouveau après la synchronisation
      if (authToken == null || authToken.isEmpty) {
        _log(
          '❌ Token toujours manquant après synchronisation - Arrêt de la soumission',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Impossible de récupérer le token d\'authentification. Veuillez vous déconnecter et vous reconnecter.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _log('✅ Token final disponible: ${authToken.length} caractères');

      _log('📝 Données du formulaire:');
      _log('  - Nom: ${_nameController.text.trim()}');
      _log('  - Catégorie: $_selectedCategory');
      _log('  - Adresse: ${_addressController.text.trim()}');
      _log(
        '  - Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      _log('  - Images: ${_selectedImages.length}');

      final openingHoursPayload = <String, dynamic>{};
      _openingHoursControllers.forEach((day, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          openingHoursPayload[day] = value;
        }
      });

      final equipmentsList = _equipmentController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      _log('  - Horaires renseignés: ${openingHoursPayload.length}');
      _log('  - Équipements saisis: ${equipmentsList.length}');

      // Soumettre via le service de contribution
      _log('📤 Appel de createProposition...');
      final createdContribution = await _contributionService.createProposition(
        userId: userState.uid ?? 'user_anonymous',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _addressController.text.trim(),
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        phone: _phoneController.text.isNotEmpty
            ? _phoneController.text.trim()
            : null,
        website: _websiteController.text.isNotEmpty
            ? _websiteController.text.trim()
            : null,
        openingHours: openingHoursPayload.isNotEmpty
            ? openingHoursPayload
            : null,
        equipments: equipmentsList.isNotEmpty ? equipmentsList : null,
        authToken: authToken,
      );

      _log('🆔 Enregistrement: ${createdContribution.id ?? "inconnu"}');
      _log('📦 Payload sauvegardé: ${createdContribution.toJson()}');

      _log('✅ Contribution soumise avec succès !');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Contribution soumise avec succès ! Elle sera examinée par notre équipe.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _resetForm();
      }
    } catch (e, stackTrace) {
      _log('❌ ERREUR lors de la soumission: $e');
      _log('📚 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _phoneController.clear();
    _websiteController.clear();
    for (final controller in _openingHoursControllers.values) {
      controller.clear();
    }
    _equipmentController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedImages.clear();
    });
  }

  Widget _buildAuthenticationRequired() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo1.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppDimensions.spacingL),
          Text(
            'Connexion requise',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'Vous devez être connecté pour pouvoir contribuer en ajoutant de nouveaux lieux.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppColors.info),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'Toutes les contributions sont vérifiées avant publication pour garantir la qualité des données.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppDimensions.spacingXl),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Se connecter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    // Vérifier l'authentification
    if (!userState.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contribuer')),
        body: _buildAuthenticationRequired(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribuer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête informatif
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimensions.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Contribuez à la communauté',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    Text(
                      'Aidez les autres citoyens en signalant de nouvelles infrastructures publiques à Cotonou.',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppDimensions.spacingL),

              // Nom de l'infrastructure
              Text(
                'Nom de l\'infrastructure *',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Toilettes publiques de la Place des Martyrs',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Catégorie
              Text(
                'Catégorie *',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  hintText: 'Sélectionnez une catégorie',
                ),
                items: _backendCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category['value'],
                        child: Text(category['label'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Adresse
              Text(
                'Adresse *',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Avenue Delorme, Cotonou',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une adresse';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Description
              Text(
                'Description *',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Décrivez l\'infrastructure, son état, ses horaires d\'ouverture...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Horaires d'ouverture (optionnel)
              Text(
                'Horaires d\'ouverture (optionnel)',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indiquez les heures d\'ouverture pour chaque jour (ex: 08:00 - 18:00). Laissez vide si non applicable.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingM),
                    ..._openingHoursControllers.entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: AppDimensions.spacingS,
                        ),
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: _formatDayLabel(entry.key),
                            hintText: 'Ex: 08:00 - 18:00',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Téléphone (optionnel)
              Text(
                'Téléphone (optionnel)',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Ex: +229 XX XX XX XX',
                ),
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Site web (optionnel)
              Text(
                'Site web (optionnel)',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'Ex: https://www.example.com',
                ),
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Équipements
              Text(
                'Équipements disponibles (optionnel)',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
              SizedBox(height: AppDimensions.spacingS),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Parking, Accès PMR, Aire de jeux',
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppDimensions.spacingS),
              Text(
                'Séparez chaque équipement par une virgule.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_equipmentPreview.isNotEmpty) ...[
                SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: _equipmentPreview
                      .map((equipment) => Chip(label: Text(equipment)))
                      .toList(),
                ),
              ],

              SizedBox(height: AppDimensions.spacingM),

              // Photos
              Text('Photos', style: AppTextStyles.label.copyWith(fontSize: 14)),
              SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Prendre une photo'),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),

              if (_selectedImages.isNotEmpty) ...[
                SizedBox(height: AppDimensions.spacingM),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(right: AppDimensions.spacingS),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              child: Image.file(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              SizedBox(height: AppDimensions.spacingM),

              // Position
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: _currentPosition != null
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: _currentPosition != null
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _currentPosition != null
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        _currentPosition != null
                            ? 'Position obtenue: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                            : 'Impossible d\'obtenir votre position',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    if (_currentPosition == null)
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Réessayer'),
                      ),
                  ],
                ),
              ),

              SizedBox(height: AppDimensions.spacingXl),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitContribution,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Envoi en cours...'),
                          ],
                        )
                      : const Text('Soumettre la contribution'),
                ),
              ),

              SizedBox(height: AppDimensions.spacingM),

              // Note informative
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Text(
                  'Note: Votre contribution sera examinée par notre équipe avant d\'être publiée. Cela peut prendre quelques jours.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment contribuer ?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Remplissez tous les champs obligatoires (*)'),
              SizedBox(height: 8),
              Text('2. Ajoutez des photos pour illustrer l\'infrastructure'),
              SizedBox(height: 8),
              Text('3. Vérifiez que votre position est correcte'),
              SizedBox(height: 8),
              Text('4. Soumettez votre contribution'),
              SizedBox(height: 16),
              Text(
                'Votre contribution aidera d\'autres citoyens à découvrir cette infrastructure !',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
