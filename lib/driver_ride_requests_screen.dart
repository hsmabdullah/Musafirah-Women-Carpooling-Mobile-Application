import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'driver_navigation_screen.dart';

class DriverRideRequestsScreen extends StatefulWidget {
  final LatLng driverPickup;
  final LatLng driverDropoff;

  const DriverRideRequestsScreen({
    super.key,
    required this.driverPickup,
    required this.driverDropoff,
  });

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState extends State<DriverRideRequestsScreen> {
  final List<_RideRequest> _availableRides = [];
  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    _generateMockRides();
  }

  void _generateMockRides() {
    // 1. GOOD RIDES (Matches Route)
    _availableRides.add(
      _createMockRide(
        "Sarah Ahmed",
        "Jinnah Ave, Blue Area",
        "DHA Phase 2",
        widget.driverPickup,
        widget.driverDropoff,
        4.8,
      ),
    );

    _availableRides.add(
      _createMockRide(
        "Hira Mani",
        "Clifton Block 4",
        "Sea View",
        _perturb(widget.driverPickup),
        _perturb(widget.driverDropoff),
        4.9,
      ),
    );

    _availableRides.add(
      _createMockRide(
        "Ali Raza",
        "Near Pickup Point",
        "Near Dropoff Point",
        _perturb(widget.driverPickup, spread: 0.005),
        _perturb(widget.driverDropoff, spread: 0.005),
        4.7,
      ),
    );

    // 2. Far Ride (Filtered out visually, but kept in logic just in case)
    _availableRides.add(
      _createMockRide(
        "Far Person",
        "North Nazimabad",
        "Gadap Town",
        const LatLng(24.98, 67.05),
        const LatLng(25.0, 67.1),
        4.5,
      ),
    );
  }

  LatLng _perturb(LatLng original, {double spread = 0.01}) {
    final random = Random();
    double lat = original.latitude + (random.nextDouble() - 0.5) * spread;
    double lng = original.longitude + (random.nextDouble() - 0.5) * spread;
    return LatLng(lat, lng);
  }

  _RideRequest _createMockRide(
    String name,
    String pickupName,
    String dropoffName,
    LatLng pick,
    LatLng drop,
    double rating,
  ) {
    final double distKm = _distance.as(LengthUnit.Kilometer, pick, drop);
    final double price = distKm * 200; // Rs 200 per km

    return _RideRequest(
      name: name,
      pickupName: pickupName,
      dropoffName: dropoffName,
      pickup: pick,
      dropoff: drop,
      distanceKm: distKm,
      price: price.round(),
      rating: rating,
    );
  }

  bool _isRideOnRoute(_RideRequest ride) {
    final double distPickup = _distance.as(
      LengthUnit.Kilometer,
      widget.driverPickup,
      ride.pickup,
    );
    final double distDropoff = _distance.as(
      LengthUnit.Kilometer,
      widget.driverDropoff,
      ride.dropoff,
    );
    return distPickup < 5.0 && distDropoff < 5.0; // 5km radius buffer
  }

  void _acceptRide(_RideRequest ride, int index) {
    // Show Futuristic Loading Dialog
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
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFC153b).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFC153b),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Connecting...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Notifying ${ride.name}",
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate Network Delay -> Success
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading
      if (!mounted) return;

      // Show Success Overlay
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                "Ride Accepted!",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Navigate to ${ride.name}'s pickup location.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close Sheet
                    // Navigate to Navigation Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverNavigationScreen(
                          start: ride.pickup,
                          end: ride.dropoff,
                          passengerName: ride.name,
                          price: ride.price,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Start Navigation",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _declineRide(_RideRequest ride) {
    setState(() {
      _availableRides.remove(ride);
    });

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
    // Filter List
    final displayRides = _availableRides
        .where((r) => _isRideOnRoute(r))
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FE), // very light futuristic grey
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
          // Background Decor (Gradient blobs for futuristic feel)
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
                    const Color(0xFFFC153b).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          displayRides.isEmpty
              ? Center(
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
                              color: Colors.grey.withOpacity(0.1),
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
                      const SizedBox(height: 8),
                      Text(
                        "No matching passengers on your route yet.",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
                  itemCount: displayRides.length,
                  itemBuilder: (context, index) {
                    final ride = displayRides[index];
                    return _buildFuturisticCard(ride, index);
                  },
                ),
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
            color: const Color(0xFFFC153b).withOpacity(0.08),
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
                        color: const Color(0xFFFC153b).withOpacity(0.3),
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
                      color: const Color(0xFFFC153b).withOpacity(0.1),
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
                          "${ride.distanceKm.toStringAsFixed(1)} KM",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFC153b).withOpacity(0.8),
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
                            color: const Color(0xFFFC153b).withOpacity(0.4),
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
  final String name;
  final String pickupName;
  final String dropoffName;
  final LatLng pickup;
  final LatLng dropoff;
  final double distanceKm;
  final int price;
  final double rating;

  _RideRequest({
    required this.name,
    required this.pickupName,
    required this.dropoffName,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.price,
    required this.rating,
  });
}
