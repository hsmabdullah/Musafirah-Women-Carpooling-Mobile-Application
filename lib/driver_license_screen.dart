import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'driver_vehicle_info_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_choice.dart';

class DriverLicenseScreen extends StatefulWidget {
  const DriverLicenseScreen({super.key});

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  File? _frontLicenseImage;
  File? _backLicenseImage;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 25,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() {
        if (isFront) {
          _frontLicenseImage = file;
          _populateFromLicenseImage(file);
        } else {
          _backLicenseImage = file;
        }
      });
    }
  }

  Future<void> _populateFromLicenseImage(File image) async {
    setState(() => _isLoading = true);
    try {
      final text = await _extractLicenseText(image);
      final data = _parseLicenseData(text);

      setState(() {
        if (data['number']?.isNotEmpty ?? false) {
          _licenseNumberController.text = data['number']!;
        }
        if (data['issue']?.isNotEmpty ?? false) {
          _issueDateController.text = data['issue']!;
        }
        if (data['expiry']?.isNotEmpty ?? false) {
          _expiryDateController.text = data['expiry']!;
        }
      });
    } catch (e) {
      debugPrint('Error extracting license data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _extractLicenseText(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  Map<String, String> _parseLicenseData(String text) {
    final result = <String, String>{};
    if (text.isEmpty) return result;

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. License Number Extraction
    // Pattern: 41801-0616143-3#166 (CNIC-like with # suffix)
    final licenseReg = RegExp(r'\b\d{5}-\d{7}-\d#?\d*\b');

    for (final line in lines) {
      // Prioritize explicit label
      if (line.toLowerCase().contains('license no')) {
        // Check specific pattern first
        final match = licenseReg.firstMatch(line);
        if (match != null) {
          result['number'] = match.group(0)!;
          break;
        }
        // Fallback: look for digits in next line?
      }

      // search universally for the complex pattern
      final match = licenseReg.firstMatch(line);
      if (match != null) {
        result['number'] = match.group(0)!;
        // Don't break yet, keep looking for better matches or continue
      }
    }
    // Specific fix for user's image where License No is labeled clearly
    if (!result.containsKey('number')) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().contains('license no')) {
          // Look at this line and next line
          final stringsToCheck = [lines[i]];
          if (i + 1 < lines.length) stringsToCheck.add(lines[i + 1]);

          for (final s in stringsToCheck) {
            // Look for any long numeric string
            final easyMatch = RegExp(
              r'[0-9-]{5,}',
            ).firstMatch(s.split(':').last);
            if (easyMatch != null) {
              result['number'] = easyMatch.group(0)!.trim();
            }
          }
        }
      }
    }

    // 2. Date Extraction (Issue & Expiry)
    // Pakistani licenses usually have "Issue Date" and "Valid Upto" labels.
    final dateReg = RegExp(
      r'(\d{1,2})[\s-/\.\\]+([a-zA-Z0-9]{2,10}|[0-9]{1,2})[\s-/\.\\]+(\d{2,4})',
    );

    List<DateTime> foundDates = [];
    final matches = dateReg.allMatches(text);
    for (final m in matches) {
      final date = _parseDate('${m.group(1)}-${m.group(2)}-${m.group(3)}');
      if (date != null) {
        foundDates.add(date);
      }
    }
    
    // Remove duplicates
    foundDates = foundDates.toSet().toList();
    
    // Filter out dates that are obviously Date of Birth (> 15 years old)
    final now = DateTime.now();
    foundDates.removeWhere((d) => now.difference(d).inDays / 365.25 > 15);

    foundDates.sort();

    if (foundDates.length >= 2) {
      // Ideal case: Issue and Expiry
      // If there are more than 2, the oldest is Issue, newest is Expiry
      result['issue'] = _formatDate(foundDates.first);
      result['expiry'] = _formatDate(foundDates.last);
    } else if (foundDates.length == 1) {
      // If only one date found, determine if it's Issue or Expiry
      final d = foundDates.first;
      if (d.isAfter(now)) {
        result['expiry'] = _formatDate(d);
      } else {
        result['issue'] = _formatDate(d);
      }
    }

    return result;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
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
        controller.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month]}-${date.year}';
  }


  DateTime? _parseDate(String raw) {
    try {
      // Raw expected: "22-Jan-2029" (normalized via our regex group extraction)
      // separators are "-" because we constructed it that way above.
      final parts = raw.split('-');
      if (parts.length < 3) return null;

      // Sanitize parts to remove OCR noise (e.g. "2029DSP" -> "2029")
      String dStr = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
      String yStr = parts[2].replaceAll(RegExp(r'[^0-9]'), '');
      String mStr = parts[1].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

      if (dStr.isEmpty || yStr.isEmpty || mStr.isEmpty) return null;

      int day = int.parse(dStr);
      int year = int.parse(yStr);
      int month = 1;

      const monthMap = {
        'jan': 1, 'ja': 1, 'ia': 1, 'za': 1,
        'feb': 2, 'fe': 2,
        'mar': 3, 'ma': 3,
        'apr': 4, 'ap': 4, 'ar': 4,
        'may': 5, 'my': 5,
        'jun': 6, 'ju': 6,
        'jul': 7, 'jl': 7,
        'aug': 8, 'au': 8,
        'sep': 9, 'se': 9, 'sp': 9,
        'oct': 10, 'oc': 10,
        'nov': 11, 'no': 11,
        'dec': 12, 'de': 12,
      };

      // StartsWith logic to handle "January" matching "jan"
      bool found = false;
      
      // Check if month is numeric
      final mNum = int.tryParse(mStr);
      if (mNum != null && mNum >= 1 && mNum <= 12) {
        month = mNum;
        found = true;
      } else {
        for (final key in monthMap.keys) {
          if (mStr.startsWith(key)) {
            month = monthMap[key]!;
            found = true;
            break;
          }
        }
      }
      if (!found) return null; // If not a valid month, exclude this date

      // Strict day validation to prevent Dart DateTime rollover
      if (day < 1 || day > 31) return null;
      if (month == 2 && day > 29) return null;
      if ((month == 4 || month == 6 || month == 9 || month == 11) && day > 30) return null;

      // Handle 2-digit years
      if (year < 100) {
        year += (year > 50 ? 1900 : 2000);
      }

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  void _next() async {
    if (_licenseNumberController.text.isEmpty ||
        _frontLicenseImage == null ||
        _backLicenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both images and enter license number'),
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

      // Encode license images to Base64 sequentially with aggressive compression
      debugPrint("Encoding front license...");
      String? frontUrl = await AuthService.compressAndEncodeImage(_frontLicenseImage!);
      if (frontUrl == null) throw 'Front license encoding failed';

      debugPrint("Encoding back license...");
      String? backUrl = await AuthService.compressAndEncodeImage(_backLicenseImage!);
      if (backUrl == null) throw 'Back license encoding failed';

      // Save user data with compressed Base64 strings
      await AuthService.saveUserData(
        uid: user.uid,
        role: 'driver',
        phone: user.phoneNumber ?? '',
        extraData: {
          'License_Number': _licenseNumberController.text.trim(),
          'license_issue_date': _issueDateController.text.trim(),
          'license_expiry': _expiryDateController.text.trim(),
          'image_license_front': frontUrl,
          'image_license_back': backUrl,
          'registrationStep': 'license_completed',
        },
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DriverVehicleInfoScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to upload images. Please try again.';
      if (e.toString().contains('storage/unauthorized')) {
        errorMessage = 'Firebase Storage access denied. Please check rules.';
      } else if (e.toString().contains('storage/retry-limit-exceeded')) {
        errorMessage = 'Upload timed out. Please check your connection.';
      } else {
        errorMessage = 'Error: $e';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
          'Driver Info',
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
              'Driving License Details',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide your Pakistani driving license information.',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            _buildLabel('License Number'),
            _buildTextField(_licenseNumberController, 'DL-1234567'),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Issue Date'),
                      GestureDetector(
                        onTap: () => _selectDate(context, _issueDateController),
                        child: AbsorbPointer(
                          child: _buildTextField(_issueDateController, 'DD-MMM-YYYY'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Valid Upto'),
                      GestureDetector(
                        onTap: () => _selectDate(context, _expiryDateController),
                        child: AbsorbPointer(
                          child: _buildTextField(_expiryDateController, 'DD-MMM-YYYY'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              'Upload License Images',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildUploadBox(
                    'Front Side',
                    _frontLicenseImage,
                    true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildUploadBox('Back Side', _backLicenseImage, false),
                ),
              ],
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
                        'Next Step',
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
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

  Widget _buildUploadBox(String label, File? file, bool isFront) {
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              image: file != null
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
            ),
            child: file == null
                ? const Center(
                    child: Icon(Icons.camera_alt, color: Colors.grey),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
