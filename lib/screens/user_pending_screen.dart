import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPendingScreen extends StatelessWidget {
  final String status; // 'pending' | 'rejected'

  const UserPendingScreen({
    super.key,
    this.status = 'pending',
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';

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
                  color: isRejected ? Colors.red.shade50 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.error_outline : Icons.hourglass_empty_rounded,
                  size: 80,
                  color: isRejected ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                isRejected ? 'Account Rejected' : 'Verification Pending',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Unfortunately, your account application has been rejected by our administration. Please contact support for more information.'
                    : 'Your account is currently under review by our administration team. This usually takes 24-48 hours. We will notify you once your account is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              if (!isRejected)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1744)),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
