import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MockStripePaymentSheet extends StatefulWidget {
  final int amount;
  const MockStripePaymentSheet({super.key, required this.amount});

  static Future<bool> show(BuildContext context, int amount) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MockStripePaymentSheet(amount: amount),
    );
    return result ?? false;
  }

  @override
  State<MockStripePaymentSheet> createState() => _MockStripePaymentSheetState();
}

class _MockStripePaymentSheetState extends State<MockStripePaymentSheet> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  void _processPayment() async {
    final card = _cardNumberController.text.replaceAll(' ', '');
    // Check if the card matches Stripe's test card
    if (card != '4242424242424242') {
      setState(() => _error = 'Your card was declined. Please try test card 4242.');
      return;
    }
    if (_expiryController.text.isEmpty || _cvcController.text.isEmpty) {
      setState(() => _error = 'Please fill out all fields.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    // Simulate network delay to make it look real
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context, true); // Success
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pay Rs. ${widget.amount}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context, false),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Card Information',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Card number',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: Icon(Icons.credit_card, color: Colors.grey[600]),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'MM / YY',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.grey[300]),
                    Expanded(
                      child: TextField(
                        controller: _cvcController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'CVC',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Country or region',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'ZIP',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.outfit(color: Colors.red[700], fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Stripe's default dark color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay Rs. ${widget.amount}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
