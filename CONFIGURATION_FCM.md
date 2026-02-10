# Configuration Firebase Cloud Messaging (FCM)

## 🚀 Installation et Configuration

### 1. Configuration Firebase Console

1. **Allez sur [Firebase Console](https://console.firebase.google.com/)**
2. **Créez un nouveau projet** ou sélectionnez votre projet existant
3. **Ajoutez votre application Android/iOS** au projet
4. **Téléchargez les fichiers de configuration** :
   - `google-services.json` pour Android → placez dans `android/app/`
   - `GoogleService-Info.plist` pour iOS → placez dans `ios/Runner/`

### 2. Configuration Android

#### Fichier `android/build.gradle` (niveau projet)

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### Fichier `android/app/build.gradle`

```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-bom:32.7.0'
    implementation 'com.google.firebase:firebase-messaging'
}
```

#### Fichier `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application>
    <!-- Service pour les notifications en arrière-plan -->
    <service
        android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService"
        android:exported="false" />

    <!-- Icône de notification par défaut -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />

    <!-- Couleur de notification par défaut -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_color" />

    <!-- Canal de notification par défaut -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="cotonou_notifications" />
</application>
```

### 3. Configuration iOS (si nécessaire)

#### Fichier `ios/Runner/Info.plist`

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### 4. Génération du fichier firebase_options.dart

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter à Firebase
firebase login

# Configurer Flutter pour Firebase
dart pub global activate flutterfire_cli

# Générer le fichier de configuration
flutterfire configure
```

## 🎯 Fonctionnalités Implémentées

### 1. Service FCM Complet (`fcm_service.dart`)

- ✅ Initialisation automatique
- ✅ Gestion des permissions
- ✅ Notifications locales
- ✅ Gestion avant-plan/arrière-plan
- ✅ Topics et abonnements
- ✅ Navigation depuis notifications

### 2. Initialisation Automatique (`notification_initializer.dart`)

- ✅ Configuration au démarrage
- ✅ Abonnement aux topics par défaut
- ✅ Gestion d'erreurs

### 3. Widget de Test (`fcm_test_widget.dart`)

- ✅ Affichage du token FCM
- ✅ Test d'envoi de notifications
- ✅ Gestion des abonnements topics
- ✅ Interface utilisateur intuitive

### 4. Intégration dans l'Application

- ✅ Initialisation dans `main.dart`
- ✅ Liaison avec le provider de notifications
- ✅ Widget de test dans les paramètres

## 📱 Utilisation

### 1. Tester les Notifications

1. **Ouvrez l'application**
2. **Allez dans Paramètres des notifications**
3. **Copiez le token FCM affiché**
4. **Utilisez Firebase Console ou votre backend pour envoyer**

### 2. Envoyer depuis Firebase Console

1. **Allez dans Firebase Console → Cloud Messaging**
2. **Cliquez sur "Send your first message"**
3. **Remplissez le titre et le message**
4. **Collez le token FCM dans "Send test message"**

### 3. Format des Données pour Navigation

```json
{
  "notification": {
    "title": "Nouvelle infrastructure",
    "body": "Un nouveau centre de santé a été ajouté"
  },
  "data": {
    "type": "infrastructure",
    "screen": "map",
    "latitude": "6.3703",
    "longitude": "2.3912",
    "category": "Santé"
  }
}
```

## 🔧 Topics Disponibles

- `cotonou_general` - Notifications générales
- `cotonou_alerts` - Alertes importantes
- `infrastructure_updates` - Nouvelles infrastructures
- `location_updates` - Mises à jour de proximité
- `emergency_alerts` - Alertes d'urgence

## 🛠️ Personnalisation

### Types de Notifications Supportés

```dart
enum NotificationType {
  infrastructure,  // Nouvelles infrastructures
  proximity,      // Notifications de proximité
  system,         // Notifications système
  update,         // Mises à jour app
  alert,          // Alertes importantes
}
```

### Priorités Disponibles

```dart
enum NotificationPriority {
  low,     // Priorité basse
  normal,  // Priorité normale (défaut)
  high,    // Priorité haute (alertes)
}
```

## 🔒 Sécurité et Bonnes Pratiques

1. **Ne jamais exposer** les clés privées Firebase
2. **Valider côté serveur** avant d'envoyer des notifications
3. **Limiter les abonnements** aux topics pertinents
4. **Gérer les permissions** utilisateur correctement
5. **Tester sur différents appareils** et versions Android/iOS

## 📝 Logs et Débogage

Les logs FCM sont préfixés :

- `📱` Messages reçus
- `🔔` Notifications cliquées
- `✅` Opérations réussies
- `❌` Erreurs

## 🚀 Prochaines Étapes

1. **Backend pour notifications** personnalisées
2. **Géofencing** pour proximité automatique
3. **Analytics** des notifications
4. **A/B Testing** des messages
5. **Rich notifications** avec images/actions

Votre système FCM est maintenant prêt et entièrement fonctionnel ! 🎉
