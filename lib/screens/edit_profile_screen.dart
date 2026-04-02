import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musafirah_app/services/database_service.dart';

const _kRed = Color(0xFFFC153B);
const _kRedDark = Color(0xFFD4002A);
const _kBg = Color(0xFFF1F4F8);
const _kCard = Colors.white;
const _kText = Color(0xFF0F172A);
const _kSubText = Color(0xFF64748B);

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _emergencyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _emergencyController =
        TextEditingController(text: widget.userData['emergencyContact'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    final err = await DatabaseService.updatePassenger(
      uid: user.uid,
      fields: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'emergencyContact': _emergencyController.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed. Please try again.',
              style: GoogleFonts.outfit()),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad = isTablet ? size.width * 0.1 : 20.0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Personal Information'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildReadonlyField(
                      label: 'Phone Number',
                      value: widget.userData['phone'] ?? 'Not set',
                      icon: Icons.phone_outlined,
                      hint: 'Cannot be changed',
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Emergency Contact'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _emergencyController,
                      label: 'Emergency Contact Number',
                      icon: Icons.emergency_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 36),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Edit Profile',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final imageUrl = widget.userData['profileImageUrl'] ?? '';
    return Center(
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kRed, width: 3),
              color: Colors.grey[200],
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 44, color: _kSubText))
                  : const Icon(Icons.person, size: 44, color: _kSubText),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kText));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.outfit(fontSize: 15, color: _kText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: _kSubText, fontSize: 13),
          prefixIcon: Icon(icon, color: _kRed, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _kCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildReadonlyField({
    required String label,
    required String value,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _kSubText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: _kSubText)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 15, color: _kText)),
              ],
            ),
          ),
          if (hint != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(hint,
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: _kSubText)),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text('Save Changes',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
