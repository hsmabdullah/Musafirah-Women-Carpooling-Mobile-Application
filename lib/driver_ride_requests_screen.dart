import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:musafirah_app/driver_data.dart'; // Import the driver data
import 'package:musafirah_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'driver_navigation_screen.dart';

class DriverRideRequestsScreen extends StatefulWidget {
  final LatLng driverPickup;
  final LatLng driverDropoff;
  final String driverPickupAddress; // Added
  final String driverDropoffAddress; // Added
  final List<LatLng> routePoints;

  const DriverRideRequestsScreen({
    super.key,
    required this.driverPickup,
    required this.driverDropoff,
    required this.driverPickupAddress, // Added
    required this.driverDropoffAddress, // Added
    this.routePoints = const [],
  });

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState extends State<DriverRideRequestsScreen> {
  final Distance _distance = const Distance();

  // Driver profile loaded from Firestore on init
  Map<String, dynamic>? _driverProfile;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await DatabaseService.getUserData(user.uid, 'Drivers');
    if (mounted && data != null) {
      setState(() => _driverProfile = data);
    }
  }



  /// Returns true when the passenger pickup is within 15 km of the driver's
  /// starting point OR within 3 km of any route segment. This is intentionally
  /// lenient so that drivers see a healthy list of requests (InDrive style).
  bool _isRideNearby(_RideRequest ride) {
    if (widget.routePoints.isNotEmpty) {
      // Passenger pickup must be reasonably close to the driver's route.
      return _isPointNearRoute(ride.pickup, thresholdKm: 3.0);
    }
    // Fallback: pickup within 15 km of driver's start point.
    final double distPickup = _distance.as(
      LengthUnit.Kilometer,
      widget.driverPickup,
      ride.pickup,
    );
    return distPickup < 15.0;
  }

  bool _isPointNearRoute(LatLng point, {double thresholdKm = 3.0}) {
    for (int i = 0; i < widget.routePoints.length; i += 3) {
      final double dist = _distance.as(
        LengthUnit.Kilometer,
        point,
        widget.routePoints[i],
      );
      if (dist < thresholdKm) return true;
    }
    return false;
  }

