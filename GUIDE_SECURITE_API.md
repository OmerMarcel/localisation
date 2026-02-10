# 🔒 Guide de Configuration des Restrictions de Sécurité Google Maps

## 📋 **Étapes Complètes pour Sécuriser votre Clé API**

### **Étape 1 : Générer le SHA-1 Fingerprint**

#### 🔧 **Méthode 1 : Via Flutter (Recommandée)**

```bash
# Dans votre terminal, à la racine du projet
flutter build apk --debug
```

Puis :

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### 🔧 **Méthode 2 : Via Android Studio**

1. Ouvrez Android Studio
2. Allez dans **Build** > **Generate Signed Bundle / APK**
3. Sélectionnez **APK** > **Next**
4. Créez un nouveau keystore ou utilisez un existant
5. Le SHA-1 sera affiché dans les informations du keystore

#### 🔧 **Méthode 3 : Via Gradle**

```bash
# Dans le dossier android/ de votre projet
./gradlew signingReport
```

### **Étape 2 : Configurer les Restrictions dans Google Cloud Console**

#### 🌐 **Accéder à votre projet Google Cloud**

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet **geoloc-cotonou-466814**
3. Naviguez vers **APIs & Services** > **Credentials**

#### 🔑 **Modifier votre clé API**

1. Trouvez votre clé API : `AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI`
2. Cliquez sur l'icône **✏️ (modifier)** à côté de la clé
3. Descendez jusqu'à **Application restrictions**

#### 📱 **Configurer les restrictions Android**

1. Sélectionnez **Android apps**
2. Cliquez sur **Add an item**
3. Remplissez :
   - **Package name** : `com.example.localisation`
   - **SHA-1 certificate fingerprint** : [Le SHA-1 obtenu à l'étape 1]

#### 💾 **Sauvegarder**

1. Cliquez sur **Save** en bas de la page
2. Attendez quelques minutes pour que les changements prennent effet

### **Étape 3 : Vérification des APIs Activées**

Dans Google Cloud Console, vérifiez que ces APIs sont activées :

- ✅ **Maps SDK for Android**
- ✅ **Geocoding API** (optionnelle mais recommandée)
- ✅ **Places API** (si vous utilisez la recherche de lieux)

### **Étape 4 : Test de la Configuration**

#### 🧪 **Tester votre application**

```bash
# Construire et lancer l'app
flutter run
```

#### 📊 **Vérifier les logs**

Recherchez dans les logs Android Studio :

```
✅ Bon signe : "Google Play services maps renderer version"
❌ Problème : "API key authentication failed"
```

### **Étape 5 : Configuration pour la Production**

#### 🏭 **Pour la version Release**

1. Créez un keystore de production :

```bash
keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

2. Obtenez le SHA-1 de production :

```bash
keytool -list -v -keystore release-key.keystore -alias release
```

3. Ajoutez ce SHA-1 aussi dans Google Cloud Console

## 🚨 **Points Importants**

### ✅ **Bonnes Pratiques**

- Utilisez des clés API différentes pour debug et release
- Ne partagez jamais vos clés API publiquement
- Configurez des quotas pour éviter les surcoûts
- Surveillez l'usage dans Google Cloud Console

### ⚠️ **Erreurs Communes**

- **Package name incorrect** : Vérifiez dans `android/app/build.gradle.kts`
- **SHA-1 manquant** : Assurez-vous d'avoir généré le keystore
- **Délai de propagation** : Les changements peuvent prendre 5-10 minutes

### 🔍 **Dépannage**

Si l'API ne fonctionne pas :

1. Vérifiez le package name dans `build.gradle.kts`
2. Vérifiez que le SHA-1 est correct
3. Attendez 10 minutes après les modifications
4. Réinstallez l'application : `flutter clean && flutter run`

## 📞 **Support**

En cas de problème, vérifiez :

- [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=geoloc-cotonou-466814)
- Les quotas et la facturation
- Les logs d'erreur de l'application
