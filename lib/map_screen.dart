import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(31.5497, 74.3436), // Lahore, Pakistan coordinates
    zoom: 12.0,
  );

  final Set<Marker> _markers = {};
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // Add a default marker (you can customize this)
    _markers.add(
      const Marker(
        markerId: MarkerId('default'),
        position: LatLng(31.5497, 74.3436),
        infoWindow: InfoWindow(
          title: 'Musafirah Pickup Point',
          snippet: 'Lahore, Pakistan',
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    });
  }

  void _goToMyLocation() {
    // This would typically get the user's current location
    // For now, we'll animate to a default location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(31.5497, 74.3436), 15.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.05).clamp(15.0, 25.0);
    final double fontSizeTitle = (screenWidth * 0.045).clamp(16.0, 20.0);
    final double fontSizeBody = (screenWidth * 0.038).clamp(14.0, 16.0);
    final double buttonHeight = (screenHeight * 0.055).clamp(45.0, 55.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Map View',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: fontSizeTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _goToMyLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onTap: _onMapTap,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Search Bar
          Positioned(
            top: screenHeight * 0.02,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 0.6,
                vertical: screenHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600], size: 20),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: fontSizeBody,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: fontSizeBody,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Info Card
          if (_selectedLocation != null)
            Positioned(
              bottom: screenHeight * 0.15,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Container(
                padding: EdgeInsets.all(horizontalPadding * 0.8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFFFC153b),
                          size: 24,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            'Selected Location',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeTitle,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.inter(
                        fontSize: fontSizeBody * 0.9,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action Buttons
          Positioned(
            bottom: screenHeight * 0.04,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Column(
              children: [
                // Confirm Location Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _selectedLocation != null
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Location confirmed!',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: const Color(0xFFFC153b),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      'Confirm Location',
                      style: GoogleFonts.inter(
                        fontSize: fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
