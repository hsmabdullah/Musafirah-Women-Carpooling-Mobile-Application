import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/wallet_repository.dart';
import 'package:musafirah_app/wallet_history_screen.dart';
import 'package:musafirah_app/screens/edit_profile_screen.dart';
import 'package:musafirah_app/screens/support_screen.dart';
import 'package:musafirah_app/screens/privacy_security_screen.dart';
import 'package:musafirah_app/user_choice.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  int _navIndex = 2;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _rideHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await DatabaseService.getUserData(user.uid, 'Passengers');
      final rides = await DatabaseService.getPassengerRides(user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _rideHistory = rides;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _name => _userData?['name'] ?? 'Rider';
  String get _phone => _userData?['phone'] ?? '';
  double get _rating => (_userData?['rating'] as num?)?.toDouble() ?? 0.0;
  int get _totalRides => (_userData?['totalRides'] as int?) ?? 0;
  String get _profileImageUrl => _userData?['profileImageUrl'] ?? '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kRed)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16,
                20,
                isTablet ? 32 : 16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Ride History'),
                  const SizedBox(height: 10),
                  _buildRideHistory(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Wallet & Payments'),
                  const SizedBox(height: 10),
                  _buildWalletCard(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Account'),
                  const SizedBox(height: 10),
                  _buildAccountActions(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final ratingStr = _rating > 0 ? _rating.toStringAsFixed(1) : 'New';
    final memberSince = _userData?['createdAt'] != null
        ? 'Member'
        : 'Trusted Rider';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('My Profile',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(_phone,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$memberSince · $ratingStr ★',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfileScreen(userData: _userData ?? {}),
                        ),
                      );
                      if (updated == true) _fetchData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            color: Colors.white24,
          ),
          child: ClipOval(
            child: _profileImageUrl.isNotEmpty
                ? Image.network(_profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 40, color: Colors.white))
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final ratingDisplay =
        _rating > 0 ? '${_rating.toStringAsFixed(1)} ★' : 'New';
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _StatCell(value: '$_totalRides', label: 'Total Rides'),
          _Divider(),
          _StatCell(value: ratingDisplay, label: 'Rating'),
          _Divider(),
          _StatCell(
              value: 'Rs ${WalletRepository.balance.toStringAsFixed(0)}',
              label: 'Balance'),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kText));
  }

  Widget _buildRideHistory() {
    if (_rideHistory.isEmpty) {
      return _EmptyCard(
          icon: Icons.directions_car_outlined,
          message: 'No rides yet. Book your first ride!');
    }

    final rides = _rideHistory.take(4).toList();
    return Column(
      children: rides
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FirestoreRideTile(ride: r),
              ))
          .toList(),
    );
  }

  Widget _buildWalletCard() {
    return _SettingsRow(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: _kRed,
      iconBg: _kRed.withValues(alpha: 0.1),
      title: 'Wallet Balance',
      trailing: Text(
        'Rs ${WalletRepository.balance.toStringAsFixed(0)}',
        style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kRed),
      ),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const WalletHistoryScreen())),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        _SettingsRow(
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF0EA5E9),
          iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
          title: 'Edit Profile',
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditProfileScreen(userData: _userData ?? {}),
              ),
            );
            if (updated == true) _fetchData();
          },
        ),
        const SizedBox(height: 8),
        _SettingsRow(
          icon: Icons.headset_mic_outlined,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
          title: 'Support',
          subtitle: 'Help & contact us',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SupportScreen(userRole: 'passenger'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SettingsRow(
          icon: Icons.privacy_tip_outlined,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          title: 'Privacy & Security',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PrivacySecurityScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Logout',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, color: _kText)),
          content: Text('Are you sure you want to logout?',
              style: GoogleFonts.outfit(color: _kSubText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: _kSubText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UserChoice()),
                  (r) => false,
                );
              },
              child: Text('Logout', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRed.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: _kRed, size: 20),
            const SizedBox(width: 8),
            Text('Logout',
                style: GoogleFonts.outfit(
                    color: _kRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8, top: 10),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isActive: _navIndex == 0,
            onTap: () {
              setState(() => _navIndex = 0);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
            isActive: _navIndex == 1,
            onTap: () {
              setState(() => _navIndex = 1);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WalletHistoryScreen()),
              ).then((_) {
                if (mounted) setState(() => _navIndex = 2);
              });
            },
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isActive: _navIndex == 2,
            onTap: () => setState(() => _navIndex = 2),
          ),
        ],
      ),
    );
  }
}

// ── Firestore Ride Tile ────────────────────────────────────────────────────────
class _FirestoreRideTile extends StatelessWidget {
  const _FirestoreRideTile({required this.ride});
  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) {
    final pickup =
        (ride['originAddress'] ?? ride['pickupAddress'] ?? 'Unknown') as String;
    final dropoff = (ride['destinationAddress'] ??
        ride['dropoffAddress'] ??
        'Unknown') as String;
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    final status = (ride['status'] ?? 'completed') as String;
    final isCompleted = status.toLowerCase() == 'completed';
    final statusColor = isCompleted ? const Color(0xFF10B981) : _kRed;
    final statusLabel =
        status[0].toUpperCase() + status.substring(1).toLowerCase();

    DateTime? ts;
    try {
      final raw = ride['createdAt'];
      if (raw != null && raw.runtimeType.toString().contains('Timestamp')) {
        ts = raw.toDate() as DateTime;
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: _kRed, size: 22),
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
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: _kSubText),
                    Expanded(
                      child: Text(dropoff,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
                if (ts != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    WalletRepository.formatTimestamp(ts),
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: _kSubText),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${fare.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: _kSubText)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 12, color: _kSubText)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }
}

// ── Empty card ────────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration:
          BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _kSubText),
          const SizedBox(height: 10),
          Text(message,
              style: GoogleFonts.outfit(fontSize: 13, color: _kSubText),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Bottom nav item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? _kRed.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(isActive ? activeIcon : icon,
                  color: isActive ? _kRed : _kSubText, size: 24),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? _kRed : _kSubText)),
          ],
        ),
      ),
    );
  }
}
