# 🔐 Guide Complet - Authentification Firebase & Mot de Passe Oublié

## 📊 État Actuel du Projet

### ✅ Ce qui est déjà configuré

1. **Firebase Core** : Initialisé dans `main.dart`
2. **Firebase Auth** : Service d'authentification créé (`auth_service.dart`)
3. **Écran de connexion** : Fonctionnel avec email/mot de passe et Google
4. **Écran mot de passe oublié** : Déjà implémenté (`forgot_password_screen.dart`)
5. **Providers Riverpod** : Configuration complète avec `authServiceProvider`
6. **Google Services** : Fichier `google-services.json` présent

### 📦 Dépendances Firebase

```yaml
firebase_core: ^4.2.1
firebase_auth: ^6.1.2
firebase_storage: ^13.0.4
firebase_messaging: ^16.0.4
firebase_app_check: 0.4.1+2
cloud_firestore: ^6.1.0
google_sign_in: ^6.2.1
```

## 🔧 Configuration Complète

### 1. Configuration Firebase Console

#### A. Activer Firebase Authentication

1. **Accéder à Firebase Console** : https://console.firebase.google.com
2. **Sélectionner votre projet** : `geoloc-cotonou`
3. **Aller dans Authentication** → **Sign-in method**
4. **Activer les méthodes suivantes** :

   ✅ **Email/Password**
   - Activez "Email/Password"
   - ✅ Cochez aussi "Email link (passwordless sign-in)" si désiré

   ✅ **Google Sign-In**
   - Cliquez sur Google
   - Activez le fournisseur
   - Ajoutez votre email d'assistance : `votre-email@gmail.com`
   - Sauvegardez

#### B. Configurer les Domaines Autorisés

1. **Dans Authentication** → **Settings** → **Authorized domains**
2. **Vérifier que ces domaines sont autorisés** :
   - `localhost`
   - `geoloc-cotonou.firebaseapp.com`
   - Votre domaine personnalisé (si applicable)

#### C. Configurer les Templates d'Emails

1. **Dans Authentication** → **Templates**
2. **Configurer "Password reset"** :

   ```
   Objet : Réinitialisation de votre mot de passe CotoNav

   Contenu :
   Bonjour,

   Vous avez demandé la réinitialisation de votre mot de passe pour CotoNav.

   Cliquez sur le lien ci-dessous pour définir un nouveau mot de passe :
   %LINK%

   Si vous n'avez pas fait cette demande, ignorez cet email.

   Cordialement,
   L'équipe CotoNav
   ```

3. **Personnaliser l'URL de redirection** (optionnel) :
   - Par défaut : `geoloc-cotonou.firebaseapp.com/__/auth/action`
   - Personnalisé : Votre domaine + `/reset-password`

### 2. Configuration Android

#### A. Vérifier le SHA-1 pour Google Sign-In

```powershell
# Générer la clé SHA-1 (Debug)
cd android
./gradlew signingReport

# Ou avec PowerShell
cd android
.\gradlew.bat signingReport
```

**Copier le SHA-1** et l'ajouter dans Firebase :

1. Firebase Console → Project Settings → Your apps
2. Sélectionnez votre app Android
3. Ajoutez le SHA-1 dans "SHA certificate fingerprints"

#### B. Vérifier AndroidManifest.xml

Fichier : `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions Internet -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:name="${applicationName}"
        android:label="CotoNav"
        android:icon="@mipmap/ic_launcher">

        <!-- Activité principale Flutter -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Deep Links pour réinitialisation mot de passe -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />

                <!-- Format Firebase Auth -->
                <data
                    android:scheme="https"
                    android:host="geoloc-cotonou.firebaseapp.com"
                    android:pathPrefix="/__/auth/action" />
            </intent-filter>

            <!-- Intent filter pour lancement -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Métadonnées Flutter -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 3. Configuration iOS (si applicable)

#### A. GoogleService-Info.plist

Téléchargez depuis Firebase Console et placez dans : `ios/Runner/GoogleService-Info.plist`

#### B. Info.plist

Ajoutez les URL schemes dans `ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.VOTRE-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### 4. Configuration Web (si applicable)

#### A. Fichier firebase-config.js

Créez `web/firebase-config.js` :

```javascript
// Votre configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDPAKyaXFXOQUDrCADfMAOS3yPSRDvuHGI",
  authDomain: "geoloc-cotonou.firebaseapp.com",
  projectId: "geoloc-cotonou",
  storageBucket: "geoloc-cotonou.firebasestorage.app",
  messagingSenderId: "191342105680",
  appId: "1:191342105680:web:VOTRE_WEB_APP_ID",
};

// Initialiser Firebase
firebase.initializeApp(firebaseConfig);
```

