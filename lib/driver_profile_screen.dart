import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:musafirah_app/screens/driver_edit_profile_screen.dart';
import 'package:musafirah_app/screens/support_screen.dart';
import 'package:musafirah_app/screens/privacy_security_screen.dart';
import 'user_choice.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await DatabaseService.getUserData(user.uid, 'Drivers');
      if (mounted) {
        setState(() {
          _driverData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _name => _driverData?['name'] ?? 'Driver';
  String get _phone => _driverData?['phone'] ?? '';
  String get _vehicleModel => _driverData?['vehicleModel'] ?? '';
  String get _vehicleColor => _driverData?['vehicleColor'] ?? '';
  String get _vehicleReg => _driverData?['vehicleRegistration'] ?? '';
  String get _city => _driverData?['city'] ?? '';
  double get _rating => (_driverData?['rating'] as num?)?.toDouble() ?? 0.0;
  int get _totalRides => (_driverData?['totalRides'] as int?) ?? 0;
  String get _profileImageUrl => _driverData?['profileImageUrl'] ?? '';
  String get _selfieUrl => _driverData?['selfieUrl'] ?? '';

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
          _buildHeader(context, isTablet),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16,
                20,
                isTablet ? 32 : 16,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  if (_vehicleModel.isNotEmpty) ...[
                    _buildSectionLabel('Vehicle'),
                    const SizedBox(height: 10),
                    _buildVehicleCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildSectionLabel('Account'),
                  const SizedBox(height: 10),
                  _buildMenuSection(context),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final avatarUrl = _profileImageUrl.isNotEmpty ? _profileImageUrl : _selfieUrl;
    final ratingStr = _rating > 0 ? _rating.toStringAsFixed(1) : 'New';

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
                  Text(
                    'My Profile',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverEditProfileScreen(
                            driverData: _driverData ?? {},
                          ),
                        ),
                      );
                      if (updated == true) _fetchDriverData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Text('Edit',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildAvatar(avatarUrl),
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$ratingStr Rating',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (_city.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(_city,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildAvatar(String url) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: Colors.white24,
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image(
                image: AuthService.getImageProvider(url),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 40, color: Colors.white),
              )
            : const Icon(Icons.person, size: 40, color: Colors.white),
      ),
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
          _StatCell(value: '$_totalRides', label: 'Trips'),
          _DividerLine(),
          _StatCell(value: ratingDisplay, label: 'Rating'),
          _DividerLine(),
          _StatCell(
              value: _city.isNotEmpty ? _city : 'N/A', label: 'City'),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kText));
  }

  Widget _buildVehicleCard() {
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: _kRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vehicleModel.isNotEmpty ? _vehicleModel : 'Vehicle',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText),
                ),
                if (_vehicleColor.isNotEmpty || _vehicleReg.isNotEmpty)
                  Text(
                    [_vehicleColor, _vehicleReg]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: _kSubText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _MenuRow(
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF0EA5E9),
          iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
          title: 'Edit Profile',
          subtitle: 'Update your personal info',
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DriverEditProfileScreen(driverData: _driverData ?? {}),
              ),
            );
            if (updated == true) _fetchDriverData();
          },
        ),
        const SizedBox(height: 8),
        _MenuRow(
          icon: Icons.headset_mic_outlined,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
          title: 'Help & Support',
          subtitle: 'Get help or contact us',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SupportScreen(userRole: 'driver'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _MenuRow(
          icon: Icons.privacy_tip_outlined,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
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
}

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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kText)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 12, color: _kSubText)),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
