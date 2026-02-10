# 💾 Système de Cache Local Automatique des Marqueurs

## 📋 Vue d'ensemble

Le système de cache local automatique permet à l'application de **sauvegarder automatiquement tous les marqueurs** (infrastructures) affichés sur la carte dans la mémoire du téléphone. Les utilisateurs peuvent ainsi **consulter les marqueurs même sans connexion Internet**.

## ✨ Fonctionnalités

### 🔄 Sauvegarde Automatique

- ✅ Tous les marqueurs affichés sur la carte sont **automatiquement sauvegardés** en cache local
- ✅ Pas besoin d'action manuelle de l'utilisateur
- ✅ Sauvegarde transparente lors du chargement depuis le backend
- ✅ Stockage local avec **Hive** (base de données NoSQL rapide)

### 📴 Mode Hors Ligne

- ✅ Détection automatique de la perte de connexion
- ✅ Chargement automatique depuis le cache local
- ✅ Indicateur visuel "Hors ligne" dans l'AppBar
- ✅ Badge indiquant le nombre de marqueurs en cache
- ✅ Affichage des marqueurs et leurs informations complètes

### 📊 Statistiques du Cache

- ✅ Nombre total de marqueurs en cache
- ✅ Nombre de marqueurs valides
- ✅ Répartition par catégorie
- ✅ Détection des marqueurs expirés (> 30 jours)

### 🔄 Synchronisation Intelligente

- ✅ En ligne : charge depuis le backend et met à jour le cache
- ✅ Hors ligne : charge depuis le cache local
- ✅ Reconnexion détectée : synchronisation automatique
- ✅ Conservation des marqueurs pendant 30 jours

## 🏗️ Architecture

### Fichiers créés

1. **`lib/core/models/infrastructure_hive.dart`**
   - Modèle Hive pour stocker les infrastructures
   - Adaptateur manuel (TypeAdapter) pour la sérialisation
   - Conversion Infrastructure ↔ InfrastructureHive

2. **`lib/core/services/infrastructure_cache_service.dart`**
   - Service de gestion du cache Hive
   - Méthodes de sauvegarde/récupération
   - Filtrage par catégorie et rayon
   - Nettoyage du cache expiré

3. **Modifications dans `lib/core/providers/app_providers.dart`**
   - Intégration du `InfrastructureCacheService`
   - Logique de fallback : API → Cache → Données de test
   - Sauvegarde automatique après chargement API

4. **Modifications dans `lib/features/map/map_screen.dart`**
   - Détection de connectivité avec `connectivity_plus`
   - Indicateur visuel du mode hors ligne
   - Bouton d'informations du cache
   - Messages de notification (hors ligne/reconnexion)

5. **Modifications dans `lib/main.dart`**
   - Initialisation de Hive au démarrage
   - Enregistrement de l'adaptateur InfrastructureHive

## 🎯 Flux de Fonctionnement

### Scénario 1 : Avec Connexion Internet

```
1. Utilisateur ouvre la carte
2. API backend envoie les marqueurs
3. ✅ SAUVEGARDE AUTOMATIQUE en cache local
4. Affichage des marqueurs sur la carte
```

### Scénario 2 : Sans Connexion Internet

```
1. Utilisateur ouvre la carte (hors ligne)
2. Détection : pas de connexion
3. ✅ CHARGEMENT depuis le cache local
4. Affichage des marqueurs sauvegardés
5. Badge "Hors ligne" + nombre de marqueurs en cache
```

### Scénario 3 : Reconnexion

```
1. L'appareil se reconnecte au réseau
2. Notification : "Connexion rétablie"
3. ✅ SYNCHRONISATION automatique avec le backend
4. Mise à jour du cache avec les nouvelles données
```

## 🔧 Configuration

### Durée de validité du cache

Par défaut : **30 jours**

Modifiable dans `infrastructure_cache_service.dart` :

```dart
static const int _maxCacheAgeDays = 30;
```

### Nom de la box Hive

```dart
static const String _boxName = 'infrastructures_cache';
```

## 📱 Interface Utilisateur

### Indicateur Hors Ligne

- Badge orange "Hors ligne" dans l'AppBar
- Icône cloud_off

### Bouton Informations Cache

- Icône storage avec badge du nombre de marqueurs
- Accessible uniquement en mode hors ligne
- Affiche les statistiques détaillées

### Dialog Statistiques Cache

Affiche :

- 📊 Total de marqueurs
- ✅ Marqueurs valides
- ⚠️ Marqueurs expirés
- 📂 Répartition par catégorie
- 🧹 Bouton de nettoyage des marqueurs expirés

## 🔍 Méthodes du Service de Cache

### `saveInfrastructures(List<Infrastructure>)`

Sauvegarde une liste d'infrastructures en cache.

### `getAllInfrastructures()`

Récupère toutes les infrastructures valides du cache.

### `getInfrastructuresByCategory(String category)`

Filtre les infrastructures par catégorie.

### `getInfrastructuresInRadius({latitude, longitude, radiusKm})`

Filtre les infrastructures dans un rayon géographique.

### `cleanExpiredCache()`

Supprime les marqueurs expirés (> 30 jours).

### `getCacheStats()`

Retourne les statistiques du cache.

## 🧪 Tests Recommandés

1. **Test de sauvegarde automatique**
   - Ouvrir la carte avec connexion
   - Vérifier les logs : "✅ X marqueurs sauvegardés automatiquement"

2. **Test mode hors ligne**
   - Activer le mode avion
   - Ouvrir la carte
   - Vérifier l'affichage des marqueurs en cache
   - Vérifier le badge "Hors ligne"

3. **Test de reconnexion**
   - Démarrer hors ligne
   - Se reconnecter au réseau
   - Vérifier le message "Connexion rétablie"
   - Vérifier la synchronisation

4. **Test des statistiques**
   - En mode hors ligne, cliquer sur l'icône storage
   - Vérifier l'affichage des statistiques
   - Tester le nettoyage des marqueurs expirés

## 📦 Dépendances Ajoutées

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^7.0.0 # Déjà présent
```

## 🚀 Avantages

✅ **Expérience utilisateur améliorée** : accès aux données sans connexion  
✅ **Performance** : chargement instantané depuis le cache local  
✅ **Économie de données** : moins d'appels API répétés  
✅ **Fiabilité** : l'application fonctionne même sans réseau  
✅ **Automatique** : aucune action requise de l'utilisateur  
✅ **Intelligent** : synchronisation automatique lors de la reconnexion

## 📝 Notes Techniques

- **Hive** a été choisi pour sa rapidité et sa facilité d'utilisation
- L'adaptateur Hive est écrit **manuellement** (pas de code generation) pour éviter les conflits de dépendances
- Le cache est stocké dans le dossier de documents de l'application
- Chaque infrastructure sauvegardée inclut un timestamp `cachedAt`
- Le système respecte le principe de **cache-first** en mode hors ligne

## 🔮 Améliorations Futures Possibles

- [ ] Synchronisation différentielle (ne télécharger que les modifications)
- [ ] Compression du cache pour économiser l'espace
- [ ] Gestion de la taille maximale du cache
- [ ] Export/import du cache
- [ ] Statistiques d'utilisation du cache
- [ ] Notifications de mise à jour disponible

---

**Date de création** : 22 janvier 2026  
**Version** : 1.0.0  
**Auteur** : GitHub Copilot
