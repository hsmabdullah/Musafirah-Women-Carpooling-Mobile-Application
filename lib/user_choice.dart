import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'passenger_email_signup_screen.dart';
import 'driver_email_signup_screen.dart';
import 'email_password_login_screen.dart';
import 'screens/admin/admin_login_screen.dart' as admin;

class UserChoice extends StatefulWidget {
  const UserChoice({super.key});

  @override
  State<UserChoice> createState() => _UserChoiceState();
}

class _UserChoiceState extends State<UserChoice>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    // Responsive measurements
    final double headerHeight = screenHeight * 0.45;
    final double logoSize = screenWidth * 0.28;
    // Calculate where content starts to avoid overlapping the logo
    final double contentStartTop = headerHeight + (logoSize * 0.5) + 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/icons/woman_2.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      const Color(0xFFFC153b).withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // Main Content Area (Fixed Layout)
          Positioned(
            top: contentStartTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "Empowering\nWomen's Mobility",
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Select your role to get started",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // Cards
                        _buildRoleCard(
                          context,
                          title: 'Passenger',
                          subtitle: 'Get a safe ride in minutes',
                          color: const Color(0xFFFC153b),
                          icon: Icons.person_rounded,
                          onLogin: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmailPasswordLoginScreen(role: 'passenger'),
                              ),
                            );
                          },
                          onSignUp: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PassengerEmailSignupScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          context,
                          title: 'Driver',
                          subtitle: 'Earn securely on your schedule',
                          color: Colors.black87,
                          icon: Icons.drive_eta_rounded,
                          onLogin: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmailPasswordLoginScreen(role: 'driver'),
                              ),
                            );
                          },
                          onSignUp: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverEmailSignupScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          context,
                          title: 'Admin',
                          subtitle: 'Manage platform securely',
                          color: const Color(0xFF1976D2),
                          icon: Icons.admin_panel_settings_rounded,
                          onLogin: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const admin.LoginScreen(),
                              ),
                            );
                          },
                          onSignUp: null,
                        ),

                        const SizedBox(height: 24),
                        // Terms Text
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 8,
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Add Terms navigation if needed
                                },
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            "By continuing, you agree to our ",
                                      ),
                                      TextSpan(
                                        text: "Terms & Conditions",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Logo (Positioned explicitly)
          Positioned(
            top: headerHeight - (logoSize * 0.5),
            left: 0,
            right: 0,
            child: Center(
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.3,
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(0, -12), // Move slightly up
                        child: Image.asset(
                          'Assets/logos/musafirah_logo_final.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onLogin,
    required VoidCallback? onSignUp,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: icon + title/subtitle
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(0),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 44,
                    ),
                    Icon(icon, color: Colors.white, size: 26),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.12),
            ),
          ),

          // Bottom row: Login + Sign Up buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // Login button
                Expanded(
                  child: GestureDetector(
                    onTap: onLogin,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Log In',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (onSignUp != null) ...[
                  const SizedBox(width: 10),
                  // Sign Up button
                  Expanded(
                    child: GestureDetector(
                      onTap: onSignUp,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_rounded,
                              color: color,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sign Up',
                              style: GoogleFonts.outfit(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
