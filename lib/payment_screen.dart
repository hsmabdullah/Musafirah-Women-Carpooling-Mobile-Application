import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        title: Text(
          'Payment Page',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: Center(
        child: Text(
          'Payment Gateway Integration Placeholder',
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ),
    );
  }
}
