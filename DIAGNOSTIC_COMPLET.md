## 🚨 DIAGNOSTIC COMPLET - ERREUR API DIRECTIONS

### 🔍 PROBLÈME IDENTIFIÉ :

```
REQUEST_DENIED: This IP, site or mobile application is not authorized to use this API key
```

### ⚡ SOLUTIONS PAR ORDRE DE PRIORITÉ :

---

## 🏃‍♂️ SOLUTION 1 : DÉSACTIVER TOUTES LES RESTRICTIONS (IMMÉDIAT)

1. **Google Cloud Console** → https://console.cloud.google.com/
2. **APIs & Services** → **Credentials**
3. **Cliquer sur votre clé** : `AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI`
4. **Application restrictions** → ☑️ **None**
5. **API restrictions** → ☑️ **Don't restrict key**
6. **💾 Save** et attendre **3-5 minutes**

---

## 🔧 SOLUTION 2 : VÉRIFIER L'ACTIVATION DES APIS

1. **Google Cloud Console** → **APIs & Services** → **Library**
2. Rechercher et ACTIVER :
   - ✅ **Directions API**
   - ✅ **Maps SDK for Android**
   - ✅ **Geocoding API**
3. Pour chaque API : **Enable** si pas déjà fait

---

## 📱 SOLUTION 3 : CONFIGURATION ANDROID CORRECTE

Si Solution 1 marche, remettre les restrictions :

1. **Application restrictions** → **Android apps**
2. **Add an item** :
   - **Package name:** `com.example.localisation`
   - **SHA-1:** `41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C`
3. **API restrictions** → **Restrict key** → Cocher seulement :
   - Directions API
   - Maps SDK for Android
   - Geocoding API

---

## 🔑 SOLUTION 4 : CRÉER UNE NOUVELLE CLÉ API

Si rien ne marche :

1. **Credentials** → **+ CREATE CREDENTIALS** → **API Key**
2. **Restrict Key** → **Android apps** avec vos infos :
   - Package: `com.example.localisation`
   - SHA-1: `41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C`
3. **Remplacer la clé** dans `directions_service.dart`

---

## 🧪 TESTS À EFFECTUER :

### Test 1 : Via l'app

1. Menu → **Test API Directions**
2. Cliquer **Tester**
3. Regarder les logs

### Test 2 : Navigateur web

Coller cette URL dans un navigateur :

```
https://maps.googleapis.com/maps/api/directions/json?origin=6.365,2.418&destination=6.391,2.444&key=AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI
```

**Si ça marche dans le navigateur :** → Problème de restrictions Android
**Si ça ne marche pas :** → Problème d'activation API ou de clé

---

## 📊 QUOTAS À VÉRIFIER :

1. **Google Cloud Console** → **APIs & Services** → **Quotas**
2. Filtrer par **Directions API**
3. Vérifier qu'il reste des requêtes disponibles

---

## 🆘 SI RIEN NE MARCHE :

### Option A : Clé API publique temporaire

```dart
// Dans directions_service.dart, remplacer temporairement par :
static const String _apiKey = 'NOUVELLE_CLE_SANS_RESTRICTIONS';
```

### Option B : Utiliser un proxy/service alternatif

- OpenRouteService
- MapBox Directions
- HERE API

---

## ✅ CONFIRMATION QUE ÇA MARCHE :

Logs attendus :

```
🔗 URL de l'API Directions: https://maps.googleapis.com/...
📡 Statut de la réponse: 200
📋 Statut de l'API: OK
✅ Directions trouvées avec succès!
🗺️ Points de polyline: 42
```

---

## 🎯 PROCHAINES ÉTAPES :

1. **Commencer par Solution 1** (le plus rapide)
2. **Tester immédiatement** avec l'app
3. **Si ça marche**, passer à Solution 3 pour la sécurité
4. **Si ça ne marche pas**, essayer Solution 2 puis 4
