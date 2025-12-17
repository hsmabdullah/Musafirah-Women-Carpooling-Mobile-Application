import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

class _RideBookingScreenState extends State<RideBookingScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    // Add pickup marker
    _markers.add(
      Marker(
        point: widget.pickupLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
      ),
    );

    // Add dropoff marker
    _markers.add(
      Marker(
        point: widget.dropoffLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
      ),
    );

    // Add polyline to connect pickup and drop-off
    _polylines.add(
      Polyline(
        points: [widget.pickupLocation, widget.dropoffLocation],
        strokeWidth: 4,
        color: const Color(0xFFFC153b),
      ),
    );

    // Calculate center and zoom to fit both markers
    final minLat =
        widget.pickupLocation.latitude < widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;
    final maxLat =
        widget.pickupLocation.latitude > widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;
    final minLng =
        widget.pickupLocation.longitude < widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;
    final maxLng =
        widget.pickupLocation.longitude > widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate zoom level to fit both points
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom = 13.0;
    if (maxDiff > 0) {
      zoom = 15.0 - (maxDiff * 50);
      if (zoom < 10.0) zoom = 10.0;
      if (zoom > 18.0) zoom = 18.0;
    }

    // Update camera to show both markers
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController.move(center, zoom);
    });

    setState(() {});
  }

  Future<void> _confirmRide() async {
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
      'initialDriverLat':
          (widget.initialDriverLocation ?? widget.pickupLocation).latitude,
      'initialDriverLng':
          (widget.initialDriverLocation ?? widget.pickupLocation).longitude,
      'dropoffLat': widget.dropoffLocation.latitude,
      'dropoffLng': widget.dropoffLocation.longitude,
      'passengerLat': widget.pickupLocation.latitude,
      'passengerLng': widget.pickupLocation.longitude,
    };

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ride Confirmed!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFC153b),
          ),
        ),
        content: Text(
          'Your ride has been confirmed. You can track the driver on the next screen.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC153b),
              foregroundColor: Colors.white,
            ),
            child: Text('Continue', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, details);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _RideResponsiveMetrics metrics = _RideResponsiveMetrics.fromContext(
      context,
    );
    final screenWidth = metrics.screenWidth;
    final screenHeight = metrics.screenHeight;
    final horizontalPadding = metrics.horizontalPadding;
    final fontSizeTitle = metrics.fontSizeTitle;
    final fontSizeBody = metrics.fontSizeBody;
    final fontSizeButton = metrics.fontSizeButton;
    final buttonHeight = metrics.buttonHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: screenHeight * 0.012,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            decoration: const BoxDecoration(color: Color(0xFFFC153b)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Book Ride',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.1), // Balance for back button
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Ride Details Card
                  Container(
                    margin: EdgeInsets.all(horizontalPadding),
                    padding: EdgeInsets.all(horizontalPadding * 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: const Color(0xFFFC153b),
                              size: 24,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup Location',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody * 0.9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.004),
                                  Text(
                                    widget.pickupAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Drop-off Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.flag,
                              color: const Color(0xFFFC153b),
                              size: 24,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drop-off Location',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody * 0.9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.004),
                                  Text(
                                    widget.dropoffAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: screenHeight * 0.01),
                        // Estimated Fare
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Fare',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFC153b),
                              ),
                            ),
                            Text(
                              '${widget.estimatedFare.toStringAsFixed(0)} PKR',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeTitle * 1.2,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFC153b),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Map Section
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: widget.pickupLocation,
                            initialZoom: 13.0,
                            minZoom: 5.0,
                            maxZoom: 18.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.musafirah_app',
                              maxZoom: 19,
                            ),
                            MarkerLayer(markers: _markers),
                            PolylineLayer(polylines: _polylines),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Confirm Ride Button
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    padding: EdgeInsets.only(
                      bottom: metrics.bottomActionPadding,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _confirmRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC153b),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm Ride',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeButton,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _RideResponsiveMetrics {
  _RideResponsiveMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.horizontalPadding,
    required this.fontSizeTitle,
    required this.fontSizeBody,
    required this.fontSizeButton,
    required this.buttonHeight,
    required this.bottomActionPadding,
  });

  final double screenWidth;
  final double screenHeight;
  final double horizontalPadding;
  final double fontSizeTitle;
  final double fontSizeBody;
  final double fontSizeButton;
  final double buttonHeight;
  final double bottomActionPadding;

  static _RideResponsiveMetrics fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return _RideResponsiveMetrics(
      screenWidth: width,
      screenHeight: height,
      horizontalPadding: (width * 0.06).clamp(16.0, 28.0),
      fontSizeTitle: (width * 0.045).clamp(16.0, 22.0),
      fontSizeBody: (width * 0.038).clamp(13.0, 18.0),
      fontSizeButton: (width * 0.042).clamp(15.0, 20.0),
      buttonHeight: (height * 0.065).clamp(48.0, 64.0),
      bottomActionPadding:
          MediaQuery.of(context).padding.bottom +
          (height * 0.01).clamp(8.0, 20.0),
    );
  }
}
