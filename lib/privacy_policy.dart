import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size using MediaQuery
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Calculate responsive values
    final double horizontalPadding = screenWidth * 0.05;
    final double titleFontSize = (screenWidth * 0.06).clamp(20.0, 28.0);
    final double headingFontSize = (screenWidth * 0.045).clamp(16.0, 22.0);
    final double bodyFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    final double sectionSpacing = screenHeight * 0.02;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFC153b),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Musafirah — Privacy Policy',
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: sectionSpacing / 2),
              Text(
                'Last updated: 29 November 2025',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: sectionSpacing),
              _buildParagraph(
                'Welcome to Musafirah. This Privacy Policy describes how Musafirah (“we”, “us”, “our”) collects, uses, stores, shares, and protects personal information provided by users of the Musafirah mobile application and related services (the “Platform”). Musafirah is a women-only carpooling service that connects verified women drivers (“Riders”) with women passengers (“Customers”) and is managed by the platform administrator (“Admin”).',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing / 2),
              _buildParagraph(
                'By using the Platform, you agree to the collection and use of personal information in accordance with this policy.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('1. Scope & Applicability', headingFontSize),
              _buildParagraph(
                'This policy applies to information collected when you:',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Register or create an account on the Musafirah mobile app;',
                bodyFontSize,
              ),
              _buildBulletPoint('Post, accept, or join rides;', bodyFontSize),
              _buildBulletPoint(
                'Communicate with other users or with Musafirah support;',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Use safety features (live tracking, SOS), or any other Platform functionality.',
                bodyFontSize,
              ),
              _buildParagraph(
                'It does not apply to third-party services linked from the Platform. Where local laws or institution policies require different handling, we will comply with those laws.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '2. What information we collect',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '2.1 Information you provide',
                headingFontSize * 0.9,
              ),
              _buildBulletPointWithTitle(
                'Account & profile:',
                'Full name, phone number, email (optional), city.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Identity & verification:',
                'CNIC (national ID) image and number, selfie image (for liveness check), vehicle details (for Riders), driver’s license (if applicable), and other identity documents requested by Admin for verification.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Emergency contacts:',
                'Name and phone number(s) of trusted contacts you provide.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Ride details & communications:',
                'Pick-up and drop-off addresses, route, ride time, passenger list, comments, messages, photos or audio you upload in chats or reports.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Ratings & feedback:',
                'Reviews, ratings, and complaint/report details.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Support & incident reports:',
                'Any additional information you provide when contacting support or reporting an incident (including photos, recordings, or documents).',
                bodyFontSize,
              ),

              SizedBox(height: sectionSpacing / 2),
              _buildSubSectionTitle(
                '2.2 Information we collect automatically',
                headingFontSize * 0.9,
              ),
              _buildBulletPointWithTitle(
                'Location data:',
                'Precise GPS location when the app is active during a ride or when you grant permission, used to enable rides, live tracking, safety monitoring, and incident investigation.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Device & usage data:',
                'Device model, OS, app version, IP address, timestamps, usage logs and crash reports.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Order and ride meta-data:',
                'Ride ID, timestamps, route distance, and status changes.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '3. How we use your information',
                headingFontSize,
              ),
              _buildParagraph('We use personal information to:', bodyFontSize),
              _buildBulletPoint(
                'Create and manage your account, verify identity and eligibility (CNIC, selfie, OTP verification).',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Enable core services: post rides, join carpools, calculate fares, and provide navigation.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Provide safety and emergency features: live tracking, SOS alerts, and notifications to trusted contacts.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Facilitate dispute resolution, incident handling, and support.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Maintain platform security and prevent fraud, abuse, or prohibited activity.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Improve the Platform’s functionality (analytics, debugging, quality improvements).',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Send non-marketing messages (e.g., ride confirmations, verification messages, safety alerts, and important notices).',
                bodyFontSize,
              ),
              _buildParagraph(
                'Our legal bases include performance of service, legitimate interests (security and fraud prevention), and your consent where required.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('4. Payment and receipts', headingFontSize),
              _buildParagraph(
                'Musafirah currently supports cash payments only. Payment is completed between Rider and Customer at trip end; both parties confirm payment in the app, which triggers a confirmation notification stored in our system. We do not store full bank card details because card payments are not supported in this version.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '5. Sharing your information',
                headingFontSize,
              ),
              _buildParagraph(
                'We may share personal information as follows:',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'With other users:',
                'Basic profile info (name, profile photo, rating), ride details (origin/destination, driver vehicle info) necessary to perform the ride.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'With your emergency contacts:',
                'In case of an SOS or incident, we may share trip and location details with the emergency contacts you provided.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Service providers:',
                'Third-party vendors that help operate the Platform (identity verification providers, cloud storage—e.g., Firebase, push notification services, analytics, or support tools). These vendors process data on our behalf and are bound by confidentiality.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Legal & safety requirements:',
                'When required by law, regulation, or to respond to lawful requests by public authorities, or to protect users’ safety and our rights.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Aggregated or anonymized data:',
                'We may share de-identified statistics for research or improvement purposes.',
                bodyFontSize,
              ),
              _buildParagraph(
                'We will not sell your personal data to third parties.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('6. Automated decisions', headingFontSize),
              _buildParagraph(
                'Musafirah may use automated processes for:',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Verifying uploaded documents (OCR checks), flagging invalid documents for human review;',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Basic ride matching (availability & proximity) and suggesting fares.',
                bodyFontSize,
              ),
              _buildParagraph(
                'Where automated decisions materially affect a user (e.g., account suspension), a human review process and an appeal path will be available.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('7. Data retention', headingFontSize),
              _buildParagraph(
                'We retain personal data for as long as necessary to provide the service and for legitimate business purposes, including:',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Account data while your account is active;',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Transaction and ride records for a reasonable period required for safety, tax or legal compliance (e.g., several years for accounting or regulatory reasons);',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Incident and dispute records for a period needed to investigate and resolve claims.',
                bodyFontSize,
              ),
              _buildParagraph(
                'Exact retention periods may vary by data type and legal requirements. Contact us to request specific retention details.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('8. Your rights and choices', headingFontSize),
              _buildParagraph('You may:', bodyFontSize),
              _buildBulletPoint(
                'Access and update certain account information within the app;',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Request a copy of the personal data we hold about you;',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Request correction or deletion of your personal data (subject to legal or operational exceptions, e.g., records needed for safety or legal compliance);',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Disable location sharing in your device settings (note: disabling location may limit app functionality).',
                bodyFontSize,
              ),
              _buildParagraph(
                'To exercise your rights, use the app settings or contact us at the address below. We may ask for identity verification before honoring requests.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('9. Security', headingFontSize),
              _buildParagraph(
                'We use industry-standard security measures to protect personal data including access controls, encryption in transit, and secure cloud storage. Admin and support access to sensitive identity documents is restricted and logged. While we take reasonable steps to protect data, no system is completely secure—if a breach occurs, we will notify affected users and relevant authorities as required.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('10. Children', headingFontSize),
              _buildParagraph(
                'Musafirah is not intended for users under the age required by local law to form binding agreements (typically 16/18). We do not knowingly collect personal data from children. If we learn we have collected a child’s data, we will take steps to delete it.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('11. Changes to this policy', headingFontSize),
              _buildParagraph(
                'We may update this Privacy Policy to reflect changes in features, legal requirements, or service improvements. We will publish the updated policy in the app and update the “Last updated” date. Continued use of the Platform constitutes acceptance of the updated policy.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('12. Contact us', headingFontSize),
              _buildParagraph(
                'For privacy questions, requests, or concerns, contact:',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing / 4),
              Text(
                'Musafirah Support',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Email: support@musafirah.app',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text(
                'Address: [Insert registered company/institute address here]',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: sectionSpacing * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPointWithTitle(
    String title,
    String text,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
