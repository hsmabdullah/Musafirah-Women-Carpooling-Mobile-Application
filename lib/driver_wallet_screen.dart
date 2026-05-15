import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/auth_service.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Transaction History",
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _uid == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Drivers')
                  .doc(_uid)
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFC153b),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    return _TransactionTile(data: data);
                  },
                );
              },
            ),
    );
  }



  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFC153b).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.login_rounded,
                  color: Color(0xFFFC153b), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view transactions',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFC153b).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFFFC153b), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When passengers pay for their rides,\ntransaction records will appear here.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // How it works card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'How Payment Works',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    icon: Icons.payments_outlined,
                    title: 'Cash Payment',
                    subtitle:
                        'Passenger pays you directly in cash at the end of the ride.',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    icon: Icons.credit_card_rounded,
                    title: 'Online Payment (Stripe)',
                    subtitle:
                        'Passenger pays online via Stripe — you receive the payment directly.',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    icon: Icons.history_rounded,
                    title: 'Transaction History',
                    subtitle:
                        'All payments will be recorded here automatically.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFC153b).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFC153b), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF0F172A))),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String paymentMethod =
        (data['paymentMethod'] as String?) ?? 'Cash';
    final bool isOnline = paymentMethod.toLowerCase() == 'online' ||
        paymentMethod.toLowerCase() == 'stripe';
    final double amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final String passengerName =
        (data['passengerName'] as String?) ?? 'Passenger';
    final String pickup = (data['pickup'] as String?) ?? '';
    final String dropoff = (data['dropoff'] as String?) ?? '';
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final DateTime dateTime = ts?.toDate() ?? DateTime.now();

    return GestureDetector(
      onTap: () => _showTransactionDetails(context, data, paymentMethod, amount, passengerName, pickup, dropoff, dateTime),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOnline
                  ? Icons.credit_card_rounded
                  : Icons.payments_rounded,
              color: isOnline ? Colors.blue[700] : Colors.green[700],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment from $passengerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      '+ Rs ${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (pickup.isNotEmpty || dropoff.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      pickup.isNotEmpty && dropoff.isNotEmpty
                          ? '$pickup → $dropoff'
                          : pickup.isNotEmpty
                              ? pickup
                              : dropoff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOnline ? 'Online (Stripe)' : 'Cash',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOnline
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(dateTime),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showTransactionDetails(
      BuildContext context,
      Map<String, dynamic> data,
      String paymentMethod,
      double amount,
      String passengerName,
      String pickup,
      String dropoff,
      DateTime dateTime) {
    final String screenshotUrl = data['screenshotUrl'] as String? ?? '';
    final String rideId = data['rideId'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction Details',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _detailRow('Passenger', passengerName),
              _detailRow('Amount', 'Rs ${amount.toStringAsFixed(0)}'),
              _detailRow('Method', paymentMethod),
              if (rideId.isNotEmpty) _detailRow('Trip ID', rideId),
              if (pickup.isNotEmpty) _detailRow('Pickup', pickup),
              if (dropoff.isNotEmpty) _detailRow('Dropoff', dropoff),
              _detailRow('Date', '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'),
              if (screenshotUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Payment Screenshot',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: AuthService.getImageProvider(screenshotUrl),
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
