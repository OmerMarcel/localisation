import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  final NotificationStorageService _storageService;

  /// On ne met plus de notifications d'exemple par défaut.
  /// La liste est uniquement alimentée par les vraies notifications
  /// (FCM / backend) via [addNotification].
  /// Les notifications sont maintenant persistées localement.
  NotificationsNotifier(this._storageService) : super([]) {
    _loadStoredNotifications();
  }

  /// Charger les notifications depuis le stockage local
  Future<void> _loadStoredNotifications() async {
    try {
      final storedNotifications = await _storageService.loadNotifications();
      state = storedNotifications;
      print(
        '✅ ${storedNotifications.length} notifications chargées depuis le stockage',
      );
    } catch (e) {
      print('❌ Erreur lors du chargement des notifications: $e');
    }
  }

  /// Recharger les notifications manuellement (utile après reconnexion)
  Future<void> refreshNotifications() async {
    await _loadStoredNotifications();
  }

  /// Ajouter une nouvelle notification et la sauvegarder
  void addNotification(NotificationModel notification) async {
    state = [notification, ...state];
    // Sauvegarder dans le stockage local
    await _storageService.addNotification(notification);
  }

  void markAsRead(String notificationId) async {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
    // Sauvegarder dans le stockage local
    await _storageService.markAsRead(notificationId);
  }

  void markAsUnread(String notificationId) async {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(isRead: false)
        else
          notification,
    ];
    // Sauvegarder dans le stockage local
    await _storageService.saveNotifications(state);
  }

  void markAllAsRead() async {
    state = [
      for (final notification in state) notification.copyWith(isRead: true),
    ];
    // Sauvegarder dans le stockage local
    await _storageService.markAllAsRead();
  }

  void deleteNotification(String notificationId) async {
    state = state
        .where((notification) => notification.id != notificationId)
        .toList();
    // Supprimer du stockage local
    await _storageService.deleteNotification(notificationId);
  }

  void clearAllNotifications() async {
    state = [];
    // Supprimer toutes les notifications du stockage local
    await _storageService.clearAllNotifications();
  }

  /// Nettoyer les anciennes notifications (par défaut > 30 jours)
  Future<void> cleanOldNotifications({int daysToKeep = 30}) async {
    await _storageService.cleanOldNotifications(daysToKeep: daysToKeep);
    await _loadStoredNotifications(); // Recharger après nettoyage
  }

  // Méthodes utilitaires pour créer des notifications spécifiques
  void addInfrastructureNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? actionData,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.infrastructure,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
    addNotification(notification);
  }

  void addProximityNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? actionData,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.proximity,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
    addNotification(notification);
  }

  void addSystemNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.system,
      timestamp: DateTime.now(),
      priority: priority,
    );
    addNotification(notification);
  }

  void addAlertNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.high,
    Map<String, dynamic>? actionData,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.alert,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
    addNotification(notification);
  }

  // Obtenir le nombre de notifications non lues
  int get unreadCount =>
      state.where((notification) => !notification.isRead).length;

  // Obtenir les notifications par type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return state.where((notification) => notification.type == type).toList();
  }

  // Obtenir les notifications par priorité
  List<NotificationModel> getNotificationsByPriority(
    NotificationPriority priority,
  ) {
    return state
        .where((notification) => notification.priority == priority)
        .toList();
  }

  // Obtenir les notifications non lues
  List<NotificationModel> get unreadNotifications {
    return state.where((notification) => !notification.isRead).toList();
  }

  // Obtenir les notifications importantes
  List<NotificationModel> get importantNotifications {
    return state
        .where(
          (notification) => notification.priority == NotificationPriority.high,
        )
        .toList();
  }
}

// Provider pour le service de stockage
final notificationStorageServiceProvider = Provider<NotificationStorageService>(
  (ref) {
    return NotificationStorageService();
  },
);

// Provider pour les notifications avec persistance
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>((
      ref,
    ) {
      final storageService = ref.watch(notificationStorageServiceProvider);
      return NotificationsNotifier(storageService);
    });

// Provider pour le nombre de notifications non lues
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((notification) => !notification.isRead).length;
});
