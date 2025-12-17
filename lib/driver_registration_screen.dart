import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'cnic_verification_screen.dart';
import 'driver_license_screen.dart'; // Forward reference to the next step

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CountryCode? _selectedCountryCode;
  bool _otpSent = false;
  String? _generatedOtp;
  String? _otpError;

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;

    // Use consistent OTP for testing convenience
    final otp = "123456";
    setState(() {
      _generatedOtp = otp;
      _otpSent = true;
      _otpError = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your OTP is $otp', style: GoogleFonts.outfit()),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _verifyOtp() {
    if (!_otpSent) {
      _sendOtp();
      return;
    }

    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (_otpController.text.trim() != _generatedOtp) {
      setState(() => _otpError = 'Incorrect OTP, try again');
      return;
    }

    setState(() => _otpError = null);

    // Navigate to CNIC Verification, but we might need a modified version or flow wrapper
    // For now, let's assume CNIC is consistent for both, but we need to chain License after it.
    // Ideally, we'd pass a "nextScreen" or "userType" to CNIC screen, but since we can't easily refactor big files right now,
    // I will navigate to License Screen directly if CNIC was already done, OR we assume this flow:
    // Registration -> License -> Car -> CNIC (or some order).
    // The user said "also add... details of license... vehicle".
    // I will Navigate to the License Screen FIRST to collect driver specific info, then maybe CNIC later?
    // Usually Identity (CNIC) comes first.
    // I will actually stick to: Registration -> CNIC (Existing) -> License -> Car.
    // BUT `CNICVerificationScreen` currently navigates to `SelfieVerificationScreen` then Dashboard.
    // I might need to Create a `DriverCNICVerificationScreen` OR `DriverLicenseScreen` that includes CNIC?
    // Let's create `DriverLicenseScreen` next.

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverLicenseScreen()),
    );
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
          'Sign Up - Driver',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'Create Driver Account',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Enter your phone number to start the application process. You will need to provide your License and Vehicle details.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40),

                // Phone Number Label
                Text(
                  'Phone Number',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                // Flag + Phone Number Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CountryCodePicker(
                        onChanged: (CountryCode countryCode) {
                          setState(() {
                            _selectedCountryCode = countryCode;
                          });
                        },
                        initialSelection: 'PK',
                        favorite: const ['+92', 'PK'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        showFlag: true,
                        textStyle: GoogleFonts.outfit(color: Colors.black87),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        style: GoogleFonts.outfit(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '300 1234567',
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.grey[400],
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFC153b),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 7) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Get OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Get OTP',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // OTP Section
                if (_otpSent) ...[
                  Text(
                    'Enter One-Time Password',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: '123456',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        letterSpacing: 1,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFFC153b),
                          width: 2,
                        ),
                      ),
                      errorText: _otpError,
                    ),
                  ),
                  SizedBox(height: 30),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC153b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Verify & Proceed',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
