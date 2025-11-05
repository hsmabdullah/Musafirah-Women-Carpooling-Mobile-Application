import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 0; // 0: Card, 1: Cash, 2: Mobile Wallet
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '500',
  );

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_selectedPaymentMethod == 0) {
      // Card payment validation
      if (_cardNumberController.text.isEmpty ||
          _cardNameController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill all card details',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Payment Successful!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(
          'Your payment of PKR ${_amountController.text} has been processed successfully.',
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
    final double fontSizeLabel = (screenWidth * 0.036).clamp(13.0, 15.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(16.0, 18.0);
    final double inputHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
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

                      // Payment Amount Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFC153b),
                          borderRadius: BorderRadius.circular(cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Text(
                                  'PKR',
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeTitle * 0.8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeTitle * 1.2,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Payment Methods Section
                      Text(
                        'Select Payment Method',
                        style: GoogleFonts.inter(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Card Payment Option
                      _buildPaymentMethodCard(
                        context,
                        icon: Icons.credit_card,
                        title: 'Credit/Debit Card',
                        subtitle: 'Pay with Visa, Mastercard, etc.',
                        index: 0,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        fontSizeTitle: fontSizeTitle,
                        fontSizeBody: fontSizeBody,
                        cardRadius: cardRadius,
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Cash Payment Option
                      _buildPaymentMethodCard(
                        context,
                        icon: Icons.money,
                        title: 'Cash Payment',
                        subtitle: 'Pay cash on delivery',
                        index: 1,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        fontSizeTitle: fontSizeTitle,
                        fontSizeBody: fontSizeBody,
                        cardRadius: cardRadius,
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Mobile Wallet Option
                      _buildPaymentMethodCard(
                        context,
                        icon: Icons.account_balance_wallet,
                        title: 'Mobile Wallet',
                        subtitle: 'JazzCash, EasyPaisa, etc.',
                        index: 2,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        fontSizeTitle: fontSizeTitle,
                        fontSizeBody: fontSizeBody,
                        cardRadius: cardRadius,
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Card Details Form (only shown when card is selected)
                      if (_selectedPaymentMethod == 0) ...[
                        Text(
                          'Card Details',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Card Number
                        Text(
                          'Card Number',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeLabel,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        SizedBox(
                          height: inputHeight,
                          child: TextField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '1234 5678 9012 3456',
                              hintStyle: GoogleFonts.inter(
                                fontSize: fontSizeBody * 0.9,
                                color: Colors.grey[400],
                              ),
                              prefixIcon: const Icon(
                                Icons.credit_card,
                                color: Colors.grey,
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
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Cardholder Name
                        Text(
                          'Cardholder Name',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeLabel,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        SizedBox(
                          height: inputHeight,
                          child: TextField(
                            controller: _cardNameController,
                            decoration: InputDecoration(
                              hintText: 'John Doe',
                              hintStyle: GoogleFonts.inter(
                                fontSize: fontSizeBody * 0.9,
                                color: Colors.grey[400],
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.grey,
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
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Expiry and CVV Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expiry',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeLabel,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.008),
                                  SizedBox(
                                    height: inputHeight,
                                    child: TextField(
                                      controller: _expiryController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'MM/YY',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: fontSizeBody * 0.9,
                                          color: Colors.grey[400],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFC153b),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: fontSizeBody,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CVV',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeLabel,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.008),
                                  SizedBox(
                                    height: inputHeight,
                                    child: TextField(
                                      controller: _cvvController,
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: '123',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: fontSizeBody * 0.9,
                                          color: Colors.grey[400],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFC153b),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: fontSizeBody,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
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
                child: ElevatedButton.icon(
                  onPressed: _processPayment,
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    'Pay Now',
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

  Widget _buildPaymentMethodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required double screenWidth,
    required double screenHeight,
    required double fontSizeTitle,
    required double fontSizeBody,
    required double cardRadius,
  }) {
    final bool isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC153b) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFC153b).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFC153b) : Colors.grey[600],
                size: 28,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: fontSizeTitle * 0.9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: fontSizeBody * 0.85,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFC153b) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
