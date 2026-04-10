import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMService {
  /// Search for places using OpenStreetMap Nominatim API.
  /// Throws an exception on network/server errors so callers can show
  /// meaningful feedback. Returns an empty list when the API succeeds but
  /// finds no matches.
  static Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    bool restrictToPakistan = true,
  }) async {
    if (query.isEmpty || query.length < 3) return [];

    final params = {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
    };
    if (restrictToPakistan) {
      params['countrycodes'] = 'pk';
      // Bias results towards Pakistan's bounding box
      params['viewbox'] = '60.87,37.13,77.83,23.63';
      params['bounded'] = '0'; // Bias rather than strict filter (already strictly filtered by countrycodes)
    }

    final url = Uri.https('nominatim.openstreetmap.org', '/search', params);

    final response = await http
        .get(url, headers: {
          'User-Agent': 'Musafirah-Women-Carpooling-App-Pakistan',
          'Accept-Language': 'en',
        })
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Request timed out. Check your connection.'),
        );

    if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      throw Exception('Search failed (HTTP ${response.statusCode}). Try again.');
    }

    final List<dynamic> data = json.decode(response.body);

    // If Pakistan filter returned nothing, retry without country restriction
    if (data.isEmpty && restrictToPakistan) {
      return searchPlaces(query, restrictToPakistan: false);
    }

    final results = <Map<String, dynamic>>[];
    for (final place in data) {
      try {
        final address = place['address'] as Map<String, dynamic>?;

        String mainText =
            place['name:en']?.toString() ??
            place['name']?.toString() ??
            place['display_name']?.toString() ??
            '';

        String secondaryText = '';

        if (address != null) {
          mainText =
              place['name:en']?.toString() ??
              place['name']?.toString() ??
              address['road:en']?.toString() ??
              address['road']?.toString() ??
              address['suburb:en']?.toString() ??
              address['suburb']?.toString() ??
              address['city:en']?.toString() ??
              address['city']?.toString() ??
              mainText;

          final parts = <String>[];
          final city =
              address['city:en']?.toString() ??
              address['city']?.toString() ??
              address['town']?.toString() ??
              address['village']?.toString();
          if (city != null) parts.add(city);

          final state =
              address['state:en']?.toString() ??
              address['state']?.toString();
          if (state != null) parts.add(state);

          if (address['country'] != null) {
            parts.add(address['country'].toString());
          }
          secondaryText = parts.join(', ');
        }

        if (mainText.isEmpty) {
          mainText = place['display_name']?.toString() ?? '';
        }

        final lat = double.tryParse(place['lat']?.toString() ?? '');
        final lng = double.tryParse(place['lon']?.toString() ?? '');

        if (lat != null && lng != null) {
          results.add({
            'placeId': place['place_id']?.toString() ?? '',
            'description': place['display_name']?.toString() ?? mainText,
            'mainText': mainText,
            'secondaryText': secondaryText,
            'latitude': lat,
            'longitude': lng,
          });
        }
      } catch (e) {
        debugPrint('Error parsing place entry: $e');
      }
    }
    return results;
  }

  /// Get place name from coordinates (reverse geocoding)
  static Future<String?> getPlaceName(LatLng location) async {
    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Musafirah-Women-Carpooling-App-Pakistan',
          'Accept-Language': 'en', // Force English language results
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place name: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double getDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371; // Radius in kilometers

    final double lat1Rad = origin.latitude * (math.pi / 180);
    final double lat2Rad = destination.latitude * (math.pi / 180);
    final double deltaLatRad =
        (destination.latitude - origin.latitude) * (math.pi / 180);
    final double deltaLonRad =
        (destination.longitude - origin.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}
