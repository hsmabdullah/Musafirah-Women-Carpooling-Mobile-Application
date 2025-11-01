import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_screen.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB5132E),
        title: Text(
          'Driver Dashboard',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: Center(
        child: ElevatedButton(
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
            "Start Driving",
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
