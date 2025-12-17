import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'passenger_live_tracking_screen.dart';

class RideConfirmedScreen extends StatelessWidget {
  RideConfirmedScreen({super.key, required Map<String, dynamic> driverDetails})
    : summary = RideSummary.fromMap(driverDetails);

  final RideSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = _ConfirmedResponsiveMetrics.fromContext(context);
    final headline = summary.driverName;
    final rating = summary.driverRating;
    final trips = summary.driverTrips;
    final vehicle = summary.vehicleModel;
    final vehicleColor = summary.vehicleColor;
    final vehiclePlate = summary.vehiclePlate;
    final driverPhone = summary.driverPhone;
    final eta = summary.initialEta;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        title: Text(
          'Ride Confirmed',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: metrics.titleFont,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: metrics.verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationBanner(metrics),
            SizedBox(height: metrics.sectionSpacing),
            _buildDriverCard(
              metrics: metrics,
              headline: headline,
              rating: rating,
              trips: trips,
              vehicle: vehicle,
              vehicleColor: vehicleColor,
              vehiclePlate: vehiclePlate,
              driverPhone: driverPhone,
            ),
            SizedBox(height: metrics.sectionSpacingLarge),
            _buildMapPreview(metrics: metrics, eta: eta),
            SizedBox(height: metrics.sectionSpacingLarge),
            _buildPrimaryButton(
              label: 'View Live Tracking',
              background: Colors.white,
              textColor: const Color(0xFFFC153b),
              borderColor: const Color(0xFFFC153b),
              onPressed: () => _openLiveTracking(context),
              metrics: metrics,
            ),
            SizedBox(height: metrics.buttonSpacing),
            _buildPrimaryButton(
              label: 'Cancel Ride',
              background: const Color(0xFFFC153b),
              textColor: Colors.white,
              borderColor: const Color(0xFFFC153b),
              onPressed: () => Navigator.pop(context),
              metrics: metrics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationBanner(_ConfirmedResponsiveMetrics metrics) {
    final driverName = summary.driverName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.bannerPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFC153b),
        borderRadius: BorderRadius.circular(metrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(metrics.bannerIconPadding),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'Assets/icons/1.png',
              width: metrics.bannerIconSize,
              height: metrics.bannerIconSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.check_circle,
                  size: metrics.bannerIconSize,
                  color: const Color(0xFFFC153b),
                );
              },
            ),
          ),
          SizedBox(height: metrics.bannerSpacing),
          Text(
            'Your ride is confirmed!',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: metrics.bannerTitleFont,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: metrics.bannerSpacing / 2),
          Text(
            '$driverName is on her way to pick you up.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: metrics.bannerBodyFont,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard({
    required _ConfirmedResponsiveMetrics metrics,
    required String headline,
    required String rating,
    required String trips,
    required String vehicle,
    required String vehicleColor,
    required String vehiclePlate,
    required String driverPhone,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SafeCircleAvatar(
                radius: metrics.avatarRadius,
                imagePath:
                    summary.driverAvatarAsset.isNotEmpty &&
                        summary.driverAvatarAsset.trim().isNotEmpty
                    ? summary.driverAvatarAsset.trim()
                    : 'Assets/icons/women1.jpeg',
                backgroundColor: const Color(
                  0xFFFC153b,
                ).withValues(alpha: 0.05),
              ),
              SizedBox(width: metrics.cardSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            headline,
                            style: GoogleFonts.inter(
                              fontSize: metrics.cardTitleFont,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            SizedBox(width: metrics.smallSpacing),
                            Text(
                              rating,
                              style: GoogleFonts.inter(
                                fontSize: metrics.cardSubtitleFont,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: metrics.smallSpacing),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.smallSpacing,
                            vertical: metrics.smallSpacing / 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFC153b,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'Assets/icons/car-seat.png',
                                width: metrics.statusIconSize,
                                height: metrics.statusIconSize,
                                color: const Color(0xFFFC153b),
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.event_seat,
                                    size: metrics.statusIconSize,
                                    color: const Color(0xFFFC153b),
                                  );
                                },
                              ),
                              SizedBox(width: metrics.smallSpacing / 2),
                              Text(
                                trips,
                                style: GoogleFonts.inter(
                                  fontSize: metrics.cardSubtitleFont,
                                  color: const Color(0xFFFC153b),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.smallSpacing),
                    Text(
                      'Active • $trips',
                      style: GoogleFonts.inter(
                        fontSize: metrics.cardSubtitleFont,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: metrics.cardSpacing),
                    Text(
                      '$vehicle, $vehicleColor',
                      style: GoogleFonts.inter(
                        fontSize: metrics.cardBodyFont,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: metrics.smallSpacing),
                    Text(
                      vehiclePlate,
                      style: GoogleFonts.inter(
                        fontSize: metrics.cardSubtitleFont,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.cardSpacingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: driverPhone.isEmpty
                  ? null
                  : () => _launchPhone(driverPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC153b),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: metrics.contactButtonPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(metrics.buttonRadius),
                ),
              ),
              icon: const Icon(Icons.phone),
              label: Text(
                'Contact Driver',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: metrics.buttonFont,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview({
    required _ConfirmedResponsiveMetrics metrics,
    required String eta,
  }) {
    return Container(
      width: double.infinity,
      height: metrics.mapHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(34.0522, -118.2437),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.musafirah_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(34.0522, -118.2437),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFFC153b),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: metrics.smallSpacing * 3,
            left: metrics.smallSpacing * 3,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.smallSpacing * 3,
                vertical: metrics.smallSpacing * 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'ETA: $eta',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: metrics.cardSubtitleFont,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required Color background,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
    required _ConfirmedResponsiveMetrics metrics,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.buttonRadius),
            side: BorderSide(color: borderColor, width: 1),
          ),
          padding: EdgeInsets.symmetric(
            vertical: metrics.buttonPadding,
            horizontal: metrics.buttonPadding,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: metrics.buttonFont,
          ),
        ),
      ),
    );
  }

  void _openLiveTracking(BuildContext context) {
    final rideId = summary.rideId;
    if (rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride ID missing', style: GoogleFonts.inter())),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassengerLiveTrackingScreen(
          rideId: rideId,
          driverName: summary.driverName,
          driverId: summary.driverId,
          driverPhone: summary.driverPhone,
          userId: summary.userId,
          initialDriverPosition: summary.initialDriverPosition,
          dropoffPosition: summary.dropoffPosition,
          initialPassengerPosition: summary.passengerPosition,
          driverAvatarAsset: summary.driverAvatarAsset,
          pickupAddress: summary.pickupAddress,
          dropoffAddress: summary.dropoffAddress,
          initialEta: summary.initialEta,
          rideFare: summary.fare,
        ),
      ),
    );
  }
}

