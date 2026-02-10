import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../profile_screen.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      final profile = await apiService.getUserProfile();
      final userState = ref.read(userProvider);

      setState(() {
        _nameController.text = profile['name'] ?? userState.name ?? '';
        _emailController.text = profile['email'] ?? userState.email ?? '';
        _phoneController.text = profile['phone'] ?? profile['telephone'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement du profil: $e');
      final userState = ref.read(userProvider);
      setState(() {
        _nameController.text = userState.name ?? '';
        _emailController.text = userState.email ?? '';
        _phoneController.text = '';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ApiService();
      final user = FirebaseAuth.instance.currentUser;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;

      // 1. Mettre à jour le profil via l'API (synchronise avec Supabase et Firebase côté backend)
      await apiService.updateUserProfile(name: name, phone: phone);

      // 2. Mettre à jour Firebase localement aussi pour une synchronisation immédiate
      if (user != null) {
        try {
          // Mettre à jour le nom d'affichage Firebase
          if (user.displayName != name) {
            await user.updateDisplayName(name);
          }

          // Note: La mise à jour du téléphone Firebase nécessite une vérification SMS
          // Le backend synchronise déjà le téléphone avec Firebase Admin SDK

          // Recharger les données utilisateur Firebase
          await user.reload();

          print('✅ Profil Firebase mis à jour localement');
        } catch (firebaseError) {
          print(
            '⚠️ Erreur lors de la mise à jour Firebase locale: $firebaseError',
          );
          // Ne pas bloquer si Firebase échoue, l'API backend a déjà synchronisé
        }
      }

      // Recharger le profil depuis l'API
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Informations mises à jour avec succès (Supabase et Firebase)',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes informations personnelles')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppDimensions.spacingXl),
                    // Nom
                    Text(
                      'Nom complet *',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Votre nom complet',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingM,
                          vertical: AppDimensions.spacingM,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom doit contenir au moins 2 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppDimensions.spacingL),

                    // Email (lecture seule)
                    Text(
                      'Email',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'votre.email@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingM,
                          vertical: AppDimensions.spacingM,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingL),

                    // Téléphone
                    Text(
                      'Numéro de téléphone',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+229 XX XX XX XX',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingM,
                          vertical: AppDimensions.spacingM,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          // Validation basique du numéro de téléphone
                          final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Format de numéro invalide';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppDimensions.spacingS),
                    Container(
                      padding: EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: AppDimensions.spacingS),
                          Expanded(
                            child: Text(
                              'Le numéro de téléphone est optionnel. Il vous permettra de recevoir des notifications importantes.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingXl),

                    // Bouton de sauvegarde
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                        child: _isSaving
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
                            : const Text('Enregistrer les modifications'),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingL),
                  ],
                ),
              ),
            ),
    );
  }
}
