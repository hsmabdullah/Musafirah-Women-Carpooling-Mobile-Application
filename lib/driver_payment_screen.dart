import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'driver_dashboard_screen.dart';

class DriverPaymentScreen extends StatefulWidget {
  final String passengerName;
  final int price;
  final String paymentMethod; // 'Cash', 'Online', 'JazzCash/EasyPaisa'
  final String pickup;
  final String dropoff;
  final String rideId;

  const DriverPaymentScreen({
    super.key,
    required this.passengerName,
    required this.price,
    this.paymentMethod = 'Cash',
    this.pickup = '',
    this.dropoff = '',
    this.rideId = '',
  });

  @override
  State<DriverPaymentScreen> createState() => _DriverPaymentScreenState();
}

class _DriverPaymentScreenState extends State<DriverPaymentScreen> {
  bool _isProcessing = false;
  String? _screenshotUrl;

  @override
  void initState() {
    super.initState();
    if (widget.rideId.isNotEmpty) {
      _listenToRideStatus();
    }
  }

  void _listenToRideStatus() {
    FirebaseFirestore.instance
        .collection('Rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _screenshotUrl = doc.data()?['paymentScreenshotUrl'];
        });
      }
    });
  }

  Future<void> _recordTransaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(uid)
          .collection('transactions')
          .add({
        'amount': widget.price,
        'paymentMethod': widget.paymentMethod,
        'passengerName': widget.passengerName,
        'pickup': widget.pickup,
        'dropoff': widget.dropoff,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'ride_payment',
        'screenshotUrl': _screenshotUrl,
        'rideId': widget.rideId,
      });
    } catch (e) {
      debugPrint('Error recording transaction: $e');
    }
  }

  Future<void> _completeRide() async {
    setState(() => _isProcessing = true);
    
    // 1. Record transaction
    await _recordTransaction();

    // 2. Update ride status to completed in Firestore
    if (widget.rideId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('Rides')
            .doc(widget.rideId)
            .update({'status': 'completed'});
      } catch (e) {
        debugPrint('Error updating ride status: $e');
      }
    }

    if (!mounted) return;
    
    // 3. Go back to Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverDashboardScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.paymentMethod.toLowerCase().contains('online') ||
        widget.paymentMethod.toLowerCase().contains('stripe');
    final bool isJazzCash = widget.paymentMethod.toLowerCase().contains('jazzcash') ||
        widget.paymentMethod.toLowerCase().contains('easypaisa');


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153B),
        elevation: 0,
        title: Text('Ride Completion', style: GoogleFonts.outfit(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Trip Finished!",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline
                          ? "Payment received online from ${widget.passengerName}"
                          : isJazzCash
                              ? "Verifying payment from ${widget.passengerName}"
                              : "Collect cash from ${widget.passengerName}",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Bill Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Total Fare",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "PKR ${widget.price}",
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFC153b),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          _detailRow("Payment Method", widget.paymentMethod),
                        ],
                      ),
                    ),

                    if (isJazzCash && _screenshotUrl != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        "Payment Screenshot",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(
                          image: AuthService.getImageProvider(_screenshotUrl!),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ] else if (isJazzCash && _screenshotUrl == null) ...[
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: Color(0xFFFC153b)),
                      const SizedBox(height: 16),
                      Text(
                        "Waiting for passenger to upload screenshot...",
                        style: GoogleFonts.outfit(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFC153b), Color(0xFFFF5252)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFC153b).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: (_isProcessing || (isJazzCash && _screenshotUrl == null)) 
                    ? null 
                    : _completeRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isJazzCash 
                          ? "Confirm & Complete ✓" 
                          : isOnline 
                            ? "Payment Received ✓" 
                            : "Cash Collected ✓",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
