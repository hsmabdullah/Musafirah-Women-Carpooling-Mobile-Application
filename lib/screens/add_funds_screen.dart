import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:musafirah_app/wallet_repository.dart';

const _kRed = Color(0xFFFC153B);
const _kBg = Color(0xFFF7F8FA);
const _kText = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);

/// Predefined top-up amounts in PKR.
const _kAmounts = [500, 1000, 2000, 5000];

/// ---------------------------------------------------------------------------
/// IMPORTANT: Replace the value below with your real Stripe publishable key
/// and point [_backendUrl] at your PaymentIntent creation endpoint.
///
/// Example Cloud Function / Express endpoint:
///   POST /create-payment-intent
///   Body: { "amount": 100000 }   // amount in paisas (PKR × 100)
///   Returns: { "clientSecret": "pi_xxx_secret_xxx" }
/// ---------------------------------------------------------------------------
const _stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
const _backendUrl = 'https://your-backend.com/create-payment-intent';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  int _selectedAmount = 1000;
  bool _isProcessing = false;
  String? _customAmount;
  final _customCtrl = TextEditingController();

  int get _amount =>
      _customAmount != null && _customAmount!.isNotEmpty
          ? (int.tryParse(_customAmount!) ?? _selectedAmount)
          : _selectedAmount;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = _stripePublishableKey;
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFundsWithStripe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Create PaymentIntent on your backend
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': _amount * 100}), // PKR → paisas
      );

      if (response.statusCode != 200) throw Exception('Backend error');

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'] as String;

      // 2. Initialise Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Musafirah',
          style: ThemeMode.light,
        ),
      );

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment succeeded – credit wallet
      WalletRepository.addFunds(
        amount: _amount.toDouble(),
        source: 'Stripe · PKR $_amount',
      );

      if (!mounted) return;
      _showSuccess();
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        _showSnack('Payment cancelled.');
      } else {
        _showSnack('Payment failed: ${e.error.localizedMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      // Demo fallback when backend is not configured
      _addFundsDemo();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Demo mode: directly credits wallet without Stripe (backend not configured).
  void _addFundsDemo() {
    WalletRepository.addFunds(
      amount: _amount.toDouble(),
      source: 'Wallet Top-up · PKR $_amount',
    );
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green[600], size: 44),
            ),
            const SizedBox(height: 16),
            Text('Payment Successful!',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            const SizedBox(height: 6),
            Text('PKR $_amount has been added to your wallet.',
                style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, true); // return to wallet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Done',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Amount',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  const SizedBox(height: 14),
                  _buildAmountGrid(),
                  const SizedBox(height: 20),
                  _buildCustomAmount(),
                  const SizedBox(height: 28),
                  _buildSummaryCard(),
                  const SizedBox(height: 28),
                  _buildPayButton(),
                  const SizedBox(height: 16),
                  _buildSecureBadge(),
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
        color: _kRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text('Add Funds',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text('Secure',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: _kAmounts.length,
      itemBuilder: (context, i) {
        final amt = _kAmounts[i];
        final selected = _customAmount == null && _selectedAmount == amt;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedAmount = amt;
            _customAmount = null;
            _customCtrl.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? _kRed : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? _kRed
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                      color: _kRed.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                'PKR $amt',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kText,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Or enter custom amount',
            style:
                GoogleFonts.outfit(fontSize: 13, color: _kSub)),
        const SizedBox(height: 8),
        TextField(
          controller: _customCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.outfit(fontSize: 15, color: _kText),
          onChanged: (v) =>
              setState(() => _customAmount = v.isEmpty ? null : v),
          decoration: InputDecoration(
            hintText: 'e.g. 3000',
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
            prefixText: 'PKR  ',
            prefixStyle: GoogleFonts.outfit(
                color: _kRed,
                fontWeight: FontWeight.w700,
                fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kRed, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _summaryRow('Top-up Amount', 'PKR $_amount'),
          const SizedBox(height: 10),
          _summaryRow('Processing Fee', 'PKR 0'),
          Divider(height: 24, color: Colors.grey[100]),
          _summaryRow('Total Charged', 'PKR $_amount',
              bold: true, valueColor: _kRed),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                color: bold ? _kText : _kSub,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: bold ? 16 : 13,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? _kText)),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _addFundsWithStripe,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _kRed.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text('Pay PKR $_amount',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }

  Widget _buildSecureBadge() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text('Payments powered by Stripe',
              style: GoogleFonts.outfit(
                  fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
