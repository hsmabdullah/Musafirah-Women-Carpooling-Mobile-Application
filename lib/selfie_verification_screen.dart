import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'passenger_dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'dart:io';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_choice.dart';

class SelfieVerificationScreen extends StatefulWidget {
  final bool isDriver;
  const SelfieVerificationScreen({super.key, this.isDriver = false});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _showCameraPreview = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takeSelfieFromCamera() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _selfieImage = File(photo.path);
        _showCameraPreview = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to capture image: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 25,
      );
      if (image != null && mounted) {
        setState(() {
          _selfieImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick image: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFC153b)),
                title: Text('Take Photo', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  if (_isCameraInitialized) {
                    setState(() {
                      _showCameraPreview = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Camera not available',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFFC153b),
                ),
                title: Text('Choose from Gallery', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitVerification() async {
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please take or upload a selfie',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
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

      // Encode selfie to Base64 with aggressive compression
      debugPrint("Encoding selfie...");
      String? selfieUrl = await AuthService.compressAndEncodeImage(_selfieImage!);
      if (selfieUrl == null) throw 'Selfie encoding failed';

      // If we're here, selfieUrl is NOT null because of the throw above
      await AuthService.saveUserData(
        uid: user.uid,
        role: widget.isDriver ? 'driver' : 'passenger',
        phone: user.phoneNumber ?? '',
        extraData: {
          'image_selfie': selfieUrl,
          'registrationStep': 'completed',
          'isVerified': false, // Admin needs to verify
        },
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isDriver
              ? const DriverDashboardScreen()
              : const PassengerDashboardScreen(),
        ),
        (route) => false,
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
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeTitle = (screenWidth * 0.050).clamp(18.0, 22.0);
    final double fontSizeBody = (screenWidth * 0.035).clamp(13.0, 15.0);
    final double fontSizeButton = (screenWidth * 0.040).clamp(15.0, 17.0);
    final double buttonHeight = (screenHeight * 0.060).clamp(48.0, 56.0);
    final double cardRadius = (screenWidth * 0.035).clamp(12.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_showCameraPreview) {
              setState(() {
                _showCameraPreview = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Selfie Verification',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: (screenWidth * 0.040).clamp(17.0, 19.0),
            fontWeight: FontWeight.w600,
          ),
        ),
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
                      'Are you sure you want to logout and cancel registration?'),
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
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserChoice()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content - everything fits on one screen, no scrolling
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.01),

                      // Introduction Text
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.3,
                          ),
                          child: Text(
                            'Please take a clear selfie to verify your identity. This helps us ensure the safety of our community.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: fontSizeBody * 1.05,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Camera Preview or Image Display Card
                      SizedBox(
                        height: screenHeight * 0.4,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(horizontalPadding * 0.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              cardRadius * 0.8,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[200],
                                  child:
                                      _showCameraPreview && _isCameraInitialized
                                      ? Stack(
                                          children: [
                                            Positioned.fill(
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: CircleOverlayPainter(),
                                              ),
                                            ),
                                          ],
                                        )
                                      : _selfieImage != null
                                      ? Image.file(
                                          _selfieImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[100],
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.face_outlined,
                                                size: (screenHeight * 0.12)
                                                    .clamp(60.0, 100.0),
                                                color: Colors.grey[400],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.008,
                                              ),
                                              Text(
                                                'Tap below to take a selfie',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontSize: fontSizeBody * 0.9,
                                                  color: Colors.grey[600],
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
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Tips Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tips for a great selfie',
                            style: GoogleFonts.inter(
                              fontSize: fontSizeTitle * 0.85,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFC153b),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),

                          // Tip Items
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildTipItem(
                                context,
                                icon: Icons.help_outline,
                                text:
                                    'Ensure good lighting, avoid shadows on your face.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text:
                                    'Look directly at the camera with a neutral expression.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text: 'Remove any glasses, hats, or masks.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text:
                                    'Make sure your entire face is visible and in focus.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Capture Selfie & Verify Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: screenHeight * 0.012,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _showCameraPreview
                  ? SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _takeSelfieFromCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC153b),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Capture Selfie',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeButton,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                  : SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _selfieImage != null && !_isLoading
                            ? _submitVerification
                            : _showImageSourceDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC153b),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selfieImage != null
                                        ? Icons.verified
                                        : Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    _selfieImage != null
                                        ? 'Verify Selfie'
                                        : 'Capture Selfie & Verify',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeButton,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required double screenWidth,
    required double fontSizeBody,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFC153b), size: 16),
        SizedBox(width: screenWidth * 0.025),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSizeBody * 0.9,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// Circle overlay painter for camera preview
class CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) * 0.35;

    // Draw darkened area outside circle
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw circle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
