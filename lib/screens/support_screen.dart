import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class SupportScreen extends StatefulWidget {
  final String userRole; // 'passenger' | 'driver'

  const SupportScreen({super.key, required this.userRole});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSending = false;
  bool _submitted = false;

  final List<String> _categories = [
    'General',
    'Ride Issue',
    'Payment Problem',
    'Safety Concern',
    'Account Issue',
    'Other',
  ];

  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I book a ride?',
      answer:
          'Go to the Home tab, enter your pickup and destination, then tap "Find Rides" to see available drivers.',
    ),
    _FaqItem(
      question: 'How is the fare calculated?',
      answer:
          'Fares are calculated based on distance and duration of the trip. You can see the estimated fare before confirming a ride.',
    ),
    _FaqItem(
      question: 'What if my driver doesn\'t show up?',
      answer:
          'If your driver is late or doesn\'t arrive, you can cancel the ride from the active rides screen and book another driver.',
    ),
    _FaqItem(
      question: 'How do I add money to my wallet?',
      answer:
          'Go to the Wallet tab and tap "Top Up". You can add funds using your preferred payment method.',
    ),
    _FaqItem(
      question: 'Is my data safe?',
      answer:
          'Yes. All your personal data is encrypted and stored securely. We never share your information with third parties.',
    ),
    _FaqItem(
      question: 'How do I report a safety issue?',
      answer:
          'Use the "Safety Concern" category in the contact form below, or call our emergency helpline directly.',
    ),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    final subject =
        '[$_selectedCategory] ${_subjectController.text.trim()}';
    final err = await DatabaseService.createSupportTicket(
      uid: user.uid,
      userRole: widget.userRole,
      subject: subject,
      message: _messageController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (err == null) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send. Please try again.',
              style: GoogleFonts.outfit()),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

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
            child: _submitted
                ? _buildSuccessView()
                : SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoBanner(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Frequently Asked Questions'),
                        const SizedBox(height: 12),
                        _buildFaqList(),
                        const SizedBox(height: 28),
                        _buildSectionLabel('Contact Us'),
                        const SizedBox(height: 4),
                        Text(
                          'Our team typically responds within 24 hours.',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: _kSubText),
                        ),
                        const SizedBox(height: 16),
                        _buildContactForm(),
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
                    'Help & Support',
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
                  'We\'re here to help you',
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

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent,
                color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('24/7 Support Available',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                Text('Emergency Helpline: 0800-MUSAFIRAH',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: _kSubText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kText));
  }

  Widget _buildFaqList() {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _faqs
              .asMap()
              .entries
              .map((e) => _FaqTile(
                    item: e.value,
                    isLast: e.key == _faqs.length - 1,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category selector
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle:
                    GoogleFonts.outfit(color: _kSubText, fontSize: 13),
                prefixIcon: const Icon(Icons.category_outlined,
                    color: _kRed, size: 20),
                border: InputBorder.none,
              ),
              style: GoogleFonts.outfit(fontSize: 14, color: _kText),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: _subjectController,
            label: 'Subject',
            icon: Icons.subject_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: _messageController,
            label: 'Describe your issue',
            icon: Icons.message_outlined,
            maxLines: 5,
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Please provide more details (min. 10 characters)'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Send Message',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.outfit(fontSize: 14, color: _kText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.outfit(color: _kSubText, fontSize: 13),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 60.0 : 0.0),
            child: Icon(icon, color: _kRed, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _kCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'Message Sent!',
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _kText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Our support team will get back to you within 24 hours. Thank you for reaching out!',
              style: GoogleFonts.outfit(fontSize: 14, color: _kSubText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Go Back',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ Item Model ─────────────────────────────────────────────────────────────
class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}

// ── FAQ Tile ──────────────────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  final bool isLast;

  const _FaqTile({required this.item, required this.isLast});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.item.question,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded ? _kRed : _kSubText, size: 22),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(widget.item.answer,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _kSubText,
                    height: 1.5)),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!widget.isLast)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
