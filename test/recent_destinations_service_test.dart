import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musafirah_app/services/recent_destinations_service.dart';

void main() {
  group('RecentDestinationsService', () {
    setUp(() {
      // Clear preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('getAll returns empty list initially', () async {
      final list = await RecentDestinationsService.getAll();
      expect(list, isEmpty);
    });

    test('save adds a trip and getAll retrieves it', () async {
      await RecentDestinationsService.save(
        address: 'Dropoff 1',
        lat: 24.8,
        lng: 67.0,
        pickupAddress: 'Pickup 1',
        pickupLat: 24.7,
        pickupLng: 66.9,
      );

      final list = await RecentDestinationsService.getAll();
      expect(list.length, equals(1));
      
      final trip = list.first;
      expect(trip['address'], equals('Dropoff 1'));
      expect(trip['lat'], equals(24.8));
      expect(trip['lng'], equals(67.0));
      expect(trip['pickupAddress'], equals('Pickup 1'));
      expect(trip['pickupLat'], equals(24.7));
      expect(trip['pickupLng'], equals(66.9));
    });

    test('save prepends new trips to the beginning', () async {
      await RecentDestinationsService.save(
        address: 'Dropoff 1', lat: 1.0, lng: 1.0,
      );
      await RecentDestinationsService.save(
        address: 'Dropoff 2', lat: 2.0, lng: 2.0,
      );

      final list = await RecentDestinationsService.getAll();
      expect(list.length, equals(2));
      expect(list[0]['address'], equals('Dropoff 2')); // Newest first
      expect(list[1]['address'], equals('Dropoff 1'));
    });

    test('save removes duplicates based on destination address', () async {
      await RecentDestinationsService.save(
        address: 'Same Dropoff', lat: 1.0, lng: 1.0,
      );
      await RecentDestinationsService.save(
        address: 'Other Dropoff', lat: 2.0, lng: 2.0,
      );
      await RecentDestinationsService.save(
        address: 'Same Dropoff', lat: 3.0, lng: 3.0, // Duplicate address, different coords (should still replace and move to top)
      );

      final list = await RecentDestinationsService.getAll();
      expect(list.length, equals(2));
      expect(list[0]['address'], equals('Same Dropoff'));
      expect(list[0]['lat'], equals(3.0)); // Should have updated data
      expect(list[1]['address'], equals('Other Dropoff'));
    });

    test('save enforces maxEntries limit (5)', () async {
      for (int i = 0; i < 7; i++) {
        await RecentDestinationsService.save(
          address: 'Dropoff $i', lat: 0.0, lng: 0.0,
        );
      }

      final list = await RecentDestinationsService.getAll();
      expect(list.length, equals(5));
      // Should contain the 5 most recently added ones (Dropoff 6 down to Dropoff 2)
      expect(list[0]['address'], equals('Dropoff 6'));
      expect(list[4]['address'], equals('Dropoff 2'));
    });

    test('clear removes all entries', () async {
      await RecentDestinationsService.save(
        address: 'Dropoff 1', lat: 1.0, lng: 1.0,
      );
      await RecentDestinationsService.clear();

      final list = await RecentDestinationsService.getAll();
      expect(list, isEmpty);
    });
  });
}
