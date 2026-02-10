## 🚨 CONFIGURATION CLÉ API GOOGLE - ÉTAPES IMPORTANTES

### ❌ PROBLÈME ACTUEL

```
REQUEST_DENIED: This IP, site or mobile application is not authorized to use this API key
```

### ✅ SOLUTIONS

#### SOLUTION 1 : Aucune restriction (pour tests rapides)

1. Aller sur https://console.cloud.google.com/
2. APIs & Services → Credentials
3. Cliquer sur votre clé API
4. Application restrictions → **None**
5. Sauvegarder

#### SOLUTION 2 : Restriction Android (recommandée)

1. Application restrictions → **Android apps**
2. Ajouter le package name : `com.example.localisation`
3. Obtenir la signature SHA-1 :
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Ajouter la signature SHA-1 à la console

#### SOLUTION 3 : Restriction IP (temporaire)

1. Application restrictions → **IP addresses**
2. Ajouter votre IP actuelle : `154.66.143.241`

### 🔧 APIs À ACTIVER

Dans API restrictions, activez :

- ✅ Directions API
- ✅ Maps SDK for Android
- ✅ Geocoding API

### ⚡ TEST RAPIDE

Après modification, attendez 2-3 minutes puis testez via :
Menu → Test API Directions

### 📱 SIGNATURE SHA-1 POUR DEBUG

Pour obtenir la signature de votre app de debug :

**Windows :**

```cmd
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Linux/Mac :**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Cherchez la ligne "SHA1:" et copiez la valeur.

### 🎯 PACKAGE NAME À UTILISER

```
com.example.localisation
```

### 📞 SI LE PROBLÈME PERSISTE

1. Vérifiez que l'API Directions est activée
2. Vérifiez les quotas (pas dépassés)
3. Attendez 5-10 minutes après les modifications
4. Redémarrez l'application Flutter

### 🔒 SÉCURITÉ

Pour la production, utilisez toujours les restrictions Android avec SHA-1.