#### B. Modifier index.html

Ajoutez dans `web/index.html` avant `</body>` :

```html
<!-- Firebase SDK -->
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-auth-compat.js"></script>
<script src="firebase-config.js"></script>
```

## 🧪 Tests de Validation

### Test 1 : Connexion avec Email/Mot de passe

```dart
// Dans un écran de test ou directement dans l'app
final authService = ref.read(authServiceProvider);

// Test inscription
final result = await authService.registerWithEmailAndPassword(
  'test@example.com',
  'password123',
  'Test User',
);

if (result != null) {
  print('✅ Inscription réussie');
} else {
  print('❌ Échec inscription');
}

// Test connexion
final loginResult = await authService.signInWithEmailAndPassword(
  'test@example.com',
  'password123',
);

if (loginResult != null) {
  print('✅ Connexion réussie');
} else {
  print('❌ Échec connexion');
}
```

### Test 2 : Mot de passe oublié

```dart
final authService = ref.read(authServiceProvider);

// Envoyer email de réinitialisation
final error = await authService.resetPassword('test@example.com');

if (error == null) {
  print('✅ Email de réinitialisation envoyé');
} else {
  print('❌ Erreur: $error');
}
```

### Test 3 : Google Sign-In

```dart
final authService = ref.read(authServiceProvider);

final result = await authService.signInWithGoogle();

if (result != null) {
  print('✅ Connexion Google réussie');
  print('User: ${result.user?.displayName}');
} else {
  print('❌ Échec connexion Google');
}
```

## 🔍 Diagnostic des Problèmes Courants

### Problème 1 : "Email de réinitialisation non reçu"

**Causes possibles** :

1. Email dans les spams
2. Configuration des templates incorrecte
3. Domaine non autorisé

**Solutions** :

```dart
// Vérifier dans auth_service.dart
Future<String?> resetPassword(String email) async {
  try {
    // Ajouter des logs pour déboguer
    debugPrint('🔄 Envoi email reset pour: $email');

    await _auth.sendPasswordResetEmail(email: email);

    debugPrint('✅ Email envoyé avec succès');
    return null;
  } on FirebaseAuthException catch (e) {
    debugPrint('❌ Erreur Firebase: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'invalid-email':
        return 'Email invalide.';
      default:
        return e.message ?? 'Erreur lors de l\'envoi de l\'email.';
    }
  }
}
```

### Problème 2 : "Google Sign-In ne fonctionne pas"

**Vérifications** :

1. ✅ SHA-1 ajouté dans Firebase Console
2. ✅ Google Sign-In activé dans Authentication
3. ✅ `google-services.json` à jour
4. ✅ Package `google_sign_in` installé

**Solution** :

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Problème 3 : "EMAIL_NOT_ALLOWED"

**Cause** : Méthode d'authentification non activée

**Solution** :

1. Firebase Console → Authentication → Sign-in method
2. Activez "Email/Password"
3. Sauvegardez

### Problème 4 : "CONFIGURATION_NOT_FOUND"

**Cause** : `google-services.json` manquant ou invalide

**Solution** :

1. Téléchargez le fichier depuis Firebase Console
2. Placez-le dans `android/app/google-services.json`
3. Vérifiez que `build.gradle.kts` contient :
   ```kotlin
   id("com.google.gms.google-services")
   ```

## 🚀 Commandes de Test

### Tester l'application

```powershell
# Nettoyer le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Lancer sur Android
flutter run --debug

# Lancer avec logs Firebase
flutter run --debug --verbose
```

### Vérifier Firebase dans l'app

```dart
// Ajouter dans main.dart après Firebase.initializeApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // TEST : Vérifier la configuration
  debugPrint('🔥 Firebase Project: ${Firebase.app().options.projectId}');
  debugPrint('🔥 Firebase App ID: ${Firebase.app().options.appId}');
  debugPrint('🔥 Firebase Storage: ${Firebase.app().options.storageBucket}');

  // Test Auth
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    debugPrint('✅ Utilisateur connecté: ${currentUser.email}');
  } else {
    debugPrint('❌ Aucun utilisateur connecté');
  }

  runApp(const MyApp());
}
```

## 📱 Flux Utilisateur - Mot de Passe Oublié

### Scénario Complet

1. **L'utilisateur oublie son mot de passe**
   - Clique sur "Mot de passe oublié?" dans `login_screen.dart`
   - Navigation vers `forgot_password_screen.dart`

2. **Entrée de l'email**
   - Saisit son adresse email
   - Validation du format email
   - Clique sur "Envoyer l'email"

