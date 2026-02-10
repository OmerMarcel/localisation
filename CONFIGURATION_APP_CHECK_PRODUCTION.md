# 🔐 Configuration Firebase App Check - Production

## 📊 Vue d'ensemble

Firebase App Check protège vos ressources backend (Cloud Storage, Realtime Database, Cloud Functions, etc.) contre les abus en vérifiant que les requêtes proviennent bien de votre application authentique.

Votre configuration dans `main.dart` est maintenant **optimisée** :

- ✅ **Debug** : Utilise les providers de debug
- ✅ **Production** : Utilise Play Integrity (Android) et Device Check (iOS)

---

## 🤖 Configuration Android - Play Integrity API

### 1. Activer Play Integrity API

1. **Google Cloud Console** : https://console.cloud.google.com
2. **Sélectionnez votre projet** : `geoloc-cotonou`
3. **APIs & Services** → **Library**
4. **Recherchez** : "Play Integrity API"
5. **Cliquez** : Play Integrity API
6. **Cliquez** : **Enable**

### 2. Configurer dans Firebase Console

1. **Firebase Console** : https://console.firebase.google.com
2. **Projet** : `geoloc-cotonou`
3. **Project Settings** ⚙️ → **App Check**
4. **Sélectionnez votre app Android**
5. **Cliquez** : **Play Integrity**
6. **Enregistrez**

### 3. Vérifier le Package Name

Assurez-vous que le package name correspond :

- **Firebase** : `com.example.localisation`
- **Android** : `android/app/build.gradle.kts` → `applicationId`

```kotlin
defaultConfig {
    applicationId = "com.example.localisation"
    // ...
}
```

### 4. Ajouter la Dépendance (déjà fait ✅)

Votre `pubspec.yaml` a déjà :

```yaml
firebase_app_check: 0.4.1+2
```

### 5. SHA-256 Fingerprints

Pour la production, ajoutez le SHA-256 de votre clé de signature :

```powershell
# Génération de la clé de signature (si pas encore fait)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Obtenir le SHA-256
keytool -list -v -keystore ~/upload-keystore.jks -alias upload | Select-String "SHA256"
```

Ajoutez le SHA-256 dans :

- **Firebase Console** → **Project Settings** → **Your app** → **Add fingerprint**

---

## 🍎 Configuration iOS - Device Check

### 1. Activer Device Check

1. **Apple Developer** : https://developer.apple.com
2. **Certificates, Identifiers & Profiles**
3. **Identifiers** → Sélectionnez votre App ID
4. **Capabilities** → Cochez **Device Check**
5. **Save**

### 2. Configurer dans Firebase Console

1. **Firebase Console** : https://console.firebase.google.com
2. **Projet** : `geoloc-cotonou`
3. **Project Settings** ⚙️ → **App Check**
4. **Sélectionnez votre app iOS**
5. **Cliquez** : **DeviceCheck**
6. **Ajoutez votre Team ID** (trouvé dans Apple Developer)
7. **Enregistrez**

### 3. Vérifier le Bundle ID

Assurez-vous que le Bundle ID correspond :

- **Firebase** : Votre Bundle ID iOS
- **Xcode** : `ios/Runner.xcodeproj` → **General** → **Bundle Identifier**

### 4. Mettre à jour Info.plist

Le fichier `ios/Runner/Info.plist` doit inclure :

```xml
<key>AppIdentifierPrefix</key>
<string>$(AppIdentifierPrefix)</string>
```

---

## 🧪 Test en Debug

Votre configuration actuelle fonctionne déjà en mode debug ! 🎉

```powershell
# Lancer en mode debug
flutter run --debug

# Vérifier les logs
# Vous devriez voir : "🔥 AppCheck initialisé — Debug mode"
```

Les logs afficheront :

```
🔥 AppCheck debug token: eyJhbGc...
🔥 AppCheck initialisé — Debug mode
```

---

## 🚀 Test en Production

### Android

```powershell
# Build APK release
flutter build apk --release

# ou Build App Bundle
flutter build appbundle --release

# Installer et tester
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```powershell
# Build iOS release
flutter build ios --release

# Tester via Xcode ou TestFlight
```

Les logs afficheront :

```
🔥 AppCheck initialisé — Production mode
```

---

## 🔍 Diagnostic des Problèmes

### Problème 1 : "App Check token not found"

**Cause** : Play Integrity API pas activée ou mal configurée

**Solutions** :

1. Vérifiez que Play Integrity API est activée dans Google Cloud Console
2. Vérifiez le package name dans Firebase et Android
3. Attendez quelques minutes après l'activation
4. Désinstallez et réinstallez l'app

### Problème 2 : "INVALID_CREDENTIAL"

**Cause** : SHA-256 manquant ou incorrect

**Solutions** :

1. Générez et ajoutez le SHA-256 de votre clé de signature release
2. Vérifiez que la clé correspond à celle utilisée pour signer l'APK
3. Attendez quelques minutes après l'ajout

### Problème 3 : iOS - "Device Check unavailable"

**Cause** : Device Check pas activé ou iOS < 11

**Solutions** :

1. Vérifiez que Device Check est activé dans Apple Developer
2. Vérifiez que le Team ID est correct dans Firebase
3. Device Check nécessite iOS 11+ et un appareil physique (pas simulateur)
4. Testez sur un appareil réel

### Problème 4 : "App Check verification failed"

**Cause** : Backend Firebase n'est pas configuré pour utiliser App Check

**Solutions** :

1. **Cloud Storage** : Ajoutez les règles App Check
2. **Firestore** : Activez l'enforcement dans Firebase Console
3. **Cloud Functions** : Utilisez le middleware App Check

---

## 🛡️ Enforcement dans Firebase

Une fois App Check configuré, activez l'enforcement pour protéger vos ressources.

### Cloud Firestore

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null && request.app != null;
    }
  }
}
```

