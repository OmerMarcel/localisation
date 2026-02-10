# 🗺️ Guide d'utilisation de la Carte Interactive

## 📱 Fonctionnalités de la Carte

### 🎯 **Navigation et Localisation**

- **Position actuelle** : Le bouton 🎯 en bas à droite vous recentre sur votre position
- **Marqueur bleu** : Indique votre position actuelle
- **Zoom/Dézoom** : Utilisez les gestes pinch ou double-tap

### 🏷️ **Marqueurs d'Infrastructures**

Chaque catégorie a sa propre couleur :

- 🔵 **Bleu** : Toilettes publiques
- 🟠 **Orange** : Aires de jeux
- 🟢 **Vert** : Terrains de sport / Espaces verts
- 🔴 **Rouge** : Centres de santé
- 🟣 **Violet** : Écoles
- 🔶 **Cyan** : Mairies
- 🟡 **Jaune** : Commissariats
- 🌹 **Rose** : Marchés
- 🟪 **Magenta** : Centres culturels

### 🔍 **Système de Filtrage**

#### **Filtrage par Catégorie (Panneau du bas)**

- Sélectionnez une catégorie pour n'afficher que ce type d'infrastructure
- Les chips colorées correspondent aux couleurs des marqueurs
- Cliquez sur "Effacer" pour annuler le filtre

#### **Filtres Avancés (Icône filter_list)**

1. **Type de carte** :

   - Normal : Carte standard
   - Satellite : Vue satellite
   - Hybride : Satellite + noms de routes
   - Terrain : Relief et topographie

2. **Favoris uniquement** : Affiche seulement vos infrastructures favorisées

3. **Rayon de recherche** : Définit la distance maximale autour de votre position (1-50 km)

### 📍 **Détails d'Infrastructure**

Cliquez sur un marqueur pour afficher :

- **Nom** et catégorie
- **Distance** depuis votre position
- **Adresse** complète
- **Description** détaillée
- **Actions** : Itinéraire et Partage
- **Bouton favori** ❤️ pour sauvegarder

### 🛠️ **Actions Disponibles**

#### **Barre d'outils (AppBar)**

- 📍 **Ma position** : Recentrer sur votre localisation
- 🔍 **Filtres** : Ouvrir les options avancées
- 🔄 **Actualiser** : Recharger les données

#### **Boutons Flottants**

- 🔄 **Petit bouton** : Actualiser les infrastructures
- 📍 **Grand bouton** : Recentrer sur votre position

### 📊 **Indicateurs d'État**

#### **Compteur d'infrastructures**

- Badge en haut à droite indiquant le nombre d'infrastructures visibles

#### **Indicateurs de chargement**

- Spinner de chargement avec overlay
- Messages d'erreur avec fallback vers données de test

#### **Messages d'erreur**

- Notification rouge en cas de problème de connexion
- Passage automatique aux données de test locales

## 🚀 **Conseils d'utilisation**

### ✅ **Bonnes pratiques**

1. **Autorisez la géolocalisation** pour une meilleure expérience
2. **Utilisez les filtres** pour trouver rapidement ce que vous cherchez
3. **Ajoutez aux favoris** les lieux que vous utilisez souvent
4. **Changez le type de carte** selon vos besoins (satellite pour voir les bâtiments)

### 🔧 **En cas de problème**

1. **Marqueurs qui n'apparaissent pas** : Cliquez sur actualiser 🔄
2. **Position incorrecte** : Vérifiez que la géolocalisation est activée
3. **Carte vide** : L'app utilise automatiquement des données de test si l'API n'est pas disponible

### 📱 **Performance**

- Les infrastructures sont filtrées côté serveur pour de meilleures performances
- Cache local pour fonctionnement hors ligne
- Marqueurs optimisés pour affichage fluide

## 🎯 **Prochaines fonctionnalités**

- 🚗 Itinéraires Google Maps
- 📤 Partage de localisation
- 🔔 Notifications de proximité
- 🌃 Mode sombre
- 📈 Clustering des marqueurs pour de meilleures performances

---

**Développé pour la ville de Cotonou 🇧🇯**
