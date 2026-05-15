import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:musafirah_app/services/stripe_service.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/wallet_repository.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    this.fare = 750,
    this.rideId = '',
    this.pickupAddress = 'Pickup location',
    this.dropoffAddress = 'Drop-off location',
    this.autoReturnToDashboard = true,
    this.driverName = 'Driver',
    this.driverId = '',
  });

  final double fare;
  final String rideId;
  final String pickupAddress;
  final String dropoffAddress;
  final bool autoReturnToDashboard;
  final String driverName;
  final String driverId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 0: Cash, 1: Online Payment via Stripe, 2: JazzCash / EasyPaisa
  int _selectedPaymentMethod = 0;
  final TextEditingController _commentController = TextEditingController();
  int _driverRating = 0;
  bool _isProcessing = false;
  late double _totalFare;

  // JazzCash / EasyPaisa details
  String? _jazzCashNumber;
  String? _easyPaisaNumber;
  String? _screenshotUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _totalFare = widget.fare;
    _fetchDriverPaymentInfo();
  }

  Future<void> _fetchDriverPaymentInfo() async {
    if (widget.driverId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(widget.driverId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _jazzCashNumber = doc.data()?['jazzCashNumber'];
          _easyPaisaNumber = doc.data()?['easyPaisaNumber'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver payment info: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadScreenshot() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Reduce quality to keep base64 string smaller
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final base64Url = "data:image/jpeg;base64,$base64String";

      if (mounted) {
        setState(() {
          _screenshotUrl = base64Url;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: const Color(0xFFFC153b),
          ),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    final timestamp = DateTime.now();

    // If Online Payment is selected, process through Stripe first
    if (_selectedPaymentMethod == 1) {
      setState(() => _isProcessing = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFC153b)),
        ),
      );

      final String? errorMessage =
          await StripeService.makePayment(_totalFare.toDouble(), 'pkr');

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator
      setState(() => _isProcessing = false);

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $errorMessage'),
            backgroundColor: const Color(0xFFFC153b),
          ),
        );
        return;
      }
    } else if (_selectedPaymentMethod == 2) {
      // JazzCash / EasyPaisa
      if (_screenshotUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a payment screenshot first.'),
            backgroundColor: Color(0xFFFC153b),
          ),
        );
        return;
      }

      setState(() => _isProcessing = true);
    }

    // NEW: Update Firestore Ride document for all payment methods
    if (widget.rideId.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final paymentMethods = ['Cash', 'Stripe', 'JazzCash/EasyPaisa'];
        final updateData = <String, dynamic>{
          'status': _selectedPaymentMethod == 2 ? 'awaiting_verification' : 'completed',
          'paymentMethod': paymentMethods[_selectedPaymentMethod],
          'rating': _driverRating,
          'comment': _commentController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (_screenshotUrl != null) {
          updateData['paymentScreenshotUrl'] = _screenshotUrl;
        }

        await FirebaseFirestore.instance
            .collection('Rides')
            .doc(widget.rideId)
            .update(updateData);
            
        // If it's a completed ride (Cash/Stripe), also update driver's average rating
        if (_selectedPaymentMethod != 2 && widget.driverId.isNotEmpty && _driverRating > 0) {
          // Note: In a production app, you'd use a cloud function or 
          // a more complex calculation, but here we'll just update it.
          final driverRef = FirebaseFirestore.instance.collection('Drivers').doc(widget.driverId);
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final driverDoc = await transaction.get(driverRef);
            if (driverDoc.exists) {
              final currentRating = (driverDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
              final totalRides = (driverDoc.data()?['totalRides'] as int?) ?? 0;
              final newTotalRides = totalRides + 1;
              final newRating = ((currentRating * totalRides) + _driverRating) / newTotalRides;
              
              transaction.update(driverRef, {
                'rating': newRating,
                'totalRides': newTotalRides,
              });
            }
          });
        }
      } catch (e) {
        debugPrint('Error updating ride result: $e');
        // We'll continue anyway to show the success dialog to the user
      }
    }

    // Record the ride in local history
    if (widget.rideId.isNotEmpty) {
      WalletRepository.recordRideCompletion(
        rideId: widget.rideId,
        pickup: widget.pickupAddress,
        dropoff: widget.dropoffAddress,
        fare: _totalFare,
        timestamp: timestamp,
        rating: _driverRating,
        comment: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        screenshotUrl: _screenshotUrl,
      );
    }

    // Show success message and navigate
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedPaymentMethod == 0
              ? 'Ride Complete! Please pay driver in cash.'
              : _selectedPaymentMethod == 1
                  ? 'Payment Successful!'
                  : 'Verification Sent!',
        ),
        backgroundColor: Colors.green,
      ),
    );

    if (widget.autoReturnToDashboard) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const PassengerDashboardScreen()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeBody = (screenWidth * 0.038).clamp(14.0, 16.0);
    final double fontSizeTitle = (screenWidth * 0.055).clamp(20.0, 24.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(16.0, 18.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double cardRadius = (screenWidth * 0.035).clamp(12.0, 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Complete Payment',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: (screenWidth * 0.042).clamp(18.0, 20.0),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.025),

                    // ── Fare Summary Card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC153b), Color(0xFFD4002A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(cardRadius + 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFC153b)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('Total Fare',
                              style: GoogleFonts.outfit(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. ${_totalFare.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: fontSizeTitle + 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${widget.pickupAddress} → ${widget.dropoffAddress}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    // ── Payment Method Card ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How would you like to pay?',
                            style: GoogleFonts.outfit(
                              fontSize: fontSizeBody,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentOption(
                            icon: Icons.payments_outlined,
                            title: 'Cash',
                            subtitle: 'Pay directly to the driver',
                            value: 0,
                          ),
                          const SizedBox(height: 10),
                          _buildPaymentOption(
                            icon: Icons.credit_card_rounded,
                            title: 'Online Payment',
                            subtitle: 'Pay securely via Stripe (Card / Bank)',
                            value: 1,
                            badge: 'Secure',
                          ),
                          const SizedBox(height: 10),
                          _buildPaymentOption(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'JazzCash / EasyPaisa',
                            subtitle: 'Transfer and upload screenshot',
                            value: 2,
                          ),

                          if (_selectedPaymentMethod == 2) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver Payment Details:',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _paymentDetailRow('JazzCash', _jazzCashNumber),
                                  const SizedBox(height: 8),
                                  _paymentDetailRow('EasyPaisa', _easyPaisaNumber),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Upload Payment Screenshot:',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_screenshotUrl != null)
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _screenshotUrl!.startsWith('data:image')
                                              ? Image.memory(
                                                  base64Decode(_screenshotUrl!.split(',').last),
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  _screenshotUrl!,
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _screenshotUrl = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _isUploading ? null : _pickAndUploadScreenshot,
                                        icon: _isUploading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFC153b)),
                                              )
                                            : const Icon(Icons.cloud_upload_outlined),
                                        label: Text(_isUploading ? 'Uploading...' : 'Pick from Gallery'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFFC153b),
                                          side: const BorderSide(color: Color(0xFFFC153b)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // ── Rate Your Driver ───────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate Your Driver',
                            style: GoogleFonts.outfit(
                              fontSize: fontSizeBody,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFC153b)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: Color(0xFFFC153b), size: 24),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.driverName,
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color:
                                              const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => GestureDetector(
                                          onTap: () => setState(
                                              () => _driverRating =
                                                  index + 1),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    right: 4),
                                            child: Icon(
                                              index < _driverRating
                                                  ? Icons.star_rounded
                                                  : Icons
                                                      .star_outline_rounded,
                                              size: 28,
                                              color: index < _driverRating
                                                  ? const Color(
                                                      0xFFFFC107)
                                                  : Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _commentController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add a comment (optional)',
                              hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF7F8FA),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFFC153b),
                                    width: 2),
                              ),
                            ),
                            style: GoogleFonts.outfit(
                                fontSize: fontSizeBody),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),

            // ── Confirm Button ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFFFC153b)
                        .withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _selectedPaymentMethod == 0
                              ? 'Confirm — Pay Cash to Driver'
                              : _selectedPaymentMethod == 1
                                  ? 'Confirm — Pay Rs. ${_totalFare.toStringAsFixed(0)} Online'
                                  : 'Confirm — Verification Pending',
                          style: GoogleFonts.outfit(
                            fontSize: fontSizeButton - 1,
                            fontWeight: FontWeight.w700,
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

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC153b).withValues(alpha: 0.05)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFC153b)
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFC153b).withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? const Color(0xFFFC153b)
                      : Colors.grey[500]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF0F172A))),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.green
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(badge,
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? const Color(0xFFFC153b)
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentDetailRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFC153b).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.account_balance_wallet,
                  size: 14, color: Color(0xFFFC153b)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value ?? 'Not available',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
