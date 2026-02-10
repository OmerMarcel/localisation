# ✅ Checklist de Configuration Firebase Auth

## 📋 Avant de Commencer

Utilisez cette checklist pour vérifier que tout est correctement configuré.

---

## 🔥 Firebase Console

### Projet Firebase

- [ ] Projet créé sur https://console.firebase.google.com
- [ ] Nom du projet : `geoloc-cotonou`
- [ ] Project ID : `geoloc-cotonou`

### Authentication

- [ ] Ouvrir **Authentication** dans le menu
- [ ] Cliquer sur **Get Started** (si première fois)
- [ ] Aller dans **Sign-in method**

### Méthodes d'Authentification

- [ ] **Email/Password**
  - [ ] Activé ✅
  - [ ] "Email link (passwordless)" : selon vos besoins
- [ ] **Google**
  - [ ] Activé ✅
  - [ ] Email d'assistance configuré
  - [ ] OAuth consent screen configuré (si nécessaire)

### Templates d'Emails

- [ ] Aller dans **Authentication** → **Templates**
- [ ] Cliquer sur **Password reset** (réinitialisation de mot de passe)
- [ ] Personnaliser :
  - [ ] Nom de l'expéditeur : `CotoNav`
  - [ ] Sujet de l'email : `Réinitialisation de votre mot de passe`
  - [ ] Message personnalisé (optionnel)
- [ ] Sauvegarder

### Domaines Autorisés

- [ ] **Authentication** → **Settings** → **Authorized domains**
- [ ] Vérifier que ces domaines sont présents :
  - [ ] `localhost`
  - [ ] `geoloc-cotonou.firebaseapp.com`
  - [ ] Votre domaine web (si applicable)

---

## 📱 Configuration Android

### Fichiers de Configuration

- [ ] Fichier `google-services.json` téléchargé depuis Firebase Console
- [ ] Placé dans `android/app/google-services.json` ✅
- [ ] Contient :
  - [ ] `project_id: "geoloc-cotonou"`
  - [ ] `package_name: "com.example.localisation"`
  - [ ] `mobilesdk_app_id`
  - [ ] `api_key`

### build.gradle.kts (Project Level)

- [ ] Fichier : `android/build.gradle.kts`
- [ ] Plugin Google Services ajouté dans `dependencies` :
  ```kotlin
  classpath("com.google.gms:google-services:4.4.0")
  ```

### build.gradle.kts (App Level)

- [ ] Fichier : `android/app/build.gradle.kts`
- [ ] Plugin appliqué en haut du fichier :
  ```kotlin
  id("com.google.gms.google-services")
  ```
- [ ] `applicationId` = `"com.example.localisation"`
- [ ] `minSdk` ≥ 21 (Firebase Auth minimum)
- [ ] `compileSdk` = 34 ou supérieur

### AndroidManifest.xml

- [ ] Fichier : `android/app/src/main/AndroidManifest.xml`
- [ ] Permission Internet :
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
- [ ] Intent filter pour deep links (optionnel mais recommandé) :
  ```xml
  <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="https"
            android:host="geoloc-cotonou.firebaseapp.com" />
  </intent-filter>
  ```

### SHA-1 pour Google Sign-In

- [ ] Générer la clé SHA-1 :
  ```powershell
  cd android
  .\gradlew.bat signingReport
  ```
- [ ] Copier la clé SHA1 (Debug et/ou Release)
- [ ] Ajouter dans Firebase Console :
  - [ ] **Project Settings** → **Your apps** → Android
  - [ ] Cliquer sur votre app
  - [ ] **Add fingerprint** dans "SHA certificate fingerprints"
  - [ ] Coller la clé SHA-1
  - [ ] Sauvegarder

---

## 🍎 Configuration iOS (si applicable)

### Fichiers de Configuration

- [ ] Fichier `GoogleService-Info.plist` téléchargé depuis Firebase
- [ ] Placé dans `ios/Runner/GoogleService-Info.plist`
- [ ] Ajouté à Xcode (clic droit → Add Files to "Runner")

### Info.plist

