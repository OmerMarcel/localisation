import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Modèle simple pour les lieux à afficher sur la carte
class Place {
  final String name;
  final LatLng latLng;

  Place({required this.name, required this.latLng});
}

class MapScreenOptimized extends StatefulWidget {
  const MapScreenOptimized({super.key});

  @override
  State<MapScreenOptimized> createState() => _MapScreenOptimizedState();
}

class _MapScreenOptimizedState extends State<MapScreenOptimized> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  // Liste de lieux (à remplacer par vos données réelles)
  final List<Place> _items = [
    Place(name: 'Lieu 1', latLng: const LatLng(6.3654, 2.4183)),
    Place(name: 'Lieu 2', latLng: const LatLng(6.3700, 2.4200)),
    Place(name: 'Lieu 3', latLng: const LatLng(6.3600, 2.4100)),
    // Ajoutez des centaines ou milliers de lieux ici
  ];

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() async {
    Set<Marker> markers = {};

    for (int i = 0; i < _items.length; i++) {
      final place = _items[i];
      final marker = Marker(
        markerId: MarkerId('place_$i'),
        position: place.latLng,
        infoWindow: InfoWindow(
          title: place.name,
          snippet:
              'Latitude: ${place.latLng.latitude}, Longitude: ${place.latLng.longitude}',
        ),
        // Utilise l'icône par défaut pour éviter les erreurs
        icon: BitmapDescriptor.defaultMarker,
      );
      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte Optimisée')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.3654, 2.4183), // Cotonou
          zoom: 14.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToFitAllMarkers,
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  // Méthode pour zoomer sur tous les marqueurs
  void _zoomToFitAllMarkers() async {
    if (_markers.isEmpty) return;

    final GoogleMapController controller = await _controller.future;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
}
