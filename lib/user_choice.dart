import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'passenger_screen.dart';
import 'driver.dart';
import 'login_screen.dart';

class UserChoice extends StatefulWidget {
  const UserChoice({super.key});

  @override
  State<UserChoice> createState() => _UserChoiceState();
}

class _UserChoiceState extends State<UserChoice> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of carousel images
  final List<String> _carouselImages = [
    'Assets/icons/handshake.png',
    'Assets/icons/car_image.png', // Replace with your second carousel image
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size using MediaQuery
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Calculate responsive values using MediaQuery
    final double horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final double logoHeight = (screenHeight * 0.08).clamp(40.0, 70.0);
    final double logoWidth = (screenWidth * 0.60).clamp(200.0, 350.0);
    final double carouselHeight = (screenHeight * 0.28).clamp(200.0, 350.0);
    final double carouselWidth = (screenWidth * 0.70).clamp(250.0, 400.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double fontSizeLarge = (screenWidth * 0.055).clamp(18.0, 24.0);
    final double fontSizeMedium = (screenWidth * 0.038).clamp(14.0, 18.0);
    final double fontSizeSmall = (screenWidth * 0.032).clamp(11.0, 14.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(15.0, 18.0);
    final double fontSizePolicy = (screenWidth * 0.030).clamp(10.0, 13.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFC153b),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.03),

                // App Logo at the top with proper visibility
                Center(
                  child: Image.asset(
                    'Assets/logos/Musafirah_text_logo.png',
                    width: logoWidth,
                    height: logoHeight,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Musafirah',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: fontSizeLarge * 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.06),

                // Image Carousel (2 images)
                SizedBox(
                  height: carouselHeight,
                  width: carouselWidth,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _carouselImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                        child: Image.asset(
                          _carouselImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white24,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                                size: 80,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                // Carousel Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _carouselImages.length,
                    (index) => Container(
                      width: _currentPage == index ? 12.0 : 8.0,
                      height: _currentPage == index ? 12.0 : 8.0,
                      margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.01,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        border: _currentPage == index
                            ? null
                            : Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.035),

                // Tagline Section
                Text(
                  "Empowering Women's Mobility",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: fontSizeLarge,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  "Travel with Confidence",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: fontSizeMedium,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  "A community built by women, for women",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: fontSizeMedium,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  "Safe journeys that support freedom and independence",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: fontSizeSmall,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.045),

                // Login Button (for already signed up users)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (buttonHeight * 0.5).clamp(20.0, 30.0),
                        ),
                      ),
                    ),
                    child: Text(
                      "Already have an account? Login",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: fontSizeButton,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.5),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                      ),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.5),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),

                // Passenger Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to passenger screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PassengerScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (buttonHeight * 0.5).clamp(20.0, 30.0),
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Continue as Passenger",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF42B4E),
                        fontSize: fontSizeButton,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),

                // Driver Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to driver screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8A7B4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (buttonHeight * 0.5).clamp(20.0, 30.0),
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Continue as Driver",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: fontSizeButton,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                // Terms and Policy Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: Text.rich(
                    TextSpan(
                      text: "Joining our app means you agree with our ",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: fontSizePolicy,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms of Use",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            fontSize: fontSizePolicy,
                          ),
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            fontSize: fontSizePolicy,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
