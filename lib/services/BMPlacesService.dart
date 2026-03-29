import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/BMPlaceModel.dart';
import '../utils/BMConstants.dart';

class BMPlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static Future<List<BMPlaceModel>> getNearbyPlaces({
    required double lat,
    required double lng,
    int radius = 5000,
    String? type,
  }) async {
    final typeParam = type ?? 'beauty_salon|hair_care|spa';
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?location=$lat,$lng&radius=$radius&type=$typeParam&key=$googlePlacesApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Places API status: ${data['status']}');
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          print('Found ${results.length} places');
          final places =
              results.map((json) => BMPlaceModel.fromJson(json)).toList();
          for (var p in places) {
            print('Place: ${p.name}, photoRef: ${p.photoReference}');
          }
          return places;
        } else {
          print(
              'Places API error: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
    }
    return [];
  }

  static Future<BMPlaceModel?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,rating,user_ratings_total,photos,geometry,opening_hours,website,price_level,types,reviews&language=en&key=$googlePlacesApiKey',
    );

    try {
      print('Fetching place details: $placeId');
      final response = await http.get(url);
      print('Place details response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API status: ${data['status']}');
        if (data['status'] == 'OK') {
          final result = data['result'];
          final photos = result['photos'] as List<dynamic>?;
          final reviews = result['reviews'] as List<dynamic>?;
          final phone = result['formatted_phone_number'];
          print('Name: ${result['name']}');
          print('Phone: $phone');
          print('Photos: ${photos?.length ?? 0}');
          print('Reviews: ${reviews?.length ?? 0}');
          return BMPlaceModel.fromJson(result);
        } else {
          print(
              'Place Details error: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  static Future<List<BMPlaceModel>> searchPlaces({
    required double lat,
    required double lng,
    required String query,
    int radius = 10000,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/textsearch/json?query=$query&location=$lat,$lng&radius=$radius&key=$googlePlacesApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Text Search status: ${data['status']}');
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          print('Text Search: ${results.length} results');
          for (var r in results.take(3)) {
            print(
                '  Result: ${r['name']}, place_id: "${r['place_id']}", photos: ${(r['photos'] as List?)?.length ?? 0}');
          }
          return results.map((json) => BMPlaceModel.fromJson(json)).toList();
        } else {
          print(
              'Text Search error: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }
    return [];
  }

  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$googlePlacesApiKey';
  }
}
