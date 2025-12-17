import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wallet_repository.dart';
import 'rider_profile_screen.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  late List<WalletEntry> _transactions;
  late List<RideHistoryEntry> _rideHistory;
  late double _balance;
  bool _showTransactions = true;
  int _bottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _transactions = WalletRepository.getTransactions();
    _rideHistory = WalletRepository.getRideHistory();
    _balance = WalletRepository.balance;
  }

  Future<void> _addFunds() async {
    WalletRepository.addFunds(amount: 500, source: 'Manual Top-up');
    setState(_loadData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PKR 500 credited to your wallet.',
          style: GoogleFonts.inter(),
        ),
      ),
    );
  }

  void _viewStatements() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Statement feature coming soon.',
          style: GoogleFonts.inter(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _WalletMetrics.fromContext(context);

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
          'Wallet & History',
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: metrics.sectionSpacing),
              _buildBalanceCard(metrics),
              SizedBox(height: metrics.sectionSpacing),
              _buildTabs(metrics),
              SizedBox(height: metrics.sectionSpacingSmall),
              Expanded(
                child: _showTransactions
                    ? _buildTransactionsList(metrics)
                    : _buildRideHistoryList(metrics),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(_WalletMetrics metrics) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFFFC153b),
              ),
              SizedBox(width: metrics.smallSpacing),
              Text(
                'Current Balance',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontSize: metrics.cardTitleFont,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: metrics.smallSpacing),
          Text(
            'Available Funds',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: metrics.smallFont,
            ),
          ),
          SizedBox(height: metrics.smallSpacing / 2),
          Text(
            'Rs. ${_balance.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: metrics.balanceFont,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFC153b),
            ),
          ),
          SizedBox(height: metrics.smallSpacing * 2),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addFunds,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Add Funds',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: metrics.smallSpacing),
              Expanded(
                child: OutlinedButton(
                  onPressed: _viewStatements,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFC153b),
                    side: const BorderSide(color: Color(0xFFFC153b)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.buttonRadius),
                    ),
                  ),
                  child: FittedBox(
                    child: Text(
                      'View Statements',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(_WalletMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_showTransactions) return;
              setState(() {
                _showTransactions = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _showTransactions
                  ? const Color(0xFFFC153b)
                  : Colors.white,
              foregroundColor: _showTransactions
                  ? Colors.white
                  : const Color(0xFFFC153b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(metrics.buttonRadius),
                side: const BorderSide(color: Color(0xFFFC153b)),
              ),
            ),
            child: Text(
              'Transactions',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(width: metrics.smallSpacing),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (!_showTransactions) return;
              setState(() {
                _showTransactions = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !_showTransactions
                  ? const Color(0xFFFC153b)
                  : Colors.white,
              foregroundColor: !_showTransactions
                  ? Colors.white
                  : const Color(0xFFFC153b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(metrics.buttonRadius),
                side: const BorderSide(color: Color(0xFFFC153b)),
              ),
            ),
            child: Text(
              'Ride History',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(_WalletMetrics metrics) {
    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet.',
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: metrics.sectionSpacingSmall,
        bottom: metrics.sectionSpacingSmall + metrics.bottomPadding + 72,
      ),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => SizedBox(height: metrics.smallSpacing),
      itemBuilder: (_, index) {
        final entry = _transactions[index];
        return _WalletEntryTile(entry: entry, metrics: metrics);
      },
    );
  }

  Widget _buildRideHistoryList(_WalletMetrics metrics) {
    if (_rideHistory.isEmpty) {
      return Center(
        child: Text(
          'No rides recorded yet.',
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: metrics.sectionSpacingSmall,
        bottom: metrics.sectionSpacingSmall + metrics.bottomPadding + 72,
      ),
      itemCount: _rideHistory.length,
      separatorBuilder: (_, __) => SizedBox(height: metrics.smallSpacing),
      itemBuilder: (_, index) {
        final ride = _rideHistory[index];
        return _RideHistoryTile(ride: ride, metrics: metrics);
      },
    );
  }

  Widget _buildBottomNav(_WalletMetrics metrics) {
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
            Navigator.pop(context);
            break;
          case 1:
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiderProfileScreen()),
            ).then((_) {
              if (mounted) {
                setState(() => _bottomNavIndex = 1);
              }
            });
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

class _WalletEntryTile extends StatelessWidget {
  const _WalletEntryTile({required this.entry, required this.metrics});

  final WalletEntry entry;
  final _WalletMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    final color = isCredit ? Colors.green : const Color(0xFFFC153b);
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(metrics.iconPadding / 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: metrics.iconSize * 0.8),
          ),
          SizedBox(width: metrics.smallSpacing * 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: metrics.cardSubtitleFont,
                  ),
                ),
                SizedBox(height: metrics.smallSpacing / 2),
                Text(
                  entry.subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: metrics.smallFont,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.smallSpacing),
          Text(
            '${isCredit ? '+ ' : '- '}Rs. ${entry.amount.abs().toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: metrics.cardSubtitleFont,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideHistoryTile extends StatelessWidget {
  const _RideHistoryTile({required this.ride, required this.metrics});

  final RideHistoryEntry ride;
  final _WalletMetrics metrics;

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${ride.pickup} → ${ride.dropoff}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: metrics.cardSubtitleFont,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: metrics.smallSpacing),
              Text(
                'Rs. ${ride.fare.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFC153b),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.smallSpacing / 2),
          Text(
            WalletRepository.formatTimestamp(ride.timestamp),
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: metrics.smallFont,
            ),
          ),
          if (ride.status.isNotEmpty) ...[
            SizedBox(height: metrics.smallSpacing / 2),
            Text(
              ride.status,
              style: GoogleFonts.inter(
                color: Colors.green,
                fontSize: metrics.smallFont,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletMetrics {
  _WalletMetrics({
    required this.horizontalPadding,
    required this.sectionSpacing,
    required this.sectionSpacingSmall,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardTitleFont,
    required this.cardSubtitleFont,
    required this.smallSpacing,
    required this.iconPadding,
    required this.iconSize,
    required this.buttonRadius,
    required this.appBarFont,
    required this.balanceFont,
    required this.buttonPadding,
    required this.bottomPadding,
    required this.smallFont,
  });

  final double horizontalPadding;
  final double sectionSpacing;
  final double sectionSpacingSmall;
  final double cardPadding;
  final double cardRadius;
  final double cardTitleFont;
  final double cardSubtitleFont;
  final double smallSpacing;
  final double iconPadding;
  final double iconSize;
  final double buttonRadius;
  final double appBarFont;
  final double balanceFont;
  final double buttonPadding;
  final double bottomPadding;
  final double smallFont;

  static _WalletMetrics fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return _WalletMetrics(
      horizontalPadding: (width * 0.06).clamp(16.0, 28.0),
      sectionSpacing: (height * 0.03).clamp(16.0, 32.0),
      sectionSpacingSmall: (height * 0.02).clamp(12.0, 24.0),
      cardPadding: (width * 0.045).clamp(14.0, 24.0),
      cardRadius: (width * 0.035).clamp(12.0, 20.0),
      cardTitleFont: (width * 0.045).clamp(16.0, 20.0),
      cardSubtitleFont: (width * 0.038).clamp(13.0, 16.0),
      smallSpacing: (height * 0.012).clamp(6.0, 16.0),
      iconPadding: (width * 0.025).clamp(8.0, 18.0),
      iconSize: (width * 0.06).clamp(20.0, 30.0),
      buttonRadius: (width * 0.04).clamp(12.0, 18.0),
      appBarFont: (width * 0.05).clamp(18.0, 22.0),
      balanceFont: (width * 0.08).clamp(28.0, 36.0),
      buttonPadding: (height * 0.02).clamp(12.0, 18.0),
      bottomPadding: MediaQuery.of(context).padding.bottom,
      smallFont: (width * 0.032).clamp(12.0, 14.0),
    );
  }
}
