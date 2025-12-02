import 'package:flutter/material.dart';
import 'rider_verification_screen.dart';
import '../widgets/bottom_nav.dart';

class RidersListScreen extends StatefulWidget {
  const RidersListScreen({super.key});

  @override
  State<RidersListScreen> createState() => _RidersListScreenState();
}

class _RidersListScreenState extends State<RidersListScreen> {
  int _currentNavIndex = 2;
  final _searchController = TextEditingController();

  // Sample rider data
  final List<Map<String, dynamic>> _allRiders = [
    {
      'name': 'Aisha Khan',
      'status': 'Pending',
      'phone': '+92 300 1234567',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Fatima Ali',
      'status': 'Verified',
      'phone': '+92 300 2345678',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Zainab Qureshi',
      'status': 'Pending',
      'phone': '+92 300 3456789',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Sana Javed',
      'status': 'Verified',
      'phone': '+92 300 4567890',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Hina Masood',
      'status': 'Pending',
      'phone': '+92 300 5678901',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Maryam Sheikh',
      'status': 'Verified',
      'phone': '+92 300 6789012',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Nida Ahmed',
      'status': 'Rejected',
      'phone': '+92 300 7890123',
      'image': 'assets/images/driver1.png',
    },
    {
      'name': 'Rabia Hassan',
      'status': 'Pending',
      'phone': '+92 300 8901234',
      'image': 'assets/images/driver1.png',
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
      // Drivers
      Navigator.pushReplacementNamed(context, '/drivers');
    } else if (index == 2) {
      // Already on Riders screen
    } else if (index == 3) {
      // Logout
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF1744),
        title: const Text(
          'All Riders',
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
                          hintText: 'Search riders...',
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
                  // Riders List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _allRiders.length,
                      itemBuilder: (context, index) {
                        final rider = _allRiders[index];
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
                                rider['image'] as String,
                              ),
                              onBackgroundImageError: (_, __) {},
                              child: const Icon(Icons.person),
                            ),
                            title: Text(
                              rider['name'] as String,
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
                                      rider['status'] as String,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    rider['status'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(
                                        rider['status'] as String,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rider['phone'] as String,
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
                                  builder: (context) => RiderVerificationScreen(
                                    riderName: rider['name'] as String,
                                    initialStatus: rider['status'] as String,
                                  ),
                                ),
                              );
                              if (result != null && mounted) {
                                setState(() {
                                  final index = _allRiders.indexWhere(
                                    (r) => r['name'] == rider['name'],
                                  );
                                  if (index != -1) {
                                    _allRiders[index]['status'] = result;
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
