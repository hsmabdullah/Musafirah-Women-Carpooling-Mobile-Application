import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'live_chat_screen.dart';
import 'passenger_live_tracking_screen.dart';

const _kRed = Color(0xFFFC153B);
const _kBg = Color(0xFFF7F8FA);
const _kText = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);

class RideAcceptedScreen extends StatefulWidget {
  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverImageUrl;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String pickupAddress;
  final String dropoffAddress;
  final double estimatedFare;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String userId;
  final String passengerName;
  final String passengerImageUrl;
  final String eta;

  const RideAcceptedScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverImageUrl,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.userId,
    this.passengerName = '',
    this.passengerImageUrl = '',
    required this.eta,
  });

  @override
  State<RideAcceptedScreen> createState() => _RideAcceptedScreenState();
}

class _RideAcceptedScreenState extends State<RideAcceptedScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _checkCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn),
    );

    // Stagger the animations
    _checkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300),
        () => _slideCtrl.forward());
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        _buildDriverCard(),
                        const SizedBox(height: 16),
                        _buildRouteCard(),
                        const SizedBox(height: 16),
                        _buildFareEtaRow(),
                        const SizedBox(height: 24),
                        _buildActionRow(context),
                        const SizedBox(height: 16),
                        _buildTrackButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header with animated check ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // Animated check circle
              ScaleTransition(
                scale: _checkScale,
                child: FadeTransition(
                  opacity: _checkOpacity,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 54),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Driver Accepted!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.driverName} is on the way to pick you up',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // ETA chip
              if (widget.eta != '—')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'ETA: ${widget.eta}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Driver Card ───────────────────────────────────────────────────────────

  Widget _buildDriverCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverName,
                      style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: _kRed, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('On the way',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _kRed,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (widget.driverPhone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12, color: _kSub),
                          const SizedBox(width: 4),
                          Text(widget.driverPhone,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: _kSub)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text('5.0',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[800])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 14),
          // Vehicle chips
          Row(
            children: [
              _chip(Icons.directions_car_rounded, widget.vehicleModel),
              const SizedBox(width: 8),
              _chip(Icons.palette_outlined, widget.vehicleColor),
              const SizedBox(width: 8),
              _plateChip(widget.vehiclePlate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    Widget inner;
    final url = widget.driverImageUrl;
    if (url.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(url.split(',').last);
        inner = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        inner = _defaultAvatar();
      }
    } else if (url.isNotEmpty) {
      inner = Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar());
    } else {
      inner = _defaultAvatar();
    }

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kRed.withValues(alpha: 0.4), width: 2.5),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _defaultAvatar() => Container(
        color: _kRed.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            widget.driverName.isNotEmpty
                ? widget.driverName[0].toUpperCase()
                : '?',
            style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kRed),
          ),
        ),
      );

  // ── Route Card ────────────────────────────────────────────────────────────

  Widget _buildRouteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: _kRed, shape: BoxShape.circle)),
              Container(width: 2, height: 30, color: Colors.grey[200]),
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: _kRed, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: _kSub,
                        fontWeight: FontWeight.w500)),
                Text(widget.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const SizedBox(height: 12),
                Text('Drop-off',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: _kSub,
                        fontWeight: FontWeight.w500)),
                Text(widget.dropoffAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fare + ETA Row ────────────────────────────────────────────────────────

  Widget _buildFareEtaRow() {
    return Row(
      children: [
        Expanded(
          child: _infoTile(
            icon: Icons.payments_outlined,
            iconColor: _kRed,
            label: 'Estimated Fare',
            value: 'Rs ${widget.estimatedFare.toInt()}',
            valueColor: _kRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoTile(
            icon: Icons.shield_rounded,
            iconColor: _kRed,
            label: 'Safe Ride',
            value: 'Women Only',
            valueColor: _kRed,
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
        ],
      ),
    );
  }

  // ── Action Row (Call + Chat) ───────────────────────────────────────────────

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.phone_rounded,
            label: 'Call Driver',
            color: _kText,
            onTap: () async {
              final phone = widget.driverPhone.isNotEmpty
                  ? widget.driverPhone
                  : '00000000000'; // Fallback for testing if missing
              final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
              final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
              try {
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri,
                      mode: LaunchMode.externalApplication);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch dialer')),
                  );
                }
              } catch (e) {
                debugPrint('Error launching dialer: $e');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            color: _kRed,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveChatScreen(
                  rideId: widget.rideId,
                  peerId: widget.driverId,
                  peerName: widget.driverName,
                  peerImageUrl: widget.driverImageUrl,
                  myName: widget.passengerName,
                  myImageUrl: widget.passengerImageUrl,
                  isDriver: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ── Track Button ──────────────────────────────────────────────────────────

  Widget _buildTrackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PassengerLiveTrackingScreen(
              rideId: widget.rideId,
              driverName: widget.driverName,
              driverId: widget.driverId,
              driverPhone: widget.driverPhone,
              userId: widget.userId,
              initialDriverPosition: widget.pickupLocation,
              dropoffPosition: widget.dropoffLocation,
              initialPassengerPosition: widget.pickupLocation,
              driverAvatarAsset: '',
              pickupAddress: widget.pickupAddress,
              dropoffAddress: widget.dropoffAddress,
              initialEta: widget.eta,
              rideFare: widget.estimatedFare,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _kRed.withValues(alpha: 0.35),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: const Icon(Icons.navigation_rounded, size: 20),
        label: Text(
          'Track My Ride',
          style:
              GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _chip(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kSub),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plateChip(String plate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(plate,
          style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1)),
    );
  }
}
