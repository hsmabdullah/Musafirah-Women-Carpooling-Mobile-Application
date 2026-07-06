import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Musafirah – GeoService
//
// Pure-Dart geohash implementation (no extra package needed).
// Precision 4  → cell ≈ 39 km × 20 km   → use for 10-km radius search
// Precision 5  → cell ≈  4.9 km × 4.9 km → use for 2-km radius search
//
// Usage:
//   final hash    = GeoService.encode(lat, lng, precision: 4);
//   final hashes  = GeoService.searchHashes(lat, lng, radiusKm: 10);
//   final distKm  = GeoService.distanceKm(lat1, lng1, lat2, lng2);
// ─────────────────────────────────────────────────────────────────────────────

class GeoService {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  // ── Encode ──────────────────────────────────────────────────────────────────

  /// Encodes [lat]/[lng] to a geohash string of [precision] characters.
  static String encode(double lat, double lng, {int precision = 4}) {
    double minLat = -90, maxLat = 90;
    double minLng = -180, maxLng = 180;

    final buffer = StringBuffer();
    int bits = 0;
    int hashValue = 0;
    bool isLng = true; // alternate lng/lat

    while (buffer.length < precision) {
      final mid = isLng ? (minLng + maxLng) / 2 : (minLat + maxLat) / 2;
      final value = isLng ? lng : lat;
      if (value >= mid) {
        hashValue = (hashValue << 1) | 1;
        if (isLng) {
          minLng = mid;
        } else {
          minLat = mid;
        }
      } else {
        hashValue = (hashValue << 1);
        if (isLng) {
          maxLng = mid;
        } else {
          maxLat = mid;
        }
      }
      isLng = !isLng;
      bits++;

      if (bits == 5) {
        buffer.write(_base32[hashValue]);
        bits = 0;
        hashValue = 0;
      }
    }
    return buffer.toString();
  }

  // ── Decode bounds ────────────────────────────────────────────────────────────

  /// Returns {minLat, maxLat, minLng, maxLng} bounding box for a geohash.
  static Map<String, double> decodeBounds(String geohash) {
    double minLat = -90, maxLat = 90;
    double minLng = -180, maxLng = 180;
    bool isLng = true;

    for (final char in geohash.split('')) {
      final charIdx = _base32.indexOf(char);
      for (int bits = 4; bits >= 0; bits--) {
        final bitN = (charIdx >> bits) & 1;
        if (isLng) {
          final mid = (minLng + maxLng) / 2;
          if (bitN == 1) {
            minLng = mid;
          } else {
            maxLng = mid;
          }
        } else {
          final mid = (minLat + maxLat) / 2;
          if (bitN == 1) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isLng = !isLng;
      }
    }
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  // ── Neighbors ───────────────────────────────────────────────────────────────

  /// Returns the 8 neighboring geohashes around [geohash] (same precision).
  static List<String> neighbors(String geohash) {
    final bounds = decodeBounds(geohash);
    final centerLat = (bounds['minLat']! + bounds['maxLat']!) / 2;
    final centerLng = (bounds['minLng']! + bounds['maxLng']!) / 2;
    final latStep = bounds['maxLat']! - bounds['minLat']!;
    final lngStep = bounds['maxLng']! - bounds['minLng']!;
    final precision = geohash.length;

    return [
      encode(centerLat + latStep, centerLng, precision: precision),           // N
      encode(centerLat + latStep, centerLng + lngStep, precision: precision), // NE
      encode(centerLat, centerLng + lngStep, precision: precision),           // E
      encode(centerLat - latStep, centerLng + lngStep, precision: precision), // SE
      encode(centerLat - latStep, centerLng, precision: precision),           // S
      encode(centerLat - latStep, centerLng - lngStep, precision: precision), // SW
      encode(centerLat, centerLng - lngStep, precision: precision),           // W
      encode(centerLat + latStep, centerLng - lngStep, precision: precision), // NW
    ];
  }

  // ── Search hashes ────────────────────────────────────────────────────────────

  /// Returns up to 9 unique geohash strings (center + 8 neighbors) that cover
  /// [radiusKm] around [lat]/[lng].
  ///
  /// Precision is chosen automatically:
  ///   ≤2 km  → precision 5 (cell ≈4.9 km)
  ///   ≤10 km → precision 4 (cell ≈39 km)
  ///   >10 km → precision 3 (cell ≈156 km)
  ///
  /// Firestore `whereIn` supports ≤10 values — 9 hashes fits perfectly.
  static List<String> searchHashes(double lat, double lng,
      {double radiusKm = 10}) {
    final precision = radiusKm <= 2 ? 5 : (radiusKm <= 10 ? 4 : 3);
    final center = encode(lat, lng, precision: precision);
    final all = {center, ...neighbors(center)};
    return all.toList();
  }

  // ── Haversine distance ───────────────────────────────────────────────────────

  /// Returns the distance in kilometres between two coordinates.
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