class _ConfirmedResponsiveMetrics {
  final double titleFont;
  final double horizontalPadding;
  final double verticalPadding;
  final double sectionSpacing;
  final double sectionSpacingLarge;
  final double buttonSpacing;
  final double cardRadius;
  final double cardPadding;
  final double cardTitleFont;
  final double cardSubtitleFont;
  final double cardBodyFont;
  final double avatarRadius;
  final double cardSpacing;
  final double smallSpacing;
  final double bannerPadding;
  final double bannerTitleFont;
  final double bannerBodyFont;
  final double bannerSpacing;
  final double bannerIconSize;
  final double bannerIconPadding;
  final double mapHeight;
  final double buttonRadius;
  final double buttonPadding;
  final double buttonFont;
  final double cardSpacingLarge;
  final double statusIconSize;
  final double contactButtonPadding;

  _ConfirmedResponsiveMetrics({
    this.titleFont = 24,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.sectionSpacing = 20,
    this.sectionSpacingLarge = 30,
    this.buttonSpacing = 15,
    this.cardRadius = 12,
    this.cardPadding = 15,
    this.cardTitleFont = 18,
    this.cardSubtitleFont = 14,
    this.cardBodyFont = 16,
    this.avatarRadius = 25,
    this.cardSpacing = 10,
    this.smallSpacing = 5,
    this.bannerPadding = 15,
    this.bannerTitleFont = 20,
    this.bannerBodyFont = 16,
    this.bannerSpacing = 8,
    this.bannerIconSize = 24,
    this.bannerIconPadding = 10,
    this.mapHeight = 200,
    this.buttonRadius = 10,
    this.buttonPadding = 15,
    this.buttonFont = 16,
    this.cardSpacingLarge = 16,
    this.statusIconSize = 16,
    this.contactButtonPadding = 12,
  });

