import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
<<<<<<< Updated upstream
=======
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/models/emergency_contact.dart';
import 'package:musafirah_app/services/emergency_contact_service.dart';
>>>>>>> Stashed changes
import 'dart:io';
import 'passenger.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

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

  // Emergency Contacts
  int _numberOfContacts = 1;
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _phoneControllers = [];
  final List<TextEditingController> _relationshipControllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeContactControllers();
  }

  void _initializeContactControllers() {
    for (int i = 0; i < 3; i++) {
      _nameControllers.add(TextEditingController());
      _phoneControllers.add(TextEditingController());
      _relationshipControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _relationshipControllers) {
      controller.dispose();
    }
    super.dispose();
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
        imageQuality: 85,
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

  void _addContact() {
    if (_numberOfContacts < 3) {
      setState(() {
        _numberOfContacts++;
      });
    }
  }

  void _removeContact(int index) {
    if (_numberOfContacts > 1) {
      setState(() {
        _nameControllers[index].clear();
        _phoneControllers[index].clear();
        _relationshipControllers[index].clear();
        _numberOfContacts--;
        // Shift remaining contacts up
        for (int i = index; i < _numberOfContacts; i++) {
          _nameControllers[i].text = _nameControllers[i + 1].text;
          _phoneControllers[i].text = _phoneControllers[i + 1].text;
          _relationshipControllers[i].text =
              _relationshipControllers[i + 1].text;
          _nameControllers[i + 1].clear();
          _phoneControllers[i + 1].clear();
          _relationshipControllers[i + 1].clear();
        }
      });
    }
  }

  Future<void> _saveEmergencyContacts() async {
    List<EmergencyContact> contacts = [];
    for (int i = 0; i < _numberOfContacts; i++) {
      final name = _nameControllers[i].text.trim();
      final phone = _phoneControllers[i].text.trim();
      final relationship = _relationshipControllers[i].text.trim();

      if (name.isNotEmpty && phone.isNotEmpty && relationship.isNotEmpty) {
        contacts.add(
          EmergencyContact(
            name: name,
            phoneNumber: phone,
            relationship: relationship,
          ),
        );
      }
    }
    if (contacts.isNotEmpty) {
      await EmergencyContactService.saveEmergencyContacts(contacts);
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    // Save emergency contacts
    await _saveEmergencyContacts();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
<<<<<<< Updated upstream
        MaterialPageRoute(builder: (context) => const PassengerDashboard()),
=======
        MaterialPageRoute(
          builder: (context) => const PassengerDashboardScreen(),
        ),
>>>>>>> Stashed changes
        (route) => false,
      );
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Main content - scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.02),

                      // Emergency Contacts Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.8),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Contact Details',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeTitle * 0.85,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            Text(
                              'Add emergency contacts (1-3) that will be available on your SOS button.',
                              style: GoogleFonts.inter(
                                fontSize: fontSizeBody * 0.9,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Dynamic contact forms
                            ...List.generate(_numberOfContacts, (index) {
                              return _buildEmergencyContactForm(
                                index: index,
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                horizontalPadding: horizontalPadding,
                                fontSizeLabel: (screenWidth * 0.036).clamp(
                                  13.0,
                                  15.0,
                                ),
                                fontSizeBody: fontSizeBody,
                                fontSizeHint: (screenWidth * 0.035).clamp(
                                  12.0,
                                  14.0,
                                ),
                                inputHeight: (screenHeight * 0.065).clamp(
                                  50.0,
                                  60.0,
                                ),
                                isLast: index == _numberOfContacts - 1,
                              );
                            }),

                            // Add Contact Button
                            if (_numberOfContacts < 3)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: screenHeight * 0.015,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _addContact,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFFFC153b),
                                    ),
                                    label: Text(
                                      'Add Another Contact',
                                      style: GoogleFonts.inter(
                                        fontSize: fontSizeBody,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFC153b),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFFC153b),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.015,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Introduction Text for Selfie Section
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
                      Container(
                        height: screenHeight * 0.35,
                        width: double.infinity,
                        padding: EdgeInsets.all(horizontalPadding * 0.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius * 0.8),
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
                                              size: (screenHeight * 0.12).clamp(
                                                60.0,
                                                100.0,
                                              ),
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
                      SizedBox(height: screenHeight * 0.02),

                      // Tips Section - Compact
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
                          SizedBox(height: screenHeight * 0.006),

                          // Tip Items - Compact spacing
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
                              SizedBox(height: screenHeight * 0.004),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text:
                                    'Look directly at the camera with a neutral expression.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.004),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text: 'Remove any glasses, hats, or masks.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                              SizedBox(height: screenHeight * 0.004),
                              _buildTipItem(
                                context,
                                icon: Icons.check_circle_outline,
                                text:
                                    'Make sure your entire face is visible and in focus.',
                                screenWidth: screenWidth,
                                fontSizeBody: fontSizeBody,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
<<<<<<< Updated upstream
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
                    color: Colors.grey.withOpacity(0.1),
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
=======
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
>>>>>>> Stashed changes
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
      ),
    );
  }

  Widget _buildEmergencyContactForm({
    required int index,
    required double screenWidth,
    required double screenHeight,
    required double horizontalPadding,
    required double fontSizeLabel,
    required double fontSizeBody,
    required double fontSizeHint,
    required double inputHeight,
    required bool isLast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) SizedBox(height: screenHeight * 0.02),
        Row(
          children: [
            Expanded(
              child: Text(
                'Emergency Contact ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFC153b),
                ),
              ),
            ),
            if (_numberOfContacts > 1 && isLast)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeContact(index),
                tooltip: 'Remove Contact',
              ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),

        // Name Field
        Text(
          'Full Name',
          style: GoogleFonts.inter(
            fontSize: fontSizeLabel,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        SizedBox(
          height: inputHeight,
          child: TextFormField(
            controller: _nameControllers[index],
            style: GoogleFonts.inter(
              fontSize: fontSizeBody,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter contact name',
              hintStyle: GoogleFonts.inter(
                fontSize: fontSizeHint,
                color: Colors.grey[400],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 0.6,
                vertical: screenHeight * 0.015,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFFC153b),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact name';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.015),

        // Phone Number Field
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: fontSizeLabel,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        SizedBox(
          height: inputHeight,
          child: TextFormField(
            controller: _phoneControllers[index],
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(
              fontSize: fontSizeBody,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              hintStyle: GoogleFonts.inter(
                fontSize: fontSizeHint,
                color: Colors.grey[400],
              ),
              prefixIcon: const Icon(Icons.phone, color: Colors.grey, size: 20),
              contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 0.6,
                vertical: screenHeight * 0.015,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFFC153b),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (value.trim().length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.015),

        // Relationship Field
        Text(
          'Relationship',
          style: GoogleFonts.inter(
            fontSize: fontSizeLabel,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        SizedBox(
          height: inputHeight,
          child: TextFormField(
            controller: _relationshipControllers[index],
            style: GoogleFonts.inter(
              fontSize: fontSizeBody,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Mother, Father, Sister, Friend',
              hintStyle: GoogleFonts.inter(
                fontSize: fontSizeHint,
                color: Colors.grey[400],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 0.6,
                vertical: screenHeight * 0.015,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFFC153b),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter relationship';
              }
              return null;
            },
          ),
        ),
      ],
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
      ..color = Colors.white.withOpacity(0.3)
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
