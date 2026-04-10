import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/user_choice.dart';

class UserPendingScreen extends StatefulWidget {
  final String status; // 'pending' | 'rejected' | 'blocked'
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

    // If there is no logged-in user, nothing to listen to.
    if (user == null) {
      return _buildBody(context, widget.status);
    }

    // Real-time listener: as soon as the admin approves/rejects the user,
    // this screen reacts automatically — no manual logout/login needed.
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

        // Auto-navigate when the admin approves the account.
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

    final Color iconBgColor = isRejected || isBlocked
        ? Colors.red.shade50
        : Colors.blue.shade50;
    final Color iconColor =
        isBlocked ? Colors.deepPurple : (isRejected ? Colors.red : Colors.blue);
    final IconData iconData = isBlocked
        ? Icons.block_rounded
        : isRejected
            ? Icons.error_outline
            : Icons.hourglass_empty_rounded;

    final String title = isBlocked
        ? 'Account Blocked'
        : isRejected
            ? 'Account Rejected'
            : 'Verification Pending';

    final String message = isBlocked
        ? 'Your account has been blocked by administration. Please contact support for assistance.'
        : isRejected
            ? 'Unfortunately, your account application has been rejected. Please contact support for more information.'
            : 'Your account is under review by our administration team. This usually takes 24–48 hours.\n\nThis screen will automatically update once you are approved — no need to log out.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 80, color: iconColor),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Spinner only for pending — indicates it's actively listening.
              if (isPending) ...[
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFFC153B)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for approval…',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 40),
              ] else
                const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
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
                    backgroundColor: const Color(0xFFFC153B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
