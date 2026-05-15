import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:musafirah_app/services/osm_service.dart';
import 'package:musafirah_app/ride_confirmed_screen.dart';
import 'passenger_ride_selection_screen.dart';
import 'package:musafirah_app/wallet_history_screen.dart';
import 'package:musafirah_app/rider_profile_screen.dart';
import 'package:musafirah_app/passenger_live_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/services/recent_destinations_service.dart';
import 'package:musafirah_app/screens/notifications_screen.dart';
import 'user_pending_screen.dart';

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
  List<LatLng> _routePoints = [];

  List<Map<String, dynamic>> _popularDestinations = [];
  List<Map<String, dynamic>> _recentDestinations = [];
  final ScrollController _popularDestinationsScrollController =
      ScrollController();

  Map<String, dynamic>? _activeRideDetails;
  String _userName = 'Customer';
  String _userStatus = 'pending';
  String _profileImageStr = '';   // base64 data URI or https URL
  bool _isFindingRide = false; // guard against double-tapping "Find Ride"

  @override
  void initState() {
    super.initState();
    _originController.text = _stripPrefix(_originText, 'From: ');
    _destinationController.text = _stripPrefix(_destinationText, 'To: ');
    // Delay location fetch until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
      _getCurrentLocation();
      _loadPopularDestinations();
      _loadRecentDestinations();
    });
  }

  Future<void> _loadRecentDestinations() async {
    final recents = await RecentDestinationsService.getAll();
    if (mounted) setState(() => _recentDestinations = recents);
  }

  Widget _buildDashboardAvatar() {
    final img = _profileImageStr;
    if (img.isEmpty) {
      return const Icon(Icons.person_rounded, size: 22, color: Colors.white);
    }
    if (img.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(img.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person_rounded, size: 22, color: Colors.white));
      } catch (_) {
        return const Icon(Icons.person_rounded, size: 22, color: Colors.white);
      }
    }
    return Image.network(img, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person_rounded, size: 22, color: Colors.white));
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService.getUserData(user.uid, 'Passengers');
      if (userData != null && mounted) {
        // prefer manually-set profileImageUrl, fall back to registration selfie
        final profileUrl =
            (userData['profileImageUrl'] as String?)?.isNotEmpty == true
                ? userData['profileImageUrl'] as String
                : (userData['image_selfie'] as String?) ?? '';
        setState(() {
          _userName = userData['name'] ?? 'Customer';
          _userStatus = userData['status'] ?? 'pending';
          _profileImageStr = profileUrl;
        });

        final isBlocked = userData['isBlocked'] == true;
        if (isBlocked) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserPendingScreen(
              status: 'blocked',
              collection: 'Passengers',
            )),
          );
        } else if (_userStatus != 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserPendingScreen(
              status: _userStatus,
              collection: 'Passengers',
            )),
          );
        }
      } else if (mounted) {
        // Handle case where user data is not found if necessary
      }
    }
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

  Future<void> _getRealRoute(LatLng start, LatLng end) async {
    if (!mounted) return;
    setState(() => _routePoints = []);

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'MusafirahApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords =
              data['routes'][0]['geometry']['coordinates'] as List;
          if (mounted) {
            setState(() {
              _routePoints =
                  coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    }

    // Fallback to straight line if OSRM fails
    if (mounted) setState(() => _routePoints = [start, end]);
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


  String _stripPrefix(String value, String prefix) {
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length).trim();
    }
    return value;
  }

  void _updateMapMarkers() {
    if (!mounted) return;

    final newMarkers = <Marker>[];

    if (_origin != null) {
      newMarkers.add(
        Marker(
          point: _origin!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 22),
          ),
        ),
      );
    }

    if (_destination != null) {
      newMarkers.add(
        Marker(
          point: _destination!,
          width: 44,
          height: 52,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC153b),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 18),
              ),
              Container(
                width: 3,
                height: 10,
                color: const Color(0xFFFC153b),
              ),
            ],
          ),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      // Clear old route when markers change; real route fetched below
      if (_origin == null || _destination == null) {
        _routePoints = [];
        _polylines.clear();
      }
    });

    // Fetch real road route when both points are set
    if (_origin != null && _destination != null) {
      _getRealRoute(_origin!, _destination!);
    }
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

  void _onFindRide() async {
    if (!mounted) return;
    if (_isFindingRide) return; // prevent double-tap creating duplicate requests

    // Validate locations
    if (_origin == null || _destination == null) {
      _showError('Please select both origin and destination.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in to find a ride.');
      return;
    }

    setState(() => _isFindingRide = true);

    // Use calculated fare or default
    final fareToUse = _estimatedFare > 0 ? _estimatedFare : 550.0;
    
    // Broadcast the request to Firestore
    final result = await DatabaseService.createRideRequest(
      uid: user.uid,
      passengerName: _userName,
      pickupLat: _origin!.latitude,
      pickupLng: _origin!.longitude,
      pickupAddress: _originText.replaceAll('From: ', ''),
      dropoffLat: _destination!.latitude,
      dropoffLng: _destination!.longitude,
      dropoffAddress: _destinationText.replaceAll('To: ', ''),
      fare: fareToUse,
    );

    if (result.startsWith('Error:')) {
      _showError('Failed to broadcast ride: $result');
      if (mounted) setState(() => _isFindingRide = false);
      return;
    }

    final rideId = result;

    // Save destination to recent destinations
    await RecentDestinationsService.save(
      address: _destinationText.replaceAll('To: ', ''),
      lat: _destination!.latitude,
      lng: _destination!.longitude,
    );

    // Navigate to ride selection screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerRideSelectionScreen(
          pickupLocation: _origin!,
          dropoffLocation: _destination!,
          pickupAddress: _originText.replaceAll('From: ', ''),
          dropoffAddress: _destinationText.replaceAll('To: ', ''),
          estimatedFare: fareToUse,
          userId: user.uid,
          rideId: rideId,
          passengerName: _userName,
          passengerImageUrl: _profileImageStr,
        ),
      ),
    ).then((rideResult) async {
      if (!mounted) return;
      setState(() => _isFindingRide = false); // allow finding a new ride

      if (rideResult != null) {
        setState(() {
          _activeRideDetails = rideResult;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RideConfirmedScreen(driverDetails: rideResult),
          ),
        );
      }

      _calculateFare();
      _loadRecentDestinations(); // refresh recently used list
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header - Extends to top
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 16,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFC153b), Color(0xFFD4002A)],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RiderProfileScreen())),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                      ),
                      child: ClipOval(child: _buildDashboardAvatar()),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good day, $_userName 👋',
                            style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w400)),
                        Text('Where to today?',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .snapshots()
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data?.docs.length ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[700], // Using yellow to stand out against the red header
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFC153b), width: 1.5),
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Map Section
            SizedBox(
              height: screenHeight * 0.45,
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
                    // Google Maps–style route: white border underneath, colored line on top
                    if (_routePoints.length >= 2) ...[
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 6,
                            color: const Color(0xFFFC153b),
                          ),
                        ],
                      ),
                    ],
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Ride Input Card or Active Ride Card
                _activeRideDetails != null
                    ? Positioned(
                        bottom: screenHeight * 0.02,
                        left: horizontalPadding,
                        right: horizontalPadding,
                        child: Container(
                          padding: EdgeInsets.all(horizontalPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFC153b).withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFC153b,
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFFFC153b),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ride in Progress",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: const Color(0xFFFC153b),
                                          ),
                                        ),
                                        Text(
                                          "${_activeRideDetails!['driverName']} is arriving",
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PassengerLiveTrackingScreen(
                                              rideId:
                                                  _activeRideDetails!['rideId'] ??
                                                  '',
                                              driverName:
                                                  _activeRideDetails!['driverName'] ??
                                                  '',
                                              driverId:
                                                  _activeRideDetails!['driverId'] ??
                                                  '',
                                              driverPhone:
                                                  _activeRideDetails!['driverPhone'] ??
                                                  '',
                                              userId:
                                                  _activeRideDetails!['userId'] ??
                                                  '',
                                              initialDriverPosition:
                                                  _activeRideDetails!['initialDriverPosition'],
                                              dropoffPosition:
                                                  _activeRideDetails!['dropoffPosition'],
                                              initialPassengerPosition:
                                                  _activeRideDetails!['passengerPosition'],
                                              driverAvatarAsset:
                                                  _activeRideDetails!['driverAvatarAsset'] ??
                                                  '',
                                              pickupAddress:
                                                  _activeRideDetails!['pickupAddress'] ??
                                                  '',
                                              dropoffAddress:
                                                  _activeRideDetails!['dropoffAddress'] ??
                                                  '',
                                              initialEta:
                                                  _activeRideDetails!['eta'] ??
                                                  '',
                                              rideFare:
                                                  _activeRideDetails!['fare'] ??
                                                  0.0,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFC153b,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Track Ride",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _activeRideDetails = null;
                                        _originController.clear();
                                        _destinationController.clear();
                                        _origin = null;
                                        _destination = null;
                                        _markers.clear();
                                        _polylines.clear();
                                        _routePoints = [];
                                        _estimatedFare = 0.0;
                                      });
                                    },
                                    child: Text(
                                      "End",
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Positioned(
                        bottom: screenHeight * 0.018,
                        left: horizontalPadding,
                        right: horizontalPadding,
                        child: Container(
                          padding: EdgeInsets.all(horizontalPadding * 0.85),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Route connector + fields
                              Row(
                                children: [
                                  // Dot connector column
                                  Column(
                                    children: [
                                      Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.green[500],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 2, height: 28,
                                        color: Colors.grey[200],
                                      ),
                                      Container(
                                        width: 10, height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFC153b),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Fields
                                  Expanded(
                                    child: Column(
                                      children: [
                                        // Origin
                                        GestureDetector(
                                          onTap: _selectOrigin,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8F9FA),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _originController.text.isEmpty
                                                        ? 'Current location'
                                                        : _originController.text,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: fontSizeBody,
                                                      color: _originController.text.isEmpty
                                                          ? Colors.grey[400]
                                                          : const Color(0xFF0F172A),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _useCurrentLocation,
                                                  child: const Icon(Icons.my_location_rounded,
                                                      color: Color(0xFFFC153b), size: 18),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Destination
                                        GestureDetector(
                                          onTap: _selectDestination,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8F9FA),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _destinationController.text.isEmpty
                                                        ? 'Where are you going?'
                                                        : _destinationController.text,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: fontSizeBody,
                                                      color: _destinationController.text.isEmpty
                                                          ? Colors.grey[400]
                                                          : const Color(0xFF0F172A),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(Icons.search_rounded,
                                                    color: Color(0xFFFC153b), size: 18),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (_estimatedFare > 0 || _isLoadingFare) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFC153b).withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.monetization_on_rounded,
                                          color: Color(0xFFFC153b), size: 16),
                                      const SizedBox(width: 6),
                                      Text('Estimated fare',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                      const Spacer(),
                                      _isLoadingFare
                                          ? const SizedBox(
                                              width: 14, height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFFC153b),
                                              ))
                                          : Text(
                                              'Rs ${_estimatedFare.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFFFC153b))),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              // Find Ride Button
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight * 0.85,
                                child: ElevatedButton(
                                  onPressed: _onFindRide,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFC153b),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions_car_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Find a Ride',
                                        style: GoogleFonts.outfit(
                                          fontSize: fontSizeButton,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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

          const SizedBox(height: 12),

          // Fare display placeholder kept for spacing when no fare
          if (_estimatedFare == 0 && !_isLoadingFare)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text('Select pickup & drop-off to see fare',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Recently Used Destinations Section
          if (_recentDestinations.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recently Used',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentDestinations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final dest = _recentDestinations[i];
                        final address = dest['address'] as String;
                        return GestureDetector(
                          onTap: () {
                            final lat = (dest['lat'] as num).toDouble();
                            final lng = (dest['lng'] as num).toDouble();
                            setState(() {
                              _destination = LatLng(lat, lng);
                              _destinationText = 'To: $address';
                              _destinationController.text = address;
                            });
                          },
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.history_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 17),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

          // Quick Destinations Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC153B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Destinations',
                      style: GoogleFonts.outfit(
                        fontSize: (fontSizeTitle * 0.82).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: (screenWidth / 2 - horizontalPadding - 5) /
                        (screenHeight * 0.075).clamp(62.0, 76.0),
                  ),
                  itemCount: _popularDestinations.length,
                  itemBuilder: (context, index) {
                    final destination = _popularDestinations[index];
                    return _buildPopularDestinationCard(
                        destination, screenWidth, screenHeight, fontSizeBody);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.history_rounded, 'History', 1),
                _buildNavItem(Icons.person_rounded, 'Profile', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFFFC153B);

    void onTap() {
      if (index == 1) {
        setState(() => _selectedIndex = index);
        Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletHistoryScreen()))
            .then((_) {
          if (mounted) setState(() => _selectedIndex = 0);
        });
        return;
      }
      if (index == 2) {
        setState(() => _selectedIndex = index);
        Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RiderProfileScreen()))
            .then((_) {
          if (mounted) setState(() => _selectedIndex = 0);
        });
        return;
      }
      setState(() => _selectedIndex = index);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  size: 24,
                  color: isSelected ? activeColor : const Color(0xFFB0BEC5),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFFB0BEC5),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Icons per destination — falls back to location_on
  static const Map<String, IconData> _destIcons = {
    'Clifton': Icons.beach_access_rounded,
    'DHA Phase 5': Icons.villa_rounded,
    'Gulshan-e-Iqbal': Icons.park_rounded,
    'North Nazimabad': Icons.location_city_rounded,
  };

  Widget _buildPopularDestinationCard(
    Map<String, dynamic> destination,
    double screenWidth,
    double screenHeight,
    double fontSizeBody,
  ) {
    final name = destination['name'] as String;
    final icon = _destIcons[name] ?? Icons.location_on_rounded;

    return GestureDetector(
      onTap: () => _onPopularDestinationTap(destination),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _onPopularDestinationTap(destination),
            borderRadius: BorderRadius.circular(14),
            splashColor: const Color(0xFFFC153B).withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFC153B), Color(0xFFFF6B8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: (fontSizeBody * 0.88).clamp(11.0, 13.0),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Karachi',
                          style: GoogleFonts.outfit(
                            fontSize: (fontSizeBody * 0.75).clamp(9.5, 11.0),
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
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
  String? _errorMessage;
  Timer? _debounce;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _errorMessage = null;
        });
      }
      return;
    }
    if (mounted) setState(() { _isSearching = true; _errorMessage = null; });
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(value);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 3) {
      if (!mounted) return;
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }

    final token = ++_searchToken;

    try {
      final results = await OSMService.searchPlaces(query);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error searching places: $e');
      if (!mounted || token != _searchToken) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
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
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.grey, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _searchPlaces(_searchController.text),
                              icon: const Icon(Icons.refresh, color: Color(0xFFFC153b)),
                              label: Text(
                                'Retry',
                                style: GoogleFonts.inter(color: const Color(0xFFFC153b)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _searchController.text.length < 3
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, color: Colors.grey[400], size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Type at least 3 characters to search',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off, color: Colors.grey[400], size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'No locations found for "${_searchController.text}"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different name or be more specific',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody * 0.85,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
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
                          subtitle: result['secondaryText']?.toString().isNotEmpty == true
                              ? Text(
                                  result['secondaryText'],
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody * 0.9,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : null,
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
