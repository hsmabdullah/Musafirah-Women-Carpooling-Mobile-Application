import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:musafirah_app/services/database_service.dart';

class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toLowerCase());
}

/// Email sign-in screen.
///
/// Production flow (useDemoMode = false):
///   1. User enters email → taps "Send Sign-in Link"
///   2. Firebase sends an email with a login link automatically
///   3. Screen shows "Check your inbox and tap the link"
///   4. User taps link → browser opens → Firebase completes sign-in there
///   5. Auth state propagates to the app → user is navigated to dashboard
///      automatically (no code entry, no pasting required)
///
/// Demo flow (useDemoMode = true):
///   1. User enters email → taps "Send OTP"
///   2. Enter 123456 → verify
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _scrollController = ScrollController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _isWaitingForLink = false; // true while listening for browser sign-in
  String? _otpError;

  StreamSubscription<User?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Auth state listener ───────────────────────────────────────────────────
  // Starts once the link has been sent. Detects when Firebase processes
  // the link in the browser and propagates the session back to the app.
  void _startListeningForAuth() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null && _isWaitingForLink && mounted) {
        await _onSignInSuccess(user);
      }
    });
  }

  Future<void> _onSignInSuccess(User user) async {
    setState(() {
      _isLoading = true;
      _isWaitingForLink = false;
    });
    _authSub?.cancel();

    String? role = await DatabaseService.getUserRole(user.uid);
    if (role == null) {
      role = 'passenger';
      await DatabaseService.savePassenger(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        email: user.email ?? _emailController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in successfully!', style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => role == 'driver'
            ? const DriverDashboardScreen()
            : const PassengerDashboardScreen(),
      ),
      (route) => false,
    );
  }

  // ── Step 1: Send link / OTP ───────────────────────────────────────────────
  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    AuthService.sendEmailSignInLink(
      email: email,
      onLinkSent: () {
        if (!mounted) return;
        setState(() {
          _otpSent = true;
          _isLoading = false;
          _isWaitingForLink = !AuthService.useDemoMode;
        });

        if (!AuthService.useDemoMode) {
          // Start listening — will auto-navigate when user taps link in email.
          _startListeningForAuth();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });

        final msg = AuthService.useDemoMode
            ? 'Demo OTP sent to $email  (code: ${AuthService.demoGeneratedOtp})'
            : 'Sign-in link sent to $email. Open your email and tap the link.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.outfit()),
            duration: const Duration(seconds: 10),
            backgroundColor: AuthService.useDemoMode
                ? Colors.green
                : Colors.blueGrey,
          ),
        );
      },
      onFailed: (err) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $err', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
    );
  }

  // ── Step 2: Verify demo code ──────────────────────────────────────────────
  void _verifyDemo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    final email = _emailController.text.trim();
    final code = _otpController.text.trim();

    UserCredential? credential;
    try {
      credential = await AuthService.verifyEmailOtp(email: email, otp: code);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = e.message ?? 'Authentication failed.';
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = 'Authentication failed. Please try again.';
      });
      return;
    }

    if (!mounted) return;

    if (credential != null && credential.user != null) {
      await _onSignInSuccess(credential.user!);
    } else {
      setState(() {
        _isLoading = false;
        _otpError = 'Incorrect OTP. Please try again.';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final w = sz.width;
    final h = sz.height;
    final hPad = (w * 0.06).clamp(20.0, 30.0);
    final fTitle = (w * 0.065).clamp(24.0, 32.0);
    final fBody = (w * 0.040).clamp(14.0, 18.0);
    final fLabel = (w * 0.038).clamp(13.0, 16.0);
    final fBtn = (w * 0.045).clamp(16.0, 20.0);
    final fSmall = (w * 0.034).clamp(12.0, 14.0);
    final inputH = (h * 0.065).clamp(50.0, 60.0);
    final btnH = (h * 0.065).clamp(50.0, 60.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Login with Email',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: (w * 0.042).clamp(16.0, 20.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h * 0.04),

                      // Title
                      Text(
                        AuthService.useDemoMode
                            ? 'Sign in with Email OTP'
                            : 'Sign in with Email Link',
                        style: GoogleFonts.outfit(
                          fontSize: fTitle,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: h * 0.015),
                      Text(
                        AuthService.useDemoMode
                            ? 'Enter your email — a demo OTP will appear on screen.'
                            : 'Enter your email. We\'ll send you a one-tap sign-in link — no password needed.',
                        style: GoogleFonts.outfit(
                          fontSize: fBody,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: h * 0.04),

                      // Email field
                      Text(
                        'Email Address',
                        style: GoogleFonts.outfit(
                          fontSize: fLabel,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: h * 0.01),
                      SizedBox(
                        height: inputH,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enabled: !_otpSent,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            _LowerCaseFormatter(),
                          ],
                          decoration: _field(
                            hint: 'yourname@example.com',
                            icon: Icons.email_outlined,
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: fBody,
                            color: Colors.black87,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$',
                            ).hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: h * 0.025),

                      // Send link / OTP button
                      SizedBox(
                        width: double.infinity,
                        height: inputH,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isWaitingForLink)
                              ? null
                              : _sendOtp,
                          style: _btnStyle(),
                          child: _isLoading && !_otpSent
                              ? _spinner()
                              : Text(
                                  _otpSent
                                      ? 'Resend'
                                      : (AuthService.useDemoMode
                                            ? 'Send OTP'
                                            : 'Send Sign-in Link'),
                                  style: GoogleFonts.outfit(
                                    fontSize: fBtn,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: h * 0.03),

                      // Step 2 UI
                      if (_otpSent) ...[
                        if (AuthService.useDemoMode) ...[
                          // Demo: enter 6-digit code
                          Text(
                            'Enter the 6-digit OTP',
                            style: GoogleFonts.outfit(
                              fontSize: fLabel,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: h * 0.01),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: inputH,
                                  child: TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: fBody,
                                      letterSpacing: 4,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '123456',
                                      hintStyle: GoogleFonts.outfit(
                                        color: Colors.grey[400],
                                      ),
                                      counterText: '',
                                      errorText: _otpError,
                                      errorStyle: GoogleFonts.outfit(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFC153b),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (!_otpSent) return null;
                                      if (v == null || v.isEmpty) {
                                        return 'Enter the OTP';
                                      }
                                      if (v.length != 6) {
                                        return 'OTP must be 6 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: w * 0.03),
                              SizedBox(
                                height: inputH,
                                child: OutlinedButton(
                                  onPressed: _sendOtp,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFFC153b),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Resend',
                                    style: GoogleFonts.outfit(
                                      fontSize: fSmall,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFC153b),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Production: waiting for link tap
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueGrey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_isWaitingForLink)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFC153b),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                Text(
                                  'Check your inbox',
                                  style: GoogleFonts.outfit(
                                    fontSize: fLabel,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'We sent a sign-in link to:\n${_emailController.text.trim()}\n\nTap the link in your email — you\'ll be signed in automatically.',
                                  style: GoogleFonts.outfit(
                                    fontSize: fSmall,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: h * 0.04),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom verify button (demo only)
              if (AuthService.useDemoMode)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: h * 0.02,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: btnH,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyDemo,
                      style: _btnStyle(),
                      child: _isLoading
                          ? _spinner()
                          : Text(
                              _otpSent ? 'Verify & Sign In' : 'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: fBtn,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _field({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFFFC153b)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFC153b), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
      );

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFC153b),
    foregroundColor: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget _spinner() => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}
