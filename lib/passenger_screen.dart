import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/payment_screen.dart';
import 'map_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'cnic_verification_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CountryCode? _selectedCountryCode;
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _otpError;

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

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
          _otpSent = true;
          _isLoading = false;
          _otpError = null;
        });

        final otpMessage = AuthService.useDemoMode
            ? 'OTP sent to $fullPhoneNumber (Demo: ${AuthService.demoGeneratedOtp})'
            : 'OTP sent to $fullPhoneNumber';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpMessage, style: GoogleFonts.inter()),
            duration: const Duration(seconds: 8),
            backgroundColor: AuthService.useDemoMode ? Colors.green : null,
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
    if (!_otpSent) {
      _sendOtp();
      return;
    }

    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

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
      // Success
      final uid = userCredential.user!.uid;
      final phone =
          userCredential.user!.phoneNumber ?? AuthService.demoPhone ?? '';

      // Save initial passenger data
      await AuthService.saveUserData(uid: uid, role: 'passenger', phone: phone);

      setState(() {
        _isLoading = false;
        _otpError = null;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CNICVerificationScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _otpError = 'Incorrect OTP, try again';
      });
    }
  }

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
          'Sign Up - Passenger',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: (screenWidth * 0.042).clamp(16.0, 20.0),
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
                          'Verify Your Account',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Enter your phone number to receive a one-time password (OTP) and securely sign up. A 6-digit code will be sent to your number.',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeBody,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),

                        // 📱 Phone Number Label
                        Text(
                          'Phone Number',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeLabel,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // 📞 Flag + Phone Number Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🇵🇰 Flag Section - 30%
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

                            // ☎️ Phone Number Field - 70%
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
                                        fillColor: Colors.white,
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
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (value.length < 7) {
                                          return 'Phone number is too short';
                                        }
                                        if (!RegExp(
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

                        // 📨 Get OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: inputHeight,
                          child: ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC153b),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Get OTP',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeButton,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // 🔢 OTP Section
                        if (_otpSent) ...[
                          Text(
                            'One-Time Password (OTP)',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeLabel,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: inputHeight,
                                  child: TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: 'Enter 6-digit OTP',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: fontSizeBody,
                                        color: Colors.grey[600],
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
                                      errorText: _otpError,
                                      errorStyle: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody,
                                      color: Colors.black87,
                                    ),
                                    validator: (value) {
                                      if (!_otpSent) return null;
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter OTP';
                                      }
                                      if (value.length != 6) {
                                        return 'OTP must be 6 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              SizedBox(
                                height: inputHeight,
                                child: OutlinedButton(
                                  onPressed: _sendOtp,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFFC153b,
                                      ).withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Resend',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeResend,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFC153b),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ✅ Verify OTP Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: screenHeight * 0.02,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Verify OTP',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeButton,
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
}

// 🎯 Passenger Dashboard
class PassengerDashboard extends StatelessWidget {
  const PassengerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        title: Text(
          'Passenger Dashboard',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC153b),
                  minimumSize: Size(double.infinity, size.height * 0.06),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                },
                child: Text(
                  "Open Map",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5132E),
                  minimumSize: Size(double.infinity, size.height * 0.06),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  );
                },
                child: Text(
                  "Go to Payments",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
