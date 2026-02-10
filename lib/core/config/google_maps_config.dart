class GoogleMapsConfig {
  // Clés API - À remplacer par vos vraies clés
  static const String androidApiKey = 'AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI';
  static const String webApiKey = 'AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI';
  
  // Configuration Cotonou
  static const double cotouLatitude = 6.3654;
  static const double cotouLongitude = 2.4183;
  static const double searchRadius = 25000; // 25km
  
  // Types de lieux pour Cotonou
  static const Map<String, String> placeTypes = {
    'hospital': 'Hôpitaux',
    'school': 'Écoles',
    'police': 'Postes de police',
    'fire_station': 'Pompiers',
    'bank': 'Banques',
    'atm': 'Distributeurs',
    'pharmacy': 'Pharmacies',
    'gas_station': 'Stations essence',
    'restaurant': 'Restaurants',
    'supermarket': 'Supermarchés',
  };
  
  // Configuration des trajets
  static const String defaultTravelMode = 'DRIVING';
  static const String language = 'fr';
  static const String region = 'BJ'; // Bénin
  
  // URLs des APIs
  static const String directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String placesApiUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String geocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}

