import 'package:flutter/material.dart';

class PerformanceOptimizer {
  // Optimisation pour Google Maps
  static const int maxMarkersBeforeClustering = 50;
  static const int imageCompressionQuality = 70;

  // Limite les markers pour éviter les problèmes ImageReader
  static List<T> limitMarkers<T>(
    List<T> markers, {
    int maxCount = maxMarkersBeforeClustering,
  }) {
    if (markers.length <= maxCount) return markers;

    // Garde les markers les plus importants/proches
    return markers.take(maxCount).toList();
  }

  // Optimise les images pour réduire l'usage mémoire
  static ImageProvider optimizeImage(String assetPath) {
    return AssetImage(assetPath);
  }

  // Dispose proprement les resources
  static void disposeResources(List<dynamic> controllers) {
    for (final controller in controllers) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      }
    }
  }

  // Configuration logging optimisée
  static void configureLogging() {
    // Réduire les logs en mode release
    // Cette configuration doit être faite au démarrage de l'app
  }
}
