import 'package:flutter/material.dart';
import 'dart:async';
import 'user_choice.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const UserChoice()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizes with constraints
    final logoSize = (screenWidth * 0.7).clamp(
      200.0,
      300.0,
    ); // Larger logo, capped
    final fontSize = (screenWidth * 0.045).clamp(
      16.0,
      20.0,
    ); // Responsive font size

    return Scaffold(
      backgroundColor: const Color(0xFFFC153b),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo moved up
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: Image.asset(
                          'Assets/logos/Musafirah_logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),

                      Transform.translate(
                        offset: const Offset(0, -110),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Your safe journey, ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'synchronized.',
                                style: TextStyle(
                                  color: Colors.amberAccent.shade100,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
