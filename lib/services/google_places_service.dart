import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_logger.dart';

class GooglePlacesService {
  final String apiKey;
  static const String _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';

  GooglePlacesService(this.apiKey);

  Future<List<Map<String, dynamic>>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'key': apiKey,
    });
    
    try {
      ApiLogger.request('GET', url.toString());
      final response = await http.get(url);
      ApiLogger.response(
        response.statusCode,
        url.toString(),
        method: 'GET',
        body: response.body,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry',
      'key': apiKey,
    });
    
    try {
      ApiLogger.request('GET', url.toString());
      final response = await http.get(url);
      ApiLogger.response(
        response.statusCode,
        url.toString(),
        method: 'GET',
        body: response.body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result']['geometry']['location'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
