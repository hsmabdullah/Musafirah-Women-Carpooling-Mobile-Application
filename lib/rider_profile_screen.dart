import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/wallet_repository.dart';

import 'package:musafirah_app/wallet_history_screen.dart';
import 'package:musafirah_app/user_choice.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  int _bottomNavIndex = 2; // Profile is selected

  @override
  Widget build(BuildContext context) {
    final metrics = _ProfileMetrics.fromContext(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: metrics.appBarFont,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(metrics),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: metrics.sectionSpacing),
              _buildProfileCard(metrics),
              SizedBox(height: metrics.sectionSpacing),
              _buildRideHistorySection(metrics),
              SizedBox(height: metrics.sectionSpacing),
              _buildPaymentMethodSection(metrics),
              SizedBox(height: metrics.sectionSpacing),
              _buildWalletBalanceSection(metrics),
              SizedBox(height: metrics.sectionSpacing),
              _buildAccountActionsSection(metrics),
              SizedBox(height: metrics.sectionSpacing * 1.5),
              _buildLogoutButton(metrics),
              SizedBox(height: metrics.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(_ProfileMetrics metrics) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(metrics.cardPadding),
      child: Row(
        children: [
          Container(
            width: metrics.avatarSize,
            height: metrics.avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('Assets/icons/women1.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: metrics.smallSpacing * 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alina Khan',
                  style: GoogleFonts.inter(
                    fontSize: metrics.nameFont,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: metrics.smallSpacing / 2),
                Text(
                  'Trusted Rider Since 2021',
                  style: GoogleFonts.inter(
                    fontSize: metrics.smallFont,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: metrics.smallSpacing / 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: metrics.iconSize * 0.8,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: metrics.smallSpacing / 2),
                    Text(
                      '+1 (555) 123-4567',
                      style: GoogleFonts.inter(
                        fontSize: metrics.smallFont,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistorySection(_ProfileMetrics metrics) {
    final rideHistory = WalletRepository.getRideHistory();
    // Add some dummy rides to match the image
    final allRides = [
      ...rideHistory,
      RideHistoryEntry(
        rideId: 'ride_20231115_01',
        pickup: 'KIET North',
        dropoff: 'Atrium',
        fare: 500,
        timestamp: DateTime(2023, 11, 15, 14, 30),
        status: 'Completed',
      ),
      RideHistoryEntry(
        rideId: 'ride_20231110_01',
        pickup: 'Malir Cantt',
        dropoff: 'DHA Phase 6',
        fare: 600,
        timestamp: DateTime(2023, 11, 10, 9, 0),
        status: 'Completed',
      ),
      RideHistoryEntry(
        rideId: 'ride_20231110_02',
        pickup: 'Malir Cantt',
        dropoff: 'DHA Phase 6',
        fare: 600,
        timestamp: DateTime(2023, 11, 10, 9, 0),
        status: 'Cancelled',
      ),
      RideHistoryEntry(
        rideId: 'ride_20231110_03',
        pickup: 'Cantt Station',
        dropoff: 'DHA Phase 6',
        fare: 600,
        timestamp: DateTime(2023, 11, 10, 9, 0),
        status: 'Completed',
      ),
    ];
    allRides.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ride History',
          style: GoogleFonts.inter(
            fontSize: metrics.sectionTitleFont,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: metrics.smallSpacing),
        ...allRides
            .take(4)
            .map(
              (ride) => Padding(
                padding: EdgeInsets.only(bottom: metrics.smallSpacing),
                child: _RideHistoryCard(ride: ride, metrics: metrics),
              ),
            ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(_ProfileMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: GoogleFonts.inter(
                fontSize: metrics.sectionTitleFont,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Payment management coming soon.',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                );
              },
              child: Text(
                'Manage',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFC153b),
                  fontWeight: FontWeight.w600,
                  fontSize: metrics.smallFont,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.smallSpacing),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(metrics.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(metrics.cardPadding),
          child: Row(
            children: [
              Image.asset(
                'Assets/icons/card_13913311.png',
                width: metrics.iconSize,
                height: metrics.iconSize,
              ),
              SizedBox(width: metrics.smallSpacing),
              Text(
                'Visa',
                style: GoogleFonts.inter(
                  fontSize: metrics.cardTitleFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '**** 1234',
                style: GoogleFonts.inter(
                  fontSize: metrics.cardTitleFont,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalanceSection(_ProfileMetrics metrics) {
    final balance = WalletRepository.balance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wallet Balance',
              style: GoogleFonts.inter(
                fontSize: metrics.sectionTitleFont,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WalletHistoryScreen(),
                  ),
                );
              },
              child: Text(
                'Manage',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFC153b),
                  fontWeight: FontWeight.w600,
                  fontSize: metrics.smallFont,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.smallSpacing),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(metrics.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(metrics.cardPadding),
          child: Row(
            children: [
              Image.asset(
                'Assets/icons/purse_993040.png',
                width: metrics.iconSize,
                height: metrics.iconSize,
              ),
              SizedBox(width: metrics.smallSpacing),
              Text(
                'Wallet Balance',
                style: GoogleFonts.inter(
                  fontSize: metrics.cardTitleFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Rs. ${balance.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: metrics.cardTitleFont,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFC153b),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(_ProfileMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Actions',
          style: GoogleFonts.inter(
            fontSize: metrics.sectionTitleFont,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: metrics.smallSpacing),
        _AccountActionTile(
          icon: Icons.person_outline,
          label: 'Edit Profile',
          metrics: metrics,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Edit profile feature coming soon.',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
        SizedBox(height: metrics.smallSpacing / 2),
        _AccountActionTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Manage Payment',
          metrics: metrics,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment management coming soon.',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
        SizedBox(height: metrics.smallSpacing / 2),
        _AccountActionTile(
          icon: Icons.headset_mic_outlined,
          label: 'Support',
          metrics: metrics,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Support feature coming soon.',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(_ProfileMetrics metrics) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Logout', style: GoogleFonts.inter()),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UserChoice()),
                    (route) => false, // Remove all previous routes
                  );
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(color: const Color(0xFFFC153b)),
                ),
              ),
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFC153b),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: metrics.buttonPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.buttonRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout),
          SizedBox(width: metrics.smallSpacing),
          Text(
            'Logout',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: metrics.buttonFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(_ProfileMetrics metrics) {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      backgroundColor: Colors.white,
      elevation: 10,
      selectedItemColor: const Color(0xFFFC153b),
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: (metrics.smallFont + 1).clamp(12.0, 16.0),
      unselectedFontSize: metrics.smallFont.clamp(11.0, 15.0),
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(),
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() => _bottomNavIndex = index);
        switch (index) {
          case 0:
            Navigator.of(context).popUntil((route) => route.isFirst);
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
            ).then((_) {
              if (mounted) {
                setState(() => _bottomNavIndex = 2);
              }
            });
            break;
          case 2:
            // Stay on Profile
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.ride, required this.metrics});

  final RideHistoryEntry ride;
  final _ProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.status.toLowerCase() == 'completed';
    final statusColor = isCompleted ? Colors.green : const Color(0xFFFC153b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(metrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'Assets/icons/location.png',
                width: metrics.iconSize * 0.7,
                height: metrics.iconSize * 0.7,
              ),
              SizedBox(width: metrics.smallSpacing / 2),
              Expanded(
                child: Text(
                  '${ride.pickup} to ${ride.dropoff}',
                  style: GoogleFonts.inter(
                    fontSize: metrics.cardSubtitleFont,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: metrics.smallSpacing),
              Text(
                'Rs ${ride.fare.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: metrics.cardSubtitleFont,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFC153b),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.smallSpacing),
          Row(
            children: [
              Image.asset(
                'Assets/icons/calendar.png',
                width: metrics.iconSize * 0.6,
                height: metrics.iconSize * 0.6,
              ),
              SizedBox(width: metrics.smallSpacing / 2),
              Text(
                WalletRepository.formatTimestamp(ride.timestamp).split(' ')[0],
                style: GoogleFonts.inter(
                  fontSize: metrics.smallFont,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: metrics.smallSpacing),
              Image.asset(
                'Assets/icons/clock.png',
                width: metrics.iconSize * 0.6,
                height: metrics.iconSize * 0.6,
              ),
              SizedBox(width: metrics.smallSpacing / 2),
              Text(
                '${ride.timestamp.hour.toString().padLeft(2, '0')}:${ride.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: metrics.smallFont,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.smallSpacing,
                  vertical: metrics.smallSpacing / 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(metrics.buttonRadius / 2),
                ),
                child: Text(
                  ride.status,
                  style: GoogleFonts.inter(
                    fontSize: metrics.smallFont * 0.85,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.label,
    required this.metrics,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _ProfileMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(metrics.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(metrics.cardPadding),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFC153b), size: metrics.iconSize),
            SizedBox(width: metrics.smallSpacing),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: metrics.cardTitleFont,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetrics {
  _ProfileMetrics({
    required this.horizontalPadding,
    required this.sectionSpacing,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardTitleFont,
    required this.cardSubtitleFont,
    required this.smallSpacing,
    required this.iconSize,
    required this.buttonRadius,
    required this.appBarFont,
    required this.nameFont,
    required this.sectionTitleFont,
    required this.buttonPadding,
    required this.smallFont,
    required this.avatarSize,
    required this.buttonFont,
  });

  final double horizontalPadding;
  final double sectionSpacing;
  final double cardPadding;
  final double cardRadius;
  final double cardTitleFont;
  final double cardSubtitleFont;
  final double smallSpacing;
  final double iconSize;
  final double buttonRadius;
  final double appBarFont;
  final double nameFont;
  final double sectionTitleFont;
  final double buttonPadding;
  final double smallFont;
  final double avatarSize;
  final double buttonFont;

  factory _ProfileMetrics.fromContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return _ProfileMetrics(
      horizontalPadding: (width * 0.05).clamp(16.0, 24.0),
      sectionSpacing: (height * 0.02).clamp(16.0, 24.0),
      cardPadding: (width * 0.04).clamp(12.0, 18.0),
      cardRadius: (width * 0.03).clamp(10.0, 16.0),
      cardTitleFont: (width * 0.04).clamp(14.0, 18.0),
      cardSubtitleFont: (width * 0.038).clamp(13.0, 17.0),
      smallSpacing: (width * 0.025).clamp(8.0, 12.0),
      iconSize: (width * 0.06).clamp(20.0, 28.0),
      buttonRadius: (width * 0.04).clamp(12.0, 18.0),
      appBarFont: (width * 0.05).clamp(18.0, 22.0),
      nameFont: (width * 0.06).clamp(20.0, 24.0),
      sectionTitleFont: (width * 0.045).clamp(16.0, 20.0),
      buttonPadding: (height * 0.02).clamp(14.0, 18.0),
      smallFont: (width * 0.032).clamp(12.0, 14.0),
      avatarSize: (width * 0.2).clamp(60.0, 80.0),
      buttonFont: (width * 0.042).clamp(15.0, 18.0),
    );
  }
}
