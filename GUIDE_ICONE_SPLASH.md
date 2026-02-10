# 🎨 Guide de personnalisation de l'icône et splash screen

## 📋 Prérequis

1. **Votre logo** au format PNG
2. **Taille recommandée** : 512x512 pixels minimum
3. **Fond transparent** pour l'icône (optionnel pour le splash)

## 📁 Étape 1 : Ajouter votre logo

1. Placez votre logo PNG dans : `assets/icon/app_icon.png`
2. Assurez-vous que le fichier s'appelle exactement `app_icon.png`

## ⚙️ Étape 2 : Configuration automatique

### Option A : Script automatique (Windows)

```bash
cd scripts
generate_icons.bat
```

### Option B : Script automatique (macOS/Linux)

```bash
cd scripts
chmod +x generate_icons.sh
./generate_icons.sh
```

### Option C : Commandes manuelles

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## 🎯 Étape 3 : Tester

```bash
flutter clean
flutter pub get
flutter run
```

## 🔧 Personnalisation avancée

### Changer la couleur de fond du splash screen

Modifiez dans `pubspec.yaml` :

```yaml
flutter_native_splash:
  color: "#your_color_hex" # Ex: "#FF5722" pour orange
```

### Icône différente pour Android et iOS

```yaml
flutter_icons:
  android: true
  ios: true
  image_path_android: "assets/icon/android_icon.png"
  image_path_ios: "assets/icon/ios_icon.png"
```

## 📱 Résultat attendu

- ✅ **Icône d'app** : Votre logo sur l'écran d'accueil
- ✅ **Splash screen** : Votre logo au démarrage
- ✅ **Multi-plateforme** : Android, iOS et Web

## 🚨 Dépannage

### Problème : L'icône ne change pas

```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter run
```

### Problème : Le splash screen ne s'affiche pas

```bash
flutter pub run flutter_native_splash:create
flutter clean
flutter run
```

### Problème : Erreur de chemin d'image

- Vérifiez que `assets/icon/app_icon.png` existe
- Vérifiez la syntaxe dans `pubspec.yaml`

## 📝 Configuration actuelle

### Icône de l'application

- **Plateformes** : Android et iOS activées
- **Chemin de l'image** : `assets/icon/app_icon.png`

### Splash screen

- **Couleur de fond** : Blanc (#ffffff)
- **Image** : `assets/icon/app_icon.png`
- **Plateformes** : Android, iOS et Web activées
