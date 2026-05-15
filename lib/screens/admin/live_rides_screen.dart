import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'widgets/bottom_nav.dart';

class LiveRidesScreen extends StatefulWidget {
  const LiveRidesScreen({super.key});

  @override
  State<LiveRidesScreen> createState() => _LiveRidesScreenState();
}

class _LiveRidesScreenState extends State<LiveRidesScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 3;
  late TabController _tabController;

  static const _primaryColor = Color(0xFFFC153B);

  final _tabs = const ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
    if (index == 1) Navigator.pushReplacementNamed(context, '/drivers');
    if (index == 2) Navigator.pushReplacementNamed(context, '/riders');
    if (index == 3) {} // Already here
    if (index == 4) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return 'ACTIVE';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      default:
        return status.toUpperCase();
    }
  }

  Stream<QuerySnapshot> _ridesStream(String filter) {
    final col = FirebaseFirestore.instance.collection('Rides');
    if (filter == 'All') {
      return col.orderBy('createdAt', descending: true).snapshots();
    }
    final statusMap = {
      'Active': ['active', 'in_progress'],
      'Completed': ['completed'],
      'Cancelled': ['cancelled'],
    };
    final statuses = statusMap[filter] ?? [];
    if (statuses.length == 1) {
      return col
          .where('status', isEqualTo: statuses.first)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    // For 'active' + 'in_progress' use whereIn
    return col
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text(
          'Live Rides',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((filter) => _RidesTab(
          filter: filter,
          ridesStream: _ridesStream(filter),
          statusColor: _statusColor,
          statusLabel: _statusLabel,
        )).toList(),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}

class _RidesTab extends StatelessWidget {
  final String filter;
  final Stream<QuerySnapshot> ridesStream;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _RidesTab({
    required this.filter,
    required this.ridesStream,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ridesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No ${filter == 'All' ? '' : filter.toLowerCase()} rides found',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final ride = doc.data() as Map<String, dynamic>;
            return _RideCard(
              rideId: doc.id,
              ride: ride,
              statusColor: statusColor,
              statusLabel: statusLabel,
            );
          },
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final String rideId;
  final Map<String, dynamic> ride;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _RideCard({
    required this.rideId,
    required this.ride,
    required this.statusColor,
    required this.statusLabel,
  });

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy  hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] ?? 'unknown';
    final fare = ride['fare'];
    final fareStr = fare != null ? 'Rs. ${fare.toStringAsFixed(0)}' : 'N/A';
    final origin = ride['originAddress'] ?? ride['pickupAddress'] ?? 'Unknown origin';
    final destination = ride['destinationAddress'] ?? ride['dropoffAddress'] ?? 'Unknown destination';
    final driverFare = ride['driverFare'] ?? fare;
    final passengerFare = ride['passengerFare'] ?? fare;
    final driverFareStr = driverFare != null ? 'Rs. ${driverFare.toStringAsFixed(0)}' : fareStr;
    final passengerFareStr = passengerFare != null ? 'Rs. ${passengerFare.toStringAsFixed(0)}' : fareStr;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showRideDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Trip #${_shortId(rideId)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 14, color: Colors.green),
                      Container(width: 1.5, height: 20, color: Colors.grey.shade300),
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFFC153B)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          origin,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          destination,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Fare & people row
              Row(
                children: [
                  _infoChip(Icons.person_rounded, ride['passengerId'] != null
                      ? 'Passenger' : 'No Passenger', Colors.blue.shade700),
                  const SizedBox(width: 8),
                  _infoChip(Icons.local_taxi_rounded, ride['driverId'] != null
                      ? 'Driver' : 'No Driver', Colors.green.shade700),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Passenger: $passengerFareStr',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      Text(
                        'Driver: $driverFareStr',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(ride['createdAt']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRideDetails(BuildContext context) {
    final status = ride['status'] ?? 'unknown';
    final fare = ride['fare'];
    final driverFare = ride['driverFare'] ?? fare;
    final passengerFare = ride['passengerFare'] ?? fare;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Trip ID: ${rideId.toUpperCase()}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              _detailRow('Driver ID', ride['driverId'] ?? 'N/A'),
              _detailRow('Passenger ID', ride['passengerId'] ?? 'N/A'),
              _detailRow('Origin', ride['originAddress'] ?? ride['pickupAddress'] ?? 'N/A'),
              _detailRow('Destination', ride['destinationAddress'] ?? ride['dropoffAddress'] ?? 'N/A'),
              _detailRow('Passenger Fare', passengerFare != null ? 'Rs. ${passengerFare.toStringAsFixed(0)}' : 'N/A'),
              _detailRow('Driver Fare', driverFare != null ? 'Rs. ${driverFare.toStringAsFixed(0)}' : 'N/A'),
              _detailRow('Total Fare', fare != null ? 'Rs. ${fare.toStringAsFixed(0)}' : 'N/A'),
              _detailRow('Created', _formatDate(ride['createdAt'])),
              if (ride['completedAt'] != null)
                _detailRow('Completed', _formatDate(ride['completedAt'])),
              if (ride['estimatedTime'] != null)
                _detailRow('Est. Time', '${ride['estimatedTime']} min'),
              if (ride['paymentScreenshotUrl'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Payment Screenshot',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: AuthService.getImageProvider(ride['paymentScreenshotUrl']),
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
