import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fcm_service.dart';
import '../../../core/services/api_service.dart';
import '../../../features/profile/profile_screen.dart';

class NotificationInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize(WidgetRef ref) async {
    if (_isInitialized) return;

    try {
      // Initialiser Firebase si ce n'est pas déjà fait
      await Firebase.initializeApp();

      // Le handler d'arrière-plan est déjà enregistré dans main.dart
      // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialiser le service FCM
      await FCMService.initialize(ref);

      // S'abonner aux topics par défaut
      await _subscribeToDefaultTopics();

      // Enregistrer le token FCM si l'utilisateur est connecté
      await _registerFcmTokenIfUserLoggedIn(ref);

      _isInitialized = true;
      print('✅ Notifications initialisées avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Enregistre le token FCM si l'utilisateur est connecté
  static Future<void> _registerFcmTokenIfUserLoggedIn(WidgetRef ref) async {
    try {
      final userState = ref.read(userProvider);
      if (userState.isLoggedIn) {
        final apiService = ApiService();

        // Vérifier et réenregistrer le token FCM
        await apiService.verifyAndRegisterFcmToken();

        print('✅ Token FCM vérifié et enregistré au démarrage');
      }
    } catch (e) {
      print(
        '⚠️ Erreur lors de l\'enregistrement du token FCM au démarrage: $e',
      );
    }
  }

  static Future<void> _subscribeToDefaultTopics() async {
    try {
      // S'abonner aux mises à jour générales
      await FCMService.subscribeToTopic('cotonou_general');

      // S'abonner aux alertes importantes
      await FCMService.subscribeToTopic('cotonou_alerts');

      // S'abonner aux nouvelles infrastructures
      await FCMService.subscribeToInfrastructureUpdates();

      print('✅ Abonnement aux topics par défaut réussi');
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement aux topics: $e');
    }
  }

  // Méthode pour tester les notifications
  static Future<void> testNotifications() async {
    await FCMService.sendTestNotification();
  }

  // Obtenir le token pour l'envoyer au serveur
  static Future<String?> getDeviceToken() async {
    return await FCMService.getToken();
  }
}
