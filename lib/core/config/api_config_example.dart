// Configuration des API Keys - EXEMPLE
// Copiez ce fichier vers api_config.dart et remplacez par vos vraies clés

class ApiConfig {
  // 1. Obtenez votre clé API sur: https://console.cloud.google.com/
  // 2. Activez l'API Directions dans votre projet Google Cloud
  // 3. Remplacez la valeur ci-dessous par votre vraie clé
  static const String googleMapsApiKey = 'VOTRE_VRAIE_CLE_API_ICI';

  // Configuration pour l'environnement de développement
  static const bool isDebugMode = true;

  // URL de base pour les API Google Maps
  static const String googleMapsBaseUrl =
      'https://maps.googleapis.com/maps/api';

  // Base URL backend (adapter selon l'environnement)
  // Émulateur Android : 10.0.2.2
  // Appareil physique : IP locale de votre machine
  static const String backendBaseUrl = 'https://backend-cotonav.onrender.com/api';

  // Exemple d’endpoint
  static String propositionsEndpoint = '$backendBaseUrl/propositions';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
}

/* 
ÉTAPES POUR CONFIGURER :
1. Copiez ce fichier vers api_config.dart
2. Remplacez 'VOTRE_VRAIE_CLE_API_ICI' par votre clé Google Maps
3. Assurez-vous que l'API Directions est activée sur votre projet Google Cloud
4. Vérifiez les restrictions de votre clé API si nécessaire
*/
