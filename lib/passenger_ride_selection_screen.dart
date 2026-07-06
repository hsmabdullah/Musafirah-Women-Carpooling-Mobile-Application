import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'ride_accepted_screen.dart';
import 'package:musafirah_app/services/notification_service.dart';

const _kRed = Color(0xFFFC153b);
const _kBg = Color(0xFFF8F9FA);
const _kText = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);

class PassengerRideSelectionScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double estimatedFare;
  final String userId;
  final String rideId;
  final String passengerName;
  final String passengerImageUrl;

  const PassengerRideSelectionScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.userId,
    required this.rideId,
    this.passengerName = '',
    this.passengerImageUrl = '',
  });

  @override
  State<PassengerRideSelectionScreen> createState() =>
      _PassengerRideSelectionScreenState();
}

class _PassengerRideSelectionScreenState
    extends State<PassengerRideSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _isCancelling = false;
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Ride?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel this ride request?',
            style: GoogleFonts.outfit(color: _kSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('No', style: GoogleFonts.outfit(color: _kSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, Cancel', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    await DatabaseService.cancelRide(widget.rideId);
    if (mounted) Navigator.pop(context);
  }

  void _onRideAccepted(Map<String, dynamic> rideData) {
    if (_navigatedAway) return;
    _navigatedAway = true;
    _pulseCtrl.stop();

    // Fire a local notification so the passenger is alerted
    final driverName = rideData['driverName']?.toString() ?? 'Your driver';
    NotificationService.notifyRideAccepted(driverName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideAcceptedScreen(
          rideId: widget.rideId,
          driverId: rideData['driverId'] ?? '',
          driverName: rideData['driverName'] ?? 'Your Driver',
          driverPhone: rideData['driverPhone'] ?? '',
          driverImageUrl: rideData['driverImageUrl'] ?? '',
          vehicleModel: rideData['vehicleModel'] ?? '—',
          vehicleColor: rideData['vehicleColor'] ?? '—',
          vehiclePlate: rideData['vehiclePlate'] ?? '—',
          pickupAddress: widget.pickupAddress,
          dropoffAddress: widget.dropoffAddress,
          estimatedFare: widget.estimatedFare,
          pickupLocation: widget.pickupLocation,
          dropoffLocation: widget.dropoffLocation,
          userId: widget.userId,
          passengerName: widget.passengerName,
          passengerImageUrl: widget.passengerImageUrl,
          eta: rideData['eta']?.toString() ?? '—',
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _cancelRide();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: DatabaseService.getRideStream(widget.rideId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final data = snapshot.data?.data();
            final status = data?['status'] as String? ?? 'requested';

            if (status == 'cancelled') {
              return _buildCancelledState();
            }

            if (status == 'accepted' && data != null) {
              // Trigger navigation on next frame to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _onRideAccepted(data));
              return _buildAcceptedState(data);
            }

            // Default: waiting/requested state
            return _buildWaitingState();
          },
        ),
      ),
    );
  }

  // ─── Waiting State ────────────────────────────────────────────────────────

  Widget _buildWaitingState() {
    return Column(
      children: [
        _buildHeader('Looking for a Driver'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                _buildPulsingSearch(),
                const SizedBox(height: 24),
                _buildOnlineDriversSection(),
                const SizedBox(height: 24),
                _buildRouteCard(),
                const SizedBox(height: 20),
                _buildFareCard(),
                const SizedBox(height: 32),
                _buildCancelButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineDriversSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DatabaseService.getOnlineDriversStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        // Exclude the current user in case they somehow appear
        final drivers = docs.where((d) => d.id != currentUid).toList();

        if (drivers.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            child: Row(
              children: [
                Icon(Icons.directions_car_outlined,
                    color: Colors.grey[400], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Searching for drivers in your area…',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                ),
                snapshot.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kRed))
                    : const SizedBox.shrink(),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${drivers.length} driver${drivers.length == 1 ? '' : 's'} online nearby',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: drivers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final data = drivers[i].data();
                  return _buildDriverCard(data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Driver';
    final vehicle = data['vehicleModel'] as String? ?? '—';
    final color = data['vehicleColor'] as String? ?? '—';
    final rating = (data['rating'] as num?)?.toStringAsFixed(1) ?? '5.0';
    final imageUrl = data['profileImageUrl'] as String? ?? '';

    Widget avatar;
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        avatar = ClipOval(
            child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover));
      } catch (_) {
        avatar = _initials(name);
      }
    } else if (imageUrl.startsWith('http')) {
      avatar = ClipOval(
          child: Image.network(imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(name)));
    } else {
      avatar = _initials(name);
    }

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 44, height: 44, child: avatar),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
          const SizedBox(height: 2),
          Text('$vehicle · $color',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 10, color: _kSub)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFC107), size: 12),
              const SizedBox(width: 2),
              Text(rating,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kSub)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kRed)),
      ),
    );
  }

  Widget _buildPulsingSearch() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Transform.scale(
            scale: _pulse.value,
            child: child,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kRed.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRed.withValues(alpha: 0.14),
                ),
                child: const Center(
                  child: Icon(Icons.directions_car_rounded,
                      color: _kRed, size: 40),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Searching for available drivers',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 6),
        Text('Drivers going your way will accept your request',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        _buildStatusDots(),
      ],
    );
  }

  Widget _buildStatusDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 600 + i * 200),
          curve: Curves.easeInOut,
          builder: (_, v, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kRed.withValues(alpha: v),
            ),
          ),
          onEnd: () => setState(() {}),
        ),
      ),
    );
  }

  // ─── Accepted State ───────────────────────────────────────────────────────

  Widget _buildAcceptedState(Map<String, dynamic> rideData) {
    final driverName = rideData['driverName'] as String? ?? 'Your Driver';
    final phone = rideData['driverPhone'] as String? ?? '';
    final vehicleModel = rideData['vehicleModel'] as String? ?? '—';
    final vehicleColor = rideData['vehicleColor'] as String? ?? '—';
    final vehiclePlate = rideData['vehiclePlate'] as String? ?? '—';
    final driverImageUrl = rideData['driverImageUrl'] as String? ?? '';

    return Column(
      children: [
        _buildHeader('Driver Found!', subtitle: 'Your ride is confirmed'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                // Success icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: Colors.green[600], size: 42),
                ),
                const SizedBox(height: 24),

                // Driver card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                          _buildDriverAvatar(driverImageUrl, driverName),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverName,
                                    style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _kText)),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined,
                                          size: 13, color: _kSub),
                                      const SizedBox(width: 4),
                                      Text(phone,
                                          style: GoogleFonts.outfit(
                                              fontSize: 13, color: _kSub)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _VehicleChip(
                              icon: Icons.directions_car_rounded,
                              label: vehicleModel),
                          const SizedBox(width: 8),
                          _VehicleChip(
                              icon: Icons.palette_outlined,
                              label: vehicleColor),
                          const SizedBox(width: 8),
                          _VehicleChip(
                              icon: Icons.pin_outlined, label: vehiclePlate),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildRouteCard(),
                const SizedBox(height: 16),
                _buildFareCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _kRed.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Proceeding to ride…',
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverAvatar(String imageUrl, String name) {
    Widget inner;
    if (imageUrl.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(imageUrl.split(',').last);
        inner = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        inner = _defaultAvatarIcon(name);
      }
    } else if (imageUrl.isNotEmpty) {
      inner = Image.network(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(name));
    } else {
      inner = _defaultAvatarIcon(name);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kRed.withValues(alpha: 0.3), width: 2),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _defaultAvatarIcon(String name) {
    return Container(
      color: _kRed.withValues(alpha: 0.08),
      child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w800, color: _kRed)),
      ),
    );
  }

  // ─── Cancelled / Error States ─────────────────────────────────────────────

  Widget _buildCancelledState() {
    return Column(
      children: [
        _buildHeader('Ride Cancelled'),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey[100], shape: BoxShape.circle),
                  child: Icon(Icons.cancel_outlined,
                      color: Colors.grey[400], size: 44),
                ),
                const SizedBox(height: 20),
                Text('Ride was cancelled',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                const SizedBox(height: 8),
                Text('You can go back and request a new ride.',
                    style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Go Back',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildHeader('Connection Error'),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Unable to connect',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Check your internet connection',
                    style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildHeader(String title, {String? subtitle}) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 18,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancelRide,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text('Safe',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                      color: Colors.green[500], shape: BoxShape.circle)),
              Container(
                  width: 2,
                  height: 28,
                  color: Colors.grey[300]),
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
                const SizedBox(height: 10),
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

  Widget _buildFareCard() {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.payments_outlined, color: _kRed, size: 22),
          ),
          const SizedBox(width: 14),
          Text('Estimated Fare',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
          const Spacer(),
          Text('Rs ${widget.estimatedFare.toInt()}',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kRed)),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isCancelling ? null : _cancelRide,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kRed,
          side: const BorderSide(color: _kRed, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isCancelling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: _kRed, strokeWidth: 2),
              )
            : Text('Cancel Request',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Vehicle Chip ─────────────────────────────────────────────────────────────
class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kRed),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kRed)),
            ),
          ],
        ),
      ),
    );
  }
}