- [ ] Fichier : `ios/Runner/Info.plist`
- [ ] URL Schemes configuré :
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.VOTRE-CLIENT-ID</string>
      </array>
    </dict>
  </array>
  ```
  _(Remplacer par le REVERSED_CLIENT_ID du GoogleService-Info.plist)_

### Podfile

- [ ] Fichier : `ios/Podfile`
- [ ] Platform iOS ≥ 13.0 :
  ```ruby
  platform :ios, '13.0'
  ```

---

## 🌐 Configuration Web (si applicable)

### Fichiers Firebase

- [ ] Fichier `firebase-config.js` créé dans `web/`
- [ ] Configuration Firebase ajoutée :
  ```javascript
  const firebaseConfig = {
    apiKey: "VOTRE_API_KEY",
    authDomain: "geoloc-cotonou.firebaseapp.com",
    projectId: "geoloc-cotonou",
    storageBucket: "geoloc-cotonou.firebasestorage.app",
    messagingSenderId: "191342105680",
    appId: "VOTRE_APP_ID",
  };
  ```

### index.html

- [ ] Fichier : `web/index.html`
- [ ] Scripts Firebase ajoutés avant `</body>` :
  ```html
  <script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-auth-compat.js"></script>
  <script src="firebase-config.js"></script>
  ```

---

## 📦 Dépendances Flutter

### pubspec.yaml

- [ ] Fichier : `pubspec.yaml`
- [ ] Dépendances Firebase :
  ```yaml
  dependencies:
    firebase_core: ^4.2.1
    firebase_auth: ^6.1.2
    google_sign_in: ^6.2.1
    flutter_riverpod: ^3.0.3
  ```
- [ ] Commandes exécutées :
  ```bash
  flutter pub get
  ```

---

## 💻 Code Flutter

### Initialisation Firebase

- [ ] Fichier : `lib/main.dart`
- [ ] Firebase initialisé dans `main()` :
  ```dart
  await Firebase.initializeApp();
  ```
- [ ] AVANT `runApp()`

### Service d'Authentification

- [ ] Fichier : `lib/core/services/auth_service.dart` ✅
- [ ] Méthodes implémentées :
  - [ ] `registerWithEmailAndPassword()` ✅
  - [ ] `signInWithEmailAndPassword()` ✅
  - [ ] `resetPassword()` ✅ (MOT DE PASSE OUBLIÉ)
  - [ ] `signInWithGoogle()` ✅
  - [ ] `signOut()` ✅
  - [ ] `sendEmailVerification()` ✅

### Providers Riverpod

- [ ] Fichier : `lib/core/providers/auth_providers.dart` ✅
- [ ] Providers configurés :
  - [ ] `authServiceProvider` ✅
  - [ ] `authStateProvider` ✅
  - [ ] `currentUserProvider` ✅

### Écrans d'Authentification

- [ ] `lib/features/auth/screens/login_screen.dart` ✅
  - [ ] Champs email et mot de passe
  - [ ] Bouton "Se connecter"
  - [ ] Bouton "Connexion Google"
  - [ ] Lien "Mot de passe oublié?" ✅
  - [ ] Lien "S'inscrire"

- [ ] `lib/features/auth/screens/forgot_password_screen.dart` ✅
  - [ ] Champ email
  - [ ] Validation email
  - [ ] Appel `authService.resetPassword()`
  - [ ] Feedback utilisateur (SnackBar)

- [ ] `lib/features/auth/screens/register_screen.dart`
  - [ ] Champs nom, email, mot de passe
  - [ ] Validation
  - [ ] Appel `authService.registerWithEmailAndPassword()`

### Navigation

- [ ] Navigation de LoginScreen vers ForgotPasswordScreen ✅
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ForgotPasswordScreen(),
    ),
  );
  ```

---

## 🧪 Tests

### Tests Manuels

- [ ] Lancer l'app : `flutter run`
- [ ] **Test 1 : Inscription**
  - [ ] Créer un nouveau compte
  - [ ] Email et mot de passe valides
  - [ ] Vérifier que l'utilisateur est créé dans Firebase Console
- [ ] **Test 2 : Connexion**
  - [ ] Se connecter avec le compte créé
  - [ ] Vérifier la redirection après connexion
- [ ] **Test 3 : Mot de passe oublié** ⭐
  - [ ] Cliquer sur "Mot de passe oublié?"
  - [ ] Entrer l'email du compte
  - [ ] Cliquer sur "Envoyer l'email"
  - [ ] Vérifier la boîte mail (et spams!)
  - [ ] Cliquer sur le lien dans l'email
  - [ ] Définir un nouveau mot de passe
  - [ ] Se reconnecter avec le nouveau mot de passe
- [ ] **Test 4 : Google Sign-In**
  - [ ] Cliquer sur "Continuer avec Google"
  - [ ] Sélectionner un compte Google
  - [ ] Vérifier la connexion réussie
- [ ] **Test 5 : Déconnexion**
  - [ ] Se déconnecter
  - [ ] Vérifier le retour à l'écran de connexion

### Tests Automatisés (Optionnel)

- [ ] Widget de test créé : `firebase_auth_test_widget.dart` ✅
- [ ] Accessible depuis l'app
- [ ] Tests fonctionnels :
  - [ ] Inscription
  - [ ] Connexion
  - [ ] Reset mot de passe
  - [ ] Google Sign-In
  - [ ] Déconnexion

### Script de Diagnostic

- [ ] Script créé : `test_firebase_auth.ps1` ✅
- [ ] Exécuter le script :
  ```powershell
  .\test_firebase_auth.ps1
  ```
