import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/screens/support_screen.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _locationSharing = true;
  bool _rideNotifications = true;
  bool _promotionalEmails = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad = isTablet ? size.width * 0.1 : 20.0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionLabel('Location & Privacy'),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: Icons.location_on_outlined,
                    iconColor: _kRed,
                    iconBg: _kRed.withValues(alpha: 0.1),
                    title: 'Location Sharing',
                    subtitle:
                        'Share your real-time location with your driver during active rides',
                    value: _locationSharing,
                    onChanged: (v) =>
                        setState(() => _locationSharing = v),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Notifications'),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFF6366F1),
                    iconBg: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    title: 'Ride Notifications',
                    subtitle:
                        'Get notified about ride status, driver arrival, and updates',
                    value: _rideNotifications,
                    onChanged: (v) =>
                        setState(() => _rideNotifications = v),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleCard(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    title: 'Promotional Emails',
                    subtitle: 'Receive offers, deals and app updates via email',
                    value: _promotionalEmails,
                    onChanged: (v) =>
                        setState(() => _promotionalEmails = v),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Safety'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
                    title: 'Safety Features',
                    items: [
                      'All drivers are verified with CNIC and driving license',
                      'Rides are tracked in real-time for your safety',
                      'Emergency contact feature available during rides',
                      'Only women drivers and passengers on this platform',
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Data & Privacy'),
                  const SizedBox(height: 12),
                  _buildPolicyCard(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Account'),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    icon: Icons.download_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    title: 'Download My Data',
                    subtitle: 'Request a copy of your personal data',
                    onTap: () => _showComingSoon('Data export'),
                  ),
                  const SizedBox(height: 10),
                  _buildActionRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    title: 'Privacy Questions',
                    subtitle: 'Contact support for privacy-related queries',
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SupportScreen(userRole: 'passenger'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDeleteAccountRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Privacy & Security',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Manage your privacy and security settings',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kText));
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: _kSubText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kRed,
            activeTrackColor: _kRed.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kSubText,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _policyRow(
            'Privacy Policy',
            'How we collect and use your data',
            Icons.description_outlined,
            () => _showPolicyDialog(
              title: 'Privacy Policy',
              content:
                  'Musafirah collects only the data necessary to provide our carpooling service. '
                  'This includes your name, phone number, location during rides, and ride history. '
                  'We do not sell your personal data to third parties. Your data is encrypted '
                  'in transit and at rest. You can request deletion of your account and data '
                  'at any time by contacting our support team.',
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _policyRow(
            'Terms of Service',
            'Rules and conditions for using Musafirah',
            Icons.article_outlined,
            () => _showPolicyDialog(
              title: 'Terms of Service',
              content:
                  'By using Musafirah, you agree to use the platform responsibly and safely. '
                  'You must be a registered user to book or offer rides. All users must maintain '
                  'respectful conduct. Musafirah reserves the right to suspend accounts for '
                  'violations of our community guidelines. Ride fares are final once confirmed.',
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _policyRow(
            'Data Retention',
            'How long we keep your information',
            Icons.timer_outlined,
            () => _showPolicyDialog(
              title: 'Data Retention',
              content:
                  'We retain your account data for as long as your account is active. '
                  'Ride history is kept for 2 years for safety and legal compliance. '
                  'After account deletion, your personal data is removed within 30 days. '
                  'Some anonymised data may be retained for analytics purposes.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyRow(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _kSubText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: _kSubText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: _kSubText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountRow() {
    return GestureDetector(
      onTap: _showDeleteAccountDialog,
      child: Container(
        decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRed.withValues(alpha: 0.2)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.delete_outline_rounded, color: _kRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete Account',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kRed)),
                  Text('Permanently delete your account and data',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _kRed.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _kRed.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!', style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPolicyDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: _kText)),
        content: SingleChildScrollView(
          child: Text(content,
              style: GoogleFonts.outfit(
                  color: _kSubText, fontSize: 14, height: 1.6)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: _kText)),
        content: Text(
          'This action is permanent. All your data, ride history, and wallet balance will be deleted and cannot be recovered.\n\nTo delete your account, please contact our support team.',
          style: GoogleFonts.outfit(color: _kSubText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: _kSubText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SupportScreen(userRole: 'passenger'),
                  ),
                );
              }
            },
            child: Text('Contact Support',
                style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }
}
