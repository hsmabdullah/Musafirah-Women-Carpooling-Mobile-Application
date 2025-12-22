import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:musafirah_app/services/osm_service.dart';
import 'package:musafirah_app/ride_booking_screen.dart';
import 'package:musafirah_app/ride_confirmed_screen.dart';
import 'package:musafirah_app/wallet_history_screen.dart';
import 'package:musafirah_app/rider_profile_screen.dart';
import 'package:musafirah_app/utils/id_utils.dart';

class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() =>
      _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  LatLng? _origin;
  LatLng? _destination;
  String _originText = 'From: Current Location';
  String _destinationText = 'To: Enter destination';
  double _estimatedFare = 0.0;
  bool _isLoadingFare = false;
  int _selectedIndex = 0; // 0: Home, 1: Wallet, 2: Profile
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  List<Map<String, dynamic>> _popularDestinations = [];
  final ScrollController _popularDestinationsScrollController =
      ScrollController();
  final List<DriverProfile> _driverProfiles = [
    DriverProfile(
      id: 'driver_sana_ali',
      name: 'Sana Ali',
      phone: '+923001112233',
      rating: '4.9',
      seats: '2/3 seats',
      vehicleModel: 'Toyota Corolla',
      vehicleColor: 'White',
      vehiclePlate: 'LEB-4521',
      avatarAsset: 'Assets/icons/women1.jpeg',
      initialEta: '6 min',
      initialPosition: const LatLng(24.8740, 67.0320),
    ),
    DriverProfile(
      id: 'driver_hina_khan',
      name: 'Hina Khan',
      phone: '+923008889900',
      rating: '5.0',
      seats: '1/3 seats',
      vehicleModel: 'Honda City',
      vehicleColor: 'Silver',
      vehiclePlate: 'KHI-6234',
      avatarAsset: 'Assets/icons/pakistani.jpg',
      initialEta: '5 min',
      initialPosition: const LatLng(24.8705, 67.0450),
    ),
    DriverProfile(
      id: 'driver_maira_ahmed',
      name: 'Maira Ahmed',
      phone: '+923021234567',
      rating: '4.8',
      seats: '3/3 seats',
      vehicleModel: 'Suzuki Swift',
      vehicleColor: 'Red',
      vehiclePlate: 'AJK-9087',
      avatarAsset: 'Assets/icons/woman_2.jpg',
      initialEta: '7 min',
      initialPosition: const LatLng(24.8785, 67.0210),
    ),
    DriverProfile(
      id: 'driver_nimra_yousuf',
      name: 'Nimra Yousuf',
      phone: '+923335551234',
      rating: '4.7',
      seats: '2/3 seats',
      vehicleModel: 'Toyota Vitz',
      vehicleColor: 'Blue',
      vehiclePlate: 'BWP-3210',
      avatarAsset: 'Assets/icons/women1.jpeg',
      initialEta: '8 min',
      initialPosition: const LatLng(24.8665, 67.0550),
    ),
  ];
  int _driverProfileIndex = 0;

  @override
  void initState() {
    super.initState();
    _originController.text = _stripPrefix(_originText, 'From: ');
    _destinationController.text = _stripPrefix(_destinationText, 'To: ');
    // Delay location fetch until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _loadPopularDestinations();
    });
  }

  @override
  void dispose() {
    _popularDestinationsScrollController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool showErrorMessages = false}) async {
    if (!mounted) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showErrorMessages && mounted) {
          _showError('Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showErrorMessages && mounted) {
            _showError('Location permissions are denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showErrorMessages && mounted) {
          _showError(
            'Location permissions are permanently denied. Please enable them in settings.',
          );
        }
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (_currentPosition != null && mounted) {
        _origin = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _updateOriginText();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _updateMapCamera();
            _updateMapMarkers();
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (showErrorMessages && mounted) {
        _showError('Failed to get current location.');
      }
    }
  }

  Future<void> _updateOriginText() async {
    if (_origin != null && mounted) {
      try {
        final placeName = await OSMService.getPlaceName(_origin!);
        if (mounted) {
          final display = placeName ?? 'Current Location';
          setState(() {
            _originText = 'From: $display';
            _originController.text = display;
          });
        }
      } catch (e) {
        debugPrint('Error getting place name: $e');
      }
    }
  }

  Future<void> _loadPopularDestinations() async {
    // Simple hardcoded popular destinations
    setState(() {
      _popularDestinations = [
        {'name': 'Clifton', 'latitude': 24.7970, 'longitude': 67.0280},
        {'name': 'DHA Phase 5', 'latitude': 24.8000, 'longitude': 67.0700},
        {'name': 'Gulshan-e-Iqbal', 'latitude': 24.9200, 'longitude': 67.0700},
        {'name': 'North Nazimabad', 'latitude': 24.9500, 'longitude': 67.0300},
      ];
    });
  }

  void _updateMapCamera() {
    if (!mounted) return;

    try {
      if (_origin != null && _destination != null) {
        // Calculate bounds to fit both markers
        final minLat = _origin!.latitude < _destination!.latitude
            ? _origin!.latitude
            : _destination!.latitude;
        final maxLat = _origin!.latitude > _destination!.latitude
            ? _origin!.latitude
            : _destination!.latitude;
        final minLng = _origin!.longitude < _destination!.longitude
            ? _origin!.longitude
            : _destination!.longitude;
        final maxLng = _origin!.longitude > _destination!.longitude
            ? _origin!.longitude
            : _destination!.longitude;

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

        _mapController.move(center, zoom);
      } else if (_origin != null) {
        _mapController.move(_origin!, 14.0);
      } else {
        // Default to Karachi
        _mapController.move(const LatLng(24.8607, 67.0011), 12.0);
      }
    } catch (e) {
      debugPrint('Error updating map camera: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectOrigin() async {
    // Show a dialog to search for origin or use current location
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DestinationSearchDialog(isOrigin: true),
    );

    if (result != null && mounted) {
      final latitude = result['latitude'] as double?;
      final longitude = result['longitude'] as double?;
      final description = result['description'] as String?;

      if (latitude != null && longitude != null) {
        final display = description?.toString().trim().isNotEmpty == true
            ? description!.toString()
            : 'Selected Location';
        setState(() {
          _origin = LatLng(latitude, longitude);
          _originText = 'From: $display';
          _originController.text = display;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _updateMapMarkers();
            _updateMapCamera();
          }
        });
        if (_origin != null && _destination != null) {
          _calculateFare();
        }
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    await _getCurrentLocation(showErrorMessages: true);
  }

  Future<void> _selectDestination() async {
    // Show a dialog to search for destination
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DestinationSearchDialog(),
    );

    if (result != null && mounted) {
      final latitude = result['latitude'] as double?;
      final longitude = result['longitude'] as double?;
      final description = result['description'] as String?;

      if (latitude != null && longitude != null) {
        final display = description?.toString().trim().isNotEmpty == true
            ? description!.toString()
            : 'Selected Location';
        setState(() {
          _destination = LatLng(latitude, longitude);
          _destinationText = 'To: $display';
          _destinationController.text = display;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _updateMapMarkers();
            _updateMapCamera();
          }
        });
        if (_origin != null && _destination != null) {
          _calculateFare();
        }
      }
    }
  }

  Future<void> _handleManualLocationSearch({
    required bool isOrigin,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      _showError('Please enter at least 3 characters to search.');
      return;
    }

    try {
      final results = await OSMService.searchPlaces(trimmed);
      if (!mounted) return;

      if (results.isEmpty) {
        _showError('No matching locations found.');
        return;
      }

      final result = results.first;
      final latitude = result['latitude'] as double?;
      final longitude = result['longitude'] as double?;
      if (latitude == null || longitude == null) {
        _showError('Selected location is missing coordinates.');
        return;
      }

      final display =
          result['description']?.toString().trim().isNotEmpty == true
          ? result['description'].toString()
          : result['mainText']?.toString() ?? trimmed;

      setState(() {
        if (isOrigin) {
          _origin = LatLng(latitude, longitude);
          _originText = 'From: $display';
          _originController.text = display;
        } else {
          _destination = LatLng(latitude, longitude);
          _destinationText = 'To: $display';
          _destinationController.text = display;
        }
      });

      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _updateMapMarkers();
        _updateMapCamera();
        if (_origin != null && _destination != null) {
          _calculateFare();
        }
      });
    } catch (e) {
      debugPrint('Manual location search error: $e');
      if (mounted) {
        _showError('Unable to search for that location. Please try again.');
      }
    }
  }

  String _stripPrefix(String value, String prefix) {
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length).trim();
    }
    return value;
  }

  void _updateMapMarkers() {
    if (!mounted) return;

    final newMarkers = <Marker>[];
    final newPolylines = <Polyline>[];

    if (_origin != null) {
      newMarkers.add(
        Marker(
          point: _origin!,
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
    }
    if (_destination != null) {
      newMarkers.add(
        Marker(
          point: _destination!,
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
    }

    // Update polylines
    if (_origin != null && _destination != null) {
      newPolylines.add(
        Polyline(
          points: [_origin!, _destination!],
          strokeWidth: 4,
          color: const Color(0xFFFC153b),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      _polylines.clear();
      _polylines.addAll(newPolylines);
    });
  }

  Future<void> _calculateFare() async {
    if (!mounted || _origin == null || _destination == null) {
      setState(() {
        _estimatedFare = 0.0;
        _isLoadingFare = false;
      });
      return;
    }

    setState(() {
      _isLoadingFare = true;
    });

    try {
      final distance = OSMService.getDistance(_origin!, _destination!);
      // Simple fare calculation: base fare + distance * rate
      const double baseFare = 100.0;
      const double ratePerKm = 25.0;
      const double minFare = 150.0;

      double fare = baseFare + (distance * ratePerKm);
      if (fare < minFare) fare = minFare;

      if (mounted) {
        setState(() {
          _estimatedFare = fare;
          _isLoadingFare = false;
        });
      }
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
        });
        _showError('Failed to calculate distance. Please try again.');
      }
    }
  }

  void _onPopularDestinationTap(Map<String, dynamic> destination) {
    if (!mounted) return;
    setState(() {
      _destination = LatLng(
        destination['latitude'] as double,
        destination['longitude'] as double,
      );
      final name = destination['name'] as String;
      _destinationText = 'To: $name';
      _destinationController.text = name;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateMapMarkers();
        _updateMapCamera();
      }
    });
    if (_origin != null && _destination != null) {
      _calculateFare();
    }
  }

  void _onFindRide() {
    if (!mounted) return;

    // Validate locations
    if (_origin == null || _destination == null) {
      _showError('Please select both origin and destination.');
      return;
    }

    // Use calculated fare or default
    final fareToUse = _estimatedFare > 0 ? _estimatedFare : 550.0;
    final driver =
        _driverProfiles[_driverProfileIndex % _driverProfiles.length];
    _driverProfileIndex = (_driverProfileIndex + 1) % _driverProfiles.length;
    final generatedRideId = IdUtils.generateRideId();
    const userId = 'passenger_demo_user';

    // Navigate to ride booking screen immediately
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideBookingScreen(
          pickupLocation: _origin!,
          dropoffLocation: _destination!,
          pickupAddress: _originText.replaceAll('From: ', ''),
          dropoffAddress: _destinationText.replaceAll('To: ', ''),
          estimatedFare: fareToUse,
          rideId: generatedRideId,
          driverId: driver.id,
          driverName: driver.name,
          driverPhone: driver.phone,
          userId: userId,
          initialDriverLocation: driver.initialPosition,
          driverAvatarAsset: driver.avatarAsset,
          driverRating: driver.rating,
          driverTrips: driver.seats,
          vehicleModel: driver.vehicleModel,
          vehicleColor: driver.vehicleColor,
          vehiclePlate: driver.vehiclePlate,
          initialEta: driver.initialEta,
        ),
      ),
    ).then((rideResult) async {
      if (!mounted) return;

      if (rideResult != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RideConfirmedScreen(driverDetails: rideResult),
          ),
        );
      }

      _calculateFare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final _ResponsiveMetrics metrics = _ResponsiveMetrics.fromContext(context);
    final screenWidth = metrics.screenWidth;
    final screenHeight = metrics.screenHeight;
    final horizontalPadding = metrics.horizontalPadding;
    final fontSizeTitle = metrics.fontSizeTitle;
    final fontSizeBody = metrics.fontSizeBody;
    final fontSizeButton = metrics.fontSizeButton;
    final buttonHeight = metrics.buttonHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header - Extends to top
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: metrics.headerBottomPadding,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            decoration: const BoxDecoration(color: Color(0xFFFC153b)),
            child: Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiderProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'Assets/icons/women1.jpeg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: Color(0xFFFC153b),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                // Title (centered)
                Expanded(
                  child: Center(
                    child: Text(
                      'Home',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                // Notification Icon
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Map Section
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // OpenStreetMap - fills entire Stack
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _origin ?? const LatLng(24.8607, 67.0011),
                    initialZoom: 12.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onMapReady: () {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _updateMapCamera();
                          _updateMapMarkers();
                        }
                      });
                    },
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

                // Ride Input Card (overlaying map at bottom)
                Positioned(
                  bottom: screenHeight * 0.02,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: Container(
                    padding: EdgeInsets.all(horizontalPadding * 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Origin Field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _originController,
                                keyboardType: TextInputType.streetAddress,
                                textInputAction: TextInputAction.search,
                                onTap: () {
                                  _originController.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: _originController.text.length,
                                  );
                                },
                                onSubmitted: (value) =>
                                    _handleManualLocationSearch(
                                      isOrigin: true,
                                      query: value,
                                    ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: _originText,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Use current location',
                              icon: const Icon(
                                Icons.my_location,
                                color: Color(0xFFFC153b),
                              ),
                              onPressed: _useCurrentLocation,
                            ),
                            IconButton(
                              tooltip: 'Browse saved locations',
                              icon: const Icon(
                                Icons.list_alt,
                                color: Color(0xFFFC153b),
                              ),
                              onPressed: _selectOrigin,
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey[300], height: 1),
                        // Destination Field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _destinationController,
                                keyboardType: TextInputType.streetAddress,
                                textInputAction: TextInputAction.search,
                                onTap: () {
                                  _destinationController.selection =
                                      TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _destinationController.text.length,
                                      );
                                },
                                onSubmitted: (value) =>
                                    _handleManualLocationSearch(
                                      isOrigin: false,
                                      query: value,
                                    ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'To: Enter destination',
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Color(0xFFFC153b),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Browse saved destinations',
                              icon: const Icon(
                                Icons.list_alt,
                                color: Color(0xFFFC153b),
                              ),
                              onPressed: _selectDestination,
                            ),
                          ],
                        ),
                        SizedBox(height: metrics.cardFieldSpacing),
                        // Find Ride Button
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight * 0.85,
                          child: ElevatedButton(
                            onPressed: _onFindRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC153b),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Find Ride',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeButton,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
          ),

          SizedBox(height: metrics.sectionSpacingLarge),

          // Estimated Fare Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding * 0.7,
              vertical: horizontalPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Estimated Fare',
                      style: GoogleFonts.inter(
                        fontSize: fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFC153b),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.004),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: const Color(0xFFFC153b),
                          size: 20,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        _isLoadingFare
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFFC153b),
                                  ),
                                ),
                              )
                            : Text(
                                _estimatedFare > 0
                                    ? '${_estimatedFare.toStringAsFixed(0)} PKR'
                                    : '-- PKR',
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
                const Spacer(),
                Text(
                  'Tap for details',
                  style: GoogleFonts.inter(
                    fontSize: fontSizeBody * 0.85,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: metrics.sectionSpacingSmall),

          // Popular Destinations Section
          SizedBox(
            height: screenHeight * 0.15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'Popular Destinations',
                    style: GoogleFonts.inter(
                      fontSize: fontSizeTitle * 0.9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: metrics.sectionSpacingTiny),
                Expanded(
                  child: ListView.builder(
                    controller: _popularDestinationsScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    itemCount: _popularDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = _popularDestinations[index];
                      return _buildPopularDestinationCard(
                        destination,
                        screenWidth,
                        screenHeight,
                        fontSizeBody,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: metrics.sectionSpacingTiny),

          // Bottom Navigation Bar
          Container(
            padding: EdgeInsets.only(
              top: screenHeight * 0.01,
              bottom:
                  MediaQuery.of(context).padding.bottom + screenHeight * 0.008,
              left: horizontalPadding * 0.5,
              right: horizontalPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0, screenWidth, fontSizeBody),
                _buildNavItem(
                  Icons.account_balance_wallet,
                  'Wallet',
                  1,
                  screenWidth,
                  fontSizeBody,
                ),
                _buildNavItem(
                  Icons.person,
                  'Profile',
                  2,
                  screenWidth,
                  fontSizeBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    double screenWidth,
    double fontSizeBody,
  ) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 1) {
            setState(() => _selectedIndex = index);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
            ).then((_) {
              if (mounted) {
                setState(() => _selectedIndex = 0);
              }
            });
            return;
          }
          if (index == 2) {
            setState(() => _selectedIndex = index);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiderProfileScreen()),
            ).then((_) {
              if (mounted) {
                setState(() => _selectedIndex = 0);
              }
            });
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFC153b) : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: screenWidth * 0.006),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSizeBody * 0.85,
                color: isSelected ? const Color(0xFFFC153b) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularDestinationCard(
    Map<String, dynamic> destination,
    double screenWidth,
    double screenHeight,
    double fontSizeBody,
  ) {
    return InkWell(
      onTap: () => _onPopularDestinationTap(destination),
      child: Container(
        width: screenWidth * 0.35,
        height: screenHeight * 0.08,
        margin: EdgeInsets.only(right: screenWidth * 0.025),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink[300]!, Colors.purple[300]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background decoration
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    destination['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: fontSizeBody * 0.9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveMetrics {
  _ResponsiveMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.horizontalPadding,
    required this.fontSizeTitle,
    required this.fontSizeBody,
    required this.fontSizeButton,
    required this.buttonHeight,
    required this.headerBottomPadding,
    required this.sectionSpacingLarge,
    required this.sectionSpacingSmall,
    required this.sectionSpacingTiny,
    required this.cardFieldSpacing,
  });

  final double screenWidth;
  final double screenHeight;
  final double horizontalPadding;
  final double fontSizeTitle;
  final double fontSizeBody;
  final double fontSizeButton;
  final double buttonHeight;
  final double headerBottomPadding;
  final double sectionSpacingLarge;
  final double sectionSpacingSmall;
  final double sectionSpacingTiny;
  final double cardFieldSpacing;

  static _ResponsiveMetrics fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    double scale(double min, double ideal, double max) {
      return (width * ideal).clamp(min, max);
    }

    return _ResponsiveMetrics(
      screenWidth: width,
      screenHeight: height,
      horizontalPadding: (width * 0.06).clamp(16.0, 30.0),
      fontSizeTitle: (width * 0.045).clamp(16.0, 22.0),
      fontSizeBody: (width * 0.038).clamp(13.0, 18.0),
      fontSizeButton: (width * 0.042).clamp(15.0, 20.0),
      buttonHeight: (height * 0.065).clamp(48.0, 64.0),
      headerBottomPadding: (height * 0.008).clamp(6.0, 20.0),
      sectionSpacingLarge: (height * 0.04).clamp(16.0, 48.0),
      sectionSpacingSmall: (height * 0.02).clamp(10.0, 32.0),
      sectionSpacingTiny: (height * 0.01).clamp(6.0, 20.0),
      cardFieldSpacing: scale(10, 0.012, 24),
    );
  }
}

// Destination Search Dialog
class _DestinationSearchDialog extends StatefulWidget {
  final bool isOrigin;

  const _DestinationSearchDialog({this.isOrigin = false});

  @override
  State<_DestinationSearchDialog> createState() =>
      _DestinationSearchDialogState();
}

class _DestinationSearchDialogState extends State<_DestinationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 3) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await OSMService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching places: $e');
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSizeBody = (screenWidth * 0.038).clamp(14.0, 16.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.isOrigin
                    ? 'Search origin location...'
                    : 'Search destination...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          if (mounted) {
                            setState(() {
                              _searchResults = [];
                            });
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchPlaces(value);
              },
              style: GoogleFonts.inter(fontSize: fontSizeBody),
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFC153b),
                        ),
                      ),
                    )
                  : _searchController.text.length < 3
                  ? Center(
                      child: Text(
                        'Type at least 3 characters to search',
                        style: GoogleFonts.inter(
                          fontSize: fontSizeBody,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: GoogleFonts.inter(
                          fontSize: fontSizeBody,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFFFC153b),
                          ),
                          title: Text(
                            result['mainText'] ?? result['description'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            result['secondaryText'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody * 0.9,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              'placeId': result['placeId'],
                              'description': result['description'],
                              'mainText': result['mainText'],
                              'secondaryText': result['secondaryText'],
                              'latitude': result['latitude'],
                              'longitude': result['longitude'],
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.seats,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.avatarAsset,
    required this.initialEta,
    required this.initialPosition,
  });

  final String id;
  final String name;
  final String phone;
  final String rating;
  final String seats;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String avatarAsset;
  final String initialEta;
  final LatLng initialPosition;
}
