import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/map_widget.dart';
import 'driver_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();

  // Sample driver data
  final List<Map<String, dynamic>> _recentDrivers = [
    {
      'name': 'Aisha Khan',
      'status': 'Verified',
      'vehicle': 'Suzuki Cultus (ABC-123)',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Fatima Ali',
      'status': 'Pending',
      'vehicle': 'Honda City (DEF-456)',
      'image': 'assets/images/driver2.png',
    },
    {
      'name': 'Zainab Qureshi',
      'status': 'Verified',
      'vehicle': 'Toyota Corolla (GHI-789)',
      'image': 'assets/images/driver3.png',
    },
    {
      'name': 'Sana Javed',
      'status': 'Rejected',
      'vehicle': 'Kia Picanto (JKL-012)',
      'image': 'assets/images/driver4.png',
    },
    {
      'name': 'Hina Masood',
      'status': 'Pending',
      'vehicle': 'Hyundai Elantra (MNO-345)',
      'image': 'assets/images/driver5.png',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF1744),
        title: const Text(
          'Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search drivers, riders, or vehicles...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Statistics Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: const StatCard(
                                icon: Icons.local_taxi,
                                number: '87',
                                label: 'Verified Drivers',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: const StatCard(
                                icon: Icons.hourglass_empty,
                                number: '12',
                                label: 'Pending Verifications',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: const StatCard(
                                icon: Icons.people,
                                number: '75',
                                label: 'Verified Riders',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: const StatCard(
                                icon: Icons.assignment,
                                number: '24',
                                label: 'Active Trips',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Map Section
                    SizedBox(
                      height: size.height * 0.3,
                      child: const MapWidget(),
                    ),
                    const SizedBox(height: 24),
                    // Recent Drivers
                    const Text(
                      'Recent Drivers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Drivers List
                    ..._recentDrivers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final driver = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage(
                              driver['image'] as String,
                            ),
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person),
                          ),
                          title: Text(
                            driver['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    driver['status'] as String,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  driver['status'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(
                                      driver['status'] as String,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    driver['vehicle'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            // Open driver details and wait for status change.
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverDetailsScreen(
                                  driverName: driver['name'] as String,
                                  initialStatus: driver['status'] as String,
                                ),
                              ),
                            );

                            // If user approved/rejected, update status in recent list.
                            if (result != null &&
                                (result == 'Verified' ||
                                    result == 'Rejected')) {
                              setState(() {
                                _recentDrivers[index]['status'] = result;
                              });
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          // Handle navigation
          if (index == 0) {
            // Already on Dashboard
          } else if (index == 1) {
            // Drivers
            Navigator.pushReplacementNamed(context, '/drivers');
          } else if (index == 2) {
            // Riders
            Navigator.pushReplacementNamed(context, '/riders');
          } else if (index == 3) {
            // Logout
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
