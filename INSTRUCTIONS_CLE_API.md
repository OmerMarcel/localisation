# 🔑 INSTRUCTIONS RAPIDES - CLÉ API GOOGLE MAPS

## ⚡ Configuration immédiate

### 1. 📱 Obtenez votre SHA-1 (pour Windows)

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Copiez le SHA1 qui s'affiche !**

### 2. 🌐 Google Cloud Console

1. Allez sur : https://console.cloud.google.com/
2. Créez un projet ou sélectionnez-en un
3. Activez "Maps SDK for Android"
4. Créez une clé API
5. **Restreignez la clé** :
   - Application restrictions : Android apps
   - Package name : `com.example.localisation`
   - SHA-1 : Collez celui obtenu à l'étape 1

### 3. 🔧 Intégrez la clé dans l'app

Remplacez `YOUR_GOOGLE_MAPS_API_KEY` par votre vraie clé dans :

```
android/app/src/main/AndroidManifest.xml
```

**Ligne 20 :**

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyC_VOTRE_VRAIE_CLE_ICI"/>
```

### 4. 🚀 Testez

```bash
flutter run
```

## ✅ Vérification

- La carte s'affiche correctement
- Les marqueurs apparaissent
- Pas d'erreur "For development purposes only"

## 📞 En cas de problème

- Vérifiez que la clé API est bien restreinte
- Assurez-vous que le SHA-1 est correct
- Activez bien "Maps SDK for Android" dans Google Cloud

---

**🎯 Une fois configuré, votre carte sera pleinement fonctionnelle avec toutes les fonctionnalités !**
