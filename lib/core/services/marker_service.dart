import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerService {
  // Cache pour les BitmapDescriptors
  final Map<String, BitmapDescriptor> _markerCache = {};

  // Crée ou récupère un BitmapDescriptor depuis le cache
  Future<BitmapDescriptor> getMarkerIcon(String assetPath, Size size) async {
    if (_markerCache.containsKey(assetPath)) {
      return _markerCache[assetPath]!;
    }

    final ImageConfiguration config = ImageConfiguration(size: size);
    final descriptor = await BitmapDescriptor.fromAssetImage(config, assetPath);
    _markerCache[assetPath] = descriptor;

    return descriptor;
  }
}