- [ ] Vérifier tous les ✅

---

## 🔍 Vérifications Firebase Console

### Utilisateurs

- [ ] **Authentication** → **Users**
- [ ] Voir les utilisateurs créés
- [ ] Colonnes affichées :
  - [ ] Identifier (email)
  - [ ] Providers (password, google.com)
  - [ ] Created
  - [ ] Signed In
  - [ ] User UID

### Activity

- [ ] Voir les tentatives de connexion récentes
- [ ] Vérifier les erreurs éventuelles

---

## 📧 Configuration Email

### Domaine d'Envoi

- [ ] Par défaut : `noreply@geoloc-cotonou.firebaseapp.com`
- [ ] Personnalisé (optionnel) :
  - [ ] Configurer un domaine personnalisé
  - [ ] Vérifier le domaine
  - [ ] Mettre à jour DNS (SPF, DKIM)

### Test d'Email

- [ ] Envoyer un email de test :
  - [ ] Inscription → Email de vérification
  - [ ] Mot de passe oublié → Email de reset
- [ ] Vérifier la réception
- [ ] Vérifier que les liens fonctionnent
- [ ] Tester depuis plusieurs clients email :
  - [ ] Gmail
  - [ ] Outlook
  - [ ] Yahoo (optionnel)

---

## 🛡️ Sécurité

### Règles de Sécurité

- [ ] **Firestore Rules** (si utilisé) :

  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```

- [ ] **Storage Rules** (si utilisé) :
  ```javascript
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /users/{userId}/{allPaths=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```

### Limites de Taux

- [ ] Vérifier les quotas Firebase
- [ ] **Authentication** → **Settings**
- [ ] Limites par défaut :
  - SMS : 10/jour (gratuit)
  - Email : illimité
  - Connexions : illimités

### Protection Contre les Abus

- [ ] Activer **Email Enumeration Protection** :
  - [ ] **Authentication** → **Settings** → **User actions**
  - [ ] Cocher "Enable Email Enumeration Protection"
  - [ ] Empêche de savoir si un email existe

---

## 📊 Monitoring

### Console Firebase

- [ ] Vérifier régulièrement :
  - [ ] Nombre d'utilisateurs actifs
  - [ ] Tentatives de connexion échouées
  - [ ] Emails envoyés

### Analytics (Optionnel)

- [ ] Activer Firebase Analytics
- [ ] Tracker les événements :
  - `login` : Connexion réussie
  - `sign_up` : Inscription
  - `login_fail` : Échec de connexion

---

## 🚀 Déploiement

### Build Release

- [ ] **Android** :
  ```bash
  flutter build apk --release
  # ou
  flutter build appbundle --release
  ```
- [ ] **iOS** :
  ```bash
  flutter build ios --release
  ```

### Clés de Signature

- [ ] Générer une clé de signature Release (Android)
- [ ] Ajouter la clé SHA-1 Release dans Firebase Console
- [ ] Configurer le signing dans `android/app/build.gradle.kts`

### Publication

- [ ] Google Play Store (Android)
- [ ] App Store (iOS)
- [ ] Tester les fonctionnalités d'auth en production

---

## 📚 Documentation

### Documentation Interne

- [ ] Guide complet : `GUIDE_AUTHENTIFICATION_FIREBASE.md` ✅
- [ ] Checklist : `CHECKLIST_FIREBASE_AUTH.md` ✅ (ce fichier)
- [ ] Documentation API : Commentaires dans le code

### Documentation Utilisateur

- [ ] Guide d'utilisation de l'app
- [ ] FAQ sur la connexion
- [ ] Aide pour mot de passe oublié

---

## ✅ Validation Finale

**Tout est prêt quand :**

- [ ] ✅ Tous les points ci-dessus sont cochés
- [ ] ✅ L'app compile sans erreur
- [ ] ✅ Les tests manuels passent
- [ ] ✅ Les emails sont bien reçus
- [ ] ✅ Google Sign-In fonctionne (si configuré)
- [ ] ✅ Le script `test_firebase_auth.ps1` affiche tous ✅

---

## 🆘 Ressources d'Aide

### En cas de problème

1. Consultez `GUIDE_AUTHENTIFICATION_FIREBASE.md` section "Diagnostic"
2. Exécutez `.\test_firebase_auth.ps1` pour un diagnostic
3. Vérifiez les logs : `flutter run --verbose`
4. Utilisez le widget de test : `FirebaseAuthTestWidget`

### Liens Utiles

- **Firebase Doc** : https://firebase.google.com/docs/auth
- **FlutterFire** : https://firebase.flutter.dev
- **Stack Overflow** : https://stackoverflow.com/questions/tagged/firebase-authentication

---

**Date** : 10 février 2026  
**Version** : 1.0  
**Projet** : CotoNav - geoloc-cotonou
