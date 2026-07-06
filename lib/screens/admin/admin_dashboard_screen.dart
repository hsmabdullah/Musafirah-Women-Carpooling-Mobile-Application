import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/stat_card.dart';
import 'widgets/bottom_nav.dart';
import 'driver_details_screen.dart';
import 'live_rides_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:musafirah_app/screens/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _primaryColor = Color(0xFFFC153B);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'blocked':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  void _handleNavigation(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    if (index == 1) Navigator.pushReplacementNamed(context, '/drivers');
    if (index == 2) Navigator.pushReplacementNamed(context, '/riders');
    if (index == 3) Navigator.pushReplacementNamed(context, '/rides');
    if (index == 4) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _primaryColor,
        elevation: 2,
        title: Text(
          'Admin Console',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search anything...',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Statistics Section
                  Text(
                    'Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
                    builder: (context, driverSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('Passengers').snapshots(),
                        builder: (context, passengerSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('Rides').snapshots(),
                            builder: (context, ridesSnap) {
                              final drivers = driverSnap.data?.docs ?? [];
                              final passengers = passengerSnap.data?.docs ?? [];
                              final rides = ridesSnap.data?.docs ?? [];

                              final activeRides = rides.where((d) {
                                final s = (d.data() as Map<String, dynamic>)['status'] ?? '';
                                return s == 'active' || s == 'in_progress';
                              }).length;

                              final pendingDrivers = drivers.where((d) =>
                                  (d.data() as Map<String, dynamic>)['status'] == 'pending').length;
                              final pendingPassengers = passengers.where((p) =>
                                  (p.data() as Map<String, dynamic>)['status'] == 'pending').length;
                              final totalPending = pendingDrivers + pendingPassengers;

                              final verifiedDrivers = drivers.where((d) =>
                                  (d.data() as Map<String, dynamic>)['status'] == 'approved').length;

                              final blockedUsers = drivers.where((d) =>
                                      (d.data() as Map<String, dynamic>)['isBlocked'] == true).length +
                                  passengers.where((p) =>
                                      (p.data() as Map<String, dynamic>)['isBlocked'] == true).length;

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final cardWidth = (constraints.maxWidth - 12) / 2;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: cardWidth,
                                        child: StatCard(
                                          icon: Icons.route_rounded,
                                          number: activeRides.toString(),
                                          label: 'Active Rides',
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(
                                        width: cardWidth,
                                        child: StatCard(
                                          icon: Icons.hourglass_top_rounded,
                                          number: totalPending.toString(),
                                          label: 'Pending Approvals',
                                          color: Colors.orange,
                                        ),
                                      ),
                                      SizedBox(
                                        width: cardWidth,
                                        child: StatCard(
                                          icon: Icons.verified_user_rounded,
                                          number: verifiedDrivers.toString(),
                                          label: 'Verified Drivers',
                                          color: _primaryColor,
                                        ),
                                      ),
                                      SizedBox(
                                        width: cardWidth,
                                        child: StatCard(
                                          icon: Icons.block_rounded,
                                          number: blockedUsers.toString(),
                                          label: 'Blocked Users',
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),

                  // Live Rides Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Rides',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/rides'),
                        child: Row(
                          children: [
                            Text(
                              'Explore',
                              style: GoogleFonts.outfit(
                                color: _primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: _primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Rides')
                        .where('status', whereIn: ['active', 'in_progress'])
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.route_outlined, color: Colors.grey.shade300, size: 32),
                              const SizedBox(width: 12),
                              Text(
                                'No active rides right now',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((doc) {
                          final ride = doc.data() as Map<String, dynamic>;
                          final origin = ride['originAddress'] ?? ride['pickupAddress'] ?? 'Unknown';
                          final destination = ride['destinationAddress'] ?? ride['dropoffAddress'] ?? 'Unknown';
                          final fare = ride['fare'];
                          final fareStr = fare != null ? 'Rs. ${fare.toStringAsFixed(0)}' : 'N/A';
                          final rideId = doc.id;
                          final shortId = rideId.length > 8 ? rideId.substring(0, 8).toUpperCase() : rideId.toUpperCase();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LiveRidesScreen()),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.route_rounded, color: Colors.green, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#$shortId',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$origin → $destination',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(fareStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),

                  // Recent Drivers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Drivers',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/drivers'),
                        child: Row(
                          children: [
                            Text(
                              'View All',
                              style: GoogleFonts.outfit(
                                color: _primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: _primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Drivers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text('Error loading drivers'));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).take(5).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('No drivers found', style: TextStyle(color: Colors.grey.shade400)),
                          ),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final driver = doc.data() as Map<String, dynamic>;
                          final status = driver['status'] ?? 'pending';
                          final isBlocked = driver['isBlocked'] == true;
                          final displayStatus = isBlocked ? 'blocked' : status;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: AuthService.getImageProvider(
                                  driver['profileImageUrl'] ?? driver['image_selfie'] ?? '',
                                ),
                                onBackgroundImageError: (_, __) {},
                                child: const Icon(Icons.person, color: Colors.grey),
                              ),
                              title: Text(
                                driver['name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(displayStatus).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          displayStatus.toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(displayStatus),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (driver['car_model'] != null || driver['carModel'] != null)
                                        Row(
                                          children: [
                                            Icon(Icons.directions_car_filled_rounded, size: 14, color: Colors.grey[400]),
                                            const SizedBox(width: 4),
                                            Text(
                                              driver['car_model'] ?? driver['carModel'] ?? '',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriverDetailsScreen(
                                    driverUid: doc.id,
                                    driverData: driver,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
