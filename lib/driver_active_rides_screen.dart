import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/driver_data.dart';
import 'driver_navigation_screen.dart';

class DriverActiveRidesScreen extends StatefulWidget {
  const DriverActiveRidesScreen({super.key});

  @override
  State<DriverActiveRidesScreen> createState() =>
      _DriverActiveRidesScreenState();
}

class _DriverActiveRidesScreenState extends State<DriverActiveRidesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "My Active Rides",
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: DriverData.acceptedRides.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DriverData.acceptedRides.length,
              itemBuilder: (context, index) {
                final ride = DriverData.acceptedRides[index];
                return _buildRideCard(ride, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 50,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Active Rides",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Accepted rides will appear here.",
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(AcceptedRide ride, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(
                    0xFFFC153b,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    ride.passengerName[0],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFC153b),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.passengerName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Accepted at ${ride.acceptedAt.hour}:${ride.acceptedAt.minute.toString().padLeft(2, '0')}",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "PKR ${ride.price}",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFC153b),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFFFC153b)),
                    Container(width: 1, height: 20, color: Colors.grey[300]),
                    const Icon(Icons.location_on, size: 14, color: Colors.blue),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ride.dropoffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverNavigationScreen(
                            start: ride.pickup,
                            end: ride.dropoff,
                            passengerName: ride.passengerName,
                            price: ride.price,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Open Navigation",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    _showCompleteDialog(index);
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Complete Ride?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Is the ride for ${DriverData.acceptedRides[index].passengerName} completed?",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("No", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                DriverData.acceptedRides.removeAt(index);
                DriverData.carCapacity += 1;
              });
              Navigator.pop(ctx);
            },
            child: Text(
              "Yes, Completed",
              style: GoogleFonts.outfit(
                color: const Color(0xFFFC153b),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
