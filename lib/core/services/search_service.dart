import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class SearchService {
  /// Rechercher des lieux par nom/adresse
  static Future<List<SearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final String url =
          '${ApiConfig.googleMapsBaseUrl}/geocode/json'
          '?address=${Uri.encodeComponent(query)}'
          '&region=bj' // Bénin
          '&components=country:BJ' // Limiter au Bénin
          '&key=${ApiConfig.googleMapsApiKey}'
          '&language=fr';

      if (ApiConfig.isDebugMode) {
        print('🔍 Recherche: $query');
        print(
          '🔗 URL: ${url.replaceAll(ApiConfig.googleMapsApiKey, 'HIDDEN_KEY')}',
        );
      }

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(ApiConfig.shortTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'] != null) {
          final List<SearchResult> results = [];

          for (var result in data['results']) {
            try {
              results.add(SearchResult.fromJson(result));
            } catch (e) {
              print('⚠️ Erreur parsing résultat: $e');
            }
          }

          if (ApiConfig.isDebugMode) {
            print('✅ ${results.length} résultats trouvés');
          }

          return results;
        } else {
          print('❌ Erreur API Geocoding: ${data['status']}');
          return [];
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 Erreur recherche: $e');
      return [];
    }
  }

  /// Rechercher des suggestions en temps réel
  static Future<List<String>> getSuggestions(String query) async {
    if (query.trim().length < 3) return [];

    // Suggestions locales pour Cotonou et environs
    final List<String> localSuggestions = [
      'Cotonou',
      'Porto-Novo',
      'Calavi',
      'Abomey-Calavi',
      'Godomey',
      'Fidjrossè',
      'Dantokpa',
      'Ganhi',
      'Aidjedo',
      'Cadjehoun',
      'Akpakpa',
      'Vêdoko',
      'Sainte-Rita',
      'Agblangandan',
      'Jéricho',
      'Haie Vive',
      'Missebo',
      'Sèmè-Kpodji',
      'Ouidah',
      'Allada',
    ];

    final lowerQuery = query.toLowerCase();
    return localSuggestions
        .where((suggestion) => suggestion.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  }
}

class SearchResult {
  final String formattedAddress;
  final LatLng location;
  final String placeId;
  final List<String> addressComponents;

  SearchResult({
    required this.formattedAddress,
    required this.location,
    required this.placeId,
    required this.addressComponents,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry['location'];

    final List<String> components = [];
    if (json['address_components'] != null) {
      for (var component in json['address_components']) {
        components.add(component['long_name'] ?? '');
      }
    }

    return SearchResult(
      formattedAddress: json['formatted_address'] ?? 'Adresse inconnue',
      location: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
      placeId: json['place_id'] ?? '',
      addressComponents: components,
    );
  }
}
