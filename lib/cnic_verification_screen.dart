import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
// ignore: unused_import
import 'passenger_screen.dart';
import 'selfie_verification_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_choice.dart';

class CNICVerificationScreen extends StatefulWidget {
  final bool isDriver;
  const CNICVerificationScreen({super.key, this.isDriver = false});

  @override
  State<CNICVerificationScreen> createState() => _CNICVerificationScreenState();
}

class _CNICVerificationScreenState extends State<CNICVerificationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _cnicNameController = TextEditingController();
  final TextEditingController _cnicNumberController = TextEditingController();
  final TextEditingController _cnicDobController = TextEditingController();
  final TextEditingController _cnicIssueController = TextEditingController();
  final TextEditingController _cnicExpiryController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _frontCNICImage;
  File? _backCNICImage;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final List<String> _emergencyRelations = const [
    'Family member',
    'Spouse',
    'Friend',
  ];
  String _emergencyRelation = 'Family member';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    _cnicNameController.dispose();
    _cnicNumberController.dispose();
    _cnicDobController.dispose();
    _cnicIssueController.dispose();
    _cnicExpiryController.dispose();
    _emergencyContactController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _populateFromFrontImage(File frontImage) async {
    final text = await _extractFrontText(frontImage);

    final parsed = _parseFrontData(text);
    setState(() {
      if (parsed['name']?.isNotEmpty ?? false) {
        _cnicNameController.text = parsed['name']!;
        // Auto-fill Personal Details Name
        _fullNameController.text = parsed['name']!;
      }
      if (parsed['number']?.isNotEmpty ?? false) {
        _cnicNumberController.text = parsed['number']!;
      }
      if (parsed['dob']?.isNotEmpty ?? false) {
        _cnicDobController.text = parsed['dob']!;
        // Auto-fill Personal Details DOB
        _dobController.text = parsed['dob']!;
      }
      if (parsed['issue']?.isNotEmpty ?? false) {
        _cnicIssueController.text = parsed['issue']!;
      }
      if (parsed['expiry']?.isNotEmpty ?? false) {
        _cnicExpiryController.text = parsed['expiry']!;
      }
    });
  }

  Future<String> _extractFrontText(File frontImage) async {
    try {
      final inputImage = InputImage.fromFile(frontImage);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  Map<String, String> _parseFrontData(String text) {
    final result = <String, String>{};
    if (text.isEmpty) return result;

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // CNIC number pattern
    final cnicReg = RegExp(r'\b\d{5}-\d{7}-\d\b');
    int cnicIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final match = cnicReg.firstMatch(lines[i]);
      if (match != null) {
        result['number'] = match.group(0)!;
        cnicIndex = i;
        break;
      }
    }

    // Dates with multiple separators (/, -, .)
    String? extractDateForKeyword(List<String> src, List<String> keys) {
      final dateReg = RegExp(
        r'\b\d{2}[\/\-.]\d{2}[\/\-.]\d{4}\b',
      ); // dd/mm/yyyy etc
      // Prefer matches on or near keyword lines
      for (int i = 0; i < src.length; i++) {
        final ll = src[i].toLowerCase();
        final hasKey = keys.any((k) => ll.contains(k));
        if (hasKey) {
          final match = dateReg.firstMatch(src[i]);
          if (match != null) return match.group(0)!;
          // look one line down if keyword line has no date
          if (i + 1 < src.length) {
            final nMatch = dateReg.firstMatch(src[i + 1]);
            if (nMatch != null) return nMatch.group(0)!;
          }
        }
      }
      // Fallback: first date anywhere
      for (final line in src) {
        final match = dateReg.firstMatch(line);
        if (match != null) return match.group(0)!;
      }
      return null;
    }

    final dob = extractDateForKeyword(lines, ['dob', 'birth', 'date of birth']);
    final issue = extractDateForKeyword(lines, [
      'issue',
      'issued',
      'date of issue',
    ]);
    final expiry = extractDateForKeyword(lines, [
      'expiry',
      'expire',
      'valid till',
      'exp',
    ]);

    if (dob != null) result['dob'] = _normalizeDate(dob);
    if (issue != null) result['issue'] = _normalizeDate(issue);
    if (expiry != null) result['expiry'] = _normalizeDate(expiry);

    // Name: prefer lines near CNIC number; allow two-line merge; fallback to best alpha line.
    String? candidateName;
    String sanitizeAlpha(String s) => s
        .replaceAll(RegExp('[^A-Za-z ]'), ' ')
        .replaceAll(RegExp(' +'), ' ')
        .trim();

    // Name Extraction
    // 1. Define Ignore List (Headers often picked up as names)
    final ignoreList = [
      'identity number',
      'identity card',
      'national identity',
      'father name',
      'husband name',
      'country of stay',
      'pakistan',
      'islamic republic',
      'date of birth',
      'date of issue',
      'date of expiry',
      'gender',
      'family no',
      'signature',
      'name', // The label "Name" itself
    ];

    bool isIgnored(String s) {
      final lower = s.toLowerCase();
      return ignoreList.any((term) => lower.contains(term));
    }

    // Helper: Line must not contain digits 0-9 to be a valid name on CNIC
    bool hasDigits(String s) => s.contains(RegExp(r'\d'));

    // Name Extraction

    // Strategy 1: Look for "Name" keyword and pick the next line
    for (int i = 0; i < lines.length - 1; i++) {
      // Precise match for "Name" header as seen in OCR debug
      if (lines[i].trim() == 'Name') {
        final candidate = lines[i + 1];
        if (!isIgnored(candidate) && !hasDigits(candidate)) {
          final alpha = sanitizeAlpha(candidate);
          if (alpha.length >= 3) {
            candidateName = alpha;
            break;
          }
        }
      }
    }

    // Strategy 2: Scan upwards from CNIC Number (Window fallback) - increased window
    if (candidateName == null && cnicIndex > 0) {
      final window = <String>[];
      // Collect lines just above CNIC Number (Increased window size to 8)
      for (int i = cnicIndex - 1; i >= 0 && i >= cnicIndex - 9; i--) {
        window.add(lines[i]);
      }

      for (final line in window) {
        if (isIgnored(line)) continue;
        if (hasDigits(line)) continue;

        final alpha = sanitizeAlpha(line);
        if (alpha.split(' ').length >= 2 && alpha.length >= 3) {
          candidateName = alpha;
          break;
        }
      }
    }

    if (candidateName == null) {
      // Fallback: pick the longest mostly-alpha line not in ignore list
      String best = '';
      for (final line in lines) {
        if (isIgnored(line)) continue;
        if (hasDigits(line)) continue;

        final alpha = sanitizeAlpha(line);
        final ratio = line.isEmpty
            ? 0
            : alpha.replaceAll(' ', '').length / line.length;
        if (ratio > 0.6 &&
            alpha.length > best.length &&
            alpha.split(' ').length >= 2) {
          best = alpha;
        }
      }
      if (best.isNotEmpty) candidateName = best;
    }
    if (candidateName != null) {
      result['name'] = candidateName;
    }

    return result;
  }

  String _normalizeDate(String input) {
    final parts = input.contains('/')
        ? input.split('/')
        : input.contains('-')
        ? input.split('-')
        : [input];
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
    return input;
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 25,
      );
      if (image != null && mounted) {
        if (isFront) {
          final file = File(image.path);
          setState(() {
            _frontCNICImage = file;
          });
          await _populateFromFrontImage(file);
        } else {
          setState(() {
            _backCNICImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
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
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
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

  void _proceedToDashboard() async {
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

      setState(() {
        _isLoading = true;
      });

      try {
        final user = AuthService.currentUser;
        if (user == null) return;

        // Encode CNIC images to Base64 sequentially with aggressive compression
        debugPrint("Encoding front CNIC...");
        String? frontUrl = await AuthService.compressAndEncodeImage(_frontCNICImage!);
        if (frontUrl == null) throw 'Front CNIC encoding failed';

        debugPrint("Encoding back CNIC...");
        String? backUrl = await AuthService.compressAndEncodeImage(_backCNICImage!);
        if (backUrl == null) throw 'Back CNIC encoding failed';

        // If we're here, frontUrl and backUrl are NOT null because of the throws above
        await AuthService.saveUserData(
          uid: user.uid,
          role: widget.isDriver ? 'driver' : 'passenger',
          phone: user.phoneNumber ?? '',
          name: _fullNameController.text.trim(),
          extraData: {
            'city': _cityController.text.trim(),
            'dob': _dobController.text.trim(),
            'cnic_name': _cnicNameController.text.trim(),
            'Cnic_Number': _cnicNumberController.text.trim(),
            'cnic_dob': _cnicDobController.text.trim(),
            'cnic_issue': _cnicIssueController.text.trim(),
            'cnic_expiry': _cnicExpiryController.text.trim(),
            'emergency_relation': _emergencyRelation,
            'emergency_contact': _emergencyContactController.text.trim(),
            'image_cnic_front': frontUrl,
            'image_cnic_back': backUrl,
            'registrationStep': 'cnic_completed',
          },
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SelfieVerificationScreen(isDriver: widget.isDriver),
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
                                    hintText: 'Pick a date',
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

                              // Emergency Contact Relation
                              Text(
                                'Emergency Contact Relation',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeLabel,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              DropdownButtonFormField<String>(
                                initialValue: _emergencyRelation,
                                items: _emergencyRelations
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          r,
                                          style: GoogleFonts.inter(
                                            fontSize: fontSizeBody,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _emergencyRelation = val);
                                  }
                                },
                                decoration: InputDecoration(
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
                              SizedBox(height: screenHeight * 0.02),

                              // Emergency Contact Number
                              Text(
                                'Emergency Contact Number',
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
                                  controller: _emergencyContactController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '03XXXXXXXXX',
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
                                      return 'Please enter an emergency contact number';
                                    }
                                    final digits = value.replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    );
                                    if (digits.length < 7) {
                                      return 'Number is too short';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // CNIC Auto Extract (front side only)
                              Text(
                                'CNIC Details (Auto from Front Image)',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeTitle * 0.70,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.012),
                              Text(
                                'We attempt OCR + NLP on the front image. Edit if needed.',
                                style: GoogleFonts.inter(
                                  fontSize: fontSizeBody * 0.9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),

                              // Name on CNIC
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
                                    hintText: 'Auto-filled from front image',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
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

                              // CNIC Number
                              Text(
                                'CNIC Number',
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
                                    hintText: 'Auto-filled from front image',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
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

                              // DOB on CNIC
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
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
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

                              // Issue Date
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
                                  controller: _cnicIssueController,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
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

                              // Expiry Date
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
                                  controller: _cnicExpiryController,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSizeBody,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: fontSizeHint,
                                      color: Colors.grey[400],
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
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // Front Side of CNIC Card
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
                              SizedBox(height: screenHeight * 0.01),

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
                              SizedBox(height: screenHeight * 0.008),

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
                        SizedBox(height: screenHeight * 0.015),

                        // Back Side of CNIC Card
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
                              SizedBox(height: screenHeight * 0.01),

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
                              SizedBox(height: screenHeight * 0.008),

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
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _proceedToDashboard,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.verified_user, color: Colors.white),
                    label: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Complete Verification',
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
