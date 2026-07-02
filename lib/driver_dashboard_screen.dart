import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:musafirah_app/services/osm_service.dart';
import 'driver_ride_requests_screen.dart';
import 'driver_active_rides_screen.dart'; // Added
import 'driver_wallet_screen.dart';
import 'driver_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musafirah_app/services/notification_service.dart';
import 'user_pending_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(24.8607, 67.0011); // Default Karachi
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  List<LatLng> _routePoints = [];
  List<_RecentTrip> _recentTrips = [];

  final TextEditingController _startLocationController =
      TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();
  final FocusNode _startFocus = FocusNode();
  final FocusNode _dropOffFocus = FocusNode();
  bool _activeFieldIsPickup = true;
  bool _mapReady = false;

  Timer? _debounce;
  int _selectedIndex = 0;

  // Search State
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String _driverStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _startLocationController.text = "Detecting Location...";
    _fetchDriverData();
    _getCurrentLocation();
    _primeRecentTrips();
    
    // Start global background listeners for notifications
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      NotificationService.startGlobalListeners(uid: user.uid, role: 'driver', lat: 24.8607, lng: 67.0011);
    }

    // Listen to focus to toggle search state if needed
    _startFocus.addListener(_onFocusChange);
    _dropOffFocus.addListener(_onFocusChange);
  }

  Future<void> _fetchDriverData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService.getUserData(user.uid, 'Drivers');
      if (userData != null && mounted) {
        setState(() {
          _driverStatus = userData['status'] ?? 'pending';
        });

        final isBlocked = userData['isBlocked'] == true;
        if (isBlocked) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserPendingScreen(
                status: 'blocked',
                collection: 'Drivers',
              ),
            ),
          );
        } else if (_driverStatus != 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserPendingScreen(
                status: _driverStatus,
                collection: 'Drivers',
              ),
            ),
          );
        }
      } else if (mounted) {
        // Handle case where user data is not found if necessary
      }
    }
  }

  void _onFocusChange() {
    // Track which field is active for search context
    setState(() {
      if (_startFocus.hasFocus) _activeFieldIsPickup = true;
      if (_dropOffFocus.hasFocus) _activeFieldIsPickup = false;
    });
  }

  Future<void> _primeRecentTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final rides = await DatabaseService.getDriverRides(user.uid);
      if (!mounted) return;

      setState(() {
        _recentTrips = rides.take(8).map((ride) {
          final pLabel = ride['pickupAddress'] ?? ride['originAddress'] ?? 'Unknown';
          final dLabel = ride['dropoffAddress'] ?? ride['destinationAddress'] ?? 'Unknown';
          return _RecentTrip(
            pickupLabel: pLabel,
            dropoffLabel: dLabel,
            pickup: LatLng(
              (ride['pickupLat'] ?? ride['originLat'] ?? 0.0).toDouble(),
              (ride['pickupLng'] ?? ride['originLng'] ?? 0.0).toDouble(),
            ),
            dropoff: LatLng(
              (ride['dropoffLat'] ?? ride['destinationLat'] ?? 0.0).toDouble(),
              (ride['dropoffLng'] ?? ride['destinationLng'] ?? 0.0).toDouble(),
            ),
            timestamp: (ride['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Error priming recent trips: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _pickupLocation ??= _currentLocation;
        });

        // 1. Move map immediately
        if (_mapReady) {
          _mapController.move(_currentLocation, 15.0);
        }

        // 2. Resolve Address (Reverse Geocoding)
        if (_startLocationController.text == "Detecting Location..." ||
            _startLocationController.text.isEmpty ||
            _startLocationController.text == "Current Location") {
          try {
            final String? address = await OSMService.getPlaceName(
              _currentLocation,
            );
            if (mounted && address != null) {
              setState(() {
                _startLocationController.text = address;
              });
            } else if (mounted) {
              setState(() {
                _startLocationController.text = "Current Location";
              });
            }
          } catch (e) {
            debugPrint("Error resolving address: $e");
            if (mounted) {
              setState(() {
                _startLocationController.text = "Current Location";
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to default location which is already set in initialization
      if (mounted) {
        setState(() {
          if (_startLocationController.text == "Detecting Location...") {
            _startLocationController.text = "Karachi (Default)";
          }
        });
      }
    }
  }

  // --- Real Location Search (Nominatim via OSMService) ---
  void _onSearchChanged(String query, {required bool isPickup}) {
    _activeFieldIsPickup = isPickup;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await OSMService.searchPlaces(trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (e) {
        debugPrint("Error fetching places: $e");
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  // --- Real Routing (OSRM) ---
  Future<void> _getRealRoute(LatLng start, LatLng end) async {
    // Clear previous
    setState(() => _routePoints = []);

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
          });

          // Fit bounds
          if (_mapReady) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(80), // More padding
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
      setState(() {
        _routePoints = [start, end]; // Fallback
      });
    }
  }

  void _syncRoute() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      _getRealRoute(_pickupLocation!, _dropoffLocation!);
    } else if (_pickupLocation != null && _mapReady) {
      setState(() => _routePoints = []);
      _mapController.move(_pickupLocation!, 15.0);
    }
  }

  void _addToRecentTrips({
    required String pickupLabel,
    required String dropoffLabel,
    required LatLng pickup,
    required LatLng dropoff,
  }) {
    final entry = _RecentTrip(
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      pickup: pickup,
      dropoff: dropoff,
      timestamp: DateTime.now(),
    );

    setState(() {
      _recentTrips.removeWhere(
        (trip) =>
            trip.pickupLabel == pickupLabel &&
            trip.dropoffLabel == dropoffLabel,
      );
      _recentTrips.insert(0, entry);
      if (_recentTrips.length > 8) {
        _recentTrips = _recentTrips.take(8).toList();
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _onFindRidePressed() async {
    final pickup = _pickupLocation;
    final dropoff = _dropoffLocation;
    if (pickup == null || dropoff == null) {
      _showSnack("Please select both start and end locations.");
      return;
    }

    final pickupLabel = _startLocationController.text.trim().isNotEmpty
        ? _startLocationController.text.trim()
        : "Start";
    final dropoffLabel = _dropOffController.text.trim().isNotEmpty
        ? _dropOffController.text.trim()
        : "Destination";

    _addToRecentTrips(
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      pickup: pickup,
      dropoff: dropoff,
    );

    // BROADCAST TRIP TO FIRESTORE
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Map route points to simple double maps for Firestore
      final List<Map<String, double>> mappedRoute = _routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      await DatabaseService.updateDriverTrip(
        uid: user.uid,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        pickupAddress: pickupLabel,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        dropoffAddress: dropoffLabel,
        routePoints: mappedRoute,
        isOnline: true,
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRideRequestsScreen(
          driverPickup: pickup,
          driverDropoff: dropoff,
          driverPickupAddress: pickupLabel,
          driverDropoffAddress: dropoffLabel,
          routePoints: _routePoints,
        ),
      ),
    );
  }

  void _onPlaceSelected(Map<String, dynamic> place, {required bool isPickup}) {
    final double? lat = place['latitude'] as double?;
    final double? lng = place['longitude'] as double?;
    if (lat == null || lng == null) return;

    final label =
        (place['mainText'] ??
                place['description'] ??
                place['full_name'] ??
                place['name'] ??
                'Selected Location')
            .toString();
    final selected = LatLng(lat, lng);

    setState(() {
      if (isPickup) {
        _pickupLocation = selected;
        _startLocationController.text = label;
      } else {
        _dropoffLocation = selected;
        _dropOffController.text = label;
      }

      // Reset Search State
      _isSearching = false;
      _searchResults = [];
    });

    FocusScope.of(context).unfocus();
    _syncRoute();
  }

  void _recenter() {
    if (_mapReady) {
      _mapController.move(_pickupLocation ?? _currentLocation, 15.0);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _startLocationController.dispose();
    _dropOffController.dispose();
    _startFocus.dispose();
    _dropOffFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0: HOME (The Map & Search Stack)
          Stack(
            children: [
              // 1. OpenStreetMap Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  onMapReady: () {
                    _mapReady = true;
                    if (_pickupLocation != null) {
                      _mapController.move(_pickupLocation!, 15.0);
                    }
                  },
                  initialCenter: _pickupLocation ?? _currentLocation,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.musafirah.app',
                  ),
                  // Real Curved Route Polyline
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: const Color(0xFFFC153b),
                        ),
                      ],
                    ),
                  // Markers
                  MarkerLayer(
                    markers: [
                      if (_pickupLocation != null)
                        Marker(
                          point: _pickupLocation!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.directions_car,
                            color: Color(0xFFFC153b),
                            size: 40,
                          ),
                        )
                      else
                        Marker(
                          point: _currentLocation,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.directions_car,
                            color: Color(0xFFFC153b),
                            size: 40,
                          ),
                        ),
                      if (_dropoffLocation != null)
                        Marker(
                          point: _dropoffLocation!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 45,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // 2. Floating Search Island (Improved)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PICKUP
                        Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Color(0xFFFC153b),
                                ),
                                Container(
                                  width: 2,
                                  height: 35,
                                  color: Colors.grey[200],
                                ),
                              ],
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pickup",
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextField(
                                    controller: _startLocationController,
                                    focusNode: _startFocus,
                                    onTap: () => _activeFieldIsPickup = true,
                                    onChanged: (value) =>
                                        _onSearchChanged(value, isPickup: true),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                      hintText: "Current Location",
                                      hintStyle: GoogleFonts.outfit(
                                        color: Colors.black87,
                                      ),
                                      suffixIcon:
                                          _startLocationController
                                              .text
                                              .isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                _startLocationController
                                                    .clear();
                                                setState(() {
                                                  _pickupLocation = null;
                                                  _routePoints = [];
                                                  _searchResults = [];
                                                  _isSearching = false;
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        // DROPOFF
                        Row(
                          children: [
                            const Icon(
                              Icons.square,
                              size: 12,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _dropOffController,
                                    focusNode: _dropOffFocus,
                                    onTap: () => _activeFieldIsPickup = false,
                                    onChanged: (value) => _onSearchChanged(
                                      value,
                                      isPickup: false,
                                    ),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                      hintText: "Where to?",
                                      hintStyle: GoogleFonts.outfit(
                                        color: Colors.grey[400],
                                      ),
                                      suffixIcon:
                                          _dropOffController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                _dropOffController.clear();
                                                setState(() {
                                                  _dropoffLocation = null;
                                                  _routePoints = [];
                                                  _searchResults = [];
                                                  _isSearching = false;
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Inline search suggestions
              if (_searchResults.isNotEmpty)
                Positioned(
                  top: 150,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFFC153b),
                            ),
                            title: Text(
                              place['mainText'] ??
                                  place['description'] ??
                                  'Location',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              place['secondaryText'] ??
                                  place['description'] ??
                                  '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              final isPickup =
                                  _startFocus.hasFocus || _activeFieldIsPickup;
                              _onPlaceSelected(place, isPickup: isPickup);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Recenter Button
              Positioned(
                right: 20,
                bottom:
                    (_isSearching ||
                        _startFocus.hasFocus ||
                        _dropOffFocus.hasFocus)
                    ? 350
                    : 350,
                child: FloatingActionButton(
                  heroTag: "recenter",
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ),

              // 3. Unified Bottom Sheet (Find Rides + List)
              DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // FIND RIDE BUTTON
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFC153b), Color(0xFFFF5252)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFC153b,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _onFindRidePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Find Rides",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        if (_searchResults.isNotEmpty || _recentTrips.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _searchResults.isNotEmpty
                                  ? "Search Results"
                                  : "Recent Trips",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_searchResults.isNotEmpty)
                            ..._searchResults.map(
                              (place) => _buildLocationItem(
                                title:
                                    place['mainText'] ??
                                    place['description'] ??
                                    'Location',
                                subtitle:
                                    place['secondaryText'] ??
                                    place['description'] ??
                                    '',
                                onTap: () {
                                  final isPickup =
                                      _startFocus.hasFocus ||
                                      _activeFieldIsPickup;
                                  _onPlaceSelected(place, isPickup: isPickup);
                                },
                              ),
                            )
                          else
                            ..._recentTrips.map((trip) {
                              return _buildRecentTripItem(
                                pickup: trip.pickupLabel,
                                dropoff: trip.dropoffLabel,
                                onTap: () {
                                  setState(() {
                                    _pickupLocation = trip.pickup;
                                    _dropoffLocation = trip.dropoff;
                                    _startLocationController.text =
                                        trip.pickupLabel;
                                    _dropOffController.text = trip.dropoffLabel;
                                    _isSearching = false;
                                    _searchResults = [];
                                  });
                                  _syncRoute();
                                },
                              );
                            }),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // 1: MY RIDES
          DriverActiveRidesScreen(),

          // 2: WALLET
          const DriverWalletScreen(),

          // 3: PROFILE
          const DriverProfileScreen(),
        ],
      ),

      // 4. Bottom Nav Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(
                  1,
                  Icons.directions_car_filled_rounded,
                  "My Rides",
                ),
                _buildNavItem(2, Icons.receipt_long_rounded, "Payments"),
                _buildNavItem(3, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isRecent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isRecent ? Icons.history : Icons.location_on_outlined,
            color: isRecent ? Colors.grey : const Color(0xFFFC153b),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentTripItem({
    required String pickup,
    required String dropoff,
    required VoidCallback onTap,
  }) {
    // Extract short name: first meaningful part before the first comma
    String short(String full) {
      final parts = full.split(',');
      return parts.isNotEmpty ? parts[0].trim() : full;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: icon column
            Column(
              children: [
                const Icon(Icons.circle, size: 10, color: Color(0xFFFC153B)),
                Container(
                  width: 1.5,
                  height: 26,
                  color: Colors.grey.shade300,
                ),
                const Icon(Icons.square, size: 10, color: Colors.black87),
              ],
            ),
            const SizedBox(width: 12),
            // Right: pickup + destination
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup
                  Text(
                    'Pickup',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    short(pickup),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Destination
                  Text(
                    'Destination',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    short(dropoff),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC153b).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFC153b) : Colors.grey,
              size: 26,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFC153b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTrip {
  const _RecentTrip({
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.pickup,
    required this.dropoff,
    required this.timestamp,
  });

  final String pickupLabel;
  final String dropoffLabel;
  final LatLng pickup;
  final LatLng dropoff;
  final DateTime timestamp;
}
