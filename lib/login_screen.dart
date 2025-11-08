import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/driver.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedUserType; // 'passenger' or 'driver'

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeTitle = (screenWidth * 0.055).clamp(20.0, 28.0);
    final double fontSizeBody = (screenWidth * 0.040).clamp(14.0, 18.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(15.0, 18.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double iconSize = (screenWidth * 0.08).clamp(24.0, 32.0);

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
          'Login',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: fontSizeTitle * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.04),
                
                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.inter(
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Choose how you want to login',
                  style: GoogleFonts.inter(
                    fontSize: fontSizeBody,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.05),

                // User Type Selection
                Text(
                  'I am a:',
                  style: GoogleFonts.inter(
                    fontSize: fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Passenger/Driver Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildUserTypeCard(
                        title: 'Passenger',
                        icon: Icons.person,
                        isSelected: _selectedUserType == 'passenger',
                        onTap: () {
                          setState(() {
                            _selectedUserType = 'passenger';
                          });
                        },
                        metrics: _LoginMetrics(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          fontSizeBody: fontSizeBody,
                          buttonHeight: buttonHeight,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: _buildUserTypeCard(
                        title: 'Driver',
                        icon: Icons.drive_eta,
                        isSelected: _selectedUserType == 'driver',
                        onTap: () {
                          setState(() {
                            _selectedUserType = 'driver';
                          });
                        },
                        metrics: _LoginMetrics(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          fontSizeBody: fontSizeBody,
                          buttonHeight: buttonHeight,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),

                // Login with Google Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _selectedUserType == null
                        ? null
                        : () => _handleGoogleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == null
                          ? Colors.grey[400]
                          : const Color(0xFF4285F4), // Google Blue
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (buttonHeight * 0.5).clamp(20.0, 30.0),
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Icon (G logo style)
                        Container(
                          width: iconSize * 0.7,
                          height: iconSize * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF4285F4),
                                fontSize: iconSize * 0.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Login with Google',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: fontSizeButton,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Login with Phone Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _selectedUserType == null
                        ? null
                        : () => _handlePhoneLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == null
                          ? Colors.grey[400]
                          : const Color(0xFFFC153b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (buttonHeight * 0.5).clamp(20.0, 30.0),
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: iconSize * 0.7,
                          color: Colors.white,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Login with Phone Number',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: fontSizeButton,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: fontSizeBody * 0.9,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: fontSizeBody,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFC153b),
                          fontSize: fontSizeBody,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required _LoginMetrics metrics,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: metrics.screenHeight * 0.02,
          horizontal: metrics.screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC153b).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFC153b)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: metrics.fontSizeBody * 2,
              color: isSelected
                  ? const Color(0xFFFC153b)
                  : Colors.grey[600],
            ),
            SizedBox(height: metrics.screenHeight * 0.01),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: metrics.fontSizeBody,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFFFC153b)
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin() {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select Passenger or Driver first',
            style: GoogleFonts.inter(),
          ),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate Google login
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      // Navigate based on user type
      if (_selectedUserType == 'passenger') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PassengerDashboardScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DriverScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    });
  }

  void _handlePhoneLogin() {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select Passenger or Driver first',
            style: GoogleFonts.inter(),
          ),
        ),
      );
      return;
    }

    // Navigate to phone login screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneLoginScreen(
          userType: _selectedUserType!,
        ),
      ),
    );
  }
}

class _LoginMetrics {
  _LoginMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.fontSizeBody,
    required this.buttonHeight,
  });

  final double screenWidth;
  final double screenHeight;
  final double fontSizeBody;
  final double buttonHeight;
}

