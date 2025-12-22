import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  final String userType; // 'passenger' or 'driver'

  const PhoneLoginScreen({super.key, required this.userType});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CountryCode? _selectedCountryCode;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeTitle = (screenWidth * 0.065).clamp(24.0, 32.0);
    final double fontSizeBody = (screenWidth * 0.040).clamp(14.0, 18.0);
    final double fontSizeLabel = (screenWidth * 0.038).clamp(13.0, 16.0);
    final double fontSizeButton = (screenWidth * 0.045).clamp(16.0, 20.0);
    final double fontSizeResend = (screenWidth * 0.035).clamp(12.0, 15.0);
    final double inputHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);

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
          'Login with Phone',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: fontSizeTitle * 0.9,
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        Text(
                          'Enter Your Phone Number',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'We will send you a verification code to your registered phone number.',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeBody,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),

                        // Phone Number Label
                        Text(
                          'Phone Number',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeLabel,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // Flag + Phone Number Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Flag Section
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: inputHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: CountryCodePicker(
                                  onChanged: (CountryCode countryCode) {
                                    setState(() {
                                      _selectedCountryCode = countryCode;
                                    });
                                  },
                                  initialSelection:
                                      _selectedCountryCode?.code ?? 'PK',
                                  favorite: const ['+92', 'PK'],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  showFlag: true,
                                  alignLeft: false,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                  ),
                                  textStyle: GoogleFonts.inter(
                                    fontSize: fontSizeBody * 0.9,
                                    color: Colors.black87,
                                  ),
                                  dialogTextStyle: GoogleFonts.inter(),
                                  searchStyle: GoogleFonts.inter(),
                                  dialogBackgroundColor: Colors.white,
                                  barrierColor: Colors.black54,
                                  boxDecoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),

                            // Phone Number Field
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: inputHeight,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 15,
                                      textAlign: TextAlign.center,
                                      enabled: !_isOtpSent,
                                      decoration: InputDecoration(
                                        hintText: 'e.g., 300 1234567',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: fontSizeBody,
                                          color: Colors.grey[600],
                                        ),
                                        errorStyle: GoogleFonts.inter(
                                          color: Colors.red,
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                        counterText: '',
                                        filled: true,
                                        fillColor: _isOtpSent
                                            ? Colors.grey[100]
                                            : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFFC153b),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: fontSizeBody,
                                        color: Colors.black87,
                                      ),
                                      validator: (value) {
                                        if (!_isOtpSent &&
                                            (value == null || value.isEmpty)) {
                                          return 'Please enter your phone number';
                                        }
                                        if (!_isOtpSent &&
                                            value != null &&
                                            value.length < 7) {
                                          return 'Phone number is too short';
                                        }
                                        if (!_isOtpSent &&
                                            value != null &&
                                            !RegExp(
                                              r'^[0-9]+$',
                                            ).hasMatch(value)) {
                                          return 'Phone number should contain only digits';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading || _isOtpSent
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isOtpSent
                                  ? Colors.grey[400]
                                  : const Color(0xFFFC153b),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (buttonHeight * 0.5).clamp(20.0, 30.0),
                                ),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Submit',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: fontSizeButton,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // OTP Card (Always visible)
                        Container(
                          padding: EdgeInsets.all(horizontalPadding),
                          decoration: BoxDecoration(
                            color: _isOtpSent ? Colors.white : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isOtpSent
                                  ? const Color(0xFFFC153b)
                                  : Colors.grey[300]!,
                              width: _isOtpSent ? 2 : 1,
                            ),
                            boxShadow: _isOtpSent
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: _isOtpSent
                                        ? const Color(0xFFFC153b)
                                        : Colors.grey[400],
                                    size: fontSizeLabel * 1.2,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Enter Verification Code',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeLabel,
                                      fontWeight: FontWeight.w600,
                                      color: _isOtpSent
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              if (!_isOtpSent)
                                Text(
                                  'Enter your phone number and click Submit to receive OTP',
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody * 0.9,
                                    color: Colors.grey[600],
                                  ),
                                )
                              else ...[
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  enabled: _isOtpSent,
                                  decoration: InputDecoration(
                                    hintText: 'Enter 6-digit OTP',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeBody,
                                      color: Colors.grey[600],
                                    ),
                                    errorStyle: GoogleFonts.inter(
                                      color: Colors.red,
                                      fontSize: 13,
                                      height: 1.2,
                                    ),
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1.5,
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
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody * 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: 8,
                                  ),
                                  validator: (value) {
                                    if (_isOtpSent &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter OTP';
                                    }
                                    if (_isOtpSent &&
                                        value != null &&
                                        value.length != 6) {
                                      return 'OTP must be 6 digits';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive code? ",
                                      style: GoogleFonts.inter(
                                        fontSize: fontSizeResend,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _resendOtp,
                                      child: Text(
                                        'Resend',
                                        style: GoogleFonts.inter(
                                          fontSize: fontSizeResend,
                                          color: const Color(0xFFFC153b),
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                // Verify & Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFC153b),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          (buttonHeight * 0.5).clamp(
                                            20.0,
                                            30.0,
                                          ),
                                        ),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Verify & Login',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: fontSizeButton,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
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

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isOtpSent) {
      _sendOtp();
    } else {
      _verifyOtp();
    }
  }

  void _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final phoneNumber = _phoneController.text.trim();
    final countryCode = _selectedCountryCode?.dialCode ?? '+92';
    final fullPhoneNumber = '$countryCode$phoneNumber';

    await AuthService.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });

        final otpMessage = AuthService.useDemoMode
            ? 'OTP sent to $fullPhoneNumber (Demo: ${AuthService.demoGeneratedOtp})'
            : 'OTP sent to $fullPhoneNumber';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpMessage, style: GoogleFonts.inter()),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.green,
          ),
        );
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification failed: ${e.message}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please request OTP first')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final smsCode = _otpController.text.trim();

    final userCredential = await AuthService.signInWithOTP(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    if (!mounted) return;

    if (userCredential != null && userCredential.user != null) {
      // Login successful
      final uid = userCredential.user!.uid;
      final phone =
          userCredential.user!.phoneNumber ?? AuthService.demoPhone ?? '';

      // Check if user exists in Firestore, if not create basic profile
      if (widget.userType == 'driver') {
        await AuthService.initializeDriverData(uid: uid, phone: phone);
      } else {
        final userDoc = await AuthService.getUserData(uid);
        if (userDoc == null || !userDoc.exists) {
          await AuthService.saveUserData(
            uid: uid,
            role: widget.userType,
            phone: phone,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful!', style: GoogleFonts.inter()),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to appropriate dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => widget.userType == 'passenger'
              ? const PassengerDashboardScreen()
              : const DriverDashboardScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid OTP. Please try again.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOtp() {
    _sendOtp();
    _otpController.clear();
  }
}
