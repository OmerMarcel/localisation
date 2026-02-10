# 🗺️ Guide d'intégration Google Maps API

## 📋 Étapes pour obtenir votre clé API Google Maps

### 1. 🌐 Accéder à Google Cloud Console

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Connectez-vous avec votre compte Google
3. Créez un nouveau projet ou sélectionnez un projet existant

### 2. 🔧 Activer l'API Google Maps

1. Dans la barre de recherche, tapez "Maps SDK for Android"
2. Cliquez sur "Maps SDK for Android"
3. Cliquez sur "Enable" (Activer)
4. Répétez pour "Maps SDK for iOS" si vous voulez supporter iOS

### 3. 🔑 Créer une clé API

1. Allez dans "APIs & Services" > "Credentials"
2. Cliquez sur "Create Credentials" > "API Key"
3. Copiez votre clé API générée

### 4. 🔒 Configurer les restrictions (Recommandé)

1. Cliquez sur votre clé API pour l'éditer
2. Sous "Application restrictions", sélectionnez "Android apps"
3. Ajoutez votre package name : `com.example.localisation`
4. Ajoutez votre SHA-1 fingerprint (voir section suivante)

### 5. 📱 Obtenir votre SHA-1 Fingerprint

#### Pour le debug (développement) :

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Pour Windows :

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Pour la release (production) :

```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### 6. 🎯 APIs recommandées à activer

Pour une application complète de géolocalisation :

- ✅ **Maps SDK for Android** (obligatoire)
- ✅ **Maps SDK for iOS** (si support iOS)
- ✅ **Geocoding API** (conversion adresse ↔ coordonnées)
- ✅ **Places API** (recherche de lieux)
- ✅ **Directions API** (calcul d'itinéraires)
- ✅ **Distance Matrix API** (calcul de distances)

### 7. 💰 Tarification et quotas

#### Quotas gratuits (par mois) :

- **Maps SDK** : Illimité
- **Geocoding** : 40,000 requêtes
- **Places** : $200 de crédit gratuit
- **Directions** : 40,000 requêtes

#### Configuration des quotas :

1. Allez dans "APIs & Services" > "Quotas"
2. Configurez les limites quotidiennes
3. Activez les alertes de facturation

## 🔧 Configuration dans l'application

### 1. Android (AndroidManifest.xml)

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="VOTRE_CLE_API_ICI"/>
```

### 2. iOS (Info.plist)

```xml
<key>com.google.android.geo.API_KEY</key>
<string>VOTRE_CLE_API_ICI</string>
```

### 3. Clé dans le code Flutter (optionnel)

```dart
const String googleMapsApiKey = "VOTRE_CLE_API_ICI";
```

## 🛡️ Sécurité et bonnes pratiques

### ✅ À faire :

- Restreindre la clé API aux applications autorisées
- Utiliser des clés différentes pour debug et release
- Monitorer l'usage via Google Cloud Console
- Activer la facturation avec des alertes
- Garder les clés confidentielles (pas dans le code source public)

### ❌ À éviter :

- Publier les clés sur GitHub
- Utiliser la même clé pour tous les environnements
- Donner des permissions trop larges
- Oublier de configurer les quotas

## 🔍 Test et validation

### Vérifier que l'API fonctionne :

1. L'application charge la carte correctement
2. Les marqueurs s'affichent
3. Pas d'erreurs dans les logs Android
4. Check de l'usage dans Google Cloud Console

### Logs à surveiller :

```
D/MapsInitializer: loadedRenderer: LATEST
I/Google Android Maps SDK: Google Play services maps renderer version
```

## 📞 Support et documentation

- [Documentation officielle Google Maps](https://developers.google.com/maps/documentation)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Exemples de code](https://github.com/flutter/plugins/tree/main/packages/google_maps_flutter)

---

**🚨 IMPORTANT** : Une fois votre clé API obtenue, remplacez `YOUR_GOOGLE_MAPS_API_KEY` dans le fichier AndroidManifest.xml par votre vraie clé !
