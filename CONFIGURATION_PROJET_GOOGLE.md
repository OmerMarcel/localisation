# 🔧 Configuration du Projet Google Maps

## 📋 Informations du Projet Google Cloud

### Projet Google Cloud

- **Nom du projet** : geoloc-cotonou-466814
- **Numéro de projet** : 365949976825
- **ID de projet** : geoloc-cotonou-466814

### API Google Maps

- **Clé API** : AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI
- **Status** : ✅ Configurée
- **Plateforme** : Android
- **Package autorisé** : com.example.localisation

## 🎯 APIs Activées

- Maps SDK for Android
- Geocoding API (recommandée)
- Places API (optionnelle)

## 🔒 Sécurité

- ✅ Clé API restreinte aux applications Android
- ✅ Package name configuré : com.example.localisation
- ✅ SHA-1 fingerprint obtenu : 41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C
- ⚠️ **ACTION REQUISE** : Configurer le SHA-1 dans Google Cloud Console

## 📱 Configuration de l'Application

### AndroidManifest.xml

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI"/>
```

### Package de l'Application

```
applicationId = "com.example.localisation"
```

## 📝 Notes

- Configuration mise à jour le : 5 août 2025
- Clé API intégrée avec succès
- Projet prêt pour le développement avec Google Maps

## 🚨 Rappels de Sécurité

1. Ne jamais exposer cette clé API dans un dépôt public
2. Vérifier régulièrement l'usage de l'API dans Google Cloud Console
3. Configurer des quotas appropriés pour éviter les surcoûts
