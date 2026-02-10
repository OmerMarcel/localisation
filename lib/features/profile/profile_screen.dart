import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../features/notifications/services/fcm_service.dart';
import 'dart:io';
import 'pages/favorites_page.dart';
import 'pages/contributions_page.dart';
import 'pages/location_settings_page.dart';
import 'pages/offline_settings_page.dart';
import 'pages/help_page.dart';
import 'pages/personal_info_page.dart';
import '../auth/screens/forgot_password_screen.dart';

// Provider pour gérer l'état de l'utilisateur avec Firebase
final StateNotifierProvider<UserNotifier, UserState> userProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
      return UserNotifier();
    });

void _log(String message) {
  if (kDebugMode) debugPrint(message);
}

// Provider pour écouter les changements d'état Firebase Auth
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class UserState {
  final bool isLoggedIn;
  final String? name;
  final String? email;
  final String? uid;
  final bool isLoading;

  UserState({
    this.isLoggedIn = false,
    this.name,
    this.email,
    this.uid,
    this.isLoading = false,
  });

  get user => null;

  UserState copyWith({
    bool? isLoggedIn,
    String? name,
    String? email,
    String? uid,
    bool? isLoading,
  }) {
    return UserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      name: name ?? this.name,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState()) {
    _initAuthListener();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        state = state.copyWith(
          isLoggedIn: true,
          email: user.email,
          uid: user.uid,
          name: user.displayName ?? 'Utilisateur',
          isLoading: false,
        );
        await _syncWithBackend(user);
      } else {
        await _restoreSessionFromJwtOrClear();
      }
    });
  }

  /// Si pas de Firebase user : tenter restauration via JWT (Supabase). Sinon déconnecter.
  Future<void> _restoreSessionFromJwtOrClear() async {
    final storageService = StorageService();
    final apiService = ApiService();
    final token = await storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      state = UserState();
      await storageService.removeAuthToken();
      apiService.clearAuthToken();
      return;
    }
    apiService.setAuthToken(token);
    try {
      final profile = await apiService.getUserProfile();
      final name = profile['prenom'] != null && profile['nom'] != null
          ? '${profile['prenom']} ${profile['nom']}'.trim()
          : (profile['name'] ?? 'Utilisateur');
      state = UserState(
        isLoggedIn: true,
        email: profile['email'] ?? '',
        uid: profile['id']?.toString(),
        name: name.isEmpty ? 'Utilisateur' : name,
        isLoading: false,
      );
    } catch (_) {
      state = UserState();
      await storageService.removeAuthToken();
      apiService.clearAuthToken();
    }
  }

  /// Synchroniser l'utilisateur Firebase avec le backend pour obtenir un token JWT
  Future<void> _syncWithBackend(User firebaseUser) async {
    try {
      _log('🔄 ========== SYNC BACKEND ==========');
      _log('🔄 Email: ${firebaseUser.email}');
      final apiService = ApiService();
      final storageService = StorageService();

      // S'assurer que StorageService est initialisé
      if (!storageService.isInitialized) {
        await storageService.init();
      }

      // Vérifier si un token existe déjà
      var existingToken = await storageService.getAuthToken();
      _log(
        '🔍 Token existant: ${existingToken != null ? "Oui (${existingToken.length} chars)" : "Non"}',
      );

      // Vérifier si le token est valide (non vide)
      if (existingToken != null && existingToken.isNotEmpty) {
        _log('✅ Token JWT déjà présent, pas besoin de synchronisation');
        apiService.setAuthToken(existingToken);
        return;
      }

      // Essayer de se connecter au backend avec l'email Firebase
      if (firebaseUser.email != null) {
        _log('📱 Tentative loginMobile pour: ${firebaseUser.email}');
        try {
          // Essayer d'abord de se connecter via la route mobile
          final loginResponse = await apiService.loginMobile(
            firebaseUser.email!,
          );
          _log('📥 Réponse loginMobile: $loginResponse');
          if (loginResponse['token'] != null) {
            final token = loginResponse['token'] as String;
            await storageService.saveAuthToken(token);
            apiService.setAuthToken(token);
            // Vérifier que le token a bien été sauvegardé
            final savedToken = await storageService.getAuthToken();
            if (savedToken != null && savedToken.isNotEmpty) {
              _log(
                '✅ Token JWT obtenu et sauvegardé via loginMobile: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
              );
              // Enregistrer le token FCM après connexion réussie
              await _registerFcmTokenIfAvailable(apiService);
            } else {
              _log('⚠️ Token obtenu mais non sauvegardé correctement');
            }
            return;
          }
        } catch (e) {
          _log('⚠️ Login mobile échoué: $e');
          _log('📝 Tentative d\'inscription...');
        }

        // Si la connexion échoue, créer un compte dans le backend
        try {
          final name =
              firebaseUser.displayName ??
              (firebaseUser.email != null
                  ? firebaseUser.email!.split('@')[0]
                  : null) ??
              'Utilisateur';
          _log('📝 Inscription avec name=$name, email=${firebaseUser.email}');
          // Enregistrer sans mot de passe pour Firebase Auth
          final registerResponse = await apiService.register(
            name,
            firebaseUser.email!,
            null, // Pas de mot de passe pour Firebase
            firebaseAuth: true, // Indiquer que c'est Firebase
          );
          _log('📥 Réponse register: $registerResponse');
          if (registerResponse['token'] != null) {
            final token = registerResponse['token'] as String;
            await storageService.saveAuthToken(token);
            apiService.setAuthToken(token);
            // Vérifier que le token a bien été sauvegardé
            final savedToken = await storageService.getAuthToken();
            if (savedToken != null && savedToken.isNotEmpty) {
              _log(
                '✅ Compte créé et token JWT obtenu et sauvegardé: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
              );
              // Enregistrer le token FCM après inscription réussie
              await _registerFcmTokenIfAvailable(apiService);
            } else {
              _log('⚠️ Token obtenu mais non sauvegardé correctement');
            }
          }
        } catch (e) {
          _log('❌ Erreur inscription backend: $e');
        }
      } else {
        _log('❌ Email Firebase est null!');
      }
      _log('🔄 ========== FIN SYNC ==========');
    } catch (e) {
      _log('❌ Erreur sync backend: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // La synchronisation avec le backend se fera automatiquement via _initAuthListener
      // mais on peut aussi la forcer ici pour être sûr
      if (userCredential.user != null) {
        await _syncWithBackend(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      throw _getErrorMessage(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw 'Erreur de connexion: $e';
    }
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? verificationCode,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // Si un code de vérification est fourni, créer le compte via l'API backend
      // qui vérifiera le code avant de créer le compte
      if (verificationCode != null) {
        final apiService = ApiService();
        final registerResponse = await apiService.register(
          name,
          email,
          password,
          verificationCode: verificationCode,
        );

        // Si l'inscription réussit, créer aussi le compte Firebase
        try {
          final UserCredential result = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);

          if (result.user != null) {
            await result.user!.updateDisplayName(name);
            await result.user!.reload();
          }
        } catch (firebaseError) {
          // Si Firebase échoue mais que le backend a réussi, continuer quand même
          _log('⚠️ Erreur Firebase après inscription backend: $firebaseError');
        }

        // Le token est déjà dans la réponse de l'API
        if (registerResponse['token'] != null) {
          final storageService = StorageService();
          await storageService.saveAuthToken(registerResponse['token']);
          apiService.setAuthToken(registerResponse['token']);
          // Enregistrer le token FCM après inscription réussie
          await _registerFcmTokenIfAvailable(apiService);
        }

        state = state.copyWith(
          isLoggedIn: true,
          email: email,
          name: name,
          isLoading: false,
        );
        return;
      }

      // Ancien flux sans vérification (pour rétrocompatibilité)
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        await result.user!.reload();

        // Synchroniser avec le backend pour créer le compte et obtenir un token JWT
        await _syncWithBackend(result.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      throw _getErrorMessage(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw 'Erreur d\'inscription: $e';
    }
  }

  /// Enregistre le token FCM si disponible
  Future<void> _registerFcmTokenIfAvailable(ApiService apiService) async {
    try {
      final token = await FCMService.getToken();
      if (token != null && token.isNotEmpty) {
        final platform = Platform.isAndroid
            ? 'android'
            : (Platform.isIOS ? 'ios' : 'web');
        await apiService.registerFcmToken(token, platform: platform);
        _log('✅ Token FCM enregistré avec succès (platform: $platform)');
      } else {
        _log('⚠️ Token FCM non disponible pour l\'enregistrement');
      }
    } catch (e) {
      _log('⚠️ Erreur lors de l\'enregistrement du token FCM: $e');
      // Ne pas bloquer l'application si l'enregistrement du token échoue
    }
  }

  Future<void> logout() async {
    try {
      final storageService = StorageService();
      await storageService.removeAuthToken();
      final apiService = ApiService();
      apiService.clearAuthToken();
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur de déconnexion: $e';
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'Email invalide.';
      default:
        return 'Erreur: ${e.message}';
    }
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImageUrl;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    // Rafraîchir les statistiques au chargement et périodiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatistics();
    });
  }

  void _refreshStatistics() {
    // Rafraîchir les favoris
    ref.read(favoritesProvider.notifier).reloadFavorites();

    // Rafraîchir les contributions
    ref.read(userContributionsProvider.notifier).refresh();

    // Rafraîchir le nombre de visites
    ref.read(visitCountProvider.notifier).refresh();
  }

  Future<void> _loadProfileImage() async {
    try {
      final apiService = ApiService();
      final profile = await apiService.getUserProfile();
      if (mounted) {
        setState(() {
          // Le backend retourne 'avatar', mais on vérifie aussi 'profile_image' pour compatibilité
          _profileImageUrl = profile['avatar'] ?? profile['profile_image'];
        });
      }
    } catch (e) {
      _log('⚠️ Erreur lors du chargement de la photo de profil: $e');
      // En cas d'erreur, on garde null pour afficher l'avatar par défaut
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoadingProfile = true;
      });

      // Uploader l'image
      final apiService = ApiService();
      String imageUrl;

      try {
        final uploadedUrl = await apiService.uploadImage(image.path);
        _log('✅ Image uploadée avec succès: $uploadedUrl');

        if (uploadedUrl.isEmpty) {
          throw Exception('L\'URL de l\'image est vide');
        }

        imageUrl = uploadedUrl;
      } catch (uploadError) {
        _log('❌ Erreur lors de l\'upload: $uploadError');
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de l\'upload de l\'image: $uploadError',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Mettre à jour le profil avec l'URL de l'image
      try {
        await apiService.updateUserProfile(avatarUrl: imageUrl);
        _log('✅ Profil mis à jour avec succès');

        // Recharger le profil depuis l'API pour obtenir l'URL complète
        try {
          final updatedProfile = await apiService.getUserProfile();
          if (mounted) {
            setState(() {
              _profileImageUrl =
                  updatedProfile['avatar'] ??
                  updatedProfile['profile_image'] ??
                  imageUrl;
              _isLoadingProfile = false;
            });
          }
        } catch (reloadError) {
          _log('⚠️ Erreur lors du rechargement du profil: $reloadError');
          // Utiliser l'URL uploadée directement si le rechargement échoue
          if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
              _isLoadingProfile = false;
            });
          }
        }
      } catch (updateError) {
        _log('❌ Erreur lors de la mise à jour du profil: $updateError');
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image uploadée mais erreur lors de la mise à jour du profil: $updateError',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Afficher le message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      _log('❌ Erreur complète: $e');
      _log('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    // Rafraîchir automatiquement les statistiques quand l'utilisateur est connecté
    if (userState.isLoggedIn) {
      // Utiliser un effet pour rafraîchir périodiquement
      ref.listen(userProvider, (previous, next) {
        if (next.isLoggedIn && previous?.isLoggedIn != next.isLoggedIn) {
          // L'utilisateur vient de se connecter, rafraîchir les stats
          _refreshStatistics();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Si on ne peut pas revenir en arrière, naviguer vers l'écran d'accueil
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: userState.isLoggedIn
          ? _buildProfileContent(context, ref, userState)
          : _buildLoginPrompt(context, ref),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, WidgetRef ref) {
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
            'Connectez-vous pour accéder à votre profil',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'Sauvegardez vos favoris, gérez vos contributions et personnalisez votre expérience.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingXl),
          ElevatedButton(
            onPressed: () {
              _showLoginDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Se connecter'),
          ),
          SizedBox(height: AppDimensions.spacingM),
          OutlinedButton(
            onPressed: () {
              _showRegisterDialog(context, ref);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Créer un compte'),
          ),
          SizedBox(height: AppDimensions.spacingL),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserState userState,
  ) {
    // Utiliser ref.watch pour que les statistiques se mettent à jour automatiquement
    final favorites = ref.watch(favoritesProvider);
    final userContributionsAsync = ref.watch(userContributionsProvider);

    // Utiliser le provider pour le nombre de visites qui se met à jour automatiquement
    final visitCount = ref.watch(visitCountProvider);

    // Calculer le nombre de contributions (se met à jour automatiquement grâce à ref.watch)
    final contributionsCount = userContributionsAsync.when(
      data: (contributions) => contributions.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête du profil
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.textLight,
                      backgroundImage: _profileImageUrl != null
                          ? CachedNetworkImageProvider(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    if (_isLoadingProfile)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black54,
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isLoadingProfile ? null : _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textLight,
                              width: 2,
                            ),
                          ),
                          child: _isLoadingProfile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacingM),
                Text(
                  userState.name ?? 'Utilisateur',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textLight),
                ),
                Text(
                  userState.email ?? 'email@example.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: AppDimensions.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Favoris', favorites.length.toString()),
                    _buildStatItem(
                      'Contributions',
                      contributionsCount.toString(),
                    ),
                    _buildStatItem('Visites', visitCount.toString()),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Options du menu
          _buildMenuSection('Mon compte', [
            _buildMenuItem(
              Icons.person,
              'Mes informations personnelles',
              'Nom, email, téléphone',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalInfoPage(),
                  ),
                );
              },
            ),
          ]),

          _buildMenuSection('Mon activité', [
            _buildMenuItem(
              Icons.favorite,
              'Mes favoris',
              'Infrastructures sauvegardées',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.add_location,
              'Mes contributions',
              'Lieux que j\'ai proposés',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContributionsPage(),
                  ),
                );
              },
            ),
          ]),

          _buildMenuSection('Paramètres', [
            _buildMenuItem(Icons.language, 'Langue', 'Français', () {
              _showLanguageDialog(context);
            }),
            _buildMenuItem(
              Icons.location_on,
              'Localisation',
              'Paramètres de géolocalisation',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationSettingsPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.download,
              'Données hors ligne',
              'Gérer le cache local',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineSettingsPage(),
                  ),
                );
              },
            ),
          ]),

          _buildMenuSection('Support', [
            _buildMenuItem(
              Icons.help,
              'Aide',
              'Comment utiliser l\'application',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
            _buildMenuItem(
              Icons.feedback,
              'Envoyer des commentaires',
              'Partager votre avis',
              () {
                _showFeedbackDialog(context);
              },
            ),
            _buildMenuItem(
              Icons.info,
              'À propos',
              'Version ${AppConstants.appVersion}',
              () {
                _showAboutDialog(context);
              },
            ),
          ]),

          SizedBox(height: AppDimensions.spacingL),

          // Bouton de déconnexion
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            child: OutlinedButton(
              onPressed: () {
                _showLogoutConfirmation(context, ref);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: AppColors.error),
              ),
              child: Text(
                'Se déconnecter',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacingXl),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: Text(title, style: AppTextStyles.h4),
        ),
        SizedBox(height: AppDimensions.spacingM),
        ...items,
        SizedBox(height: AppDimensions.spacingL),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LoginPage(ref: ref),
        fullscreenDialog: true,
      ),
    );
  }

  void _showRegisterDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RegisterPage(ref: ref),
        fullscreenDialog: true,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.supportedLanguages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['name']!),
              value: lang['code']!,
              groupValue: 'fr', // TODO: Langue actuelle
              onChanged: (value) {
                Navigator.pop(context);
                // TODO: Changer la langue
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
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, size: 24, color: AppColors.primary),
            SizedBox(width: AppDimensions.spacingS),
            Expanded(child: Text(AppConstants.appName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppConstants.appVersion}',
              style: AppTextStyles.bodySmall,
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text(AppConstants.appDescription),
            SizedBox(height: AppDimensions.spacingM),
            const Text(
              'Développé pour faciliter l\'accès aux services publics à Cotonou.',
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

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(userProvider.notifier).logout();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous avez été déconnecté'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FeedbackPage(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _LoginPage extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LoginPage({required this.ref});

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingXl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: AppDimensions.spacingL),
                      Icon(Icons.login, size: 50, color: AppColors.primary),
                      SizedBox(height: AppDimensions.spacingL),
                      Text(
                        'Connectez-vous à votre compte',
                        style: AppTextStyles.h4,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.spacingXl),
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingS,
                        ),
                        child: TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
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
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingS,
                        ),
                        child: TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
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
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Mot de passe oublié?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingL),
                      ElevatedButton(
                        onPressed: userState.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                if (email.isEmpty || password.isEmpty) return;
                                try {
                                  await ref
                                      .read(userProvider.notifier)
                                      .login(email, password);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Connexion réussie !'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: userState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Se connecter'),
                      ),
                      SizedBox(height: AppDimensions.spacingL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterPage extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _RegisterPage({required this.ref});

  @override
  ConsumerState<_RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<_RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingXl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppDimensions.spacingL),
                      Icon(
                        Icons.person_add,
                        size: 50,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: AppDimensions.spacingL),
                      Text(
                        'Créez votre compte',
                        style: AppTextStyles.h4,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.spacingXl),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: const Icon(Icons.person),
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Veuillez entrer votre nom'
                            : null,
                      ),
                      SizedBox(height: AppDimensions.spacingM),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Veuillez entrer votre email'
                            : null,
                      ),
                      SizedBox(height: AppDimensions.spacingM),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText:
                              'Créer un mot de passe (min. 6 caractères)',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
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
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Veuillez entrer un mot de passe';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),
                      SizedBox(height: AppDimensions.spacingL),
                      ElevatedButton(
                        onPressed: userState.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                if (name.isEmpty || email.isEmpty) return;
                                try {
                                  await ref
                                      .read(userProvider.notifier)
                                      .register(name, email, password);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Compte créé avec succès !',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: userState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Créer un compte'),
                      ),
                      SizedBox(height: AppDimensions.spacingL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPage extends StatefulWidget {
  @override
  State<_FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<_FeedbackPage> {
  final feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer des commentaires'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppDimensions.spacingL),
                          Text(
                            'Que pensez-vous de cette application ?',
                            style: AppTextStyles.h4,
                          ),
                          SizedBox(height: AppDimensions.spacingM),
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingS,
                            ),
                            child: TextFormField(
                              controller: feedbackController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: 'Écrivez vos commentaires ici...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM,
                                  ),
                                ),
                                contentPadding: EdgeInsets.all(
                                  AppDimensions.spacingM,
                                ),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer vos commentaires';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingL),
                          ElevatedButton(
                            onPressed: () {
                              if (feedbackController.text.isNotEmpty) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Merci pour vos commentaires !',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // TODO: Envoyer le feedback à l'API
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Envoyer'),
                          ),
                          SizedBox(height: AppDimensions.spacingL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
