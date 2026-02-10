# localisation

A new Flutter project.

## Getting Started

# Application de Géolocalisation des Infrastructures de Services Publics - Cotonou

## 📍 Description du Projet

Cette application mobile Flutter a été développée pour faciliter l'accès aux infrastructures de services publics dans la commune de Cotonou, Bénin. Elle permet aux citoyens de localiser rapidement et facilement les services publics à proximité de leur position géographique.

## 🎯 Objectifs

### Objectif Principal

Développer une application mobile intuitive et performante de géolocalisation dédiée aux citoyens béninois, leur permettant de localiser rapidement et facilement les infrastructures de services publics à proximité de leur position géographique.

### Objectifs Spécifiques

- ✅ Recenser les infrastructures de services publics dans la commune de Cotonou
- ✅ Fournir une carte interactive avec un système de recherche avancé
- ✅ Permettre aux utilisateurs de proposer de nouveaux emplacements à ajouter
- ✅ Sensibiliser la population sur l'utilisation des services publics
- ✅ Offrir une expérience fluide et rapide via une application multiplateforme

## 🏗️ Architecture Technique

### Technologies Utilisées

- **Frontend** : Flutter (Dart)
- **Backend** : Node.js avec Express.js (API RESTful)
- **Base de données** : Backend API
- **Storage** : Firebase Storage
- **Authentification** : Firebase Auth
- **Notifications** : Firebase Cloud Messaging (FCM)
- **Cartographie** : Google Maps SDK
- **Géolocalisation** : Geolocator
- **State Management** : Riverpod

### Structure du Projet

```
lib/
├── core/                     # Cœur de l'application
│   ├── constants/            # Constantes de l'app
│   ├── models/              # Modèles de données
│   ├── providers/           # Providers Riverpod
│   ├── services/            # Services (API, Storage, etc.)
│   └── theme/               # Thème et styles
├── features/                # Fonctionnalités principales
│   ├── home/                # Écran d'accueil
│   ├── map/                 # Carte interactive
│   ├── search/              # Recherche
│   ├── profile/             # Profil utilisateur
│   └── contribute/          # Contribution
├── shared/                  # Composants partagés
│   └── widgets/             # Widgets réutilisables
└── main.dart               # Point d'entrée
```

## 🌟 Fonctionnalités

### 🗺️ Géolocalisation et Recherche Interactive

- Carte dynamique avec infrastructures géolocalisées
- Recherche avancée par catégorie, localisation, distance
- Filtrage et tri des résultats
- Affichage des détails complets de chaque infrastructure

### 👥 Contribution et Validation Participative

- Formulaire de proposition de nouveaux lieux
- Système de modération des contributions
- Upload de photos pour illustrer les infrastructures

### 📚 Sensibilisation et Information

- Section éducative avec contenus pédagogiques
- FAQ interactive
- Notifications informatives

### 👤 Profil Utilisateur Personnalisé

- Gestion des favoris
- Historique des consultations
- Statistiques personnelles

### 📱 Expérience Multiplateforme

- Application optimisée iOS et Android
- Fonctionnement hors ligne
- Support multilingue (Français, Yoruba, Fon)

## 📋 Catégories d'Infrastructures

- 🚻 Toilettes publiques
- 🎪 Aires de jeux
- ⚽ Terrains de sport
- 🏥 Centres de santé
- 🏫 Écoles
- 🏛️ Mairies
- 👮 Commissariats
- 🏪 Marchés
- 🌳 Espaces verts
- 🎭 Centres culturels

## 🚀 Installation et Configuration

### Prérequis

- Flutter SDK (≥ 3.8.1)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

```bash
# Cloner le repository
git clone [URL_DU_REPO]
cd localisation

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Configuration

1. **Google Maps API** : Ajouter votre clé API dans `android/app/src/main/AndroidManifest.xml`
2. **Firebase** : Configurer Firebase selon la documentation officielle
3. **Permissions** : Les permissions nécessaires sont déjà configurées dans le manifest

## 🔧 Configuration Firebase

1. Créer un projet Firebase
2. Ajouter les applications Android et iOS
3. Télécharger les fichiers de configuration :
   - `google-services.json` pour Android
   - `GoogleService-Info.plist` pour iOS
4. Activer l'authentification et Cloud Firestore

## 📊 Données de Test

L'application inclut des données de test complètes dans `assets/data/sample_infrastructures.json` avec 10 infrastructures réelles de Cotonou, permettant de tester toutes les fonctionnalités sans serveur backend.

## 🎨 Design et UX

### Palette de Couleurs

- **Primaire** : Vert du drapeau béninois (#00A651)
- **Secondaire** : Jaune du drapeau béninois (#FDD835)
- **Accent** : Rouge du drapeau béninois (#E53935)

### Principes de Design

- Interface intuitive et accessible
- Design moderne avec Material Design 3
- Optimisation pour différentes tailles d'écran
- Support du mode sombre (à venir)

## 🔐 Sécurité

- Authentification sécurisée avec Firebase
- Chiffrement des données sensibles
- Protection contre les injections et vulnérabilités XSS
- Gestion des autorisations selon les rôles

## 📈 Performance

- Optimisation des requêtes spatiales
- Cache intelligent pour l'usage hors ligne
- Compression et optimisation des images
- Gestion efficace de la mémoire

## 🌐 Internationalisation

Support multilingue :

- 🇫🇷 Français (par défaut)
- 🗣️ Yoruba
- 🗣️ Fon

## 🤝 Contribution au Projet

1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Équipe de Développement

- **Développement Mobile** : Flutter/Dart
- **Backend** : Node.js/Express
- **Base de données** : MongoDB
- **UI/UX Design** : Material Design 3

## 📞 Support

Pour toute question ou support :

- Email : support@geolocalisation-cotonou.bj
- Documentation : [Wiki du projet]
- Issues : [GitHub Issues]

## 🎯 Roadmap

### Version 1.1 (À venir)

- [ ] Authentification complète
- [ ] Synchronisation en temps réel
- [ ] Notifications push
- [ ] Mode sombre
- [ ] Support hors ligne complet

### Version 1.2 (Futur)

- [ ] Réalité augmentée
- [ ] Intégration transport public
- [ ] Système de rating avancé
- [ ] Analytics et statistiques

## 🏆 Impact Social

Cette application contribue à :

- Améliorer l'accès aux services publics
- Valoriser les espaces de loisirs
- Renforcer le lien citoyen-administration
- Promouvoir un aménagement inclusif du territoire

---

**Développé avec ❤️ pour la ville de Cotonou et ses citoyens**
