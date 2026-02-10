import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/places_service.dart';
import '../../core/config/google_maps_config.dart';

class GoogleAPIsTestScreen extends StatefulWidget {
  const GoogleAPIsTestScreen({super.key});

  @override
  State<GoogleAPIsTestScreen> createState() => _GoogleAPIsTestScreenState();
}

class _GoogleAPIsTestScreenState extends State<GoogleAPIsTestScreen> {
  String _testResults = 'Cliquez sur "Tester toutes les APIs" pour commencer';
  bool _isLoading = false;

  Future<void> _testAllAPIs() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Tests en cours...\n\n';
    });

    final StringBuffer results = StringBuffer();

    // Test 1: Directions API
    results.write('🗺️ TEST DIRECTIONS API\n');
    results.write('=' * 40 + '\n');
    await _testDirectionsAPI(results);

    results.write('\n\n🏥 TEST PLACES API\n');
    results.write('=' * 40 + '\n');
    await _testPlacesAPI(results);

    results.write('\n\n📊 RÉSUMÉ FINAL\n');
    results.write('=' * 40 + '\n');
    results.write('Configuration terminée !\n');
    results.write('Vérifiez les résultats ci-dessus.\n');

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testDirectionsAPI(StringBuffer results) async {
    try {
      final origin = LatLng(
        GoogleMapsConfig.cotouLatitude,
        GoogleMapsConfig.cotouLongitude,
      );
      final destination = LatLng(6.3915, 2.4439); // Aéroport Cotonou

      results.write('📍 Origine: Centre Cotonou\n');
      results.write('🎯 Destination: Aéroport Cotonou\n\n');

      final result = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (result != null) {
        results.write('✅ SUCCÈS!\n');
        results.write('Distance: ${result.distance}\n');
        results.write('Durée: ${result.duration}\n');
        results.write('Points tracé: ${result.polylinePoints.length}\n');
        results.write('Étapes: ${result.steps.length}\n');
      } else {
        results.write('❌ ÉCHEC: Aucun résultat\n');
      }
    } catch (e) {
      results.write('💥 ERREUR: $e\n');
    }
  }

  Future<void> _testPlacesAPI(StringBuffer results) async {
    try {
      final location = LatLng(
        GoogleMapsConfig.cotouLatitude,
        GoogleMapsConfig.cotouLongitude,
      );

      results.write('📍 Recherche autour de: Centre Cotonou\n');
      results.write('🔍 Type: Hôpitaux\n');
      results.write('📐 Rayon: 5km\n\n');

      final places = await PlacesService.searchNearby(
        location: location,
        radius: 5000,
        type: 'hospital',
      );

      if (places.isNotEmpty) {
        results.write('✅ SUCCÈS!\n');
        results.write('Lieux trouvés: ${places.length}\n\n');

        for (int i = 0; i < places.take(3).length; i++) {
          final place = places[i];
          results.write('${i + 1}. ${place.name}\n');
          results.write('   📍 ${place.vicinity}\n');
          results.write('   ⭐ ${place.rating}/5\n\n');
        }
      } else {
        results.write('❌ ÉCHEC: Aucun lieu trouvé\n');
      }
    } catch (e) {
      results.write('💥 ERREUR: $e\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test APIs Google Maps'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'APIs configurées:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Directions API - Calcul d\'itinéraires'),
                    Text('• Places API - Recherche de lieux'),
                    Text('• Maps SDK - Affichage des cartes'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testAllAPIs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.play_arrow),
                label: Text(
                  _isLoading ? 'Tests en cours...' : 'Tester toutes les APIs',
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Résultats:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
