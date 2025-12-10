import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: December 2025',
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to Musafirah. By using our app, you agree to these terms. Our platform connects women passengers with women drivers to ensure safe and secure travel.',
            ),
            _buildSection(
              '2. User Accounts',
              'You must verify your identity using a valid CNIC and facial verification to use our services. You are responsible for maintaining the confidentiality of your account.',
            ),
            _buildSection(
              '3. Safety Guidelines',
              'We prioritize safety. Both drivers and passengers must adhere to our community guidelines. Any form of harassment or unsafe behavior will result in immediate suspension.',
            ),
            _buildSection(
              '4. Privacy Policy',
              'We collect and protect your data according to our privacy policy. Your location data is used solely for the purpose of the ride service.',
            ),
            _buildSection(
              '5. Payments',
              'Payments are processed securely. You agree to pay for all rides booked through your account.',
            ),
            _buildSection(
              '6. Contact Us',
              'If you have any questions, please contact our support team.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              color: Colors.grey[800],
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
