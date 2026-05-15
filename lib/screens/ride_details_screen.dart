import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> rideData;

  const RideDetailsScreen({super.key, required this.rideData});

  String _formatTimestamp(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')} ${_getMonth(dt.month)} ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _getMonth(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final status = rideData['status'] as String? ?? 'completed';
    final isCompleted = status.toLowerCase().contains('complete');
    final isCancelled = status.toLowerCase().contains('cancel');
    
    final statusColor = isCompleted
        ? Colors.green[600]!
        : isCancelled
            ? Colors.red[600]!
            : Colors.orange[600]!;

    final pickup = rideData['pickupAddress'] as String? ?? 'Unknown Location';
    final dropoff = rideData['dropoffAddress'] as String? ?? 'Unknown Destination';
    final fare = (rideData['fare'] as num?)?.toDouble() ?? 0.0;
    
    final timestamp = rideData['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Unknown Date';

    // Driver Details are fetched inline using FutureBuilder if driverId is present

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ride Details',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rs ${fare.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateString,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Route Details
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Info',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFC153B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickup,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              dropoff,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
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

            const SizedBox(height: 12),

            // Driver Details (if assigned)
            if (rideData['driverId'] != null && rideData['driverId'].toString().isNotEmpty)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Drivers').doc(rideData['driverId']).get(),
                builder: (context, snapshot) {
                  // Fallback to rideData if fetch fails or is still loading
                  String name = rideData['driverName'] as String? ?? 'Driver';
                  String phone = rideData['driverPhone'] as String? ?? '';
                  String vehicle = rideData['vehicleModel'] as String? ?? '-';
                  String plate = rideData['vehiclePlate'] as String? ?? '-';
                  String imgUrl = rideData['driverImageUrl'] as String? ?? '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final d = snapshot.data!.data() as Map<String, dynamic>;
                    name = d['name'] ?? name;
                    phone = d['phone'] ?? phone;
                    vehicle = d['vehicleModel'] ?? vehicle;
                    plate = d['vehicleRegistration'] ?? plate; // it's vehicleRegistration in Drivers collection
                    imgUrl = d['profileImageUrl'] ?? imgUrl;
                  }

                  // If still exactly "-" or empty, try to show something nicer
                  if (name.isEmpty) name = 'Driver';
                  if (vehicle.isEmpty) vehicle = 'Unknown Vehicle';
                  if (plate.isEmpty) plate = 'N/A';

                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Details',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                              child: imgUrl.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        phone,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (vehicle != 'Unknown Vehicle' || plate != 'N/A') ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicle',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vehicle,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'License Plate',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[700],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Text(
                                      plate,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }
              ),
              
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
