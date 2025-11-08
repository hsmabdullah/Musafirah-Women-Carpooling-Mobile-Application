// Passenger live tracking experience.
//
// Configuration notes (README excerpt)
// - Replace `_socketBaseUrl` and `_restBaseUrl` with your backend endpoints.
// - Update `_emergencyNumber` to your operations emergency hotline.
// - Ensure required packages are configured in `pubspec.yaml` and platform
//   manifests (location + internet permissions).

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:google_fonts/google_fonts.dart';

import 'passenger_chat_screen.dart';
import 'payment_screen.dart';

const String _socketBaseUrl = 'wss://api.example.com/rides';
const String _restBaseUrl = 'https://api.example.com/api/rides';
const String _emergencyNumber = '112';
const double _averageSpeedKmh = 28.0;

bool get _isDemoBackend =>
    _socketBaseUrl.contains('example.com') ||
    _restBaseUrl.contains('example.com');

enum ConnectionStatus { connecting, connected, reconnecting, failed }

class PassengerLiveTrackingScreen extends StatefulWidget {
  const PassengerLiveTrackingScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverId,
    this.driverPhone,
    this.userId,
    this.initialDriverPosition,
    this.dropoffPosition,
    this.initialEta,
    this.initialPassengerPosition,
    this.driverAvatarAsset,
    this.pickupAddress,
    this.dropoffAddress,
    this.rideFare,
  });

  final String rideId;
  final String driverName;
  final String? driverId;
  final String? driverPhone;
  final String? userId;
  final LatLng? initialDriverPosition;
  final LatLng? dropoffPosition;
  final String? initialEta;
  final LatLng? initialPassengerPosition;
  final String? driverAvatarAsset;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? rideFare;

  @override
  State<PassengerLiveTrackingScreen> createState() =>
      _PassengerLiveTrackingScreenState();
}

