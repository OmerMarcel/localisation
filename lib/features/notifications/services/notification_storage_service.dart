import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

/// Service de stockage local des notifications
/// Permet de persister les notifications même après déconnexion
class NotificationStorageService {
  static const String _storageKey = 'stored_notifications';
  static const int _maxNotifications =
      100; // Limite pour éviter trop de stockage

  /// Sauvegarder toutes les notifications
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limiter le nombre de notifications stockées
      final notificationsToSave = notifications.length > _maxNotifications
          ? notifications.take(_maxNotifications).toList()
          : notifications;

      // Convertir en JSON
      final jsonList = notificationsToSave.map((n) => n.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Sauvegarder
      await prefs.setString(_storageKey, jsonString);
      print('✅ ${notificationsToSave.length} notifications sauvegardées');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des notifications: $e');
    }
  }

  /// Charger toutes les notifications sauvegardées
  Future<List<NotificationModel>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('ℹ️ Aucune notification sauvegardée');
        return [];
      }

      // Décoder le JSON
      final jsonList = json.decode(jsonString) as List;
      final notifications = jsonList
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      print(
        '✅ ${notifications.length} notifications chargées depuis le stockage',
      );
      return notifications;
    } catch (e) {
      print('❌ Erreur lors du chargement des notifications: $e');
      return [];
    }
  }

  /// Ajouter une notification au stockage
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final existingNotifications = await loadNotifications();

      // Ajouter la nouvelle notification au début
      final updatedNotifications = [notification, ...existingNotifications];

      // Sauvegarder
      await saveNotifications(updatedNotifications);
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la notification: $e');
    }
  }

  /// Supprimer une notification spécifique
  Future<void> deleteNotification(String notificationId) async {
    try {
      final existingNotifications = await loadNotifications();

      // Filtrer pour retirer la notification
      final updatedNotifications = existingNotifications
          .where((n) => n.id != notificationId)
          .toList();

      // Sauvegarder
      await saveNotifications(updatedNotifications);
      print('✅ Notification $notificationId supprimée');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la notification: $e');
    }
  }

  /// Marquer une notification comme lue dans le stockage
  Future<void> markAsRead(String notificationId) async {
    try {
      final existingNotifications = await loadNotifications();

      // Mettre à jour l'état de lecture
      final updatedNotifications = existingNotifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      // Sauvegarder
      await saveNotifications(updatedNotifications);
    } catch (e) {
      print('❌ Erreur lors du marquage de la notification comme lue: $e');
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final existingNotifications = await loadNotifications();

      // Marquer toutes comme lues
      final updatedNotifications = existingNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      // Sauvegarder
      await saveNotifications(updatedNotifications);
      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur lors du marquage de toutes les notifications: $e');
    }
  }

  /// Supprimer toutes les notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✅ Toutes les notifications supprimées du stockage');
    } catch (e) {
      print('❌ Erreur lors de la suppression de toutes les notifications: $e');
    }
  }

  /// Obtenir le nombre de notifications stockées
  Future<int> getNotificationCount() async {
    try {
      final notifications = await loadNotifications();
      return notifications.length;
    } catch (e) {
      print('❌ Erreur lors du comptage des notifications: $e');
      return 0;
    }
  }

  /// Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final notifications = await loadNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Erreur lors du comptage des notifications non lues: $e');
      return 0;
    }
  }

  /// Nettoyer les vieilles notifications (plus de X jours)
  Future<void> cleanOldNotifications({int daysToKeep = 30}) async {
    try {
      final existingNotifications = await loadNotifications();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      // Garder seulement les notifications récentes
      final recentNotifications = existingNotifications
          .where((n) => n.timestamp.isAfter(cutoffDate))
          .toList();

      if (recentNotifications.length < existingNotifications.length) {
        await saveNotifications(recentNotifications);
        final removed =
            existingNotifications.length - recentNotifications.length;
        print('✅ $removed anciennes notifications supprimées');
      }
    } catch (e) {
      print('❌ Erreur lors du nettoyage des vieilles notifications: $e');
    }
  }
}
