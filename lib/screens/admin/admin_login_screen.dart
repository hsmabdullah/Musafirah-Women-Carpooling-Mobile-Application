import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isVerySmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 600,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen
                        ? size.width * 0.08
                        : isSmallScreen
                        ? size.width * 0.1
                        : size.width * 0.05,
                    vertical: isVerySmallScreen
                        ? size.height * 0.05
                        : size.height * 0.08,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: isVerySmallScreen ? 20 : 40),
                        // Title
                        Text(
                          'Admin Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isVerySmallScreen
                                ? 24
                                : isSmallScreen
                                ? 28
                                : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 8 : 12),
                        // Subtitle
                        Text(
                          'Access the Musafirah Admin Dashboard securely.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 32 : 48),
                        // Username Field
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 6 : 8),
                        TextFormField(
                          controller: _usernameController,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your admin username',
                            hintStyle: TextStyle(
                              fontSize: isVerySmallScreen ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF1744),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 14 : 16,
                              vertical: isVerySmallScreen ? 14 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isVerySmallScreen ? 20 : 24),
                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 6 : 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              fontSize: isVerySmallScreen ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF1744),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 14 : 16,
                              vertical: isVerySmallScreen ? 14 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isVerySmallScreen ? 32 : 40),
                        // Login Button
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF1744),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isVerySmallScreen ? 14 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                size: isVerySmallScreen ? 18 : 20,
                              ),
                              SizedBox(width: isVerySmallScreen ? 6 : 8),
                              Text(
                                'Login to Dashboard',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 20 : 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
