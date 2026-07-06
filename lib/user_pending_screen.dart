import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/user_choice.dart';

class UserPendingScreen extends StatefulWidget {
  final String status;     // 'pending' | 'rejected' | 'blocked'
  final String collection; // 'Passengers' | 'Drivers'

  const UserPendingScreen({
    super.key,
    this.status = 'pending',
    this.collection = 'Passengers',
  });

  @override
  State<UserPendingScreen> createState() => _UserPendingScreenState();
}

class _UserPendingScreenState extends State<UserPendingScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildBody(context, widget.status);

    // Real-time listener on the user's Firestore document.
    // The moment the admin approves/rejects, this rebuilds and auto-navigates.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final liveStatus = data?['status'] as String? ?? widget.status;
        final isBlocked = data?['isBlocked'] == true;
        final effectiveStatus = isBlocked ? 'blocked' : liveStatus;

        // Auto-navigate to dashboard as soon as admin approves.
        if (effectiveStatus == 'approved' && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final isDriver = widget.collection == 'Drivers';
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => isDriver
                    ? const DriverDashboardScreen()
                    : const PassengerDashboardScreen(),
              ),
              (route) => false,
            );
          });
        }

        return _buildBody(context, effectiveStatus);
      },
    );
  }

  Widget _buildBody(BuildContext context, String effectiveStatus) {
    final isRejected = effectiveStatus == 'rejected';
    final isBlocked = effectiveStatus == 'blocked';
    final isPending = !isRejected && !isBlocked;

    final Color accentColor = isBlocked
        ? Colors.deepPurple
        : isRejected
            ? Colors.red
            : const Color(0xFFFC153b);

    final IconData statusIcon = isBlocked
        ? Icons.block_rounded
        : isRejected
            ? Icons.gpp_bad_rounded
            : Icons.gpp_maybe_rounded;

    final String title = isBlocked
        ? 'Account Blocked'
        : isRejected
            ? 'Account Rejected'
            : 'Verification Underway';

    final String message = isBlocked
        ? 'Your account has been blocked by an administrator. Please contact support if you believe this is a mistake.'
        : isRejected
            ? 'Unfortunately, your account application has been rejected. Please contact support for more information.'
            : 'Your account is under review by our team. This usually takes 24–48 hours.\n\nThis screen will automatically update once you are approved — no need to log out and back in.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, size: 60, color: accentColor),
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Spinner + label visible only while pending.
                if (isPending) ...[
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFC153b)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Waiting for admin approval…',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 40),
                ] else
                  const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const UserChoice()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
