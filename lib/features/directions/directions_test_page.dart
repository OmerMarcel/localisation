import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';

class DirectionsTestPage extends StatefulWidget {
  const DirectionsTestPage({super.key});

  @override
  State<DirectionsTestPage> createState() => _DirectionsTestPageState();
}

class _DirectionsTestPageState extends State<DirectionsTestPage> {
  DirectionsResult? _currentDirections;
  bool _isLoading = false;
  String _statusMessage = 'Prêt à calculer un itinéraire';

  // Coordonnées d'exemple (Cotonou)
  final LatLng _origin = const LatLng(6.3654, 2.4183); // Centre de Cotonou
  final LatLng _destination = const LatLng(6.3700, 2.4200); // Point proche

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Directions API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations de test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points de test:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Origine: ${_origin.latitude}, ${_origin.longitude}'),
                    Text(
                      'Destination: ${_destination.latitude}, ${_destination.longitude}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton de test
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testDirections,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions),
              label: Text(
                _isLoading ? 'Calcul en cours...' : 'Tester l\'API Directions',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Statut
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Statut: $_statusMessage',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 16),

            // Résultats
            if (_currentDirections != null) ...[
              const Text(
                'Résultats:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Distance',
                            _currentDirections!.distance,
                          ),
                          _buildInfoRow('Durée', _currentDirections!.duration),
                          _buildInfoRow(
                            'Départ',
                            _currentDirections!.startAddress,
                          ),
                          _buildInfoRow(
                            'Arrivée',
                            _currentDirections!.endAddress,
                          ),
                          _buildInfoRow(
                            'Points polyline',
                            '${_currentDirections!.polylinePoints.length}',
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'Étapes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          ...(_currentDirections!.steps.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key + 1;
                            final step = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Étape $index',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(step.instruction),
                                    Text(
                                      '${step.distance} • ${step.duration}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _testDirections() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Appel à l\'API en cours...';
      _currentDirections = null;
    });

    try {
      final result = await DirectionsService.getDirections(
        origin: _origin,
        destination: _destination,
        travelMode: 'DRIVING',
      );

      setState(() {
        _isLoading = false;
        if (result != null) {
          _currentDirections = result;
          _statusMessage = 'Itinéraire calculé avec succès !';
        } else {
          _statusMessage = 'Erreur: Impossible de calculer l\'itinéraire';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erreur: $e';
      });
    }
  }
}
