import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';

class DirectionsTestScreen extends StatefulWidget {
  const DirectionsTestScreen({super.key});

  @override
  State<DirectionsTestScreen> createState() => _DirectionsTestScreenState();
}

class _DirectionsTestScreenState extends State<DirectionsTestScreen> {
  String _testResult = 'Cliquez sur "Tester" pour commencer';
  bool _isLoading = false;

  Future<void> _testDirectionsAPI() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Test en cours...';
    });

    try {
      // Test avec des coordonnées de Cotonou
      final origin = LatLng(6.3654, 2.4183); // Centre-ville de Cotonou
      final destination = LatLng(6.3915, 2.4439); // Aéroport de Cotonou

      print('🧪 Test de l\'API Directions...');
      print('📍 Origine: ${origin.latitude}, ${origin.longitude}');
      print(
        '🎯 Destination: ${destination.latitude}, ${destination.longitude}',
      );

      final result = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: 'DRIVING',
      );

      if (result != null) {
        setState(() {
          _testResult =
              '''✅ API FONCTIONNE !

🛣️ Distance: ${result.distance}
⏱️ Durée: ${result.duration}
📍 Départ: ${result.startAddress}
🎯 Arrivée: ${result.endAddress}
🗺️ Points de tracé: ${result.polylinePoints.length}
📋 Étapes: ${result.steps.length}

Premier point: ${result.polylinePoints.isNotEmpty ? result.polylinePoints.first : 'Aucun'}
''';
        });
      } else {
        setState(() {
          _testResult = '''❌ ÉCHEC DE L'API

L'API n'a pas retourné de résultat.
Vérifiez:
- La clé API Google
- La connexion internet
- Les quotas API
''';
        });
      }
    } catch (e) {
      final errorMessage = e.toString();

      // Diagnostic spécifique pour REQUEST_DENIED
      if (errorMessage.contains('REQUEST_DENIED')) {
        setState(() {
          _testResult = '''🚫 ERREUR D'AUTORISATION API

❌ Statut: REQUEST_DENIED

🔧 SOLUTIONS:

1️⃣ RESTRICTIONS D'APPLICATION:
   • Allez sur Google Cloud Console
   • API & Services > Credentials  
   • Modifiez votre clé API
   • Dans "Application restrictions":
     - Sélectionnez "Android apps"
     - Ajoutez le package: com.example.localisation
     - Ajoutez l'empreinte SHA-1 de votre app

2️⃣ RESTRICTIONS D'API:
   • Dans "API restrictions":
     - Sélectionnez "Restrict key"
     - Activez "Directions API"
     - Activez "Maps SDK for Android"

3️⃣ VÉRIFICATIONS:
   • La clé API est bien activée
   • Les quotas ne sont pas dépassés
   • La facturation est activée sur le projet

📱 Package détecté: com.example.localisation
🌐 IP actuelle: Visible dans les logs

⚠️ L'app doit être signée avec le bon certificat
   pour que l'empreinte SHA-1 corresponde.

💡 Pour les tests, vous pouvez temporairement
   supprimer les restrictions d'application.
''';
        });
      } else if (errorMessage.contains('OVER_QUERY_LIMIT')) {
        setState(() {
          _testResult = '''📊 QUOTA DÉPASSÉ

❌ Statut: OVER_QUERY_LIMIT

🔧 SOLUTIONS:
• Vérifiez vos quotas sur Google Cloud Console
• Activez la facturation si nécessaire
• Attendez le renouvellement des quotas
• Optimisez l'utilisation de l'API
''';
        });
      } else if (errorMessage.contains('INVALID_REQUEST')) {
        setState(() {
          _testResult = '''🔧 REQUÊTE INVALIDE

❌ Statut: INVALID_REQUEST

🔧 SOLUTIONS:
• Vérifiez les coordonnées
• Vérifiez les paramètres de la requête
• Assurez-vous que le format est correct
''';
        });
      } else {
        setState(() {
          _testResult =
              '''💥 ERREUR GÉNÉRALE:

${errorMessage}

🔧 VÉRIFICATIONS:
- Connexion internet
- Configuration de l'API
- Permissions de l'application
- Validité de la clé API

📞 Si le problème persiste, consultez:
https://developers.google.com/maps/documentation/directions/troubleshooting
''';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test API Directions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test de l\'API Google Directions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Package détecté: com.example.localisation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Assurez-vous que ce package est autorisé dans votre clé API Google.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Vérifications facturation Google Cloud:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Console > Billing > Vérifiez "Billing enabled"',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• APIs & Services > Quotas > Vérifiez les limites',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• Directions API: 2,500 requêtes gratuites/mois',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ce test vérifie si l\'API Google Directions fonctionne correctement avec votre clé API.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testDirectionsAPI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Test en cours...'),
                        ],
                      )
                    : const Text(
                        'Tester l\'API Directions',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Résultat:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
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
