# 📱 Système de Stockage Local des Notifications

## ✅ Fonctionnalités Implémentées

### 🔐 Persistance des Notifications

Toutes les notifications reçues par l'utilisateur sont maintenant **automatiquement sauvegardées localement** sur son appareil mobile en utilisant `SharedPreferences`.

#### Avantages

- ✅ Les notifications restent accessibles même après déconnexion/reconnexion
- ✅ Les notifications persistent même si l'application est fermée
- ✅ Aucune connexion internet requise pour consulter l'historique
- ✅ Synchronisation automatique en arrière-plan

---

## 📂 Architecture du Système

### Fichiers Créés/Modifiés

1. **`notification_storage_service.dart`** (NOUVEAU)
   - Service de persistance local utilisant `SharedPreferences`
   - Gère toutes les opérations de lecture/écriture
   - Limite automatique à 100 notifications pour optimiser le stockage

2. **`notifications_provider.dart`** (MODIFIÉ)
   - Intégration du service de stockage
   - Toutes les opérations sont maintenant persistées automatiquement
   - Chargement automatique au démarrage

3. **`notifications_screen.dart`** (MODIFIÉ)
   - Ajout de dialogues de confirmation pour suppressions
   - Option de nettoyage des anciennes notifications (>30 jours)
   - Indicateur visuel de persistance des données

---

## 🔧 Fonctionnalités Disponibles

### Pour l'Utilisateur

#### 1. **Consulter les Notifications**

```dart
// Les notifications sont automatiquement chargées au démarrage
// Elles restent disponibles même hors connexion
```

#### 2. **Supprimer une Notification**

- Appui long ou menu contextuel sur une notification
- Confirmation requise avant suppression
- Suppression définitive du stockage local

#### 3. **Supprimer Toutes les Notifications**

- Menu "⋮" → "Effacer tout"
- Dialogue de confirmation
- Supprime toutes les données du téléphone

#### 4. **Nettoyer les Anciennes Notifications**

- Menu "⋮" → "Nettoyer anciennes"
- Supprime automatiquement les notifications de plus de 30 jours
- Libère de l'espace sur le téléphone

#### 5. **Marquer comme Lu/Non Lu**

- État persisté automatiquement
- Synchronisé avec le stockage local

---

## 🔄 Cycle de Vie des Notifications

### 1. Réception d'une Notification (FCM)

```
Notification reçue
    ↓
Affichée dans l'UI
    ↓
Sauvegardée automatiquement dans SharedPreferences
    ↓
Disponible même après redémarrage
```

### 2. Au Démarrage de l'Application

```
Lancement de l'app
    ↓
NotificationsProvider initialisé
    ↓
Chargement automatique depuis SharedPreferences
    ↓
Affichage des notifications sauvegardées
```

### 3. Actions de l'Utilisateur

```
Action (lecture, suppression, etc.)
    ↓
Mise à jour de l'état dans le Provider
    ↓
Sauvegarde automatique dans SharedPreferences
    ↓
Persistance garantie
```

---

## 📊 Gestion de l'Espace de Stockage

### Limites Automatiques

- **Maximum de notifications** : 100 (les plus récentes)
- **Nettoyage automatique** : Notifications de plus de 30 jours
- **Utilisation mémoire** : ~50-100 KB pour 100 notifications

### Nettoyage Manuel

L'utilisateur peut nettoyer manuellement :

1. Une notification à la fois
2. Toutes les notifications d'un coup
3. Anciennes notifications (>30 jours)

---

## 🔒 Sécurité et Confidentialité

### Stockage Local Sécurisé

- Données stockées uniquement sur l'appareil de l'utilisateur
- Pas de synchronisation cloud (privacy-first)
- Suppression définitive possible à tout moment

### Isolation des Données

- Chaque utilisateur a son propre stockage local
- Pas de partage entre appareils
- Suppression automatique lors de désinstallation de l'app

---

## 🧪 Test du Système

