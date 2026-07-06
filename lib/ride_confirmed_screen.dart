import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'passenger_live_tracking_screen.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class RideConfirmedScreen extends StatelessWidget {
  RideConfirmedScreen({super.key, required Map<String, dynamic> driverDetails})
      : summary = RideSummary.fromMap(driverDetails);

  final RideSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildDriverCard(context),
                const SizedBox(height: 14),
                _buildRouteCard(),
                const SizedBox(height: 14),
                _buildMapPreview(),
                const SizedBox(height: 24),
                _buildTrackingButton(context),
                const SizedBox(height: 10),
                _buildCancelButton(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero section (gradient header + confirmation) ─────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Ride Confirmed',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Confirmation card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver is on the way!',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            '${summary.driverName} is heading to your pickup.',
                            style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(height: 2),
                          Text(summary.initialEta,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Driver card ───────────────────────────────────────────────────────────
  Widget _buildDriverCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kRed, _kRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: _kRed.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Center(
                  child: Text(
                    summary.driverName.isNotEmpty
                        ? summary.driverName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(summary.driverName,
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _kText)),
                        ),
                        _StarBadge(rating: summary.driverRating),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('On the way · ${summary.driverTrips} trips',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: _kSubText)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F4F8)),
          const SizedBox(height: 16),
          // Vehicle info row
          Row(
            children: [
              _VehicleChip(
                  icon: Icons.directions_car_rounded,
                  label: summary.vehicleModel),
              const SizedBox(width: 8),
              _VehicleChip(
                  icon: Icons.palette_outlined, label: summary.vehicleColor),
              const SizedBox(width: 8),
              _PlateChip(plate: summary.vehiclePlate),
            ],
          ),
          const SizedBox(height: 16),
          // Phone button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: summary.driverPhone.isEmpty
                  ? null
                  : () => _launchPhone(summary.driverPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.phone_rounded, size: 17),
              label: Text('Contact Driver',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Route card ────────────────────────────────────────────────────────────
  Widget _buildRouteCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Route line
          Column(
            children: [
              Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 4)
                      ])),
              Container(
                width: 2,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green[400]!, _kRed],
                  ),
                ),
              ),
              Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                      color: _kRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: _kRed.withValues(alpha: 0.4),
                            blurRadius: 4)
                      ])),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: _kSubText,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(summary.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                const SizedBox(height: 12),
                Text('Drop-off',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: _kSubText,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(summary.dropoffAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('Rs ${summary.fare.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _kRed)),
                Text('fare',
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: _kSubText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Map preview ───────────────────────────────────────────────────────────
  Widget _buildMapPreview() {
    final center = summary.passengerPosition ??
        summary.initialDriverPosition ??
        const LatLng(24.8607, 67.0011);
    final dropoff =
        summary.dropoffPosition ?? const LatLng(24.8607, 67.0011);

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.musafirah_app',
              ),
              PolylineLayer(polylines: [
                Polyline(
                    points: [center, dropoff],
                    strokeWidth: 3.5,
                    color: _kRed,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: center,
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.person_pin_circle_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                Marker(
                  point: dropoff,
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: _kRed.withValues(alpha: 0.4),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ],
          ),
          // ETA overlay
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: _kRed, size: 13),
                  const SizedBox(width: 5),
                  Text('ETA: ${summary.initialEta}',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                ],
              ),
            ),
          ),
          // Live badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE',
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildTrackingButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _openLiveTracking(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _kRed.withValues(alpha: 0.35),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: const Icon(Icons.navigation_rounded, size: 20),
        label: Text('Track Live',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kRed,
          side: const BorderSide(color: _kRed, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: Text('Cancel Ride',
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _openLiveTracking(BuildContext context) {
    if (summary.rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ride ID missing', style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassengerLiveTrackingScreen(
          rideId: summary.rideId,
          driverName: summary.driverName,
          driverId: summary.driverId,
          driverPhone: summary.driverPhone,
          userId: summary.userId,
          initialDriverPosition: summary.initialDriverPosition,
          dropoffPosition: summary.dropoffPosition,
          initialPassengerPosition: summary.passengerPosition,
          driverAvatarAsset: summary.driverAvatarAsset,
          pickupAddress: summary.pickupAddress,
          dropoffAddress: summary.dropoffAddress,
          initialEta: summary.initialEta,
          rideFare: summary.fare,
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.rating});
  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
          const SizedBox(width: 3),
          Text(rating,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800])),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: _kSubText),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
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

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(plate,
          style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1)),
    );
  }
}

Future<void> _launchPhone(String phoneNumber) async {
  final uri = 'tel:${phoneNumber.replaceAll(' ', '')}';
  if (!await launchUrlString(uri)) debugPrint('Cannot launch $uri');
}

// ── RideSummary model (unchanged) ─────────────────────────────────────────────
class RideSummary {
  RideSummary({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.userId,
    required this.driverRating,
    required this.driverTrips,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.initialEta,
    required this.driverAvatarAsset,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    this.initialDriverPosition,
    this.dropoffPosition,
    this.passengerPosition,
  });

  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String userId;
  final String driverRating;
  final String driverTrips;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String initialEta;
  final String driverAvatarAsset;
  final String pickupAddress;
  final String dropoffAddress;
  final double fare;
  final LatLng? initialDriverPosition;
  final LatLng? dropoffPosition;
  final LatLng? passengerPosition;

  factory RideSummary.fromMap(Map<String, dynamic> map) {
    LatLng? parseLatLng(String latKey, String lngKey) {
      final lat = map[latKey];
      final lng = map[lngKey];
      if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
      return null;
    }

    return RideSummary(
      rideId: map['rideId']?.toString() ?? map['ride_id']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? 'driver',
      driverName: map['driverName']?.toString() ?? 'Driver',
      driverPhone: map['driverPhone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'passenger',
      driverRating: map['driverRating']?.toString() ?? '5.0',
      driverTrips: map['driverTrips']?.toString() ?? '—',
      vehicleModel: map['vehicleModel']?.toString() ?? 'Vehicle',
      vehicleColor: map['vehicleColor']?.toString() ?? '—',
      vehiclePlate: map['vehiclePlate']?.toString() ?? '—',
      initialEta: map['eta']?.toString() ?? '—',
      driverAvatarAsset: map['driverAvatarAsset']?.toString() ?? '',
      pickupAddress: map['pickupAddress']?.toString() ?? 'Pickup',
      dropoffAddress: map['dropoffAddress']?.toString() ?? 'Drop-off',
      fare: (map['fare'] as num?)?.toDouble() ?? 0,
      initialDriverPosition:
          parseLatLng('initialDriverLat', 'initialDriverLng'),
      dropoffPosition: parseLatLng('dropoffLat', 'dropoffLng'),
      passengerPosition: parseLatLng('passengerLat', 'passengerLng'),
    );
  }
}
