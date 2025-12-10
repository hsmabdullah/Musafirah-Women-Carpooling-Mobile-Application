import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';
import 'driver_payment_screen.dart';

class DriverNavigationScreen extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final String passengerName;
  final int price;

  const DriverNavigationScreen({
    super.key,
    required this.start,
    required this.end,
    required this.passengerName,
    required this.price,
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();

  // Mock Instructions for "International Standard" UX
  final List<Map<String, dynamic>> _instructions = [
    {
      "icon": Icons.turn_right,
      "text": "Turn right onto Khayaban-e-Saadi",
      "dist": "200 m",
      "time": "1 min",
    },
    {
      "icon": Icons.straight,
      "text": "Continue straight on Sunset Boulevard",
      "dist": "3.5 km",
      "time": "8 mins",
    },
    {
      "icon": Icons.turn_left,
      "text": "Turn left towards Clifton Road",
      "dist": "1.2 km",
      "time": "4 mins",
    },
    {
      "icon": Icons.location_on,
      "text": "Destination is on the right",
      "dist": "0 m",
      "time": "Arriving",
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _onSOSPressed() {
    // In a real app, retrieve the emergency contact from Driver Profile Provider/SharedPrefs
    // For now, we mock it or call a standard emergency line
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              "Emergency SOS",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Call your emergency contact or Police (15)?",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _makePhoneCall("15"); // Logic to call police
            },
            icon: const Icon(Icons.local_police, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            label: Text(
              "Call Police",
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onChatPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(peerName: widget.passengerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Navigation",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: _onChatPressed,
          ),
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white, size: 28),
            onPressed: _onSOSPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          // MAP SECTION (Top Half)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Center roughly between start/end or just start
                    initialCenter: widget.start,
                    initialZoom: 14.0,
                    onMapReady: () {
                      // Fit bounds to show route
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints([
                            widget.start,
                            widget.end,
                          ]),
                          padding: const EdgeInsets.all(50),
                        ),
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.musafirah.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            widget.start,
                            widget.end,
                          ], // Straight line mock for now
                          strokeWidth: 5.0,
                          color: const Color(0xFFFC153b),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.start,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.directions_car,
                            color: Color(0xFFFC153b),
                            size: 30,
                          ),
                        ),
                        Marker(
                          point: widget.end,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Overlay Controls (Zoom, Re-center)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: "zoom_in",
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.add, color: Colors.black87),
                        onPressed: () {
                          final zoom = _mapController.camera.zoom + 1;
                          _mapController.move(
                            _mapController.camera.center,
                            zoom,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: "zoom_out",
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.remove, color: Colors.black87),
                        onPressed: () {
                          final zoom = _mapController.camera.zoom - 1;
                          _mapController.move(
                            _mapController.camera.center,
                            zoom,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // INSTRUCTIONS SECTION (Bottom Half)
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // Active Instruction Highlight
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC153b),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Head north on Abdul Sattar Edhi Avenue",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Next 0.5 km",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // List of Instructions
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _instructions.length,
                      separatorBuilder: (ctx, index) =>
                          const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final step = _instructions[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(step['icon'], color: Colors.red[400]),
                          ),
                          title: Text(
                            step['text'],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Then ${step['dist']}",
                            style: GoogleFonts.outfit(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            step['time'],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Complete Trip Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC153b), Color(0xFFFF5252)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFC153b).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Complete Logic
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Complete Trip?"),
                              content: const Text(
                                "Are you sure you have dropped off the passenger?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("No"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx); // Close Dialog
                                    // Navigate to Payment
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DriverPaymentScreen(
                                              passengerName:
                                                  widget.passengerName,
                                              price: widget.price,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("Yes, Complete"),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Complete Trip",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
}
