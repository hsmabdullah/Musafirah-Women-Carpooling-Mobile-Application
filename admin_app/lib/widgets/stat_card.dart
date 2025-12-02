import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height so all dashboard boxes look the same size.
    return SizedBox(
      height: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF1744), size: 26),
              const SizedBox(height: 8),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
