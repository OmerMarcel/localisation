# 🔧 Configuration de la clé API Google Maps

## ❌ Problème actuel

Votre API Directions retourne l'erreur `REQUEST_DENIED` avec le message :

```
"This IP, site or mobile application is not authorized to use this API key. Request received from IP address 154.66.138.245, with empty referer"
```

## ✅ Solution : Configurer les restrictions de votre clé API

### Étape 1 : Accéder à Google Cloud Console

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet
3. Naviguez vers **APIs & Services > Credentials**
4. Cliquez sur votre clé API : `AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI`

### Étape 2 : Configurer les restrictions d'application

**Dans la section "Application restrictions" :**

Choisissez **Android apps** et ajoutez :

```
Package name: com.example.localisation
SHA-1 certificate fingerprint: 41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C
```

### Étape 3 : Configurer les restrictions d'API

**Dans la section "API restrictions" :**

Sélectionnez **Restrict key** et activez ces APIs :

- ✅ **Directions API**
- ✅ **Maps SDK for Android** (si vous utilisez Google Maps)
- ✅ **Geocoding API** (si vous l'utilisez)
- ✅ **Places API** (si vous l'utilisez)

### Étape 4 : Solution temporaire pour les tests

**Pour tester rapidement**, vous pouvez temporairement :

1. Dans "Application restrictions", choisir **None**
2. Tester votre application
3. Remettre les restrictions une fois les tests terminés

⚠️ **ATTENTION** : Ne laissez jamais une clé API sans restrictions en production !

### Étape 5 : Vérifier la facturation

Assurez-vous que :

- ✅ La facturation est activée sur votre projet Google Cloud
- ✅ Vous avez des crédits ou une carte de crédit valide
- ✅ L'API Directions n'a pas atteint ses quotas

## 🧪 Test après configuration

Après avoir configuré les restrictions :

1. Sauvegardez les modifications dans Google Cloud Console
2. Attendez **5-10 minutes** pour la propagation
3. Relancez votre application Flutter
4. Testez l'API Directions

## 📱 Informations de votre application

- **Package name** : `com.example.localisation`
- **SHA-1 Debug** : `41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C`
- **Clé API** : `AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI`

## 🔄 Alternative rapide

Si vous voulez tester immédiatement, créez une nouvelle clé API sans restrictions :

1. Dans Google Cloud Console > Credentials
2. Cliquez **+ CREATE CREDENTIALS > API key**
3. Utilisez cette nouvelle clé temporairement
4. Configurez les restrictions plus tard

## 📞 Support

Si le problème persiste après configuration :

- Vérifiez que l'API Directions est bien activée
- Vérifiez les quotas et la facturation
- Attendez 10-15 minutes après les modifications
