import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _kRed = Color(0xFFFC153B);
const _kText = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);

class RideBookingScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double estimatedFare;
  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String userId;
  final LatLng? initialDriverLocation;
  final String driverAvatarAsset;
  final String driverRating;
  final String driverTrips;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String initialEta;

  const RideBookingScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.userId,
    this.initialDriverLocation,
    required this.driverAvatarAsset,
    required this.driverRating,
    required this.driverTrips,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.initialEta,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _sheetAnim;
  late Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapBounds();
      _sheetAnim.forward();
    });
  }

  void _fitMapBounds() {
    final minLat = widget.pickupLocation.latitude < widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;
    final maxLat = widget.pickupLocation.latitude > widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;
    final minLng = widget.pickupLocation.longitude < widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;
    final maxLng = widget.pickupLocation.longitude > widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom = 13.0;
    if (maxDiff > 0) {
      zoom = (15.0 - maxDiff * 50).clamp(9.0, 17.0);
    }
    Future.delayed(const Duration(milliseconds: 300),
        () => _mapController.move(center, zoom));
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    super.dispose();
  }

  Future<void> _confirmRide() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        driverName: widget.driverName,
        fare: widget.estimatedFare,
      ),
    );
    if (confirmed == true && mounted) {
      final details = {
        'rideId': widget.rideId,
        'driverId': widget.driverId,
        'driverName': widget.driverName,
        'driverPhone': widget.driverPhone,
        'userId': widget.userId,
        'driverAvatarAsset': widget.driverAvatarAsset,
        'driverRating': widget.driverRating,
        'driverTrips': widget.driverTrips,
        'vehicleModel': widget.vehicleModel,
        'vehicleColor': widget.vehicleColor,
        'vehiclePlate': widget.vehiclePlate,
        'eta': widget.initialEta,
        'fare': widget.estimatedFare,
        'pickupAddress': widget.pickupAddress,
        'dropoffAddress': widget.dropoffAddress,
        'initialDriverPosition':
            widget.initialDriverLocation ?? widget.pickupLocation,
        'dropoffPosition': widget.dropoffLocation,
        'passengerPosition': widget.pickupLocation,
        'initialDriverLat':
            (widget.initialDriverLocation ?? widget.pickupLocation).latitude,
        'initialDriverLng':
            (widget.initialDriverLocation ?? widget.pickupLocation).longitude,
        'dropoffLat': widget.dropoffLocation.latitude,
        'dropoffLng': widget.dropoffLocation.longitude,
        'passengerLat': widget.pickupLocation.latitude,
        'passengerLng': widget.pickupLocation.longitude,
      };
      Navigator.pop(context, details);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ─────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.pickupLocation,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.musafirah_app',
                maxZoom: 19,
              ),
              PolylineLayer(polylines: [
                Polyline(
                  points: [widget.pickupLocation, widget.dropoffLocation],
                  strokeWidth: 4.5,
                  color: _kRed,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ]),
              MarkerLayer(markers: [
                _buildMarker(widget.pickupLocation, Colors.green[600]!,
                    Icons.radio_button_checked_rounded),
                _buildMarker(
                    widget.dropoffLocation, _kRed, Icons.location_on_rounded),
              ]),
            ],
          ),

          // ── Top floating bar ────────────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _FloatBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: _kRed, size: 15),
                      const SizedBox(width: 6),
                      Text('Safe Ride',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kText)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom sheet ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _sheetSlide,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, -6))
                  ],
                ),
                padding: EdgeInsets.fromLTRB(20, 0, 20, botPad + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),

                    // Driver row
                    Row(
                      children: [
                        _DriverInitialAvatar(name: widget.driverName),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.driverName,
                                  style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _kText)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 14),
                                  const SizedBox(width: 3),
                                  Text(widget.driverRating,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _kSub)),
                                  const SizedBox(width: 10),
                                  Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 5),
                                  Text('Online',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, color: Colors.green[700])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text('Rs ${widget.estimatedFare.toInt()}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _kRed)),
                              Text('fare',
                                  style: GoogleFonts.outfit(
                                      fontSize: 10, color: _kSub)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Vehicle info chips
                    Row(
                      children: [
                        _InfoPill(
                            icon: Icons.directions_car_rounded,
                            label: widget.vehicleModel),
                        const SizedBox(width: 8),
                        _InfoPill(
                            icon: Icons.palette_outlined,
                            label: widget.vehicleColor),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.vehiclePlate,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Route row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: Colors.green[600],
                                      shape: BoxShape.circle)),
                              Container(
                                  width: 1.5,
                                  height: 22,
                                  color: Colors.grey[300]),
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: _kRed,
                                      shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.pickupAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kText)),
                                const SizedBox(height: 12),
                                Text(widget.dropoffAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kText)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _confirmRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: _kRed.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text('Confirm Ride',
                            style: GoogleFonts.outfit(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng point, Color color, IconData icon) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Confirm bottom sheet ──────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.driverName, required this.fare});
  final String driverName;
  final double fare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFC153B).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFFFC153B), size: 36),
          ),
          const SizedBox(height: 16),
          Text('Ready to go?',
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 6),
          Text('$driverName will pick you up · Rs ${fare.toInt()}',
              style: GoogleFonts.outfit(fontSize: 14, color: _kSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Go Back',
                      style: GoogleFonts.outfit(
                          color: _kSub, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFFFC153B).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Yes, Confirm',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  const _FloatBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, size: 18, color: _kText),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kSub),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverInitialAvatar extends StatelessWidget {
  const _DriverInitialAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFC153B), Color(0xFFD4002A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFC153B).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}
