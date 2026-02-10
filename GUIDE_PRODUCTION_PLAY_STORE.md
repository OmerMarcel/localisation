# 🚀 Guide Complet - Configuration Production Play Store

## 📊 Situation Actuelle

**App Check est temporairement désactivé** pour permettre le développement et les tests.

### ⚠️ Pourquoi ?

**Play Integrity API** nécessite que l'app soit :

1. Signée avec une clé de production
2. Publiée sur Google Play Store (au moins en Internal Testing)
3. Vérifiée par Google Play

Sans cela, vous obtenez : `Error 403: App attestation failed`

---

## 🎯 Plan de Déploiement en 3 Phases

### 📱 Phase 1 : Développement (MAINTENANT)

**Status** : App Check désactivé ✅

**Avantages** :

- ✅ Authentification fonctionne
- ✅ Toutes les fonctionnalités disponibles
- ✅ Tests possibles

**Inconvénients** :

- ⚠️ Pas de protection App Check (OK pour les tests)

**Action** : Aucune, continuez le développement

---

### 🔨 Phase 2 : Préparation Production

#### A. Créer une Clé de Signature

```powershell
# Créer le répertoire pour la clé
mkdir $env:USERPROFILE\upload-keystore -Force

# Générer la clé de signature
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore\localisation-upload-key.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload

# Suivez les instructions et NOTEZ LE MOT DE PASSE !
```

**Informations demandées** :

- Mot de passe du keystore : (notez-le !)
- Mot de passe de la clé : (notez-le !)
- Prénom et nom : Votre nom
- Nom de l'organisation : CotoNav
- Ville : Cotonou
- État : Littoral
- Code pays : BJ

#### B. Configurer le Signing dans Android

Créez `android/key.properties` :

```properties
storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=upload
storeFile=C:/Users/HP/upload-keystore/localisation-upload-key.jks
```

⚠️ **Important** : Ajoutez `key.properties` au `.gitignore` !

#### C. Modifier `android/app/build.gradle.kts`

Ajoutez avant `android {` :

```kotlin
// Lecture des propriétés de signature
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuration existante ...

    // Ajoutez la configuration de signature
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Configuration existante...
        }
    }
}
```

#### D. Obtenir les SHA Fingerprints

```powershell
# SHA-1 (pour Google Sign-In)
keytool -list -v -keystore $env:USERPROFILE\upload-keystore\localisation-upload-key.jks -alias upload | Select-String "SHA1"

# SHA-256 (pour Play Integrity)
keytool -list -v -keystore $env:USERPROFILE\upload-keystore\localisation-upload-key.jks -alias upload | Select-String "SHA256"
```

**Copiez ces valeurs** et ajoutez-les dans :

- **Firebase Console** → **Project Settings** → **Your apps** → **Android** → **Add fingerprint**

#### E. Build de Production

```powershell
# Build App Bundle (recommandé pour Play Store)
flutter build appbundle --release

# Le fichier sera dans : build/app/outputs/bundle/release/app-release.aab
```

#### F. Tester le Build Release Localement

```powershell
# Build APK pour tester
flutter build apk --release

# Installer sur appareil
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### 🏪 Phase 3 : Publication Play Store

#### A. Créer un Compte Google Play Console

1. **Allez sur** : https://play.google.com/console
2. **Créez un compte développeur** (25$ unique)
3. **Créez une nouvelle application**

#### B. Remplir les Informations de l'App

**Contenu de l'App** :

- Nom : CotoNav
- Description courte : App de géolocalisation à Cotonou
- Description complète : (votre description détaillée)
- Catégorie : Cartes et navigation
- Email : votre-email@gmail.com

**Assets graphiques** :

- Icône : 512x512 px
- Feature Graphic : 1024x500 px
- Screenshots : Minimum 2 (phone)

#### C. Internal Testing (Recommandé en premier)

1. **Testing** → **Internal testing**
2. **Create new release**
3. **Upload** : `app-release.aab`
4. **Ajoutez des testeurs** (votre email)
5. **Review and roll out**

#### D. Activer Play Integrity API

1. **Google Cloud Console** : https://console.cloud.google.com
2. **Sélectionnez** : Projet Firebase (`geoloc-cotonou`)
3. **APIs & Services** → **Library**
4. **Recherchez** : "Play Integrity API"
5. **Enable**

#### E. Configurer App Check dans Firebase

1. **Firebase Console** → **App Check**
2. **Register app** → Sélectionnez votre app Android
3. **Play Integrity** → **Register**
4. **Save**

#### F. Réactiver App Check dans le Code

Dans [lib/main.dart](lib/main.dart), décommentez :

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode
      ? AppleProvider.debug
      : AppleProvider.deviceCheck,
);
```

#### G. Rebuild et Republier

```powershell
# Rebuild avec App Check activé
flutter build appbundle --release

# Upload la nouvelle version sur Play Console
```

---

## 📋 Checklist Complète Production

### Préparation

- [ ] Clé de signature créée
- [ ] `key.properties` configuré
- [ ] SHA-1 et SHA-256 ajoutés dans Firebase
- [ ] `build.gradle.kts` configuré pour signing
- [ ] `.gitignore` mis à jour (clés exclues)

### Build

- [ ] `flutter build appbundle --release` réussi
- [ ] Taille de l'app < 150 MB
- [ ] Testé sur appareil physique

### Play Store

