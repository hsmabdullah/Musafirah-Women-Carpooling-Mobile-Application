import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          'Terms of Use',
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
                'Musafirah — Terms of Use',
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: sectionSpacing / 2),
              Text(
                'Last updated: 02 December 2025',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: sectionSpacing),
              _buildParagraph(
                'Welcome to Musafirah. These Terms of Use (“Agreement”) govern your access to and use of the Musafirah mobile application, website, products, content, and platform services (collectively, the “Platform”). By registering, accessing, or using the Platform you confirm that you accept these terms and form a binding contract with the entity operating Musafirah (referred to below as “Musafirah”, “we”, “us” or “our”). If you do not agree to these terms, do not use the Platform.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '1. Overview — Platform & Relationship',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '1.1 Platform role.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Musafirah is a technology platform that connects verified women drivers (“Riders”) with verified women passengers (“Customers”) for women-only carpooling. Musafirah facilitates matching, communication, safety features and record-keeping — it does not provide transportation services itself. All rides and transportation services are provided by independent Riders.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '1.2 Independent contractors.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Riders are independent third-party service providers. Riders are not employees, agents, or representatives of Musafirah. Musafirah does not control how a Rider performs a ride beyond the Platform features and does not assume liability for Riders’ actions except as expressly stated in this Agreement.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '1.3 Agreement scope.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'These Terms, together with the Privacy Policy and any supplemental policies posted in the app, form the complete agreement between you and Musafirah governing your use of the Platform.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '2. Eligibility & Account Registration',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '2.1 Age & capacity.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'To create an account you must be at least 18 years old (or meet the local legal age to enter into a binding agreement) and have legal capacity to contract.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '2.2 Single account.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Each person may register only one account. You must provide accurate, current, and complete information during registration and keep it updated.',
                bodyFontSize,
              ),
              _buildSubSectionTitle('2.3 Verification.', headingFontSize * 0.9),
              _buildParagraph(
                'Musafirah requires identity verification (CNIC upload, selfie/liveness check, and OTP). Riders must also submit vehicle details where applicable. Admin manually reviews verification documents. Failure to verify may limit access to features.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '2.4 Account security.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'You are responsible for maintaining the confidentiality of your account credentials. Notify Musafirah immediately of any unauthorized use.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('3. User Types & Conduct', headingFontSize),
              _buildSubSectionTitle('3.1 User roles.', headingFontSize * 0.9),
              _buildParagraph('The Platform supports:', bodyFontSize),
              _buildBulletPointWithTitle(
                'Riders (Drivers):',
                'women offering rides.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Customers (Passengers):',
                'women requesting/joining carpools.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Admin:',
                'manages verification, disputes, and safety monitoring.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing / 2),
              _buildSubSectionTitle(
                '3.2 Women-only policy.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Musafirah is strictly for women drivers and women passengers. Users must comply with this policy; attempts to register or participate as non-women will result in immediate suspension or account termination.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '3.3 Acceptable conduct.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Users must act lawfully, respectfully and safely. Prohibited conduct includes harassment, discrimination, violence, sexual misconduct, supplying false documents, fraud, or any act that endangers others.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '3.4 Zero tolerance.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Musafirah enforces a strict zero-tolerance policy on harassment, discrimination, sexual misconduct and other illegal or unsafe behavior. Complaints are investigated and may lead to suspension, deactivation, or referral to authorities.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '4. Booking, Rides & Payments',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '4.1 Booking process.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Customers may request or join carpools; Riders post available rides with route, time, capacity and fare details. A ride becomes confirmed according to the app flow (e.g., Rider acceptance).',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '4.2 Cash-only payments (current version).',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Musafirah’s payment method for this version is cash. Payment is made in person at trip end unless the Platform indicates otherwise. Musafirah may support other payment methods in future; changes will be notified.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '4.3 Mutual payment verification.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'After the trip ends, both Customer and Rider must confirm in-app that cash payment was received/paid. Once both parties confirm, the Platform generates a payment confirmation notification logged in the system. This confirmation is the official record of payment for the trip.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '4.4 Fare agreements.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Fare for each Customer may be set per-ride or per-customer as posted by the Rider; Customers and Riders must agree on fare terms through the Platform’s flow prior to travel. Any additional charges requested outside the agreed fare are prohibited.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '4.5 Disputes over payment.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'If either party disputes payment, they should report via the app immediately. Musafirah will review logs, confirmations, and available evidence. Musafirah may suspend accounts pending investigation.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '5. Safety Features & Incidents',
                headingFontSize,
              ),
              _buildSubSectionTitle('5.1 Safety tools.', headingFontSize * 0.9),
              _buildParagraph(
                'The Platform offers features such as live ride sharing, trusted contact notifications, and an SOS emergency button. Users must use these features responsibly.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '5.2 Emergency contacts.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Users are encouraged to register trusted emergency contacts. Musafirah may share trip data with emergency contacts if an SOS is triggered.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '5.3 Incident reports.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Report any safety incidents, harassment, criminal activity, or violations immediately through the app. Musafirah may share relevant information with law enforcement when required.',
                bodyFontSize,
              ),
              _buildSubSectionTitle('5.4 Limitations.', headingFontSize * 0.9),
              _buildParagraph(
                'While we implement verification and safety measures, Musafirah cannot guarantee absolute safety. You use the Platform and rides at your own risk.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '6. User Content, Ratings & Reviews',
                headingFontSize,
              ),
              _buildSubSectionTitle('6.1 User content.', headingFontSize * 0.9),
              _buildParagraph(
                'Any content you post (profile info, messages, reviews) must comply with the law and these Terms. You retain ownership of your content but grant Musafirah a worldwide, royalty-free license to use it for Platform operation and improvement.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '6.2 Ratings & reviews.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Customers and Riders can rate each other. Musafirah may use ratings to manage access, privileges or deactivation. Ratings may be reviewed for abuse or manipulation.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('7. Privacy & Personal Data', headingFontSize),
              _buildParagraph(
                'Your use of personal data is governed by our Privacy Policy. By using Musafirah you consent to collection, processing and sharing of your personal data as described in that policy. Sensitive documents submitted for verification are handled per the Privacy Policy and may be retained for verification and safety purposes.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '8. Restrictions & Prohibited Actions',
                headingFontSize,
              ),
              _buildParagraph('You must not:', bodyFontSize),
              _buildBulletPoint(
                'Use the Platform for unlawful purposes or to promote illegal activities.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Share, sell or misuse other users’ personal information.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Submit false, forged or misleading identity documents.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Use unauthorized tools, automation, bots, or attempts to manipulate the Platform.',
                bodyFontSize,
              ),
              _buildBulletPoint(
                'Solicit, coerce or induce other users to cancel orders or commit fraud.',
                bodyFontSize,
              ),
              _buildParagraph(
                'Violations may result in immediate suspension, account termination, and legal action.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '9. Musafirah Rights & Remedies',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '9.1 Investigation & action.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'We may investigate breaches and take reasonable actions including warnings, temporary suspension, permanent deactivation, or legal referral.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '9.2 Modifications.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'We may change features, fees, and terms. Material changes will be posted in the app; continued use constitutes acceptance.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '9.3 Removal of content.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'We may remove or restrict access to any content that violates these Terms or harms users.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('10. Intellectual Property', headingFontSize),
              _buildParagraph(
                'The Platform and its content (design, logos, code, text, images) are owned by Musafirah or licensors. You are granted a limited, non-transferable license to use the Platform for its intended purposes. Do not copy, reproduce or create derivative works without permission.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '11. Disclaimers & Limitation of Liability',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '11.1 No carrier/guarantee.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Musafirah only provides a platform for arranging rides. We do not provide transportation services and are not responsible for the conduct, actions, or omissions of Riders or Customers.',
                bodyFontSize,
              ),
              _buildSubSectionTitle('11.2 Disclaimer.', headingFontSize * 0.9),
              _buildParagraph(
                'THE PLATFORM IS PROVIDED “AS IS.” TO THE MAXIMUM EXTENT PERMITTED BY LAW, MUSAFIRAH DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '11.3 Limitation of liability.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'TO THE MAXIMUM EXTENT PERMITTED BY LAW, MUSAFIRAH WILL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFIT, INCOME OR REVENUE ARISING FROM YOUR USE OF THE PLATFORM OR ANY RIDE. MUSAFIRAH’S AGGREGATE LIABILITY FOR DIRECT DAMAGES IS LIMITED TO THE AMOUNT, IF ANY, ACTUALLY PAID BY YOU TO MUSAFIRAH IN THE PRIOR TWELVE (12) MONTHS, UNLESS OTHERWISE REQUIRED BY LAW.',
                bodyFontSize,
              ),
              _buildSubSectionTitle('11.4 Lost items.', headingFontSize * 0.9),
              _buildParagraph(
                'Musafirah is not responsible for lost, stolen or damaged items left in vehicles. We will assist on a best-effort basis.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('12. Indemnity', headingFontSize),
              _buildParagraph(
                'You agree to indemnify and hold Musafirah, its officers, employees and agents harmless from any claims, losses, damages, liabilities and expenses (including reasonable legal fees) arising out of your use of the Platform, your breach of these Terms, or your interactions with other users.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '13. Termination & Account Deactivation',
                headingFontSize,
              ),
              _buildSubSectionTitle('13.1 By you.', headingFontSize * 0.9),
              _buildParagraph(
                'You may delete your account via app settings. Certain data may be retained after deletion in accordance with our Privacy Policy and applicable law.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '13.2 By Musafirah.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'We may suspend or terminate accounts for violations, safety risks, legal reasons, or other conduct in Musafirah’s reasonable discretion. We will try to notify you where feasible.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '13.3 Consequences.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Upon termination, your right to use the Platform ends but accrued rights and obligations (e.g., dispute resolution, indemnity) survive.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle(
                '14. Dispute Resolution & Governing Law',
                headingFontSize,
              ),
              _buildSubSectionTitle(
                '14.1 Governing law.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'These Terms are governed by the laws of Pakistan.',
                bodyFontSize,
              ),
              _buildSubSectionTitle(
                '14.2 Dispute resolution.',
                headingFontSize * 0.9,
              ),
              _buildParagraph(
                'Parties will attempt to resolve disputes amicably. If not resolved, disputes may be referred to arbitration or the competent courts in Pakistan as per applicable law. (You may specify arbitration rules/venue in your final deployment.)',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('15. Changes to the Terms', headingFontSize),
              _buildParagraph(
                'We may update these Terms from time to time. We will post the revised Terms in the app with an updated “Last updated” date. Continued use after changes means you accept the updated Terms.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('16. Miscellaneous', headingFontSize),
              _buildBulletPointWithTitle(
                'Severability:',
                'If a provision is invalid it will be replaced by a valid provision reflecting the parties’ intent; remaining Terms remain effective.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'No waiver:',
                'Failure to enforce a right is not a waiver.',
                bodyFontSize,
              ),
              _buildBulletPointWithTitle(
                'Assignment:',
                'You may not assign rights without our consent; Musafirah may assign rights freely.',
                bodyFontSize,
              ),
              SizedBox(height: sectionSpacing),

              _buildSectionTitle('17. Contact', headingFontSize),
              _buildParagraph(
                'For questions, support or complaints contact:',
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
                'Address: [Insert official company / institute address]',
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
