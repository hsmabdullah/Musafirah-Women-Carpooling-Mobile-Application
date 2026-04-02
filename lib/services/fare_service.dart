import 'dart:math';

/// Immutable breakdown of a calculated fare.
class FareBreakdown {
  /// Distance in kilometres.
  final double distanceKm;

  /// Estimated duration in minutes.
  final double durationMinutes;

  /// Fixed charge applied to every trip.
  final double baseFare;

  /// Distance-based charge.
  final double distanceCharge;

  /// Time-based charge.
  final double durationCharge;

  /// Applied surge multiplier (1.0 = no surge).
  final double surgeMultiplier;

  /// Human-readable label for the current surge, e.g. "Peak hours".
  final String surgeLabel;

  /// Total fare after surge (already rounded to nearest PKR).
  final double totalFare;

  const FareBreakdown({
    required this.distanceKm,
    required this.durationMinutes,
    required this.baseFare,
    required this.distanceCharge,
    required this.durationCharge,
    required this.surgeMultiplier,
    required this.surgeLabel,
    required this.totalFare,
  });

  @override
  String toString() =>
      'FareBreakdown('
      'dist=${distanceKm.toStringAsFixed(2)} km, '
      'duration=${durationMinutes.toStringAsFixed(1)} min, '
      'surge=$surgeMultiplier ($surgeLabel), '
      'total=PKR ${totalFare.toStringAsFixed(0)})';
}

/// Calculates ride fares for Musafirah (Pakistan market).
///
/// Tariff model
/// ────────────
///   Base fare    : PKR 80  (charged once per trip)
///   Distance     : PKR 22 / km
///   Duration     : PKR 3  / minute
///   Minimum fare : PKR 120 (applied after surge)
///
/// Surge schedule (applied on the pre-surge sub-total)
/// ─────────────────────────────────────────────────────
///   Morning peak   07:00–10:00  → ×1.3
///   Evening peak   17:00–21:00  → ×1.3
///   Late night     23:00–05:00  → ×1.2
///   Otherwise                  → ×1.0
class FareService {
  // ── Tariff constants ────────────────────────────────────────────────────────
  static const double _baseFare = 80.0;
  static const double _perKmRate = 22.0;
  static const double _perMinuteRate = 3.0;
  static const double _minimumFare = 120.0;

  // ── Surge brackets ─────────────────────────────────────────────────────────
  static const double _surgeNone = 1.0;
  static const double _surgePeak = 1.3;
  static const double _surgeNight = 1.2;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Calculates the fare for a ride.
  ///
  /// [distanceKm]     : trip distance in kilometres (from OSRM route).
  /// [durationMinutes]: estimated travel time in minutes (from OSRM route).
  /// [pickupTime]     : scheduled pickup time; defaults to [DateTime.now()].
  ///
  /// Returns a [FareBreakdown] with all cost components.
  static FareBreakdown calculateFare({
    required double distanceKm,
    required double durationMinutes,
    DateTime? pickupTime,
  }) {
    final time = pickupTime ?? DateTime.now();

    final distanceCharge = distanceKm * _perKmRate;
    final durationCharge = durationMinutes * _perMinuteRate;
    final subTotal = _baseFare + distanceCharge + durationCharge;

    final (surge, surgeLabel) = _surgeMultiplier(time);

    double total = (subTotal * surge).roundToDouble();
    total = max(total, _minimumFare);

    return FareBreakdown(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      baseFare: _baseFare,
      distanceCharge: distanceCharge,
      durationCharge: durationCharge,
      surgeMultiplier: surge,
      surgeLabel: surgeLabel,
      totalFare: total,
    );
  }

  /// Convenience helper: converts OSRM distance (metres) and duration
  /// (seconds) to a [FareBreakdown].
  static FareBreakdown calculateFareFromOsrm({
    required double distanceMetres,
    required double durationSeconds,
    DateTime? pickupTime,
  }) =>
      calculateFare(
        distanceKm: distanceMetres / 1000.0,
        durationMinutes: durationSeconds / 60.0,
        pickupTime: pickupTime,
      );

  // ── Private helpers ─────────────────────────────────────────────────────────

  static (double multiplier, String label) _surgeMultiplier(DateTime t) {
    final h = t.hour;

    if ((h >= 7 && h < 10) || (h >= 17 && h < 21)) {
      return (_surgePeak, 'Peak hours');
    }
    if (h >= 23 || h < 5) {
      return (_surgeNight, 'Late night');
    }
    return (_surgeNone, 'Standard');
  }
}