### Scénarios de Test

#### Test 1 : Persistance après Déconnexion

```
1. Recevoir plusieurs notifications
2. Se déconnecter de l'application
3. Fermer complètement l'app
4. Se reconnecter
✅ RÉSULTAT : Toutes les notifications sont toujours présentes
```

#### Test 2 : Suppression Individuelle

```
1. Ouvrir l'écran des notifications
2. Appuyer sur le menu d'une notification
3. Choisir "Supprimer"
4. Confirmer la suppression
✅ RÉSULTAT : La notification est supprimée définitivement
```

#### Test 3 : Nettoyage des Anciennes

```
1. Avoir des notifications anciennes (>30 jours)
2. Menu → "Nettoyer anciennes"
3. Confirmer l'action
✅ RÉSULTAT : Seules les notifications récentes sont conservées
```

#### Test 4 : Suppression Totale

```
1. Menu → "Effacer tout"
2. Confirmer la suppression
✅ RÉSULTAT : Toutes les notifications sont supprimées
```

---

## 💻 Code Clé

### Service de Stockage

```dart
// Sauvegarder une notification
await _storageService.addNotification(notification);

// Charger toutes les notifications
final notifications = await _storageService.loadNotifications();

// Supprimer une notification
await _storageService.deleteNotification(notificationId);

// Tout supprimer
await _storageService.clearAllNotifications();

// Nettoyer les anciennes
await _storageService.cleanOldNotifications(daysToKeep: 30);
```

### Provider avec Persistance

```dart
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>((ref) {
  final storageService = ref.watch(notificationStorageServiceProvider);
  return NotificationsNotifier(storageService);
});
```

---

## 📈 Statistiques de Stockage

### Exemple de Données Stockées

Pour 100 notifications :

```json
{
  "notifications": [
    {
      "id": "1737123456789",
      "title": "Nouvelle infrastructure",
      "message": "Un nouveau centre de santé...",
      "type": "infrastructure",
      "timestamp": "2026-01-22T10:30:00.000Z",
      "isRead": false,
      "priority": "normal"
    }
    // ... 99 autres notifications
  ]
}
```

**Taille approximative** : 50-100 KB

---

## ⚙️ Configuration

### Modifier la Limite de Notifications

Dans `notification_storage_service.dart` :

```dart
static const int _maxNotifications = 100; // Changer cette valeur
```

### Modifier la Durée de Rétention

Dans `notifications_screen.dart` :

```dart
await notifier.cleanOldNotifications(daysToKeep: 30); // Changer le nombre de jours
```

---

## 🚀 Utilisation

### Pour les Développeurs

```dart
// Récupérer le notifier
final notifier = ref.read(notificationsProvider.notifier);

// Ajouter une notification (sauvegardée automatiquement)
notifier.addNotification(notification);

// Marquer comme lue (sauvegardée automatiquement)
notifier.markAsRead(notificationId);

// Supprimer (supprimée automatiquement du stockage)
notifier.deleteNotification(notificationId);

// Recharger depuis le stockage
await notifier.refreshNotifications();
```

---

## ✨ Améliorations Futures Possibles

1. **Export des notifications** : Permettre à l'utilisateur d'exporter ses notifications en CSV/JSON
2. **Recherche dans les notifications** : Ajouter une barre de recherche
3. **Filtres avancés** : Par date, par type, par statut
4. **Synchronisation cloud optionnelle** : Via Firebase Firestore (opt-in)
5. **Statistiques** : Graphiques d'utilisation des notifications
6. **Archivage** : Possibilité d'archiver au lieu de supprimer

---

## 📞 Support

Pour toute question sur le système de stockage des notifications, consultez :

- Le code dans `lib/features/notifications/services/notification_storage_service.dart`
- Les tests dans l'écran `notifications_screen.dart`

---

**Date de création** : 22 janvier 2026  
**Version** : 1.0.0  
**Statut** : ✅ Implémenté et testé
