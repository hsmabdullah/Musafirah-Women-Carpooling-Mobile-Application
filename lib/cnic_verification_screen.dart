import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'selfie_verification_screen.dart';

class CNICVerificationScreen extends StatefulWidget {
  const CNICVerificationScreen({super.key});

  @override
  State<CNICVerificationScreen> createState() => _CNICVerificationScreenState();
}

class _CNICVerificationScreenState extends State<CNICVerificationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  // CNIC information (optional, can be auto-filled from images)
  final TextEditingController _cnicNameController = TextEditingController();
  final TextEditingController _cnicNumberController = TextEditingController();
  final TextEditingController _cnicDobController = TextEditingController();
  final TextEditingController _cnicIssueDateController =
      TextEditingController();
  final TextEditingController _cnicExpiryDateController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _frontCNICImage;
  File? _backCNICImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _cnicNameController.dispose();
    _cnicNumberController.dispose();
    _cnicDobController.dispose();
    _cnicIssueDateController.dispose();
    _cnicExpiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontCNICImage = File(image.path);
          } else {
            _backCNICImage = File(image.path);
          }
        });

        // Extract CNIC info from front image only
        if (isFront && _frontCNICImage != null) {
          await _extractCnicInfoFromImages();
        }
      }
    } catch (e) {
<<<<<<< Updated upstream
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
=======
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _extractCnicInfoFromImages() async {
    if (_frontCNICImage == null) return;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Reading CNIC information...', style: GoogleFonts.inter()),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final inputImage = InputImage.fromFile(_frontCNICImage!);
      final RecognizedText recognizedText = await recognizer.processImage(
        inputImage,
      );

      final rawText = recognizedText.text;
      if (rawText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not read text from image. Please fill manually.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
        return;
      }

      // Split into lines and clean them
      final lines = rawText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final upperLines = lines.map((line) => line.toUpperCase()).toList();

      // Extract CNIC Number (format: 12345-1234567-1)
      String? extractCnicNumber() {
        // Try exact format first
        final cnicRegex1 = RegExp(r'\b\d{5}-\d{7}-\d\b');
        final match1 = cnicRegex1.firstMatch(rawText);
        if (match1 != null) {
          return match1.group(0);
        }
        // Try without dashes
        final cnicRegex2 = RegExp(r'\b\d{5}\s*\d{7}\s*\d\b');
        final match2 = cnicRegex2.firstMatch(rawText);
        if (match2 != null) {
          final num = match2.group(0)!.replaceAll(RegExp(r'\s+'), '');
          if (num.length == 13) {
            return '${num.substring(0, 5)}-${num.substring(5, 12)}-${num.substring(12)}';
          }
        }
        return null;
      }

      // Extract name (usually appears after "NAME" label or in first few lines)
      String? extractName() {
        // Look for "NAME" label
        for (int i = 0; i < upperLines.length; i++) {
          final line = upperLines[i];
          if (line.contains('NAME') && !line.contains('FATHER')) {
            // Check if name is on same line after "NAME"
            final nameMatch = RegExp(
              r'NAME[:\s]+([A-Z\s]+)',
              caseSensitive: false,
            ).firstMatch(lines[i]);
            if (nameMatch != null) {
              final name = nameMatch.group(1)?.trim();
              if (name != null && name.length > 2) {
                return name.split(RegExp(r'\s+')).take(2).join(' ');
              }
            }
            // Check next line for name
            if (i + 1 < lines.length) {
              final nextLine = lines[i + 1];
              if (RegExp(r'^[A-Z\s]{3,}$').hasMatch(nextLine.trim())) {
                return nextLine.trim().split(RegExp(r'\s+')).take(2).join(' ');
              }
            }
          }
        }
        // Fallback: look for common name patterns in first few lines
        for (int i = 0; i < lines.length && i < 5; i++) {
          final line = lines[i];
          if (RegExp(r'^[A-Za-z\s]{3,}$').hasMatch(line) &&
              !line.contains('PAKISTAN') &&
              !line.contains('ISLAMIC') &&
              !line.contains('REPUBLIC') &&
              !line.contains('IDENTITY')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 2 && parts.length <= 4) {
              return parts.take(2).join(' ');
            }
          }
        }
        return null;
      }

      // Extract Date (format: DD.MM.YYYY or DD/MM/YYYY)
      String? extractDate(List<String> labels, {bool returnFirst = false}) {
        // Try to find date near a label
        for (int i = 0; i < upperLines.length; i++) {
          final line = upperLines[i];
          if (labels.any((label) => line.contains(label))) {
            // Look for date in same line
            final dateMatch = RegExp(
              r'\b(\d{2}[./]\d{2}[./]\d{4})\b',
            ).firstMatch(lines[i]);
            if (dateMatch != null) {
              return dateMatch.group(1)?.replaceAll('/', '.');
            }
            // Check next 2 lines
            for (int j = i + 1; j <= i + 2 && j < lines.length; j++) {
              final dateMatch2 = RegExp(
                r'\b(\d{2}[./]\d{2}[./]\d{4})\b',
              ).firstMatch(lines[j]);
              if (dateMatch2 != null) {
                return dateMatch2.group(1)?.replaceAll('/', '.');
              }
            }
          }
        }
        // If returnFirst is true, find first date
        if (returnFirst) {
          final allDates = RegExp(
            r'\b(\d{2}[./]\d{2}[./]\d{4})\b',
          ).allMatches(rawText).toList();
          if (allDates.isNotEmpty) {
            return allDates.first.group(1)?.replaceAll('/', '.');
          }
        }
        return null;
      }

      // Extract all values
      final parsedCnicNumber = extractCnicNumber();
      final parsedName = extractName();

      // Extract dates - be more specific
      String? parsedDob;
      String? parsedIssueDate;
      String? parsedExpiryDate;

      // Find all dates first
      final allDates = RegExp(r'\b(\d{2}[./]\d{2}[./]\d{4})\b')
          .allMatches(rawText)
          .map((m) => m.group(1)?.replaceAll('/', '.') ?? '')
          .where((d) => d.isNotEmpty)
          .toList();

      // DOB - usually near "DATE OF BIRTH" or "BIRTH" or first date
      parsedDob = extractDate([
        'DATE OF BIRTH',
        'DOB',
        'BIRTH',
      ], returnFirst: true);
      if (parsedDob == null && allDates.isNotEmpty) {
        parsedDob = allDates[0];
      }

      // Issue Date - usually near "DATE OF ISSUE" or "ISSUE"
      parsedIssueDate = extractDate(['DATE OF ISSUE', 'ISSUE']);

      // Expiry Date - usually near "DATE OF EXPIRY", "EXPIRY", or "VALID TILL"
      parsedExpiryDate = extractDate([
        'DATE OF EXPIRY',
        'EXPIRY',
        'VALID TILL',
        'VALID',
      ]);

      // If we have dates but couldn't identify which is which, use ordering
      if (allDates.length >= 3) {
        // Typically: DOB, Issue, Expiry in order
        parsedDob ??= allDates[0];
        parsedIssueDate ??= allDates[1];
        parsedExpiryDate ??= allDates[2];
      } else if (allDates.length == 2) {
        parsedDob ??= allDates[0];
        parsedIssueDate ??= allDates[1];
      }

      // Update UI
      if (!mounted) return;
      setState(() {
        if (parsedCnicNumber != null && _cnicNumberController.text.isEmpty) {
          _cnicNumberController.text = parsedCnicNumber;
        }
        if (parsedName != null && _cnicNameController.text.isEmpty) {
          _cnicNameController.text = parsedName;
        }
        if (parsedDob != null && _cnicDobController.text.isEmpty) {
          _cnicDobController.text = parsedDob;
        }
        if (parsedIssueDate != null && _cnicIssueDateController.text.isEmpty) {
          _cnicIssueDateController.text = parsedIssueDate;
        }
        if (parsedExpiryDate != null &&
            _cnicExpiryDateController.text.isEmpty) {
          _cnicExpiryDateController.text = parsedExpiryDate;
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final extractedCount = [
          parsedCnicNumber,
          parsedName,
          parsedDob,
          parsedIssueDate,
          parsedExpiryDate,
        ].where((x) => x != null).length;
        if (extractedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Extracted $extractedCount field(s) from CNIC. Please verify.',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to read CNIC automatically. Please fill manually.',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    } finally {
      recognizer.close();
>>>>>>> Stashed changes
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFC153b)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _showImageSourceDialog(bool isFront) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFC153b)),
              title: Text('Take Photo', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isFront);
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
                _pickImage(ImageSource.gallery, isFront);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToSelfieVerification() {
    if (_formKey.currentState!.validate()) {
      if (_frontCNICImage == null || _backCNICImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload both front and back sides of your CNIC',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelfieVerificationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 30.0);
    final double fontSizeTitle = (screenWidth * 0.060).clamp(22.0, 28.0);
    final double fontSizeBody = (screenWidth * 0.038).clamp(14.0, 16.0);
    final double fontSizeLabel = (screenWidth * 0.036).clamp(13.0, 15.0);
    final double fontSizeHint = (screenWidth * 0.035).clamp(12.0, 14.0);
    final double fontSizeButton = (screenWidth * 0.042).clamp(16.0, 18.0);
    final double inputHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double buttonHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final double cardRadius = (screenWidth * 0.035).clamp(12.0, 16.0);
    final double uploadAreaHeight = (screenHeight * 0.20).clamp(150.0, 200.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CNIC Verification',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: (screenWidth * 0.042).clamp(18.0, 20.0),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.025),

                        // Upload Your National ID Section
                        Text(
                          'Upload Your National ID (CNIC)',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          'For your safety and to comply with regulations, please upload clear Images of your CNIC (National Identity Card).',
                          style: GoogleFonts.inter(
                            fontSize: fontSizeBody,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ...[
                          'Ensure all text is readable.',
                          'Use good lighting.',
                          'Avoid glare or shadows.',
                          'Use original document.',
                        ].map(
                          (text) => Padding(
                            padding: EdgeInsets.only(
                              bottom: screenHeight * 0.005,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeBody,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Personal Details Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(horizontalPadding * 0.8),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Details',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeTitle * 0.85,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'Provide your personal information for verification.',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody * 0.9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Full Name Field
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
                                  controller: _fullNameController,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your full name',
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
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
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
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Date of Birth Field
                              Text(
                                'Date of Birth',
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
                                  controller: _dobController,
                                  readOnly: true,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'DD-MM-YYYY',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding * 0.6,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFC153b),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _selectDate(context),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select your date of birth';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Email Field
                              Text(
                                'Email',
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
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding * 0.6,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
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
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    // Email validation regex
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // City Field
                              Text(
                                'City of Residence',
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
                                  controller: _cityController,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your city',
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
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
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
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your city';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // CNIC Information (Optional, auto-fill from CNIC photos)
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
                                'CNIC Information (Optional)',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeTitle * 0.80,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'You can type details manually or let us auto-fill them from your CNIC photos.',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody * 0.9,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // CNIC Name
                              Text(
                                'Name (as on CNIC)',
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
                                  controller: _cnicNameController,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter name from CNIC',
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
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFC153b),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // Optional field – no validator
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // CNIC Number
                              Text(
                                'Identity Number (CNIC)',
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
                                  controller: _cnicNumberController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 41801-0616143-3',
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
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFC153b),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // CNIC Date of Birth
                              Text(
                                'Date of Birth (as on CNIC)',
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
                                  controller: _cnicDobController,
                                  readOnly: true,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'DD.MM.YYYY',
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
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFC153b),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // You can add a date picker here if you want manual input.
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Date of Issue & Date of Expiry
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date of Issue',
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
                                            controller:
                                                _cnicIssueDateController,
                                            readOnly: true,
                                            style: GoogleFonts.inter(
                                              fontSize: fontSizeBody,
                                              color: Colors.black87,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'DD.MM.YYYY',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: fontSizeHint,
                                                color: Colors.grey[400],
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal:
                                                        horizontalPadding * 0.6,
                                                    vertical:
                                                        screenHeight * 0.015,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFFC153b),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date of Expiry',
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
                                            controller:
                                                _cnicExpiryDateController,
                                            readOnly: true,
                                            style: GoogleFonts.inter(
                                              fontSize: fontSizeBody,
                                              color: Colors.black87,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'DD.MM.YYYY',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: fontSizeHint,
                                                color: Colors.grey[400],
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal:
                                                        horizontalPadding * 0.6,
                                                    vertical:
                                                        screenHeight * 0.015,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFFC153b),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // Front Side of CNIC Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(horizontalPadding * 0.8),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.crop_free,
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    'Front Side of CNIC',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeTitle * 0.85,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'Position your CNIC front within the frame, ensure all details are visible and clearly readable.',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody * 0.9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Upload Area
                              GestureDetector(
                                onTap: () => _showImageSourceDialog(true),
                                child: Container(
                                  width: double.infinity,
                                  height: uploadAreaHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: _frontCNICImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _frontCNICImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 50,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(
                                              height: screenHeight * 0.01,
                                            ),
                                            Text(
                                              'Tap to upload or take photo',
                                              style: GoogleFonts.inter(
                                                fontSize: fontSizeHint,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),

                              // Upload/Capture Button
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight * 0.85,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showImageSourceDialog(true),
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Upload/Capture',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeButton * 0.95,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFC153b),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // Back Side of CNIC Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(horizontalPadding * 0.8),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.crop_free,
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    'Back Side of CNIC',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeTitle * 0.85,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'Position your CNIC back within the frame, ensure all details are visible and clearly readable.',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody * 0.9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Upload Area
                              GestureDetector(
                                onTap: () => _showImageSourceDialog(false),
                                child: Container(
                                  width: double.infinity,
                                  height: uploadAreaHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: _backCNICImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _backCNICImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 50,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(
                                              height: screenHeight * 0.01,
                                            ),
                                            Text(
                                              'Tap to upload or take photo',
                                              style: GoogleFonts.inter(
                                                fontSize: fontSizeHint,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),

                              // Upload/Capture Button
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight * 0.85,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showImageSourceDialog(false),
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Upload/Capture',
                                    style: GoogleFonts.inter(
                                      fontSize: fontSizeButton * 0.95,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFC153b),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),

              // Proceed to Selfie Verification Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: screenHeight * 0.02,
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
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _proceedToSelfieVerification,
                    icon: const Icon(Icons.verified_user, color: Colors.white),
                    label: Text(
                      'Proceed to Selfie Verification',
                      style: GoogleFonts.inter(
                        fontSize: fontSizeButton,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
}
