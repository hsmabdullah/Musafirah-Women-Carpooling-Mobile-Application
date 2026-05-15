import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'live_chat_screen.dart';
import 'driver_payment_screen.dart';
import 'package:musafirah_app/driver_data.dart';

const _kRed = Color(0xFFFC153B);
const _kText = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);
const _kBg = Color(0xFFF1F4F8);

class DriverNavigationScreen extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final String passengerName;
  final int price;
  final String rideId;
  final String passengerId;
  final String passengerImageUrl;
  final String paymentMethod;
  final String pickupAddress;
  final String dropoffAddress;
  final String driverName;
  final String driverImageUrl;

  const DriverNavigationScreen({
    super.key,
    required this.start,
    required this.end,
    required this.passengerName,
    required this.price,
    required this.rideId,
    required this.passengerId,
    this.passengerImageUrl = '',
    this.paymentMethod = 'Cash',
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.driverName = '',
    this.driverImageUrl = '',
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();
  int _activeStep = 0;

  final List<Map<String, dynamic>> _instructions = [
    {
      'icon': Icons.straight_rounded,
      'text': 'Head north on Abdul Sattar Edhi Ave',
      'dist': '0.5 km',
      'time': '2 min',
    },
    {
      'icon': Icons.turn_right_rounded,
      'text': 'Turn right onto Khayaban-e-Saadi',
      'dist': '200 m',
      'time': '1 min',
    },
    {
      'icon': Icons.straight_rounded,
      'text': 'Continue straight on Sunset Boulevard',
      'dist': '3.5 km',
      'time': '8 min',
    },
    {
      'icon': Icons.turn_left_rounded,
      'text': 'Turn left towards Clifton Road',
      'dist': '1.2 km',
      'time': '4 min',
    },
    {
      'icon': Icons.location_on_rounded,
      'text': 'Destination is on the right',
      'dist': '0 m',
      'time': 'Arriving',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([widget.start, widget.end]),
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
        ),
      );
    });
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _onSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            Text('Emergency SOS',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text(
          'Call your emergency contact or Pakistan Police (15)?',
          style: GoogleFonts.outfit(color: _kSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: _kSub)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _callNumber('15');
            },
            icon: const Icon(Icons.local_police_rounded,
                color: Colors.white, size: 17),
            label: Text('Call Police',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _onCompleteTrip() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompleteTripSheet(
        passengerName: widget.passengerName,
        price: widget.price,
        onConfirm: () {
          if (DriverData.carCapacity < DriverData.totalCapacity) {
            DriverData.carCapacity += 1;
          }
          DriverData.acceptedRides
              .removeWhere((r) => r.passengerName == widget.passengerName);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverPaymentScreen(
                passengerName: widget.passengerName,
                price: widget.price,
                paymentMethod: widget.paymentMethod,
                pickup: widget.pickupAddress,
                dropoff: widget.dropoffAddress,
                rideId: widget.rideId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final current = _instructions[_activeStep];

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Map (top 42%) ───────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.42,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.start,
                    initialZoom: 14,
                    onMapReady: () {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          _mapController.fitCamera(
                            CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(
                                  [widget.start, widget.end]),
                              padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
                            ),
                          );
                        }
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.musafirah.app',
                    ),
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [widget.start, widget.end],
                        strokeWidth: 5,
                        color: _kRed,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: widget.start,
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _kRed,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: _kRed.withValues(alpha: 0.4),
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.directions_car_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      Marker(
                        point: widget.end,
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ]),
                  ],
                ),

                // Top overlay: back + passenger info + action buttons
                Positioned(
                  top: topPad + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _MapBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _kRed.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.passengerName.isNotEmpty
                                        ? widget.passengerName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _kRed),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.passengerName,
                                        style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _kText),
                                        overflow: TextOverflow.ellipsis),
                                    Text('Passenger · Rs ${widget.price}',
                                        style: GoogleFonts.outfit(
                                            fontSize: 11, color: _kSub)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MapBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LiveChatScreen(
                                  rideId: widget.rideId,
                                  peerId: widget.passengerId,
                                  peerName: widget.passengerName,
                                  peerImageUrl: widget.passengerImageUrl,
                                  myName: widget.driverName,
                                  myImageUrl: widget.driverImageUrl,
                                  isDriver: true)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MapBtn(
                        icon: Icons.sos_rounded,
                        color: Colors.red,
                        onTap: _onSOS,
                      ),
                    ],
                  ),
                ),

                // Zoom controls
                Positioned(
                  bottom: 16,
                  right: 12,
                  child: Column(
                    children: [
                      _MapBtn(
                          icon: Icons.add,
                          onTap: () => _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1)),
                      const SizedBox(height: 8),
                      _MapBtn(
                          icon: Icons.remove,
                          onTap: () => _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, -4))
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),

                  // Active instruction
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kRed, Color(0xFFD4002A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: _kRed.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(current['icon'] as IconData,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(current['text'] as String,
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text(
                                    '${current['dist']} · ${current['time']}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Steps list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      itemCount: _instructions.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey[100], height: 1),
                      itemBuilder: (_, i) {
                        final step = _instructions[i];
                        final isActive = i == _activeStep;
                        return InkWell(
                          onTap: () => setState(() => _activeStep = i),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? _kRed.withValues(alpha: 0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(step['icon'] as IconData,
                                      color: isActive ? _kRed : _kSub,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(step['text'] as String,
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color:
                                              isActive ? _kText : _kSub),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text(step['time'] as String,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? _kRed : _kSub)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Complete trip button
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, botPad + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onCompleteTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: _kRed.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flag_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Complete Trip',
                                style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                          ],
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
}

// ── Complete trip sheet ───────────────────────────────────────────────────────
class _CompleteTripSheet extends StatelessWidget {
  const _CompleteTripSheet({
    required this.passengerName,
    required this.price,
    required this.onConfirm,
  });
  final String passengerName;
  final int price;
  final VoidCallback onConfirm;

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
                color: _kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.flag_rounded, color: _kRed, size: 34),
          ),
          const SizedBox(height: 16),
          Text('Complete Trip?',
              style: GoogleFonts.outfit(
                  fontSize: 21, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 6),
          Text(
            'Confirm you have dropped off $passengerName\n and collect Rs $price.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Not Yet',
                      style: GoogleFonts.outfit(
                          color: _kSub, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor: _kRed.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Yes, Complete',
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

// ── Floating map button ───────────────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  const _MapBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? _kText),
      ),
    );
  }
}