3. **Envoi de l'email**

   ```dart
   final authService = ref.read(authServiceProvider);
   final errorMessage = await authService.resetPassword(email);

   if (errorMessage == null) {
     // ✅ Succès
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Email de réinitialisation envoyé!')),
     );
     Navigator.pop(context);
   } else {
     // ❌ Erreur
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(errorMessage)),
     );
   }
   ```

4. **Réception de l'email**
   - L'utilisateur reçoit un email Firebase
   - Contient un lien de réinitialisation
   - Clique sur le lien

5. **Page de réinitialisation**
   - Ouvre une page Firebase (web)
   - Saisit le nouveau mot de passe
   - Confirme le mot de passe
   - Soumet

6. **Retour à l'app**
   - Peut se reconnecter avec le nouveau mot de passe
   - Le mot de passe est immédiatement actif

## 🔐 Sécurité et Bonnes Pratiques

### 1. Validation des Emails

```dart
// Regex complète pour validation email
bool isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  ).hasMatch(email);
}
```

### 2. Force du Mot de Passe

```dart
// Validation mot de passe fort
String? validatePassword(String password) {
  if (password.length < 8) {
    return 'Le mot de passe doit contenir au moins 8 caractères';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Le mot de passe doit contenir au moins une majuscule';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Le mot de passe doit contenir au moins une minuscule';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Le mot de passe doit contenir au moins un chiffre';
  }
  return null;
}
```

### 3. Limitation des Tentatives

Firebase limite automatiquement :

- **Réinitialisation** : 5 emails par heure par IP
- **Connexion** : Blocage temporaire après plusieurs échecs

### 4. Vérification d'Email

```dart
// Envoyer email de vérification après inscription
Future<void> verifyEmail() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.emailVerified) {
    await user.sendEmailVerification();
    debugPrint('✅ Email de vérification envoyé');
  }
}
```

## 📊 Monitoring et Analytics

### Surveiller les Authentifications

1. **Firebase Console** → **Authentication** → **Users**
   - Voir tous les utilisateurs inscrits
   - Statut de vérification d'email
   - Dernière connexion

2. **Analytics** (optionnel)

   ```dart
   // Tracker les événements d'authentification
   import 'package:firebase_analytics/firebase_analytics.dart';

   final analytics = FirebaseAnalytics.instance;

   // Après connexion réussie
   await analytics.logLogin(loginMethod: 'email');

   // Après inscription
   await analytics.logSignUp(signUpMethod: 'email');
   ```

## ✅ Checklist Finale

### Configuration Firebase Console

- [ ] Projet créé : `geoloc-cotonou`
- [ ] Authentication activée
- [ ] Email/Password activé
- [ ] Google Sign-In activé
- [ ] Templates d'emails configurés
- [ ] Domaines autorisés ajoutés
- [ ] SHA-1 ajouté (Android)

### Configuration App

- [ ] `google-services.json` présent dans `android/app/`
- [ ] `GoogleService-Info.plist` présent dans `ios/Runner/` (iOS)
- [ ] Firebase initialisé dans `main.dart`
- [ ] Dépendances installées
- [ ] Navigation vers `forgot_password_screen` fonctionnelle

### Tests

- [ ] Inscription avec email/mot de passe
- [ ] Connexion avec email/mot de passe
- [ ] Mot de passe oublié (email reçu)
- [ ] Google Sign-In (Android)
- [ ] Deep links de réinitialisation

### Sécurité

- [ ] Validation email côté client
- [ ] Validation mot de passe fort
- [ ] Gestion des erreurs Firebase
- [ ] Messages d'erreur utilisateur-friendly

## 🆘 Support et Documentation

### Ressources Firebase

- **Documentation officielle** : https://firebase.google.com/docs/auth
- **FlutterFire** : https://firebase.flutter.dev/docs/auth/overview
- **Code samples** : https://github.com/firebase/flutterfire/tree/master/packages/firebase_auth

### Commandes Utiles

```powershell
# Mettre à jour FlutterFire
flutter pub upgrade firebase_core firebase_auth

# Vérifier la configuration
flutter doctor -v

# Voir les logs Firebase
flutter run --verbose | Select-String "Firebase"

# Nettoyer complètement
flutter clean
Remove-Item -Recurse -Force android/.gradle
Remove-Item -Recurse -Force android/build
flutter pub get
```

---

## 🎯 Prochaines Étapes

1. **Vérifier la console Firebase** et activer toutes les méthodes d'authentification
2. **Tester le mot de passe oublié** avec un vrai email
3. **Vérifier les spams** si l'email n'arrive pas
4. **Ajouter la vérification d'email** après inscription (optionnel)
5. **Configurer les analytics** pour suivre l'utilisation (optionnel)

---

**Date de création** : 10 février 2026  
**Version** : 1.0  
**Auteur** : GitHub Copilot
