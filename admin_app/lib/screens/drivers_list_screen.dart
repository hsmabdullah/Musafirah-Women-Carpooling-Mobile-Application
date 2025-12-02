import 'package:flutter/material.dart';
import 'driver_details_screen.dart';
import '../widgets/bottom_nav.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  int _currentNavIndex = 1;
  final _searchController = TextEditingController();

  // Sample driver data
  final List<Map<String, dynamic>> _allDrivers = [
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
    {
      'name': 'Maryam Sheikh',
      'status': 'Verified',
      'vehicle': 'Toyota Vitz (PQR-678)',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Nida Ahmed',
      'status': 'Pending',
      'vehicle': 'Suzuki Swift (STU-901)',
      'image': 'assets/images/driver2.png',
    },
    {
      'name': 'Rabia Hassan',
      'status': 'Verified',
      'vehicle': 'Honda Civic (VWX-234)',
      'image': 'assets/images/driver3.png',
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

  void _handleNavigation(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    if (index == 0) {
      // Dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 1) {
      // Already on Drivers screen
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF1744),
        title: const Text(
          'All Drivers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
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
                          hintText: 'Search drivers...',
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
                  ),
                  // Drivers List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _allDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = _allDrivers[index];
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverDetailsScreen(
                                    driverName: driver['name'] as String,
                                    initialStatus: driver['status'] as String,
                                  ),
                                ),
                              );
                              if (result != null && mounted) {
                                setState(() {
                                  final index = _allDrivers.indexWhere(
                                    (d) => d['name'] == driver['name'],
                                  );
                                  if (index != -1) {
                                    _allDrivers[index]['status'] = result;
                                  }
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}

