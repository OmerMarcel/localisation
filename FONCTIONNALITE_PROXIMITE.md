# Fonctionnalité de Recherche par Proximité

## Vue d'ensemble

La fonctionnalité de recherche par proximité permet aux utilisateurs de trouver toutes les infrastructures situées dans un rayon de 1 kilomètre autour de leur position actuelle.

## Activation de la fonctionnalité

### Via le Drawer

1. Ouvrir le menu drawer (hamburger menu)
2. Cliquer sur **"Proximité"** dans la section "Services populaires"
3. L'application navigue automatiquement vers la carte en mode proximité

### Comportement

- **Navigation automatique** : Bascule vers l'onglet "Carte"
- **Filtrage intelligent** : Affiche uniquement les infrastructures à moins de 1km
- **Indicateur visuel** : Cercle semi-transparent de 1km autour de la position utilisateur

## Fonctionnalités visuelles

### Indicateurs sur la carte

- **Cercle de proximité** : Zone transparente bleue de 1km de rayon
- **Marqueurs spéciaux** : Les infrastructures proches sont marquées en vert
- **Badge "Proximité 1km"** : Indicateur visuel en haut à gauche de la carte

### Interface utilisateur

- **Titre mis à jour** : "Infrastructures à proximité (1km)"
- **Bouton de fermeture** : Icône "X" pour quitter le mode proximité
- **Message informatif** : Alerte si aucune infrastructure n'est trouvée

## Fonctionnalités techniques

### Calcul de distance

- Utilise `Geolocator.distanceBetween()` pour calculer les distances précises
- Filtre en temps réel basé sur la position GPS de l'utilisateur
- Rayon fixe de 1 kilomètre (1000 mètres)

### Gestion des permissions

- Nécessite l'autorisation de géolocalisation
- Gestion gracieuse en cas de permission refusée
- Position par défaut si GPS non disponible

### Optimisations

- **Zoom automatique** : Vue rapprochée (niveau 15) pour une meilleure visibilité
- **Mise à jour dynamique** : Recalcul automatique lors du déplacement
- **Performance** : Filtrage côté client pour une réponse rapide

## États de l'interface

### Mode normal

- Affichage de toutes les infrastructures
- Filtres avancés disponibles
- Zoom standard (niveau par défaut)

### Mode proximité

- Affichage limité aux infrastructures proches
- Filtres avancés masqués
- Zoom rapproché automatique
- Cercle de proximité visible

## Gestion des erreurs

### Position non disponible

- Message d'erreur informatif
- Fallback vers la position par défaut (Cotonou)
- Bouton pour réessayer la géolocalisation

### Aucune infrastructure trouvée

- Message explicatif en bas de l'écran
- Suggestion de se déplacer ou désactiver le mode
- Icône d'information claire

## Intégration avec les autres fonctionnalités

### Favoris

- Les infrastructures favorites restent filtrées selon la proximité
- Possibilité de combiner proximité + favoris

### Détails d'infrastructure

- Affichage normal des détails lors du clic
- Calcul de distance depuis la position actuelle
- Boutons d'itinéraire et partage fonctionnels

### Navigation

- Retour à l'écran normal via le bouton fermer
- Changement d'onglet désactive automatiquement le mode proximité
- Conservation de l'état lors des rotations d'écran

## Code key

### Classe MapScreen

```dart
class MapScreen extends ConsumerStatefulWidget {
  final bool proximityMode;

  const MapScreen({
    super.key,
    this.proximityMode = false,
  });
}
```

### Filtrage par proximité

```dart
List<Infrastructure> _filterInfrastructuresByProximity(
  List<Infrastructure> infrastructures,
  Position userPosition,
) {
  return infrastructures.where((infrastructure) {
    final distance = _calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      infrastructure.latitude,
      infrastructure.longitude,
    );
    return distance <= _proximityRadius;
  }).toList();
}
```

### Navigation depuis le drawer

```dart
void _navigateToMapWithProximity() {
  setState(() {
    _currentIndex = 1; // Index de la carte
    _proximityMode = true; // Activer le mode proximité
  });
}
```

## Améliorations futures possibles

1. **Rayon personnalisable** : Permettre à l'utilisateur de choisir le rayon (500m, 1km, 2km)
2. **Historique des recherches** : Sauvegarder les recherches par proximité
3. **Notifications** : Alerter quand l'utilisateur entre dans une zone d'intérêt
4. **Mode hors ligne** : Cache des infrastructures proches pour utilisation sans connexion
5. **Filtres combinés** : Proximité + catégorie d'infrastructure spécifique
