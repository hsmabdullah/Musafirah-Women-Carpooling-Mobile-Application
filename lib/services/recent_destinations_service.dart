import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves the passenger's recently used trips (pickup + destination).
/// Stores up to [maxEntries] entries, most-recent first.
class RecentDestinationsService {
  static const _key = 'musafirah_recent_destinations';
  static const maxEntries = 5;

  /// Save a trip (pickup + destination). Duplicates (by destination address) are removed before inserting.
  static Future<void> save({
    required String address,
    required double lat,
    required double lng,
    String pickupAddress = '',
    double pickupLat = 0.0,
    double pickupLng = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _load(prefs);

    // Remove duplicate
    list.removeWhere((e) => e['address'] == address);

    // Prepend
    list.insert(0, {
      'address': address,
      'lat': lat,
      'lng': lng,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
    });

    // Trim
    if (list.length > maxEntries) list.removeRange(maxEntries, list.length);

    await prefs.setString(_key, jsonEncode(list));
  }

  /// Returns list of recent trips, most-recent first.
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  }

  static List<Map<String, dynamic>> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          jsonDecode(raw).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
