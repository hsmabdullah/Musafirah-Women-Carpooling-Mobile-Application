import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMService {
  /// Search for places using OpenStreetMap Nominatim API
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 3) {
      return [];
    }

    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'pk', // Pakistan
      });

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MusafirahApp/1.0',
          'Accept-Language': 'en', // Force English language results
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((place) {
              try {
                final address = place['address'] as Map<String, dynamic>?;

                // Prioritize English names over localized names
                String mainText =
                    place['name:en']?.toString() ??
                    place['name']?.toString() ??
                    place['display_name']?.toString() ??
                    '';
                String secondaryText = '';

                if (address != null) {
                  // Build main text from English address components first, fallback to localized
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

                  // Build secondary text using English components
                  final parts = <String>[];
                  if (address['city:en'] != null) {
                    parts.add(address['city:en'].toString());
                  } else if (address['city'] != null) {
                    parts.add(address['city'].toString());
                  }

                  if (address['state:en'] != null) {
                    parts.add(address['state:en'].toString());
                  } else if (address['state'] != null) {
                    parts.add(address['state'].toString());
                  }

                  // Country is usually already in English
                  if (address['country'] != null) {
                    parts.add(address['country'].toString());
                  }

                  secondaryText = parts.join(', ');
                }

                // Use display_name as fallback (should respect Accept-Language header)
                if (mainText.isEmpty) {
                  mainText = place['display_name']?.toString() ?? '';
                }

                // Safely parse latitude and longitude
                double? lat;
                double? lng;

                if (place['lat'] != null) {
                  final latStr = place['lat'].toString();
                  lat = double.tryParse(latStr);
                }

                if (place['lon'] != null) {
                  final lngStr = place['lon'].toString();
                  lng = double.tryParse(lngStr);
                }

                // Only return valid results with coordinates
                if (lat != null && lng != null) {
                  // Use display_name for description (should respect Accept-Language header)
                  final description =
                      place['display_name']?.toString() ?? mainText;

                  return {
                    'placeId': place['place_id']?.toString() ?? '',
                    'description': description,
                    'mainText': mainText,
                    'secondaryText': secondaryText,
                    'latitude': lat,
                    'longitude': lng,
                  };
                }
                return null;
              } catch (e) {
                debugPrint('Error parsing place: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
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
          'User-Agent': 'MusafirahApp/1.0',
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
