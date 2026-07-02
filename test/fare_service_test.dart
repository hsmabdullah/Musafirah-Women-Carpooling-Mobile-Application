import 'package:flutter_test/flutter_test.dart';
import 'package:musafirah_app/services/fare_service.dart';

void main() {
  group('FareService – calculateFare', () {
    // ── Standard hours (no surge) ─────────────────────────────────────────
    group('Standard hours (no surge)', () {
      // A time well outside any surge window: 12:00 noon on a weekday
      final standardTime = DateTime(2025, 1, 15, 12, 0);

      test('base fare is PKR 80 for every trip', () {
        final fare = FareService.calculateFare(
          distanceKm: 0,
          durationMinutes: 0,
          pickupTime: standardTime,
        );
        expect(fare.baseFare, equals(80.0));
      });

      test('surge multiplier is 1.0 during standard hours', () {
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: standardTime,
        );
        expect(fare.surgeMultiplier, equals(1.0));
        expect(fare.surgeLabel, equals('Standard'));
      });

      test('total = base + distance×22 + duration×3 at standard rate', () {
        // 5 km trip, 10 minutes
        // expected = 80 + 5×22 + 10×3 = 80 + 110 + 30 = 220
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: standardTime,
        );
        expect(fare.distanceCharge, equals(110.0));
        expect(fare.durationCharge, equals(30.0));
        expect(fare.totalFare, equals(220.0));
      });

      test('minimum fare PKR 120 is applied for very short trips', () {
        // 0 km, 0 min → sub-total = 80, which is < 120
        final fare = FareService.calculateFare(
          distanceKm: 0,
          durationMinutes: 0,
          pickupTime: standardTime,
        );
        expect(fare.totalFare, equals(120.0));
      });

      test('minimum fare is NOT applied when trip exceeds it', () {
        // 2 km, 5 min → 80 + 44 + 15 = 139 > 120
        final fare = FareService.calculateFare(
          distanceKm: 2,
          durationMinutes: 5,
          pickupTime: standardTime,
        );
        expect(fare.totalFare, greaterThanOrEqualTo(120.0));
        expect(fare.totalFare, equals(139.0));
      });
    });

    // ── Morning peak surge (07:00–10:00) ─────────────────────────────────
    group('Morning peak surge (07:00–10:00)', () {
      test('surge multiplier is 1.3 at 08:00', () {
        final peakTime = DateTime(2025, 1, 15, 8, 0);
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: peakTime,
        );
        expect(fare.surgeMultiplier, equals(1.3));
        expect(fare.surgeLabel, equals('Peak hours'));
      });

      test('total is 30% higher during morning peak', () {
        final standardTime = DateTime(2025, 1, 15, 12, 0);
        final peakTime = DateTime(2025, 1, 15, 8, 0);

        final standard = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: standardTime,
        );
        final peak = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: peakTime,
        );

        // 220 × 1.3 = 286
        expect(peak.totalFare, equals((standard.totalFare * 1.3).roundToDouble()));
      });

      test('surge applies at 07:00 exactly', () {
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: DateTime(2025, 1, 15, 7, 0),
        );
        expect(fare.surgeMultiplier, equals(1.3));
      });

      test('no surge at 10:00 exactly (boundary excluded)', () {
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: DateTime(2025, 1, 15, 10, 0),
        );
        expect(fare.surgeMultiplier, equals(1.0));
      });
    });

    // ── Evening peak surge (17:00–21:00) ─────────────────────────────────
    group('Evening peak surge (17:00–21:00)', () {
      test('surge multiplier is 1.3 at 18:00', () {
        final fare = FareService.calculateFare(
          distanceKm: 3,
          durationMinutes: 8,
          pickupTime: DateTime(2025, 1, 15, 18, 0),
        );
        expect(fare.surgeMultiplier, equals(1.3));
        expect(fare.surgeLabel, equals('Peak hours'));
      });

      test('surge applies at 17:00 exactly', () {
        final fare = FareService.calculateFare(
          distanceKm: 3,
          durationMinutes: 8,
          pickupTime: DateTime(2025, 1, 15, 17, 0),
        );
        expect(fare.surgeMultiplier, equals(1.3));
      });

      test('no surge at 21:00 exactly (boundary excluded)', () {
        final fare = FareService.calculateFare(
          distanceKm: 3,
          durationMinutes: 8,
          pickupTime: DateTime(2025, 1, 15, 21, 0),
        );
        expect(fare.surgeMultiplier, equals(1.0));
      });
    });

    // ── Late night surge (23:00–05:00) ───────────────────────────────────
    group('Late night surge (23:00–05:00)', () {
      test('surge multiplier is 1.2 at 23:00', () {
        final fare = FareService.calculateFare(
          distanceKm: 4,
          durationMinutes: 12,
          pickupTime: DateTime(2025, 1, 15, 23, 0),
        );
        expect(fare.surgeMultiplier, equals(1.2));
        expect(fare.surgeLabel, equals('Late night'));
      });

      test('surge multiplier is 1.2 at 02:00', () {
        final fare = FareService.calculateFare(
          distanceKm: 4,
          durationMinutes: 12,
          pickupTime: DateTime(2025, 1, 16, 2, 0),
        );
        expect(fare.surgeMultiplier, equals(1.2));
        expect(fare.surgeLabel, equals('Late night'));
      });

      test('no late-night surge at 05:00 exactly (boundary excluded)', () {
        final fare = FareService.calculateFare(
          distanceKm: 4,
          durationMinutes: 12,
          pickupTime: DateTime(2025, 1, 16, 5, 0),
        );
        expect(fare.surgeMultiplier, equals(1.0));
      });
    });

    // ── FareBreakdown fields ───────────────────────────────────────────────
    group('FareBreakdown fields are correctly populated', () {
      test('distanceKm and durationMinutes are stored verbatim', () {
        final fare = FareService.calculateFare(
          distanceKm: 7.5,
          durationMinutes: 20.0,
          pickupTime: DateTime(2025, 1, 15, 12, 0),
        );
        expect(fare.distanceKm, equals(7.5));
        expect(fare.durationMinutes, equals(20.0));
      });

      test('toString contains key fields', () {
        final fare = FareService.calculateFare(
          distanceKm: 5,
          durationMinutes: 10,
          pickupTime: DateTime(2025, 1, 15, 12, 0),
        );
        final str = fare.toString();
        expect(str, contains('dist='));
        expect(str, contains('surge='));
        expect(str, contains('total='));
      });
    });
  });

  // ── calculateFareFromOsrm ─────────────────────────────────────────────────
  group('FareService – calculateFareFromOsrm', () {
    final standardTime = DateTime(2025, 1, 15, 12, 0);

    test('converts metres to km and seconds to minutes correctly', () {
      // 5000 m = 5 km, 600 s = 10 min → same as 5 km / 10 min
      final fromKm = FareService.calculateFare(
        distanceKm: 5,
        durationMinutes: 10,
        pickupTime: standardTime,
      );
      final fromOsrm = FareService.calculateFareFromOsrm(
        distanceMetres: 5000,
        durationSeconds: 600,
        pickupTime: standardTime,
      );

      expect(fromOsrm.totalFare, equals(fromKm.totalFare));
      expect(fromOsrm.distanceKm, equals(fromKm.distanceKm));
      expect(fromOsrm.durationMinutes, equals(fromKm.durationMinutes));
    });

    test('minimum fare still applies via OSRM helper', () {
      final fare = FareService.calculateFareFromOsrm(
        distanceMetres: 0,
        durationSeconds: 0,
        pickupTime: standardTime,
      );
      expect(fare.totalFare, equals(120.0));
    });
  });
}
