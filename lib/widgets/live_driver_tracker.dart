import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveDriverTracker
//
// Drop-in widget for the passenger side (RideBookingScreen / RideConfirmedScreen).
// Shows:
//   • Passenger pickup pin  (pink)
//   • Driver live marker    (teal car icon, moves as driver moves)
//   • Optional dropoff pin  (grey)
//
// Usage:
//   LiveDriverTracker(
//     driverUid:    rideData['driverId'],
//     passengerPos: LatLng(pickupLat, pickupLng),
//     dropoffPos:   LatLng(dropoffLat, dropoffLng),   // optional
//   )
// ─────────────────────────────────────────────────────────────────────────────

class LiveDriverTracker extends StatefulWidget {
  final String driverUid;
  final LatLng passengerPos;
  final LatLng? dropoffPos;

  const LiveDriverTracker({
    super.key,
    required this.driverUid,
    required this.passengerPos,
    this.dropoffPos,
  });

  @override
  State<LiveDriverTracker> createState() => _LiveDriverTrackerState();
}

class _LiveDriverTrackerState extends State<LiveDriverTracker> {
  final MapController _mapController = MapController();
  StreamSubscription<Map<String, double>>? _locationSub;

  LatLng? _driverPos;
  bool _firstFix = true;

  @override
  void initState() {
    super.initState();
    _locationSub = LocationService.driverLocationStream(widget.driverUid)
        .listen(_onDriverLocation);
  }

  void _onDriverLocation(Map<String, double> coords) {
    final pos = LatLng(coords['lat']!, coords['lng']!);
    setState(() => _driverPos = pos);

    if (_firstFix) {
      _firstFix = false;
      // On first real fix, fit map to show both driver and passenger
      _fitBounds(pos, widget.passengerPos);
    } else {
      // Gently pan to keep driver in view without jarring the user
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    final bounds = LatLngBounds(a, b);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.passengerPos,
        initialZoom: 14,
      ),
      children: [
        // ── Base tile layer ────────────────────────────────────────────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.musafirah.app',
        ),

        // ── Markers ────────────────────────────────────────────────────────
        MarkerLayer(
          markers: [
            // Passenger pickup
            Marker(
              point: widget.passengerPos,
              width: 40,
              height: 40,
              child: const _PinMarker(color: Color(0xFFFC153B)),
            ),

            // Dropoff (optional)
            if (widget.dropoffPos != null)
              Marker(
                point: widget.dropoffPos!,
                width: 40,
                height: 40,
                child: const _PinMarker(color: Colors.grey),
              ),

            // Driver live position
            if (_driverPos != null)
              Marker(
                point: _driverPos!,
                width: 44,
                height: 44,
                child: const _CarMarker(),
              ),
          ],
        ),

        // ── Loading overlay ─────────────────────────────────────────────────
        if (_driverPos == null)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Driver ki location mil rahi hai...',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Small reusable marker widgets ────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final Color color;
  const _PinMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4)
            ],
          ),
        ),
        CustomPaint(
          painter: _TrianglePainter(color),
          size: const Size(10, 6),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _CarMarker extends StatelessWidget {
  const _CarMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF009688),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
    );
  }
}
