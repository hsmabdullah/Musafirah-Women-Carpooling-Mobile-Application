import 'package:flutter_test/flutter_test.dart';
import 'package:musafirah_app/services/geo_service.dart';

void main() {
  group('GeoService', () {
    // Typical coordinates for testing (e.g., somewhere in Karachi)
    const double karachiLat = 24.8607;
    const double karachiLng = 67.0011;

    group('encode', () {
      test('encodes coordinates to geohash with default precision', () {
        final hash = GeoService.encode(karachiLat, karachiLng);
        expect(hash, isA<String>());
        expect(hash.length, equals(4)); // Default precision is 4
      });

      test('encodes coordinates with specific precision', () {
        final hash = GeoService.encode(karachiLat, karachiLng, precision: 6);
        expect(hash.length, equals(6));
      });

      test('known coordinate produces expected prefix', () {
        // Just checking consistency.
        final hash1 = GeoService.encode(karachiLat, karachiLng, precision: 5);
        final hash2 = GeoService.encode(karachiLat, karachiLng, precision: 8);
        expect(hash2.startsWith(hash1), isTrue);
      });
    });

    group('decodeBounds', () {
      test('decoding a geohash returns valid bounds containing the original point', () {
        final hash = GeoService.encode(karachiLat, karachiLng, precision: 5);
        final bounds = GeoService.decodeBounds(hash);

        expect(bounds, containsPair('minLat', isA<double>()));
        expect(bounds, containsPair('maxLat', isA<double>()));
        expect(bounds, containsPair('minLng', isA<double>()));
        expect(bounds, containsPair('maxLng', isA<double>()));

        expect(karachiLat, greaterThanOrEqualTo(bounds['minLat']!));
        expect(karachiLat, lessThanOrEqualTo(bounds['maxLat']!));
        expect(karachiLng, greaterThanOrEqualTo(bounds['minLng']!));
        expect(karachiLng, lessThanOrEqualTo(bounds['maxLng']!));
      });
    });

    group('neighbors', () {
      test('returns 8 surrounding geohashes', () {
        final hash = GeoService.encode(karachiLat, karachiLng, precision: 5);
        final neighbors = GeoService.neighbors(hash);

        expect(neighbors, isA<List<String>>());
        expect(neighbors.length, equals(8));

        // All neighbors should have the same precision as the center
        for (final n in neighbors) {
          expect(n.length, equals(5));
        }
      });
    });

    group('searchHashes', () {
      test('returns 9 unique hashes (center + 8 neighbors)', () {
        final hashes = GeoService.searchHashes(karachiLat, karachiLng);
        expect(hashes.length, equals(9));
        
        // Ensure uniqueness
        final uniqueHashes = hashes.toSet();
        expect(uniqueHashes.length, equals(9));
      });

      test('adjusts precision based on radius', () {
        final hashes2km = GeoService.searchHashes(karachiLat, karachiLng, radiusKm: 2);
        // Precision 5 for <= 2km
        expect(hashes2km.first.length, equals(5));

        final hashes10km = GeoService.searchHashes(karachiLat, karachiLng, radiusKm: 10);
        // Precision 4 for <= 10km
        expect(hashes10km.first.length, equals(4));

        final hashes20km = GeoService.searchHashes(karachiLat, karachiLng, radiusKm: 20);
        // Precision 3 for > 10km
        expect(hashes20km.first.length, equals(3));
      });
    });

    group('distanceKm', () {
      test('calculates correct distance between two known points', () {
        // Karachi to Hyderabad is roughly 160 km
        const hydLat = 25.3960;
        const hydLng = 68.3578;

        final distance = GeoService.distanceKm(karachiLat, karachiLng, hydLat, hydLng);
        
        expect(distance, greaterThan(130.0));
        expect(distance, lessThan(180.0));
      });

      test('distance to same point is 0', () {
        final distance = GeoService.distanceKm(karachiLat, karachiLng, karachiLat, karachiLng);
        expect(distance, equals(0.0));
      });

      test('distance is symmetric', () {
        const otherLat = 31.5204; // Lahore
        const otherLng = 74.3587;

        final d1 = GeoService.distanceKm(karachiLat, karachiLng, otherLat, otherLng);
        final d2 = GeoService.distanceKm(otherLat, otherLng, karachiLat, karachiLng);

        // Allow tiny floating point differences, though Haversine is symmetric
        expect((d1 - d2).abs(), lessThan(0.0001));
      });
    });
  });
}