- [ ] Compte développeur créé (25$)
- [ ] Application créée dans Play Console
- [ ] Informations remplies
- [ ] Assets graphiques ajoutés
- [ ] Internal testing configuré
- [ ] AAB uploadé

### Firebase & App Check

- [ ] Play Integrity API activée
- [ ] App Check configuré dans Firebase
- [ ] Code App Check réactivé
- [ ] Nouvelle version publiée

### Tests Production

- [ ] Installation depuis Play Store (Internal Testing)
- [ ] Authentification fonctionne
- [ ] App Check tokens générés
- [ ] Pas d'erreur 403

---

## 🔧 Configuration Avancée

### Activer ProGuard (Obfuscation)

Dans `android/app/build.gradle.kts` :

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

Créez `android/app/proguard-rules.pro` :

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
```

### Versioning Automatique

Dans `pubspec.yaml` :

```yaml
version: 1.0.0+1
# Format: versionName+versionCode
# Incrémentez versionCode à chaque publication
```

### Firebase App Distribution (Beta Testing)

```powershell
# Installer Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Distribuer l'APK aux testeurs
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk `
  --app YOUR_FIREBASE_APP_ID `
  --groups "testers" `
  --release-notes "Version beta 1.0"
```

---

## 🆘 Résolution de Problèmes

### "App not verified by Play Protect"

**Normal** pour Internal Testing. Pour résoudre :

1. Passez en **Open Testing** ou **Production**
2. Attendez la vérification Google (quelques jours)

### "Play Integrity API failure"

**Causes** :

- App pas encore publiée → Publiez en Internal Testing
- SHA corrects pas ajoutés → Vérifiez les fingerprints
- Cache Google → Attendez 24h après configuration

**Solution temporaire** :

```dart
// Gardez en debug mode temporairement
androidProvider: AndroidProvider.debug
```

### "Signed APK installs but crashes"

**Causes** :

- ProGuard trop agressif → Ajustez les règles
- Missing native libraries → Vérifiez `build.gradle.kts`

**Debug** :

```powershell
# Voir les logs de crash
adb logcat | Select-String "AndroidRuntime"
```

### "App size too large"

**Solutions** :

1. **Activer split APKs** :

```kotlin
android {
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}
```

2. **Compiler pour architectures spécifiques** :

```powershell
flutter build appbundle --target-platform android-arm64
```

---

## 📱 Checklist de Lancement

### Semaine Avant Lancement

- [ ] Tests utilisateurs (Internal Testing)
- [ ] Correction des bugs critiques
- [ ] Performance optimisée
- [ ] Vérification de tous les assets
- [ ] Politique de confidentialité rédigée
- [ ] Conditions d'utilisation rédigées

### Jour du Lancement

- [ ] Version finale buildée
- [ ] App Check activé et testé
- [ ] Monitoring Firebase activé
- [ ] Analytics configuré
- [ ] Crashlytics activé
- [ ] Publication en Production

### Après Lancement

- [ ] Surveiller les crashes (Firebase Crashlytics)
- [ ] Répondre aux avis utilisateurs
- [ ] Corriger les bugs urgents
- [ ] Préparer les mises à jour

---

## 📊 Monitoring Production

### Firebase Crashlytics

Ajoutez dans `pubspec.yaml` :

```yaml
firebase_crashlytics: ^4.0.0
```

Dans `main.dart` :

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

### Firebase Analytics

Suivez :

- Installations
- Sessions actives
- Rétention utilisateurs
- Événements personnalisés

### Play Console Metrics

Surveillez :

- Crashes et ANRs
- Performances
- Avis et notes
- Statistiques d'installation

---

## 💰 Coûts Estimés

| Service                          | Coût                              | Fréquence   |
| -------------------------------- | --------------------------------- | ----------- |
| **Compte Google Play Developer** | 25$                               | Une fois    |
| **Firebase** (Spark - gratuit)   | 0$                                | -           |
| **Firebase** (Blaze - au besoin) | ~5-50$/mois                       | Selon usage |
| **Google Maps API**              | Gratuit jusqu'à 28K requêtes/mois | -           |
| **App Check**                    | Inclus Firebase                   | -           |

**Budget mensuel estimé** : 0-50$ selon l'utilisation

---

## 🎯 Résumé pour Démarrer MAINTENANT

### Action Immédiate (5 min)

```powershell
# 1. Hot Restart (l'app devrait fonctionner maintenant)
# Tapez 'R' dans le terminal flutter run
```

### Pour Publier sur Play Store (2-3 jours)

1. **Créer clé de signature** (10 min)
2. **Configurer signing** (10 min)
3. **Build release** (5 min)
4. **Créer compte Play Console** (30 min + 25$)
5. **Remplir informations** (1-2h)
6. **Internal Testing** (1 jour - approbation Google)
7. **Activer App Check** (10 min)
8. **Republier avec App Check** (30 min)

---

## 📚 Ressources

- **Play Console** : https://play.google.com/console
- **Flutter Release** : https://docs.flutter.dev/deployment/android
- **Firebase App Check** : https://firebase.google.com/docs/app-check
- **Play Integrity** : https://developer.android.com/google/play/integrity

---

**Date** : 10 février 2026  
**Version** : 1.0  
**Status** :

- Phase 1 ✅ (App Check désactivé - auth fonctionne)
- Phase 2 : En attente de votre action
- Phase 3 : En attente de publication Play Store
