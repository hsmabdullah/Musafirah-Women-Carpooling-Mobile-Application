import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'rider_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/screens/notifications_screen.dart';
import 'package:musafirah_app/screens/ride_details_screen.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  bool _showTransactions = false; // default to Ride History tab
  int _bottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _WalletMetrics.fromContext(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ride History',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: metrics.appBarFont,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 16, top: 12),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 12,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFC153b), width: 1.5),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(metrics),
      body: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: metrics.sectionSpacing),
              _buildTabs(metrics),
              SizedBox(height: metrics.sectionSpacingSmall),
              Expanded(
                child: _showTransactions
                    ? _buildEmptyPaymentsInfo(metrics)
                    : _buildRideHistoryList(metrics),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(_WalletMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Ride History',
            icon: Icons.directions_car_rounded,
            selected: !_showTransactions,
            onTap: () => setState(() => _showTransactions = false),
          ),
          _TabButton(
            label: 'Payments',
            icon: Icons.receipt_long_rounded,
            selected: _showTransactions,
            onTap: () => setState(() => _showTransactions = true),
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryList(_WalletMetrics metrics) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _EmptyState(icon: Icons.error_outline, label: 'Not logged in');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Rides')
          .where(Filter.or(
            Filter('passengerId', isEqualTo: uid),
            Filter('userId', isEqualTo: uid),
          ))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFC153b)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading history: ${snapshot.error}', 
                style: GoogleFonts.outfit(),
                textAlign: TextAlign.center,
              ),
            )
          );
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        
        // Sort locally to avoid Firebase composite index requirement
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

        if (docs.isEmpty) {
          return const _EmptyState(
              icon: Icons.directions_car_rounded, label: 'No rides recorded yet');
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
              top: 12,
              bottom:
                  metrics.sectionSpacingSmall + metrics.bottomPadding + 72),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _RideHistoryTile(data: data);
          },
        );
      },
    );
  }

  Widget _buildEmptyPaymentsInfo(_WalletMetrics metrics) {
    // Inform the user how payments work
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC153b).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: Color(0xFFFC153b), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'How Payment Works',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                icon: Icons.payments_outlined,
                title: 'Cash Payment',
                subtitle:
                    'Pay the driver directly in cash at the end of your ride.',
              ),
              const SizedBox(height: 14),
              _buildInfoRow(
                icon: Icons.credit_card_rounded,
                title: 'Online Payment via Stripe',
                subtitle:
                    'If you don\'t have cash, you can pay securely online using your debit/credit card through Stripe.',
              ),
              const SizedBox(height: 14),
              _buildInfoRow(
                icon: Icons.check_circle_outline_rounded,
                title: 'No Wallet Needed',
                subtitle:
                    'You don\'t need to top up any wallet. Payment is made directly at the end of each ride.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFC153b).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFC153b), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF0F172A))),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(_WalletMetrics metrics) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _bottomNavIndex == 0,
                onTap: () {
                  setState(() => _bottomNavIndex = 0);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: _bottomNavIndex == 1,
                onTap: () => setState(() => _bottomNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: _bottomNavIndex == 2,
                onTap: () {
                  setState(() => _bottomNavIndex = 2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RiderProfileScreen()),
                  ).then((_) {
                    if (mounted) setState(() => _bottomNavIndex = 1);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected
                      ? const Color(0xFFFC153b)
                      : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFFFC153b)
                          : Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFC153b).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFC153b), size: 28),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFC153b).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: selected
                    ? const Color(0xFFFC153b)
                    : Colors.grey[400],
                size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFFFC153b)
                      : Colors.grey[500])),
        ],
      ),
    );
  }
}

class _RideHistoryTile extends StatelessWidget {
  const _RideHistoryTile({required this.data});
  final Map<String, dynamic> data;

  String _formatTimestamp(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'completed';
    final isCompleted = status.toLowerCase().contains('complete');
    final statusColor =
        isCompleted ? Colors.green[600]! : Colors.orange[600]!;
    
    final pickup = data['pickupAddress'] as String? ?? 'Unknown Location';
    final dropoff = data['dropoffAddress'] as String? ?? 'Unknown Destination';
    final fare = (data['fare'] as num?)?.toDouble() ?? 0.0;
    
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null 
        ? _formatTimestamp(timestamp.toDate()) 
        : 'Unknown Date';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(rideData: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFC153b).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: Color(0xFFFC153b), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(pickup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF0F172A))),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 12, color: Color(0xFF94A3B8)),
                  ],
                ),
                Text(dropoff,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(dateString,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${fare.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFC153b),
                      fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _WalletMetrics {
  _WalletMetrics({
    required this.horizontalPadding,
    required this.sectionSpacing,
    required this.sectionSpacingSmall,
    required this.appBarFont,
    required this.bottomPadding,
  });

  final double horizontalPadding;
  final double sectionSpacing;
  final double sectionSpacingSmall;
  final double appBarFont;
  final double bottomPadding;

  static _WalletMetrics fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return _WalletMetrics(
      horizontalPadding: (width * 0.06).clamp(16.0, 28.0),
      sectionSpacing: (height * 0.03).clamp(16.0, 32.0),
      sectionSpacingSmall: (height * 0.02).clamp(12.0, 24.0),
      appBarFont: (width * 0.05).clamp(18.0, 22.0),
      bottomPadding: MediaQuery.of(context).padding.bottom,
    );
  }
}