  factory _ConfirmedResponsiveMetrics.fromContext(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double titleFont = screenWidth * 0.05;
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenWidth * 0.05;
    final double sectionSpacing = screenWidth * 0.05;
    final double sectionSpacingLarge = screenWidth * 0.07;
    final double buttonSpacing = screenWidth * 0.03;
    final double cardRadius = screenWidth * 0.03;
    final double cardPadding = screenWidth * 0.04;
    final double cardTitleFont = screenWidth * 0.045;
    final double cardSubtitleFont = screenWidth * 0.035;
    final double cardBodyFont = screenWidth * 0.04;
    final double avatarRadius = screenWidth * 0.06;
    final double cardSpacing = screenWidth * 0.02;
    final double smallSpacing = screenWidth * 0.01;
    final double bannerPadding = screenWidth * 0.04;
    final double bannerTitleFont = screenWidth * 0.05;
    final double bannerBodyFont = screenWidth * 0.04;
    final double bannerSpacing = screenWidth * 0.02;
    final double bannerIconSize = screenWidth * 0.08;
    final double bannerIconPadding = screenWidth * 0.02;
    final double mapHeight = screenWidth * 0.3;
    final double buttonRadius = screenWidth * 0.04;
    final double buttonPadding = screenWidth * 0.04;
    final double buttonFont = screenWidth * 0.04;
    final double cardSpacingLarge = screenWidth * 0.035;
    final double statusIconSize = screenWidth * 0.04;
    final double contactButtonPadding = screenWidth * 0.04;

    return _ConfirmedResponsiveMetrics(
      titleFont: titleFont,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      sectionSpacing: sectionSpacing,
      sectionSpacingLarge: sectionSpacingLarge,
      buttonSpacing: buttonSpacing,
      cardRadius: cardRadius,
      cardPadding: cardPadding,
      cardTitleFont: cardTitleFont,
      cardSubtitleFont: cardSubtitleFont,
      cardBodyFont: cardBodyFont,
      avatarRadius: avatarRadius,
      cardSpacing: cardSpacing,
      smallSpacing: smallSpacing,
      bannerPadding: bannerPadding,
      bannerTitleFont: bannerTitleFont,
      bannerBodyFont: bannerBodyFont,
      bannerSpacing: bannerSpacing,
      bannerIconSize: bannerIconSize,
      bannerIconPadding: bannerIconPadding,
      mapHeight: mapHeight,
      buttonRadius: buttonRadius,
      buttonPadding: buttonPadding,
      buttonFont: buttonFont,
      cardSpacingLarge: cardSpacingLarge,
      statusIconSize: statusIconSize,
      contactButtonPadding: contactButtonPadding,
    );
  }
}

Future<void> _launchPhone(String phoneNumber) async {
  final uri = 'tel:${phoneNumber.replaceAll(' ', '')}';
  if (!await launchUrlString(uri)) {
    debugPrint('Unable to launch $uri');
  }
}

class RideSummary {
  RideSummary({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.userId,
    required this.driverRating,
    required this.driverTrips,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.initialEta,
    required this.driverAvatarAsset,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    this.initialDriverPosition,
    this.dropoffPosition,
    this.passengerPosition,
  });

  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String userId;
  final String driverRating;
  final String driverTrips;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String initialEta;
  final String driverAvatarAsset;
  final String pickupAddress;
  final String dropoffAddress;
  final double fare;
  final LatLng? initialDriverPosition;
  final LatLng? dropoffPosition;
  final LatLng? passengerPosition;

  factory RideSummary.fromMap(Map<String, dynamic> map) {
    LatLng? parseLatLng(String latKey, String lngKey) {
      final lat = map[latKey];
      final lng = map[lngKey];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
      return null;
    }

    return RideSummary(
      rideId: map['rideId']?.toString() ?? map['ride_id']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? 'driver',
      driverName: map['driverName']?.toString() ?? 'Driver',
      driverPhone: map['driverPhone']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'passenger',
      driverRating: map['driverRating']?.toString() ?? '5.0',
      driverTrips: map['driverTrips']?.toString() ?? '—',
      vehicleModel: map['vehicleModel']?.toString() ?? 'Vehicle',
      vehicleColor: map['vehicleColor']?.toString() ?? 'Color',
      vehiclePlate: map['vehiclePlate']?.toString() ?? 'Plate',
      initialEta: map['eta']?.toString() ?? '--',
      driverAvatarAsset: map['driverAvatarAsset']?.toString() ?? '',
      pickupAddress: map['pickupAddress']?.toString() ?? 'Pickup',
      dropoffAddress: map['dropoffAddress']?.toString() ?? 'Drop-off',
      fare: (map['fare'] as num?)?.toDouble() ?? 0,
      initialDriverPosition: parseLatLng(
        'initialDriverLat',
        'initialDriverLng',
      ),
      dropoffPosition: parseLatLng('dropoffLat', 'dropoffLng'),
      passengerPosition: parseLatLng('passengerLat', 'passengerLng'),
    );
  }
}

class _SafeCircleAvatar extends StatefulWidget {
  const _SafeCircleAvatar({
    required this.radius,
    required this.imagePath,
    required this.backgroundColor,
  });

  final double radius;
  final String imagePath;
  final Color backgroundColor;

  @override
  State<_SafeCircleAvatar> createState() => _SafeCircleAvatarState();
}

class _SafeCircleAvatarState extends State<_SafeCircleAvatar> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        child: Icon(
          Icons.person,
          size: widget.radius,
          color: const Color(0xFFFC153b),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: AssetImage(widget.imagePath),
      onBackgroundImageError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
  }
}