### Cloud Storage

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null && request.app != null;
    }
  }
}
```

### Activer l'Enforcement

1. **Firebase Console** → **App Check**
2. **Sélectionnez chaque service** (Firestore, Storage, etc.)
3. **Cliquez** : **Enforce**
4. **Confirmez**

⚠️ **Attention** : Activez l'enforcement seulement après avoir configuré App Check sur toutes les plateformes !

---

## 📊 Monitoring

### Firebase Console

1. **App Check** → **Metrics**
2. Visualisez :
   - Requêtes vérifiées
   - Requêtes rejetées
   - Taux de succès

### Logs dans l'App

En mode debug, vous verrez :

```dart
if (kDebugMode) {
  final token = await FirebaseAppCheck.instance.getToken(true);
  debugPrint('🔥 AppCheck debug token: $token');
}
```

---

## 🔄 Migration Debug → Production

### Checklist

- [ ] Play Integrity API activée (Android)
- [ ] Device Check activé (iOS)
- [ ] SHA-256 de la clé release ajouté (Android)
- [ ] Team ID ajouté (iOS)
- [ ] App Check configuré dans Firebase Console
- [ ] Build en mode release testé
- [ ] Enforcement activé pour chaque service
- [ ] Monitoring vérifié

### Commandes

```powershell
# Android - Vérifier la signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk | Select-String "SHA256"

# iOS - Vérifier le provisioning
security find-identity -v -p codesigning
```

---

## 💡 Bonnes Pratiques

### 1. Utiliser des Builds Séparés

```powershell
# Debug (avec debug provider)
flutter run --debug

# Release (avec Play Integrity / Device Check)
flutter build apk --release
```

### 2. Rotation des Secrets

- Régénérez périodiquement les clés de signature
- Mettez à jour les SHA-256 dans Firebase Console
- Surveillez les métriques pour détecter les anomalies

### 3. Fallback Gracieux

Même si App Check échoue, votre app devrait continuer à fonctionner (avec des restrictions côté backend).

### 4. Logs en Production

Gardez les logs d'App Check en production pour le diagnostic :

```dart
try {
  final token = await FirebaseAppCheck.instance.getToken(true);
  debugPrint('🔥 AppCheck token généré');
} catch (e) {
  debugPrint('⚠️ AppCheck error: $e');
  // Continuer sans bloquer l'app
}
```

---

## 🧪 Script de Test

Créez `test_app_check.ps1` :

```powershell
Write-Host "🔐 Test Firebase App Check" -ForegroundColor Cyan

# 1. Vérifier Play Integrity API
Write-Host "`n1️⃣  Vérification Play Integrity API..." -ForegroundColor Yellow
Write-Host "   Allez sur: https://console.cloud.google.com" -ForegroundColor White
Write-Host "   APIs & Services → Library → Play Integrity API → Verify ENABLED" -ForegroundColor Cyan

# 2. Vérifier Firebase App Check
Write-Host "`n2️⃣  Vérification Firebase App Check..." -ForegroundColor Yellow
Write-Host "   Allez sur: https://console.firebase.google.com" -ForegroundColor White
Write-Host "   Project Settings → App Check → Verify CONFIGURED" -ForegroundColor Cyan

# 3. Build et test
Write-Host "`n3️⃣  Build release..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Build réussi" -ForegroundColor Green
} else {
    Write-Host "   ❌ Build échoué" -ForegroundColor Red
}

Write-Host "`n✅ Configuration App Check mise à jour!" -ForegroundColor Green
Write-Host "   Mode Debug : AndroidProvider.debug" -ForegroundColor Cyan
Write-Host "   Mode Release: AndroidProvider.playIntegrity" -ForegroundColor Cyan
```

---

## 📚 Ressources

### Documentation Officielle

- **Firebase App Check** : https://firebase.google.com/docs/app-check
- **Play Integrity API** : https://developer.android.com/google/play/integrity
- **Device Check** : https://developer.apple.com/documentation/devicecheck

### FlutterFire

- **firebase_app_check** : https://firebase.flutter.dev/docs/app-check/overview

### Guides

- **App Check Setup** : https://firebase.google.com/docs/app-check/android/play-integrity-provider
- **iOS Setup** : https://firebase.google.com/docs/app-check/ios/devicecheck-provider

---

## ✅ Récapitulatif

### Ce Qui a Changé

```dart
// AVANT (toujours en debug)
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);

// MAINTENANT (adapté au mode)
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode
      ? AppleProvider.debug
      : AppleProvider.deviceCheck,
);
```

### Avantages

✅ **Sécurité renforcée** en production  
✅ **Développement simplifié** en debug  
✅ **Configuration automatique** selon le mode  
✅ **Meilleure protection** contre les abus

### Prochaines Étapes

1. **Debug** : Testez maintenant (`flutter run --debug`)
2. **Production** : Configurez Play Integrity et Device Check
3. **Release** : Testez en mode release
4. **Enforcement** : Activez l'enforcement dans Firebase Console

---

**Date** : 10 février 2026  
**Version** : 2.0  
**Projet** : CotoNav - geoloc-cotonou
