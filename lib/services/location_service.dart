import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'geo_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Musafirah – LocationService
//
// Provides:
//  • requestPermission()        – ask once before starting tracking
//  • startDriverTracking()      – continuous background stream that writes
//                                  live lat/lng + geohash to Firestore
//  • stopDriverTracking()       – cancel stream + mark driver offline
//  • driverLocationStream()     – passenger side: real-time GeoPoint stream
//                                  for a specific driver document
// ─────────────────────────────────────────────────────────────────────────────

class LocationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static StreamSubscription<Position>? _driverSub;

  // ── Android settings ─────────────────────────────────────────────────────────

  static final LocationSettings _androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20, // update every 20 m of movement
    intervalDuration: Duration(seconds: 5),
    foregroundNotificationConfig: ForegroundNotificationConfig(
      notificationText: 'Musafirah – location sharing is active',
      notificationTitle: 'Musafirah Driver',
      enableWakeLock: true,
    ),
  );

  // ── iOS settings ─────────────────────────────────────────────────────────────

  static final LocationSettings _iosSettings = AppleSettings(
    accuracy: LocationAccuracy.high,
    activityType: ActivityType.automotiveNavigation,
    distanceFilter: 20,
    pauseLocationUpdatesAutomatically: false,
    showBackgroundLocationIndicator: true,
  );

  static LocationSettings get _settings =>
      defaultTargetPlatform == TargetPlatform.android
          ? _androidSettings
          : _iosSettings;

  // ── Permission ───────────────────────────────────────────────────────────────

  /// Returns true if location permission is granted (always or while in use).
  /// Call this once from your UI before starting tracking.
  static Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return false;
    final enabled = await Geolocator.isLocationServiceEnabled();
    return enabled && perm != LocationPermission.denied;
  }

  // ── Driver: start background tracking ────────────────────────────────────────

  /// Starts a continuous position stream.
  /// Every [distanceFilter] metres the driver's Firestore document is updated:
  ///   Drivers/{driverUid}:
  ///     currentLat        : double
  ///     currentLng        : double
  ///     currentGeopoint   : GeoPoint   ← for map display
  ///     currentGeohash    : String     ← for radius queries (precision 4)
  ///     lastLocationAt    : Timestamp
  ///
  /// [onError] is called if the stream emits an error (e.g. permission revoked).
  static void startDriverTracking({
    required String driverUid,
    void Function(String error)? onError,
  }) {
    _driverSub?.cancel();

    _driverSub = Geolocator.getPositionStream(locationSettings: _settings)
        .listen(
      (Position pos) async {
        final geohash = GeoService.encode(pos.latitude, pos.longitude);
        try {
          await _db.collection('Drivers').doc(driverUid).update({
            'currentLat': pos.latitude,
            'currentLng': pos.longitude,
            'currentGeopoint': GeoPoint(pos.latitude, pos.longitude),
            'currentGeohash': geohash,
            'lastLocationAt': FieldValue.serverTimestamp(),
          });
        } on FirebaseException catch (e) {
          debugPrint('LocationService Firestore error: ${e.message}');
        }
      },
      onError: (e) {
        debugPrint('LocationService stream error: $e');
        onError?.call(e.toString());
      },
    );
  }

  // ── Driver: stop tracking ────────────────────────────────────────────────────

  /// Cancels the stream and marks the driver offline.
  static Future<void> stopDriverTracking(String driverUid) async {
    await _driverSub?.cancel();
    _driverSub = null;
    try {
      await _db.collection('Drivers').doc(driverUid).update({
        'isOnline': false,
        'lastLocationAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('LocationService stop error: ${e.message}');
    }
  }

  // ── Passenger: listen to driver's live position ───────────────────────────────

  /// Returns a stream of {lat, lng} maps from the driver's Firestore document.
  /// The passenger screen uses this to move the driver marker on the map.
  ///
  /// Example:
  ///   LocationService.driverLocationStream(driverUid).listen((coords) {
  ///     setState(() => _driverPos = LatLng(coords['lat']!, coords['lng']!));
  ///   });
  static Stream<Map<String, double>> driverLocationStream(String driverUid) {
    return _db
        .collection('Drivers')
        .doc(driverUid)
        .snapshots()
        .where((snap) => snap.exists && snap.data()?['currentLat'] != null)
        .map((snap) {
      final data = snap.data()!;
      return {
        'lat': (data['currentLat'] as num).toDouble(),
        'lng': (data['currentLng'] as num).toDouble(),
      };
    });
  }

  // ── One-shot current position ────────────────────────────────────────────────

  /// Quick helper — returns current position or null on error.
  static Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('LocationService.currentPosition error: $e');
      return null;
    }
  }
}
