import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 0: Cash, 1: Credit/Debit Card, 2: Wallet Balance
  int _selectedPaymentMethod = 0;
  final TextEditingController _commentController = TextEditingController();
  int _driverRating = 0; // 0..5
  final int _totalFare = 750; // PKR

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _processPayment() {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Payment Successful!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFC107),
          ),
        ),
        content: Text(
          'Your payment of PKR $_totalFare has been processed successfully.\nRating: $_driverRating/5',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: const Color(0xFFFC153b),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeTitle = (screenWidth * 0.055).clamp(20.0, 24.0);
    final double fontSizeBody = (screenWidth * 0.038).clamp(14.0, 16.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(16.0, 18.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double cardRadius = (screenWidth * 0.035).clamp(12.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: (screenWidth * 0.042).clamp(18.0, 20.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.025),

                      // Ride Summary Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride Summary',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Fare',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFC153b),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Rs. ${_totalFare.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFC153b),
                                    fontWeight: FontWeight.w700,
                                    fontSize: fontSizeTitle,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Divider(color: Colors.grey[300]),
                            SizedBox(height: screenHeight * 0.006),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Base Fare',
                                  style: GoogleFonts.inter(
                                    color: Colors.black54,
                                    fontSize: fontSizeBody,
                                  ),
                                ),
                                Text(
                                  'Rs. 650.00',
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: fontSizeBody,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Taxes & Fees',
                                  style: GoogleFonts.inter(
                                    color: Colors.black54,
                                    fontSize: fontSizeBody,
                                  ),
                                ),
                                Text(
                                  'Rs. 100.00',
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: fontSizeBody,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Payment Methods Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Methods',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildRadioMethod(
                              icon: Icons.payments_outlined,
                              title: 'Cash',
                              value: 0,
                              screenWidth: screenWidth,
                              fontSizeBody: fontSizeBody,
                            ),
                            _buildRadioMethod(
                              icon: Icons.credit_card,
                              title: 'Credit/Debit Card',
                              value: 1,
                              screenWidth: screenWidth,
                              fontSizeBody: fontSizeBody,
                            ),
                            _buildRadioMethod(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Wallet Balance',
                              value: 2,
                              screenWidth: screenWidth,
                              fontSizeBody: fontSizeBody,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Rate Your Driver
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate Your Driver',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                    'assets/images/placeholder_user.png',
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ayesha Khan',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: List.generate(5, (index) {
                                          final isFilled =
                                              index < _driverRating;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _driverRating = index + 1;
                                              });
                                            },
                                            child: Icon(
                                              Icons.star,
                                              size: 22,
                                              color: isFilled
                                                  ? const Color(0xFFFFC107)
                                                  : Colors.grey[300],
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            TextField(
                              controller: _commentController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add a comment (optional)',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFC153b),
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: GoogleFonts.inter(fontSize: fontSizeBody),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),

            // Pay Now Button
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
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  child: Text(
                    'Confirm Payment',
                    style: GoogleFonts.inter(
                      fontSize: fontSizeButton,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildRadioMethod({
    required IconData icon,
    required String title,
    required int value,
    required double screenWidth,
    required double fontSizeBody,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              _selectedPaymentMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedPaymentMethod == value
                  ? const Color(0xFFFC153b)
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
