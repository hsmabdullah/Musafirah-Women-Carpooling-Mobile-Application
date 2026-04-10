import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wallet_repository.dart';
import 'rider_profile_screen.dart';
import 'screens/add_funds_screen.dart';

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
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddFundsScreen()),
    );
    if (result == true) setState(_loadData);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFC153b), Color(0xFFD4002A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFC153b).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(metrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Musafirah Wallet',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Active',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Available Balance',
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Rs ${_balance.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                  fontSize: metrics.balanceFont,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _addFunds,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('+ Add Funds',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFC153b),
                              fontSize: 13)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _viewStatements,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text('Statements',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13)),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Transactions',
            icon: Icons.receipt_long_rounded,
            selected: _showTransactions,
            onTap: () => setState(() => _showTransactions = true),
          ),
          _TabButton(
            label: 'Ride History',
            icon: Icons.directions_car_rounded,
            selected: !_showTransactions,
            onTap: () => setState(() => _showTransactions = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(_WalletMetrics metrics) {
    if (_transactions.isEmpty) {
      return _EmptyState(
          icon: Icons.receipt_long_rounded, label: 'No transactions yet');
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
          top: 12,
          bottom: metrics.sectionSpacingSmall + metrics.bottomPadding + 72),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _WalletEntryTile(entry: _transactions[i]),
    );
  }

  Widget _buildRideHistoryList(_WalletMetrics metrics) {
    if (_rideHistory.isEmpty) {
      return _EmptyState(
          icon: Icons.directions_car_rounded, label: 'No rides recorded yet');
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
          top: 12,
          bottom: metrics.sectionSpacingSmall + metrics.bottomPadding + 72),
      itemCount: _rideHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RideHistoryTile(ride: _rideHistory[i]),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                icon: Icons.account_balance_wallet_rounded,
                label: 'Wallet',
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
                color:
                    selected ? const Color(0xFFFC153b) : Colors.grey[400],
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

class _WalletEntryTile extends StatelessWidget {
  const _WalletEntryTile({required this.entry});
  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    final color = isCredit ? Colors.green[600]! : const Color(0xFFFC153b);
    final icon = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(entry.subtitle,
                    style: GoogleFonts.outfit(
                        color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} Rs ${entry.amount.abs().toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RideHistoryTile extends StatelessWidget {
  const _RideHistoryTile({required this.ride});
  final RideHistoryEntry ride;

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.status.toLowerCase().contains('complete');
    final statusColor = isCompleted ? Colors.green[600]! : Colors.orange[600]!;

    return Container(
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
                      child: Text(ride.pickup,
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
                Text(ride.dropoff,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(WalletRepository.formatTimestamp(ride.timestamp),
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${ride.fare.toStringAsFixed(0)}',
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
                child: Text(ride.status,
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
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
