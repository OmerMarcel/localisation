import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/google_maps_config.dart';
import '../models/place_result.dart';

class PlacesService {
  static Future<List<PlaceResult>> searchNearby({
    required LatLng location,
    required double radius,
    required String type,
  }) async {
    try {
      final String url =
          '${GoogleMapsConfig.placesApiUrl}'
          '?location=${location.latitude},${location.longitude}'
          '&radius=$radius'
          '&type=$type'
          '&key=${GoogleMapsConfig.androidApiKey}'
          '&language=${GoogleMapsConfig.language}';

      print('🔗 URL Places API: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Statut HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📋 Statut API: ${data['status']}');

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          return results.map((result) => PlaceResult.fromJson(result)).toList();
        } else {
          print('❌ Erreur API: ${data['status']}');
          throw Exception('Erreur API Places: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erreur PlacesService: $e');
      throw e;
    }
  }
}
