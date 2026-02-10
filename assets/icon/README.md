# Icône de l'application

## Instructions pour remplacer l'icône :

1. **Placez votre logo** (`app_icon.png`) dans ce dossier
2. **Format recommandé** : PNG, 512x512 pixels minimum
3. **Fond transparent** recommandé pour l'icône
4. **Pour le splash screen** : 200x200 pixels maximum

## Fichiers requis :

- `app_icon.png` - Votre logo principal

## Commandes à exécuter après avoir ajouté l'icône :

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## Structure finale :

```
assets/
  icon/
    app_icon.png  <- Votre logo ici
```
