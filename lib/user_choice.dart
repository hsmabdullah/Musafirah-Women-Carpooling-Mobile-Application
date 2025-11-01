import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserChoice extends StatelessWidget {
  const UserChoice({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Calculate responsive values
    final double horizontalPadding = screenWidth * 0.06; // 6% of screen width
    final double logoHeight = screenHeight * 0.07; // 7% of screen height
    final double logoWidth = screenWidth * 0.55; // 55% of screen width
    
    return Scaffold(
      backgroundColor: const Color(0xFFFC153b),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // App Logo (lifted higher)
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'Assets/logos/Musafirah_text_logo.png',
                  width: logoWidth,
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.08),

              // Handshake Image
              Image.asset(
                'Assets/icons/handshake.png',
                width: screenWidth * 0.5,
                height: screenHeight * 0.25,
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.04),

              // Tagline Section
              Text(
                "Empowering Women's Mobility",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: screenWidth * 0.055, // Responsive font size
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "Travel with Confidence\nA community built by women, for women\nSafe journeys that support freedom and independence",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035, // Responsive font size
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),

              // Buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate to passenger screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  "Continue as Passenger",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFC153b),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // Navigate to driver screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5132E),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  "Continue as Driver",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Terms and Policy Text (tightened spacing, centered cleanly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text.rich(
                  TextSpan(
                    text: "By joining our app, you agree with our ",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms of Use",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                      const TextSpan(text: " \nand "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
