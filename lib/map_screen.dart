// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map View', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFFFC153b),
      ),
      body: const Center(child: Text('Google Maps Integration Here')),
    );
  }
}