  void _acceptRide(_RideRequest ride, int index) {
    // Prevent double-tap: ignore if already being processed.
    if (ride.rideId != null && _acceptingRideIds.contains(ride.rideId)) return;
    if (ride.rideId != null) setState(() => _acceptingRideIds.add(ride.rideId!));

    if (DriverData.carCapacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Car is full! Cannot accept more rides.',
            style: GoogleFonts.outfit()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFC153b).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                        color: Color(0xFFFC153b), strokeWidth: 3)),
                const SizedBox(height: 20),
                Text('Connecting…',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Notifying ${ride.name}',
                    style: GoogleFonts.outfit(
                        color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    // Write to Firestore with driver details so passenger sees real info
    () async {
      if (!mounted) return;
      String? acceptError;
      try {
        if (ride.rideId != null) {
          final driver = FirebaseAuth.instance.currentUser;
          final profile = _driverProfile;
          acceptError = await DatabaseService.acceptRideByDriver(
            rideId: ride.rideId!,
            driverUid: driver?.uid ?? '',
            driverName: profile?['name'] as String? ?? 'Driver',
            driverPhone: profile?['phone'] as String? ?? '',
            vehicleModel: profile?['vehicleModel'] as String? ?? '—',
            vehicleColor: profile?['vehicleColor'] as String? ?? '—',
            vehiclePlate: profile?['vehicleRegistration'] as String? ?? '—',
            driverImageUrl: (profile?['profileImageUrl'] as String?) ?? '',
          );
        }
      } finally {
        // Always release the "accepting" lock so the card can re-appear if
        // something went wrong, and the driver can try again.
        if (mounted && acceptError != null) {
          setState(() => _acceptingRideIds.remove(ride.rideId));
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      // Passenger cancelled before driver accepted
      if (acceptError == 'ride_cancelled') {
        setState(() {
          _dismissedRideIds.add(ride.rideId!);
          _acceptingRideIds.remove(ride.rideId);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'This ride was cancelled by the passenger.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Another driver already accepted
      if (acceptError == 'already_accepted') {
        setState(() {
          _dismissedRideIds.add(ride.rideId!);
          _acceptingRideIds.remove(ride.rideId);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'This ride was already accepted by another driver.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      if (acceptError != null) {
        if (mounted) setState(() => _acceptingRideIds.remove(ride.rideId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to accept ride: $acceptError',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.red,
        ));
        return;
      }

      setState(() {
        DriverData.carCapacity -= 1;
      });

      // Add to in-memory accepted rides
      final alreadyAdded = DriverData.acceptedRides.any((r) =>
          r.passengerName == ride.name &&
          r.pickupName == ride.pickupName &&
          r.dropoffName == ride.dropoffName);
      if (!alreadyAdded) {
        DriverData.acceptedRides.add(AcceptedRide(
          rideId: ride.rideId ?? '',
          passengerId: ride.userId ?? '',
          passengerImageUrl: ride.passengerImageUrl,
          passengerName: ride.name,
          pickupName: ride.pickupName,
          dropoffName: ride.dropoffName,
          pickup: ride.pickup,
          dropoff: ride.dropoff,
          price: ride.price,
          acceptedAt: DateTime.now(),
          paymentMethod: ride.paymentMethod,
        ));
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration:
                    BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.green, size: 30),
              ),
              const SizedBox(height: 16),
              Text('Ride Accepted!',
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Seats left: ${DriverData.carCapacity}',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFC153b))),
              const SizedBox(height: 4),
              Text('Navigate to ${ride.name}\'s pickup location.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverNavigationScreen(
                          start: ride.pickup,
                          end: ride.dropoff,
                          passengerName: ride.name,
                          price: ride.price,
                          rideId: ride.rideId ?? '',
                          passengerId: ride.userId ?? '',
                          passengerImageUrl: ride.passengerImageUrl,
                          paymentMethod: ride.paymentMethod,
                          pickupAddress: ride.pickupName,
                          dropoffAddress: ride.dropoffName,
                          driverName: _driverProfile?['name'] ?? '',
                          driverImageUrl: _driverProfile?['profileImageUrl'] ?? '',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Start Navigation',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }();
  }

  // Locally dismissed ride IDs — driver skips these without touching Firestore.
  final Set<String> _dismissedRideIds = {};

  // Guard against tapping Accept multiple times on the same ride.
  final Set<String> _acceptingRideIds = {};

  void _declineRide(_RideRequest ride) {
    if (ride.rideId != null) {
      setState(() => _dismissedRideIds.add(ride.rideId!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Declined ride from ${ride.name}",
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFC153B),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Matching Rides',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFC153b).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Real-time Stream Content
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: DatabaseService.getRequestedRidesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFC153b)),
                      const SizedBox(height: 16),
                      Text(
                        "Connecting to matching service...",
                        style: GoogleFonts.outfit(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Map docs to _RideRequest, filter nearby, sort by proximity
              final realRides = docs.map((doc) {
                final data = doc.data();
                final pick = LatLng(
                  (data['pickupLat'] as num?)?.toDouble() ?? 0.0,
                  (data['pickupLng'] as num?)?.toDouble() ?? 0.0,
                );
                final drop = LatLng(
                  (data['dropoffLat'] as num?)?.toDouble() ?? 0.0,
                  (data['dropoffLng'] as num?)?.toDouble() ?? 0.0,
                );
                // Ride length (pickup → dropoff)
                final rideDistKm = _distance.as(LengthUnit.Kilometer, pick, drop);
                // Distance from driver's start to passenger pickup (for sorting)
                final driverToPickupKm = _distance.as(
                  LengthUnit.Kilometer, widget.driverPickup, pick);

                return _RideRequest(
                  rideId: doc.id,
                  userId: data['userId'] as String?,
                  name: data['passengerName'] as String? ?? 'Rider',
                  pickupName: data['pickupAddress'] as String? ?? 'Pickup',
                  dropoffName: data['dropoffAddress'] as String? ?? 'Dropoff',
                  pickup: pick,
                  dropoff: drop,
                  distanceKm: rideDistKm,
                  driverToPickupKm: driverToPickupKm,
                  price: ((data['fare'] as num?)?.toInt()) ?? (rideDistKm * 25).toInt(),
                  rating: 5.0,
                  passengerImageUrl: data['passengerImageUrl'] as String? ?? '',
                  paymentMethod: data['paymentMethod'] as String? ?? 'Cash',
                );
              })
                .where(_isRideNearby)
                .where((r) => !_dismissedRideIds.contains(r.rideId))
                .where((r) => !_acceptingRideIds.contains(r.rideId))
                .toList()
                ..sort((a, b) => a.driverToPickupKm.compareTo(b.driverToPickupKm));

              // Deduplicate: one ride per passenger — keep only the first
              // (closest/most-recent) entry per userId.
              final seenUserIds = <String>{};
              final uniqueRides = realRides.where((r) {
                final key = r.userId ?? r.rideId ?? '';
                return seenUserIds.add(key);
              }).toList();

              if (uniqueRides.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.radar,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Scanning for rides...",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 170, 16, 40),
                itemCount: uniqueRides.length,
                itemBuilder: (context, index) {
                  return _buildFuturisticCard(uniqueRides[index], index);
                },
              );
            },
          ),

          // Capacity Indicator
          Positioned(
            top: 120,
            left: 16,
            right: 16,
            child: _buildCapacityIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityIndicator() {
    // Determine how many are used
    // If total=4, cap=3 -> used=1
    int used = DriverData.totalCapacity - DriverData.carCapacity;
    if (used < 0) used = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Capacity:",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          // Draw Seats
          ...List.generate(DriverData.totalCapacity, (index) {
            bool isUsed = index < used;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isUsed ? Icons.person : Icons.event_seat,
                color: isUsed ? Colors.grey[400] : const Color(0xFFFC153b),
                size: 20,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFuturisticCard(_RideRequest ride, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFC153b).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Section: Info & Price
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar with Status Ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFC153b).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[100],
                      child: Text(
                        ride.name[0],
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFC153b),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ride.rating.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Price Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC153b).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "PKR ${ride.price}",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFC153b),
                          ),
                        ),
                        Text(
                          "${ride.distanceKm.toStringAsFixed(1)} km ride",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFC153b).withValues(alpha: 0.8),
                          ),
                        ),
                        if (ride.driverToPickupKm > 0)
                          Text(
                            "${ride.driverToPickupKm.toStringAsFixed(1)} km away",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Middle Section: Route
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Row(
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 16,
                        color: Color(0xFFFC153b),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFC153b),
                              Colors.grey[300]!,
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          ride.dropoffName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bottom Section: Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _declineRide(ride),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Decline",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC153b), Color(0xFFFF5252)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFC153b,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _acceptRide(ride, index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Accept Ride",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideRequest {
  final String? rideId;
  final String? userId;
  final String name;
  final String pickupName;
  final String dropoffName;
  final LatLng pickup;
  final LatLng dropoff;
  /// Distance of the passenger's ride (pickup → dropoff).
  final double distanceKm;
  /// Distance from the driver's start point to the passenger's pickup.
  final double driverToPickupKm;
  final int price;
  final double rating;
  final String passengerImageUrl;
  final String paymentMethod;

  _RideRequest({
    this.rideId,
    this.userId,
    required this.name,
    required this.pickupName,
    required this.dropoffName,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    this.driverToPickupKm = 0.0,
    required this.price,
    required this.rating,
    this.passengerImageUrl = '',
    this.paymentMethod = 'Cash',
  });
}
