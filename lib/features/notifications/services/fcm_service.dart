import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static WidgetRef? _ref;

  // Initialiser le service FCM
  static Future<void> initialize(WidgetRef ref) async {
    _ref = ref;

    try {
      // Demander les permissions
      await _requestPermissions();

      // Configurer les notifications locales
      await _initializeLocalNotifications();

      // Configurer FCM
      await _configureFCM();

      // Obtenir le token FCM
      String? token = await getToken();
      if (token != null) {
        print(
          '================================================================',
        );
        print('✅ Token FCM (copiez ceci pour les tests):');
        print(token);
        print(
          '================================================================',
        );
        // Vous pouvez envoyer ce token à votre serveur backend
      }

      print('✅ FCM Service initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation FCM: $e');
    }
  }

  // Demander les permissions nécessaires
  static Future<void> _requestPermissions() async {
    // Permissions FCM
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permission FCM: ${settings.authorizationStatus}');

    // Permissions système (Android 13+)
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print('Permission système: $status');
    }
  }

  // Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Créer le canal de notification Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'cotonou_notifications', // ID
      'Notifications Cotonou', // Nom
      description: 'Notifications pour les infrastructures de Cotonou',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.blue,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Configurer FCM
  static Future<void> _configureFCM() async {
    // Écouter les messages en avant-plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les clics sur les notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageClick);

    // Gérer les messages reçus quand l'app était fermée
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        _handleBackgroundMessageClick(message);
      }
    });

    // Configurer les paramètres d'avant-plan
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Gérer les messages en avant-plan
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Message reçu en avant-plan: ${message.messageId}');

    // Ajouter à la liste des notifications dans l'app
    if (_ref != null) {
      final notificationsNotifier = _ref!.read(notificationsProvider.notifier);
      final appNotification = _createAppNotificationFromFCM(message);
      notificationsNotifier.addNotification(appNotification);
    }

    // Afficher une notification locale
    await _showLocalNotification(message);
  }

  // Gérer les clics sur les notifications en arrière-plan
  static Future<void> _handleBackgroundMessageClick(
    RemoteMessage message,
  ) async {
    print('🔔 Notification cliquée: ${message.messageId}');

    // Ajouter à la liste des notifications dans l'app si pas déjà fait
    if (_ref != null) {
      final notificationsNotifier = _ref!.read(notificationsProvider.notifier);
      final appNotification = _createAppNotificationFromFCM(message);
      notificationsNotifier.addNotification(appNotification);
    }

    // Naviguer vers l'écran approprié selon les données
    _handleNotificationNavigation(message.data);
  }

  // Afficher une notification locale
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'cotonou_notifications',
          'Notifications Cotonou',
          channelDescription:
              'Notifications pour les infrastructures de Cotonou',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Colors.blue,
          enableVibration: true,
          enableLights: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Créer une notification app à partir d'un message FCM
  static NotificationModel _createAppNotificationFromFCM(
    RemoteMessage message,
  ) {
    // Déterminer le type de notification basé sur les données
    NotificationType type = NotificationType.system;
    NotificationPriority priority = NotificationPriority.normal;

    if (message.data.containsKey('type')) {
      switch (message.data['type']) {
        case 'infrastructure':
          type = NotificationType.infrastructure;
          priority = NotificationPriority.high;
          break;
        case 'proposition':
          type = NotificationType.infrastructure;
          priority = NotificationPriority.high;
          break;
        case 'signalement':
          type = NotificationType.alert;
          priority = NotificationPriority.high;
          break;
        case 'proximity':
          type = NotificationType.proximity;
          priority = NotificationPriority.high;
          break;
        case 'alert':
          type = NotificationType.alert;
          priority = NotificationPriority.high;
          break;
        case 'update':
          type = NotificationType.update;
          break;
        default:
          type = NotificationType.system;
      }
    }

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Nouvelle notification',
      message: message.notification?.body ?? '',
      type: type,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: message.data.isNotEmpty ? message.data : null,
    );
  }

  // Gérer la navigation depuis une notification
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Implémentez ici la logique de navigation basée sur les données
    print('Navigation avec données: $data');

    // Exemple de navigation :
    // if (data.containsKey('screen')) {
    //   switch (data['screen']) {
    //     case 'map':
    //       // Naviguer vers la carte avec les coordonnées
    //       break;
    //     case 'profile':
    //       // Naviguer vers le profil
    //       break;
    //   }
    // }
  }

  // Gérer le clic sur une notification locale
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification locale cliquée: ${notificationResponse.payload}');
    // Gérer le clic sur la notification locale
  }

  // Obtenir le token FCM
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print('Erreur lors de l\'obtention du token: $e');
      return null;
    }
  }

  // S'abonner à un topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      print('❌ Erreur abonnement topic $topic: $e');
    }
  }

  // Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      print('❌ Erreur désabonnement topic $topic: $e');
    }
  }

  // Envoyer une notification de test (pour développement)
  static Future<void> sendTestNotification() async {
    if (_ref != null) {
      final notificationsNotifier = _ref!.read(notificationsProvider.notifier);

      final testNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Notification de test FCM',
        message: 'Ceci est une notification de test envoyée via FCM',
        type: NotificationType.system,
        timestamp: DateTime.now(),
        priority: NotificationPriority.normal,
      );

      notificationsNotifier.addNotification(testNotification);

      // Afficher aussi une notification locale
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'cotonou_notifications',
            'Notifications Cotonou',
            channelDescription:
                'Notifications pour les infrastructures de Cotonou',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        testNotification.hashCode,
        testNotification.title,
        testNotification.message,
        platformChannelSpecifics,
      );
    }
  }

  // Méthodes utilitaires pour les topics
  static Future<void> subscribeToLocationUpdates() async {
    await subscribeToTopic('location_updates');
  }

  static Future<void> subscribeToInfrastructureUpdates() async {
    await subscribeToTopic('infrastructure_updates');
  }

  static Future<void> subscribeToEmergencyAlerts() async {
    await subscribeToTopic('emergency_alerts');
  }

  // Gérer les permissions pour iOS
  static Future<bool> requestPermissionsIOS() async {
    if (Platform.isIOS) {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return true;
  }
}

// Handler pour les messages en arrière-plan (doit être une fonction top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Assurez-vous que Firebase est initialisé pour le traitement en arrière-plan
  await Firebase.initializeApp();
  print('📱 Message reçu en arrière-plan: ${message.messageId}');

  // Vous pouvez traiter les messages en arrière-plan ici
  // Attention: pas d'accès au context ou aux providers ici
}
