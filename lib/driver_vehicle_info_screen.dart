import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'cnic_verification_screen.dart'; // Navigates to CNIC next
import 'package:musafirah_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_choice.dart';
import 'package:musafirah_app/driver_data.dart';

class DriverVehicleInfoScreen extends StatefulWidget {
  const DriverVehicleInfoScreen({super.key});

  @override
  State<DriverVehicleInfoScreen> createState() =>
      _DriverVehicleInfoScreenState();
}

class _DriverVehicleInfoScreenState extends State<DriverVehicleInfoScreen> {
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  File? _carImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 25,
    );
    if (image != null) {
      setState(() {
        _carImage = File(image.path);
      });
    }
  }

  void _next() async {
    if (_plateController.text.isEmpty || _carImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide car image and plate number'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Encode car image to Base64 with aggressive compression
      debugPrint("Encoding car image...");
      String? carImageUrl = await AuthService.compressAndEncodeImage(_carImage!);
      if (carImageUrl == null) throw 'Car image encoding failed';

      final cap = int.tryParse(_capacityController.text) ?? 4;
      DriverData.carCapacity = cap;
      DriverData.totalCapacity = cap;

      // Save to Firestore
      await AuthService.saveUserData(
        uid: user.uid,
        role: 'driver',
        phone: user.phoneNumber ?? '',
        extraData: {
          'car_model': _modelController.text.trim(),
          'car_year': _yearController.text.trim(),
          'car_color': _colorController.text.trim(),
          'car_number': _plateController.text.trim(),
          'available_seats': cap,
          'image_car_front': carImageUrl,
          'registrationStep': 'vehicle_completed',
        },
      );

      if (!mounted) return;
      // Navigate to CNIC Verification (Reused from existing flow)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CNICVerificationScreen(isDriver: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Info',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFC153b),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text(
                      'Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const UserChoice()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Details',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter details of the car you will be driving.',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            _buildLabel('Car Model (e.g. Honda City)'),
            _buildTextField(_modelController, 'Honda City 1.3'),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Year'),
                      _buildTextField(
                        _yearController,
                        '2023',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Color'),
                      _buildTextField(_colorController, 'White'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('License Plate Number'),
                      _buildTextField(_plateController, 'ABC-123'),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Car Capacity'),
                      _buildTextField(
                        _capacityController,
                        '4',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              'Upload Car Image',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  image: _carImage != null
                      ? DecorationImage(
                          image: FileImage(_carImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _carImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to upload car photo',
                            style: GoogleFonts.outfit(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC153b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        'Complete Registration',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