class _PassengerLiveTrackingScreenState
    extends State<PassengerLiveTrackingScreen> {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  Timer? _pollTimer;
  Timer? _passengerRefreshTimer;
  Timer? _debugTimer;

  LatLng? _driverLatLng;
  LatLng? _passengerLatLng;
  LatLng? _dropoffLatLng;

  List<Marker> _markers = const [];
  List<Polyline> _polylines = const [];

  bool _permissionDenied = false;
  bool _mapReady = false;
  bool _isSosSending = false;
  bool _isSosSent = false;
  bool _debugSimulate = false;

  ConnectionStatus _status = ConnectionStatus.connecting;
  String? _errorMessage;
  int _reconnectAttempts = 0;
  DateTime? _lastMapFit;
  String _etaText = '--';

  @override
  void initState() {
    super.initState();
    _driverLatLng = widget.initialDriverPosition;
    _dropoffLatLng = widget.dropoffPosition;
    _etaText = widget.initialEta ?? '--';
    _passengerLatLng = widget.initialPassengerPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.rideId.isEmpty) {
        _showSnack('Ride information missing.');
        Navigator.pop(context);
      } else {
        _initTracking();
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _channel?.sink.close(ws_status.normalClosure);
    _pollTimer?.cancel();
    _passengerRefreshTimer?.cancel();
    _debugTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTracking() async {
    await _ensurePermission();
    if (_permissionDenied) return;

    await _fetchPassengerLocation();
    _startPassengerRefresh();

    if (_isDemoBackend) {
      if (mounted) {
        setState(() {
          _status = ConnectionStatus.connected;
          _errorMessage = 'Demo mode active';
          _debugSimulate = true;
        });
      }
      _startDebugSimulation();
      return;
    }

    _connectSocket();
    if (_debugSimulate) {
      _startDebugSimulation();
    }
  }

  Future<void> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _fetchPassengerLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _passengerLatLng = LatLng(position.latitude, position.longitude);
      });
      _updateMarkersAndFit();
    } catch (e) {
      _log('Passenger location error: $e');
    }
  }

  void _startPassengerRefresh() {
    _passengerRefreshTimer?.cancel();
    _passengerRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_permissionDenied) {
        _fetchPassengerLocation();
      }
    });
  }

  Future<void> _connectSocket() async {
    _log('Opening websocket connection');
    _channel?.sink.close();
    _socketSubscription?.cancel();

    setState(() {
      _status = ConnectionStatus.connecting;
      _errorMessage = null;
    });

    final uri = Uri.parse('$_socketBaseUrl/${widget.rideId}/ws');
    try {
      _channel = WebSocketChannel.connect(uri);
      _socketSubscription = _channel!.stream.listen(
        (event) {
          _handleSocketMessage(event);
        },
        onError: (error) {
          _log('Socket error: $error');
          _handleSocketFailure();
        },
        onDone: () {
          _log('Socket closed');
          _handleSocketFailure();
        },
      );
      if (mounted) {
        setState(() => _status = ConnectionStatus.connected);
      }
      _pollTimer?.cancel();
    } catch (e) {
      _log('Socket connection failed: $e');
      _handleSocketFailure();
    }
  }

  void _handleSocketMessage(dynamic event) {
    _log('Socket message: $event');
    try {
      final data = event is String ? jsonDecode(event) : event as Map;
      final lat = (data['latitude'] ?? data['lat'])?.toDouble();
      final lng = (data['longitude'] ?? data['lng'])?.toDouble();
      if (lat == null || lng == null) return;
      if (!mounted) return;
      setState(() {
        _driverLatLng = LatLng(lat, lng);
        _status = ConnectionStatus.connected;
        _reconnectAttempts = 0;
        _errorMessage = null;
      });
      _updateEta();
      _updateMarkersAndFit();
    } catch (e) {
      _log('Parse error: $e');
    }
  }

  void _handleSocketFailure() {
    if (mounted) {
      setState(() {
        _status = ConnectionStatus.reconnecting;
        _errorMessage = 'Trying to reconnect…';
      });
    }
    _channel?.sink.close();
    _socketSubscription?.cancel();
    _pollLocation();
    final delaySeconds = min(30, pow(2, _reconnectAttempts + 1).toInt());
    _reconnectAttempts++;
    if (_reconnectAttempts > 5 && mounted) {
      setState(() {
        _status = ConnectionStatus.failed;
        _errorMessage = 'Unable to reach live tracking service.';
        _debugSimulate = true;
      });
      _startDebugSimulation();
      return;
    }
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (!mounted) return;
      _connectSocket();
    });
  }

  void _pollLocation() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final response = await http.get(
          Uri.parse('$_restBaseUrl/${widget.rideId}/location'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final lat = (data['latitude'] ?? data['lat'])?.toDouble();
          final lng = (data['longitude'] ?? data['lng'])?.toDouble();
          if (lat != null && lng != null) {
            if (!mounted) return;
            setState(() {
              _driverLatLng = LatLng(lat, lng);
              _status = ConnectionStatus.connected;
              _errorMessage = null;
            });
            _updateEta();
            _updateMarkersAndFit();
          }
        }
      } catch (e) {
        _log('Polling error: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Network issue. Retrying…';
            _status = ConnectionStatus.reconnecting;
          });
        }
      }
    });
  }

  void _updateMarkersAndFit() {
    if (!_mapReady) return;

    final markers = <Marker>[];
    final points = <LatLng>[];

    if (_driverLatLng != null) {
      markers.add(
        Marker(
          point: _driverLatLng!,
          width: 44,
          height: 44,
          child: Image.asset('Assets/icons/car.png', width: 44, height: 44),
        ),
      );
      points.add(_driverLatLng!);
    }

    if (_passengerLatLng != null) {
      markers.add(
        Marker(
          point: _passengerLatLng!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFC153b),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
      points.add(_passengerLatLng!);
    }

    if (_dropoffLatLng != null) {
      markers.add(
        Marker(
          point: _dropoffLatLng!,
          width: 32,
          height: 32,
          child: Image.asset('Assets/icons/target.png', width: 32, height: 32),
        ),
      );
      points.add(_dropoffLatLng!);
    }

    final polylines = <Polyline>[];
    final polyPoints = <LatLng>[];
    if (_driverLatLng != null) polyPoints.add(_driverLatLng!);
    if (_passengerLatLng != null) polyPoints.add(_passengerLatLng!);
    if (_dropoffLatLng != null) polyPoints.add(_dropoffLatLng!);
    if (polyPoints.length >= 2) {
      polylines.add(
        Polyline(
          points: polyPoints,
          strokeWidth: 5,
          color: const Color(0xFFFC153b),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    }

    if (points.length >= 2) {
      final now = DateTime.now();
      if (_lastMapFit == null || now.difference(_lastMapFit!).inSeconds >= 2) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
        );
        _lastMapFit = now;
      }
    } else if (_driverLatLng != null) {
      _mapController.move(_driverLatLng!, 15);
    }
  }

  void _updateEta() {
    if (_driverLatLng == null) return;
    final target = _passengerLatLng ?? _dropoffLatLng;
    if (target == null) return;
    final distanceKm = _distance
        .as(LengthUnit.Kilometer, _driverLatLng!, target)
        .abs();
    final minutes = max(1, (distanceKm / _averageSpeedKmh * 60).round());
    if (mounted) {
      setState(() => _etaText = '$minutes min');
    }
  }

  Future<void> _sendSos() async {
    if (_isSosSending) return;
    if (mounted) setState(() => _isSosSending = true);
    try {
      final uri = Uri.parse('$_restBaseUrl/${widget.rideId}/sos');
      final body = {
        'userId': widget.userId ?? 'passenger',
        'rideId': widget.rideId,
        'location': {
          'latitude': _passengerLatLng?.latitude,
          'longitude': _passengerLatLng?.longitude,
        },
      };
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) setState(() => _isSosSent = true);
        _showSnack('SOS alert sent to control room.');
        await launchUrlString('tel:$_emergencyNumber');
      } else {
        _showSnack('Unable to send SOS. Please try again.');
      }
    } catch (e) {
      _showSnack('SOS failed: $e');
    } finally {
      if (mounted) setState(() => _isSosSending = false);
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassengerChatScreen(
          rideId: widget.rideId,
          driverId: widget.driverId ?? 'driver',
          driverName: widget.driverName,
        ),
      ),
    );
  }

  void _startDebugSimulation() {
    if (!kDebugMode) return;
    _debugTimer?.cancel();
    final start =
        _driverLatLng ??
        widget.initialDriverPosition ??
        const LatLng(24.8607, 67.0011);
    final end =
        _passengerLatLng ?? _dropoffLatLng ?? const LatLng(24.8707, 67.0511);
    var t = 0.0;
    _debugTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      t += 0.05;
      if (t > 1) t = 0;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      if (!mounted) return;
      setState(() => _driverLatLng = LatLng(lat, lng));
      _updateEta();
      _updateMarkersAndFit();
    });
  }

  void _toggleDebugSimulation(bool value) {
    setState(() => _debugSimulate = value);
    if (value) {
      _startDebugSimulation();
    } else {
      _debugTimer?.cancel();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.inter())),
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[LiveTracking] $message');
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _LiveTrackingMetrics.fromContext(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Live Tracking',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: metrics.appBarFont,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: metrics.sectionSpacingSmall),
              _buildDriverInfoCard(metrics),
              SizedBox(height: metrics.sectionSpacingSmall),
              _buildStatusRow(metrics),
              SizedBox(height: metrics.sectionSpacingSmall),
              Expanded(child: _buildMapArea(metrics)),
              SizedBox(height: metrics.sectionSpacingSmall),
              _buildBottomPanel(metrics),
              SizedBox(height: metrics.sectionSpacingSmall),
              _buildActionButtons(metrics),
              SizedBox(height: metrics.sectionSpacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(_LiveTrackingMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A9E), Color(0xFFFC153b)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SafeCircleAvatar(
                radius: metrics.cardAvatarRadius,
                imagePath: (widget.driverAvatarAsset?.isNotEmpty ?? false)
                    ? widget.driverAvatarAsset!
                    : 'Assets/icons/women1.jpeg',
                backgroundColor: Colors.white,
              ),
              SizedBox(width: metrics.cardSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Driver ${widget.driverName}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: metrics.cardTitleFont,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: metrics.smallSpacing / 2),
                    Text(
                      'ETA: ${_etaText == '--' ? (widget.initialEta ?? '--') : _etaText}',
                      style: GoogleFonts.inter(
                        fontSize: metrics.cardSubtitleFont,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(height: metrics.smallSpacing / 2),
                    Text(
                      widget.pickupAddress ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: metrics.smallFont,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: metrics.cardSpacing),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.directions_car, color: Colors.white),
                  SizedBox(height: metrics.smallSpacing / 2),
                  Text(
                    'Ride ID',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: metrics.smallFont * 0.9,
                    ),
                  ),
                  Text(
                    widget.rideId,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: metrics.smallFont,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(_LiveTrackingMetrics metrics) {
    Color color;
    String label;
    switch (_status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        label = 'Connected';
        break;
      case ConnectionStatus.reconnecting:
        color = Colors.orange;
        label = 'Reconnecting…';
        break;
      case ConnectionStatus.failed:
        color = Colors.red;
        label = 'Disconnected';
        break;
      case ConnectionStatus.connecting:
        color = Colors.blue;
        label = 'Connecting…';
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: metrics.smallFont),
        ),
        backgroundColor: color.withValues(alpha: 0.15),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildMapArea(_LiveTrackingMetrics metrics) {
    if (_permissionDenied) {
      return _buildPermissionWarning(metrics);
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _driverLatLng ??
                  widget.initialDriverPosition ??
                  const LatLng(24.8607, 67.0011),
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                _updateMarkersAndFit();
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.musafirah_app',
              ),
              if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),
        ),
        Positioned(
          bottom: metrics.smallSpacing * 4,
          left: metrics.smallSpacing * 4,
          child: _buildLocationPill(metrics),
        ),
        if (_status != ConnectionStatus.connected)
          Positioned(
            top: metrics.smallSpacing * 2,
            right: metrics.smallSpacing * 2,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.smallSpacing * 3,
                vertical: metrics.smallSpacing * 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                _errorMessage ?? 'Reconnecting…',
                style: GoogleFonts.inter(fontSize: metrics.smallFont),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationPill(_LiveTrackingMetrics metrics) {
    return ElevatedButton.icon(
      onPressed: _fetchPassengerLocation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC153b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFC153b)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.smallSpacing * 4,
          vertical: metrics.smallSpacing * 2,
        ),
      ),
      icon: const Icon(Icons.my_location, size: 18),
      label: Text(
        'Your Location',
        style: GoogleFonts.inter(fontSize: metrics.smallFont),
      ),
    );
  }

  Widget _buildPermissionWarning(_LiveTrackingMetrics metrics) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 40, color: Colors.grey),
          SizedBox(height: metrics.smallSpacing * 2),
          Text(
            'Location permission required.',
            style: GoogleFonts.inter(
              fontSize: metrics.cardSubtitleFont,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: metrics.smallSpacing * 2),
          ElevatedButton(
            onPressed: Geolocator.openAppSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC153b),
              foregroundColor: Colors.white,
            ),
            child: Text('Open Settings', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(_LiveTrackingMetrics metrics) {
    return Container(
      width: double.infinity,
      height: metrics.bottomPanelHeight,
      padding: EdgeInsets.all(metrics.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: Color(0xFFFC153b)),
                      SizedBox(width: metrics.smallSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pickupAddress ?? 'Pickup location',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: metrics.cardSubtitleFont,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: metrics.smallSpacing / 2),
                            Text(
                              widget.dropoffAddress ?? 'Drop-off location',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: metrics.smallFont,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Ride updates',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: metrics.cardSubtitleFont,
                    ),
                  ),
                  SizedBox(height: metrics.smallSpacing / 2),
                  Text(
                    'Stay tuned for messages from Musafirah support.',
                    style: GoogleFonts.inter(
                      fontSize: metrics.cardSubtitleFont,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (kDebugMode) ...[
                    const Divider(height: 24),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _debugSimulate,
                      onChanged: _toggleDebugSimulation,
                      title: Text(
                        'Simulate driver movement',
                        style: GoogleFonts.inter(fontSize: metrics.smallFont),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(_LiveTrackingMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSosSending ? null : _sendSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC153b),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: metrics.buttonPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(metrics.buttonRadius),
                  ),
                ),
                icon: _isSosSent
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.error_outline),
                label: Text(
                  _isSosSent ? 'SOS Sent' : 'SOS',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: metrics.buttonFont,
                  ),
                ),
              ),
            ),
            SizedBox(width: metrics.sectionSpacingSmall),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openChat,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFC153b), width: 2),
                  foregroundColor: const Color(0xFFFC153b),
                  padding: EdgeInsets.symmetric(
                    vertical: metrics.buttonPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(metrics.buttonRadius),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  'Chat',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: metrics.buttonFont,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.sectionSpacingSmall),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  fare: widget.rideFare ?? 750,
                  rideId: widget.rideId,
                  pickupAddress: widget.pickupAddress ?? 'Pickup location',
                  dropoffAddress: widget.dropoffAddress ?? 'Drop-off location',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFC153b),
            padding: EdgeInsets.symmetric(vertical: metrics.buttonPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(metrics.buttonRadius),
              side: const BorderSide(color: Color(0xFFFC153b), width: 2),
            ),
          ),
          child: Text(
            'Complete Ride',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: metrics.buttonFont,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveTrackingMetrics {
  _LiveTrackingMetrics({
    required this.screenWidth,
    required this.horizontalPadding,
    required this.sectionSpacingSmall,
    required this.sectionSpacingLarge,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardSpacing,
    required this.cardSpacingLarge,
    required this.cardTitleFont,
    required this.cardSubtitleFont,
    required this.smallSpacing,
    required this.iconPadding,
    required this.iconSize,
    required this.appBarFont,
    required this.bottomPanelHeight,
    required this.buttonPadding,
    required this.buttonFont,
    required this.buttonRadius,
    required this.smallFont,
    required this.statusIconSize,
    required this.contactButtonPadding,
    required this.cardAvatarRadius,
  });

  final double screenWidth;
  final double horizontalPadding;
  final double sectionSpacingSmall;
  final double sectionSpacingLarge;
  final double cardPadding;
  final double cardRadius;
  final double cardSpacing;
  final double cardSpacingLarge;
  final double cardTitleFont;
  final double cardSubtitleFont;
  final double smallSpacing;
  final double iconPadding;
  final double iconSize;
  final double appBarFont;
  final double bottomPanelHeight;
  final double buttonPadding;
  final double buttonFont;
  final double buttonRadius;
  final double smallFont;
  final double statusIconSize;
  final double contactButtonPadding;
  final double cardAvatarRadius;

  static _LiveTrackingMetrics fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return _LiveTrackingMetrics(
      screenWidth: width,
      horizontalPadding: (width * 0.06).clamp(16.0, 32.0),
      sectionSpacingSmall: (width * 0.03).clamp(10.0, 24.0),
      sectionSpacingLarge: (width * 0.05).clamp(16.0, 36.0),
      cardPadding: (width * 0.04).clamp(12.0, 24.0),
      cardRadius: (width * 0.04).clamp(12.0, 24.0),
      cardSpacing: (width * 0.035).clamp(10.0, 20.0),
      cardSpacingLarge: (width * 0.06).clamp(16.0, 28.0),
      cardTitleFont: (width * 0.045).clamp(16.0, 22.0),
      cardSubtitleFont: (width * 0.035).clamp(13.0, 18.0),
      smallSpacing: (width * 0.02).clamp(6.0, 16.0),
      iconPadding: (width * 0.025).clamp(8.0, 18.0),
      iconSize: (width * 0.06).clamp(20.0, 32.0),
      appBarFont: (width * 0.052).clamp(18.0, 24.0),
      bottomPanelHeight: (size.height * 0.18).clamp(120.0, 200.0),
      buttonPadding: (width * 0.035).clamp(12.0, 18.0),
      buttonFont: (width * 0.04).clamp(15.0, 20.0),
      buttonRadius: (width * 0.045).clamp(12.0, 22.0),
      smallFont: (width * 0.032).clamp(12.0, 16.0),
      statusIconSize: (width * 0.045).clamp(14.0, 22.0),
      contactButtonPadding: (width * 0.04).clamp(12.0, 18.0),
      cardAvatarRadius: (width * 0.08).clamp(22.0, 32.0),
    );
  }
}

class _SafeCircleAvatar extends StatelessWidget {
  const _SafeCircleAvatar({
    required this.radius,
    required this.imagePath,
    required this.backgroundColor,
  });

  final double radius;
  final String imagePath;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image.asset(
          imagePath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: radius,
                color: const Color(0xFFFC153b),
              ),
            );
          },
        ),
      ),
    );
  }
}
